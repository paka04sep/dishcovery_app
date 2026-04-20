import 'package:dishcovery_app/models/restaurant_model.dart';
import 'package:dishcovery_app/models/restaurant_details_model.dart';
import 'package:dishcovery_app/models/restaurant_mock.dart';
import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:dishcovery_app/services/places_service.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dishcovery_app/models/user_model.dart';
import 'package:dishcovery_app/services/recommendation_engine.dart';
import 'package:dishcovery_app/utils/cuisine_keywords.dart';
import 'package:dishcovery_app/utils/time_utils.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';

class RestaurantService extends ChangeNotifier {
  // Singleton pattern (Nullable to allow reset)
  static RestaurantService? _instance;

  static RestaurantService get instance {
    _instance ??= RestaurantService._internal();
    return _instance!;
  }

  factory RestaurantService() {
    return instance;
  }

  // Allow resetting the instance (e.g. on logout)
  static void reset() {
    if (_instance != null) {
      _instance!.dispose();
      _instance = null;
      if (kDebugMode) print("RestaurantService Instance Destroyed/Reset.");
    }
  }

  RestaurantService._internal() {
    _initializeData();
  }

  List<RestaurantCardData> _restaurants = [];
  final RecommendationEngine _recommendationEngine = RecommendationEngine();
  List<String> _userPreferences = [];
  List<String> _userPriceRangePreferences = [];
  bool _showClosedRestaurants = false;

  // Track ALL swiped IDs in this session to prevent duplicates
  final Set<String> _sessionSwipedIds = {};

  // Store chronological swipe events: [{restaurantId: '...', action: '...', timestamp: DateTime}]
  List<Map<String, dynamic>> _swipeLogs = [];

  double _userMaxDistance = 50.0; // Default max distance
  bool _isReady = false; // Add isReady flag
  bool _isLoadingUser = false; // Flag to track if user data is being fetched

  bool get isReady => _isReady && !_isLoadingUser;

  double _lastKnownLat = 0.0; // Cache location
  double _lastKnownLng = 0.0;

  UserModel? _userModel;

  UserModel? get userModel => _userModel;

  // Subscription to auth state changes
  StreamSubscription<User?>? _authSubscription;

  Future<void> _initializeData() async {
    // 0. Setup Auth Listener to handle login/logout automatically
    _setupAuthListener();
    // Data loading is now deferred to the Auth Listener
  }

  Future<void> _fetchRestaurants() async {
    // 2. Get User Location (Fresh check)
    Position? position = await _getCurrentLocation();
    if (position != null) {
      _lastKnownLat = position.latitude;
      _lastKnownLng = position.longitude;
    }

    List<RestaurantCardData> fetchedRestaurants = [];

    // CRM: Toggle for Mock Data vs Real Data
    if (AppConfig.useMockData) {
      if (kDebugMode) print("DEBUG: Using Firestore");

      // Process Mock Data
      // List<RestaurantCardData> mockList = mockRestaurants;

      // Process Firestore Data (Merge with Mock)
      List<RestaurantCardData> firestoreList = [];
      try {
        final firestoreData = await fetchRestaurantsFromFirestore();
        if (firestoreData.isNotEmpty) {
          firestoreList = firestoreData;
        }
      } catch (e) {
        if (kDebugMode) print("Error fetching/merging Firestore data: $e");
      }

      // fetchedRestaurants = [...mockList, ...firestoreList];
      fetchedRestaurants = [...firestoreList];
    } else {
      // Try fetching from Firestore first
      List<RestaurantCardData> firestoreList =
          await fetchRestaurantsFromFirestore();

      if (firestoreList.isNotEmpty) {
        fetchedRestaurants = firestoreList;
      } else if (position != null) {
        // Fallback: Fetch Restaurants from Google Places API
        try {
          if (kDebugMode) print("DEBUG: Using Places API Data");
          final places = await PlacesService().fetchNearbyRestaurants(
            latitude: position.latitude,
            longitude: position.longitude,
          );
          fetchedRestaurants = places;
        } catch (e) {
          if (kDebugMode) print("Error fetching places: $e");
        }
      } else {
        if (kDebugMode)
          print("Location not available, cannot fetch nearby places.");
      }
    }

    // Filter restaurants to only include 'approved' ones OR ones owned by the current user
    String currentUid = _userModel?.uid ?? '';
    fetchedRestaurants = fetchedRestaurants.where((r) {
      return r.status == 'approved' || r.ownerId == currentUid;
    }).toList();

    _restaurants = fetchedRestaurants;
    _isReady = true;
    notifyListeners();
  }

  void _setupAuthListener() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      User? user,
    ) async {
      if (user == null) {
        if (kDebugMode) print("Auth Listener: User logged out or deleted.");
        // Always clear data and reset the Singleton on logout to prevent stale stats for the next account
        clearUserData();
        RestaurantService.reset();
      } else {
        if (kDebugMode)
          print("Auth Listener: User logged in (${user.uid}). Fetching data.");

        // Start loading
        _isLoadingUser = true;
        notifyListeners(); // UI should show loading/init screen

        // 1. Fetch User Data
        await fetchUserModel();

        // 2. Fetch Restaurants (Fresh for this user session)
        await _fetchRestaurants();

        // 3. Fetch Swipe Logs for Chronological History
        await _fetchSwipeLogs();

        // 4. Trigger initial recommendation batch fetch
        // (Moved from swipableRestaurants getter to prevent fetch from build())
        if (_swipableCache.isEmpty && !_isFetchingBatch && !_hasNoMoreData) {
          _fetchNextBatch();
        }

        // Finish loading
        _isLoadingUser = false;
        notifyListeners(); // UI should show content
      }
    });
  }

  void clearUserData() {
    // Flush any pending swipe actions before clearing
    _flushPendingSwipes();
    _userModel = null;
    _userPreferences = [];
    _userPriceRangePreferences = [];
    _showClosedRestaurants = false;
    _swipeLogs = []; // Clear logs
    _sessionSwipedIds.clear(); // Clear session tracking
    _pendingSwipeActions.clear(); // Clear pending batch
    _isLoadingUser = false;
    _isReady = false;
    _restaurants = [];
    notifyListeners();
    // Do not call reset() here to avoid loop if called from listener.
    // Reset is manually called or handled in auth listener
  }

  @override
  void dispose() {
    // Flush pending swipes before shutdown
    _flushPendingSwipes();
    _authSubscription?.cancel();
    super.dispose();
  }

  // Helper to hydrate status -> REMOVED

  // Calculate distance on the fly
  double getDistance(RestaurantCardData r) {
    if (_lastKnownLat == 0.0 && _lastKnownLng == 0.0) return 0.0;

    double distanceInMeters = Geolocator.distanceBetween(
      _lastKnownLat,
      _lastKnownLng,
      r.latitude,
      r.longitude,
    );
    return double.parse((distanceInMeters / 1000).toStringAsFixed(1));
  }

  // Get Restaurant Status Dynamically
  SwipeStatus getRestaurantStatus(String id) {
    if (_userModel == null) return SwipeStatus.none;

    if (_userModel!.history.yum.contains(id)) return SwipeStatus.yum;
    if (_userModel!.history.passed.contains(id)) return SwipeStatus.pass;
    if (_userModel!.history.fav.contains(id)) return SwipeStatus.fav;

    return SwipeStatus.none;
  }

  //Get Restaurant Data from Firestore
  Future<List<RestaurantCardData>> fetchRestaurantsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Cast if necessary
        return RestaurantCardData.fromFirestore(data, doc.id);
      }).toList();
    } catch (e) {
      if (kDebugMode) print("Error fetching from Firestore: $e");
      return [];
    }
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  Future<void> fetchUserModel() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user!.getIdTokenResult(true);
    print(token.claims);
    if (user != null) {
      try {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);
        final doc = await docRef.get();

        if (doc.exists) {
          Map<String, dynamic> data = doc.data() ?? {};
          bool needsRepair = false;
          Map<String, dynamic> repairData = {};

          // Check for missing 'stats'
          if (!data.containsKey('stats')) {
            if (kDebugMode)
              print("DEBUG: User doc missing 'stats'. Repairing...");
            repairData['stats'] = UserStats().toJson();
            needsRepair = true;
          }

          // Check for missing 'history'
          if (!data.containsKey('history')) {
            if (kDebugMode)
              print("DEBUG: User doc missing 'history'. Repairing...");
            repairData['history'] = UserHistory().toJson();
            needsRepair = true;
          }

          // Repair missing profile picture from Google
          if ((!data.containsKey('profilePictureUrl') ||
                  data['profilePictureUrl'] == null ||
                  (data['profilePictureUrl'] as String).isEmpty) &&
              user.photoURL != null &&
              user.photoURL!.isNotEmpty) {
            repairData['profilePictureUrl'] = user.photoURL!;
            needsRepair = true;
          }

          // Repair missing username from Google
          if ((!data.containsKey('username') ||
                  data['username'] == null ||
                  (data['username'] as String).isEmpty) &&
              user.displayName != null &&
              user.displayName!.isNotEmpty) {
            repairData['username'] = user.displayName!;
            needsRepair = true;
          }

          if (needsRepair) {
            // Repair the document
            if (kDebugMode) print("DEBUG: Performing user doc repair...");
            await docRef.set(repairData, SetOptions(merge: true));

            // Re-fetch to get complete data
            final repairedDoc = await docRef.get();
            _userModel = UserModel.fromFirestore(repairedDoc);

            // Also ensure swipes collection is initialized for repaired users
            _ensureSwipesCollectionExists(docRef);
          } else {
            _userModel = UserModel.fromFirestore(doc);
          }

          _userPreferences = _userModel?.preferences ?? [];
          _userPriceRangePreferences = _userModel?.priceRangePreference ?? [];
          _showClosedRestaurants = _userModel?.showClosedRestaurants ?? false;

          // Update lastActiveAt
          await docRef.update({'lastActiveAt': FieldValue.serverTimestamp()});

          notifyListeners();
        } else {
          // Create new user document
          if (kDebugMode)
            print("User document not found. Creating new user...");

          final newUser = UserModel(
            uid: user.uid,
            email: user.email,
            username: user.displayName,
            profilePictureUrl: user.photoURL,
            createdAt: DateTime.now(),
            lastActiveAt: DateTime.now(),
            stats: UserStats(),
            history: UserHistory(),
          );

          await docRef.set({
            ...newUser.toJson(),
            'createdAt': FieldValue.serverTimestamp(),
            'lastActiveAt': FieldValue.serverTimestamp(),
          });

          // Initialize swipes collection for new users
          await _ensureSwipesCollectionExists(docRef);

          _userModel = newUser;
          _userPreferences = [];
          _userPriceRangePreferences = [];
          _showClosedRestaurants = false;
          notifyListeners();
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error fetching/repairing user stats: $e");
        }
      }
    }
  }

  Future<void> _ensureSwipesCollectionExists(DocumentReference userRef) async {
    try {
      // Create a dummy document to initialize the collection, then delete it?
      // Or just keep an 'init' doc. Keeping 'init' is safer and easier.
      final initDoc = userRef.collection('swipes').doc('init');
      final snapshot = await initDoc.get();

      if (!snapshot.exists) {
        if (kDebugMode) print("DEBUG: Initializing 'swipes' subcollection...");
        await initDoc.set({'created': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      if (kDebugMode) print("Error initializing swipes collection: $e");
    }
  }

  // Deprecated: merged into fetchUserModel, keeping for compatibility if needed elsewhere
  Future<void> fetchUserPreferences() async {
    await fetchUserModel();
  }

  void updateCuisinePreferences(List<String> prefs) {
    _userPreferences = prefs;
    notifyListeners();
  }

  void updateDistanceAndPriceRange(
    double distance,
    List<String> priceRanges,
    bool showClosedRestaurants,
  ) {
    _userMaxDistance = distance;
    _userPriceRangePreferences = priceRanges;
    _showClosedRestaurants = showClosedRestaurants;
    notifyListeners();
  }

  // ฟังก์ชันเพื่อให้ปุ่ม Refresh สามารถสับเปลี่ยนร้านที่อัลกอริทึมจัดไว้นำมาแสดงใหม่
  void forceRefreshRecommendations() {
    _isManualRefresh = true;
    _hasNoMoreData = false; // CRITICAL: Reset so fetch can proceed again
    _swipableCache.clear();
    _sessionSwipedIds.clear(); // Reset session tracking on manual refresh
    if (!_isFetchingBatch) {
      _fetchNextBatch();
    }
    // Always notify so UI transitions to AppInitScreen immediately
    notifyListeners();
  }

  // Getters for different states
  List<RestaurantCardData> get restaurants => _restaurants;

  Future<void> addRestaurant(RestaurantCardData data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _userModel == null) return;

    try {
      final db = FirebaseFirestore.instance;

      // Create a new document ref (or if ID is provided, use it, but usually add is new)
      final docRef = data.id.isEmpty
          ? db.collection('restaurants').doc()
          : db.collection('restaurants').doc(data.id);

      // Update data with the new ID, pending status, and ownerId
      final restaurantData = data.copyWith(
        id: docRef.id,
        ownerId: user.uid,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      // Save to restaurants
      await docRef.set(restaurantData.toJson());

      // Update user's ownedRestaurantIds and potentially skip fetching if we manually mutate, but fetch is safer.
      await db.collection('users').doc(user.uid).update({
        'ownedRestaurantIds': FieldValue.arrayUnion([docRef.id]),
      });

      await fetchUserModel(); // Refresh user model

      // Optimistically add to local list
      _restaurants.add(restaurantData);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error adding restaurant: $e");
      rethrow;
    }
  }

  Future<String> _uploadImage(File file, String pathString) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(pathString);
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) print("Error uploading image: $e");
      return '';
    }
  }

  Future<void> updateRestaurantInfo(RestaurantDetailsData data) async {
    try {
      if (kDebugMode) print("DEBUG: Updating restaurant info for ${data.id}");

      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(data.id)
          .update(data.toJson());

      // Update the local cache optimistically
      final index = _restaurants.indexWhere((r) => r.id == data.id);
      if (index != -1) {
        // Details inherits Card, so it works. Just merging needed.
        _restaurants[index] = data;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print("Error updating restaurant info: $e");
      rethrow;
    }
  }

  Future<void> updateRestaurantWithDetails(
    RestaurantDetailsData data, {
    File? newCoverImage,
    List<File>? newGalleryImages,
  }) async {
    try {
      if (kDebugMode)
        print("DEBUG: Updating restaurant info with images for ${data.id}");

      final db = FirebaseFirestore.instance;
      final docRef = db.collection('restaurants').doc(data.id);

      // Upload Cover Image if new
      String coverUrl = data.imageUrl;
      if (newCoverImage != null) {
        coverUrl = await _uploadImage(
          newCoverImage,
          'restaurants/${docRef.id}/cover.jpg',
        );
      }

      // Upload New Gallery Images
      List<String> combinedGalleryUrls = List<String>.from(data.galleryImages);
      if (newGalleryImages != null && newGalleryImages.isNotEmpty) {
        for (int i = 0; i < newGalleryImages.length; i++) {
          final url = await _uploadImage(
            newGalleryImages[i],
            'restaurants/${docRef.id}/gallery_update_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
          );
          if (url.isNotEmpty) combinedGalleryUrls.add(url);
        }
      }

      final updatedData = data.copyWith(
        imageUrl: coverUrl.isNotEmpty ? coverUrl : data.imageUrl,
        galleryImages: combinedGalleryUrls,
      );

      final jsonToSave = updatedData.toJson();
      // Remove subcollections data before updating main doc
      jsonToSave.remove('menuItems');
      jsonToSave.remove('menuCategories');

      await docRef.update(jsonToSave);

      // Update the local cache
      final index = _restaurants.indexWhere((r) => r.id == updatedData.id);
      if (index != -1) {
        _restaurants[index] = updatedData;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print("Error updating restaurant info with images: $e");
      rethrow;
    }
  }

  Future<void> updateRestaurantMenus(
    String restaurantId, {
    required List<MenuCategory> categories,
    required List<MenuItem> items,
    Map<String, File>? newMenuImages,
    List<String>? deletedCategoryIds,
    List<String>? deletedItemIds,
  }) async {
    try {
      if (kDebugMode) print("DEBUG: Updating menus for $restaurantId");

      final db = FirebaseFirestore.instance;
      final docRef = db.collection('restaurants').doc(restaurantId);
      final batch = db.batch();

      // Handle deletions
      if (deletedCategoryIds != null) {
        for (var id in deletedCategoryIds) {
          batch.delete(docRef.collection('menuCategories').doc(id));
        }
      }
      if (deletedItemIds != null) {
        for (var id in deletedItemIds) {
          batch.delete(docRef.collection('menuItems').doc(id));
        }
      }

      // Handle categories updates/adds
      for (var cat in categories) {
        final catRef = docRef.collection('menuCategories').doc(cat.id);
        batch.set(catRef, cat.toJson(), SetOptions(merge: true));
      }

      // Handle items updates/adds and image uploads
      List<MenuItem> finalItems = [];
      for (var item in items) {
        String itemImageUrl = item.menuImage;
        if (newMenuImages != null && newMenuImages.containsKey(item.id)) {
          itemImageUrl = await _uploadImage(
            newMenuImages[item.id]!,
            'restaurants/$restaurantId/menus/${item.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
        }

        final updatedItem = item.copyWith(menuImage: itemImageUrl);
        finalItems.add(updatedItem);

        final menuRef = docRef.collection('menuItems').doc(item.id);
        batch.set(menuRef, updatedItem.toJson(), SetOptions(merge: true));
      }

      await batch.commit();

      // Update local cache
      final index = _restaurants.indexWhere((r) => r.id == restaurantId);
      if (index != -1) {
        final currentData = _restaurants[index];
        if (currentData is RestaurantDetailsData) {
          _restaurants[index] = currentData.copyWith(
            menuCategories: categories,
            menuItems: finalItems,
          );
        }
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print("Error updating restaurant menus: $e");
      rethrow;
    }
  }

  Future<void> addRestaurantWithDetails(
    RestaurantDetailsData data, {
    File? coverImage,
    List<File>? galleryImages,
    Map<String, File>? menuImages,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _userModel == null) return;

    try {
      final db = FirebaseFirestore.instance;
      final docRef = data.id.isEmpty
          ? db.collection('restaurants').doc()
          : db.collection('restaurants').doc(data.id);

      // Upload Cover Image
      String coverUrl = data.imageUrl;
      if (coverImage != null) {
        coverUrl = await _uploadImage(
          coverImage,
          'restaurants/${docRef.id}/cover.jpg',
        );
      }

      // Upload Gallery Images
      List<String> galleryUrls = [];
      if (galleryImages != null && galleryImages.isNotEmpty) {
        for (int i = 0; i < galleryImages.length; i++) {
          final url = await _uploadImage(
            galleryImages[i],
            'restaurants/${docRef.id}/gallery_$i.jpg',
          );
          if (url.isNotEmpty) galleryUrls.add(url);
        }
      }

      // Prepare main restaurant data
      final restaurantData = data.copyWith(
        id: docRef.id,
        ownerId: user.uid,
        status: 'pending',
        createdAt: DateTime.now(),
        imageUrl: coverUrl.isNotEmpty ? coverUrl : data.imageUrl,
        galleryImages: galleryUrls,
      );

      // We should not save menuItems and menuCategories in the main document since we use subcollections
      final jsonToSave = restaurantData.toJson();
      jsonToSave.remove('menuItems');
      jsonToSave.remove('menuCategories');

      await docRef.set(jsonToSave);

      // Save categories to subcollection
      final batch = db.batch();
      for (var cat in data.menuCategories) {
        final catRef = docRef.collection('menuCategories').doc(cat.id);
        batch.set(catRef, cat.toJson());
      }

      // Upload menu images and save menus to subcollection
      for (var item in data.menuItems) {
        String itemImageUrl = item.menuImage;
        if (menuImages != null && menuImages.containsKey(item.id)) {
          itemImageUrl = await _uploadImage(
            menuImages[item.id]!,
            'restaurants/${docRef.id}/menus/${item.id}.jpg',
          );
        }

        final updatedItem = MenuItem(
          id: item.id,
          name: item.name,
          price: item.price,
          category: item.category,
          menuImage: itemImageUrl,
          isRecommended: item.isRecommended,
          isAvailable: item.isAvailable,
        );
        final menuRef = docRef.collection('menuItems').doc(item.id);
        batch.set(menuRef, updatedItem.toJson());
      }

      await batch.commit();

      // Update user's ownedRestaurantIds
      await db.collection('users').doc(user.uid).update({
        'ownedRestaurantIds': FieldValue.arrayUnion([docRef.id]),
      });

      await fetchUserModel(); // Refresh user model

      _restaurants.add(restaurantData);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error adding restaurant with details: $e");
      rethrow;
    }
  }

  Future<void> toggleBusinessMode(bool isActive) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _userModel == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'isBusinessMode': isActive},
      );

      await fetchUserModel(); // Refresh user model
    } catch (e) {
      if (kDebugMode) print("Error toggling business mode: $e");
    }
  }

  List<RestaurantCardData> _swipableCache = [];
  bool _isFetchingBatch = false;
  bool _isManualRefresh = false;
  bool _hasNoMoreData = false;

  // === Batch Swipe Queue ===
  // Accumulate swipe actions locally, flush to Cloud Function in batch
  static const int _swipeBatchSize = 5; // Flush every N swipes
  final List<Map<String, dynamic>> _pendingSwipeActions = [];
  bool _isFlushingSwipes = false;

  bool get isFetchingBatch => _isFetchingBatch;
  bool get isManualRefresh => _isManualRefresh;
  bool get hasNoMoreData => _hasNoMoreData;

  // Pure getter — does NOT trigger fetching.
  // Initial fetch is triggered by auth listener after login.
  // Subsequent fetches are triggered by swipe threshold (< 3 cards remaining).
  List<RestaurantCardData> get swipableRestaurants {
    return _swipableCache;
  }

  Future<void> _fetchNextBatch() async {
    if (_isFetchingBatch) return;
    _isFetchingBatch = true;
    notifyListeners(); // Optionally trigger UI to show loading if we want, or just quietly load in bg

    try {
      Position? position;
      if (_lastKnownLat == 0.0 && _lastKnownLng == 0.0) {
        position = await _getCurrentLocation();
        if (position != null) {
          _lastKnownLat = position.latitude;
          _lastKnownLng = position.longitude;
        }
      }

      // Build comprehensive exclude list to prevent ANY duplicates
      final Set<String> excludeSet = {};
      // 1. From user history (persisted)
      excludeSet.addAll(_userModel?.history.yum ?? []);
      excludeSet.addAll(_userModel?.history.passed ?? []);
      excludeSet.addAll(_userModel?.history.fav ?? []);
      // 2. From session tracking (covers race condition where history hasn't synced yet)
      excludeSet.addAll(_sessionSwipedIds);
      // 3. From current swipe queue
      excludeSet.addAll(_swipableCache.map((r) => r.id));
      final List<String> excludeIds = excludeSet.toList();

      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'getRecommendedBatch',
      );
      final result = await callable.call({
        'latitude': _lastKnownLat,
        'longitude': _lastKnownLng,
        'excludeIds': excludeIds,
        'preferences': _userPreferences,
        'maxDistance': _userMaxDistance,
        'priceRangePreference': _userPriceRangePreferences,
        'showClosedRestaurants': _showClosedRestaurants,
      });

      final List<dynamic> batchData = result.data['restaurants'] ?? [];

      List<RestaurantCardData> newBatch = batchData.map((data) {
        // use fromJson passing mapped data
        return RestaurantCardData.fromJson(Map<String, dynamic>.from(data));
      }).toList();

      // OPTIONAL NEW FILTER: closed
      if (!_showClosedRestaurants) {
        newBatch = newBatch.where((r) {
          final status = TimeUtils.getRestaurantStatus(r.openingHours);
          return status != RestaurantStatus.closed;
        }).toList();
      }

      _swipableCache = newBatch;
      if (newBatch.isEmpty) {
        _hasNoMoreData = true;
      } else {
        _hasNoMoreData = false;
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching batch from Firebase: $e");
      _hasNoMoreData = true; // Prevent infinite fetch loop on error
    } finally {
      _isFetchingBatch = false;
      _isManualRefresh = false;
      notifyListeners();
    }
  }

  // Get History Sorted by Time (Newest First)
  List<RestaurantCardData> get history {
    if (_swipeLogs.isEmpty) return [];

    // Extract IDs in order (Newest is at index 0 because we sort DESC)
    // Use LinkedHashSet or just map to preserve order and remove duplicates if any
    final Set<String> validIds = {};
    final List<RestaurantCardData> sortedList = [];

    for (final log in _swipeLogs) {
      final rId = log['restaurantId'] as String;
      // Only add if not already added (though standard flow shouldn't have dupes for active status)
      // And check current status is valid (not none)
      if (!validIds.contains(rId)) {
        final status = getRestaurantStatus(rId);
        if (status != SwipeStatus.none) {
          final restaurant = _restaurants.firstWhere(
            (r) => r.id == rId,
            orElse: () => _restaurants.first,
          ); // Fallback safe
          if (restaurant.id == rId) {
            // Check if found correctly
            validIds.add(rId);
            sortedList.add(restaurant);
          }
        }
      }
    }
    return sortedList;
  }

  // Get Favorites Sorted by Time (Newest Fav First)
  List<RestaurantCardData> get favorites {
    if (_swipeLogs.isEmpty) return [];

    final Set<String> validIds = {};
    final List<RestaurantCardData> sortedList = [];

    for (final log in _swipeLogs) {
      final rId = log['restaurantId'] as String;

      // We only care if the *current* status is FAV.
      // But we want the order of when it was swiped.
      // _swipeLogs is ordered Newest -> Oldest.

      if (!validIds.contains(rId)) {
        final status = getRestaurantStatus(rId);
        if (status == SwipeStatus.fav) {
          final restaurant = _restaurants.firstWhere(
            (r) => r.id == rId,
            orElse: () => _restaurants.first,
          );
          if (restaurant.id == rId) {
            validIds.add(rId);
            sortedList.add(restaurant);
          }
        }
      }
    }
    return sortedList;
  }

  // Update status (Swipe Action)
  Future<void> swipeRestaurant(
    String id,
    SwipeStatus newStatus, {
    int dwellTime = 0,
  }) async {
    if (newStatus == SwipeStatus.none) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (kDebugMode)
      print("CURRENT USER IN SERVICE: ${_userModel?.uid}"); // Debug Print

    if (currentUser == null) {
      if (kDebugMode) print("Error: No authenticated user.");
      return;
    }

    // Race Condition Fix: Ensure _userModel matches current Auth User
    // If we just logged in as B, but _userModel is null or A, we must reload.
    if (_userModel == null || _userModel!.uid != currentUser.uid) {
      if (kDebugMode)
        print("DEBUG: User Model mismatch detected. Forcing reload...");
      await fetchUserModel();

      if (_userModel == null || _userModel!.uid != currentUser.uid) {
        if (kDebugMode) print("Critical Error: Failed to sync user model.");
        return;
      }
    }

    // 1. Optimistic Update Local State
    final index = _restaurants.indexWhere((r) => r.id == id);
    RestaurantCardData? swipedRestaurant;
    SwipeStatus oldStatus = getRestaurantStatus(id);

    if (index != -1) {
      swipedRestaurant = _restaurants[index];
      // oldStatus already set

      // Optimistic Update Local State
      if (_userModel != null) {
        // Remove from old lists
        _userModel!.history.yum.remove(id);
        _userModel!.history.passed.remove(id);
        _userModel!.history.fav.remove(id);

        // Track this swipe in session to prevent re-fetch
        _sessionSwipedIds.add(id);

        // Remove from current batch cache
        _swipableCache.removeWhere((r) => r.id == id);

        // Pre-fetch next batch if running low
        if (_swipableCache.length < 3 && !_isFetchingBatch) {
          _fetchNextBatch();
        }

        // Add to new list
        String actionStr = '';
        switch (newStatus) {
          case SwipeStatus.yum:
            _userModel!.history.yum.add(id);
            actionStr = 'yum';
            break;
          case SwipeStatus.pass:
            _userModel!.history.passed.add(id);
            actionStr = 'pass';
            break;
          case SwipeStatus.fav:
            _userModel!.history.fav.add(id);
            actionStr = 'fav';
            break;
          default:
            break;
        }

        // Optimistic Update Swipe Logs
        _swipeLogs.insert(0, {
          'restaurantId': id,
          'action': actionStr,
          'timestamp': DateTime.now(),
        });
      }

      notifyListeners();
    }

    // 2. Queue swipe action for batch persist (instead of firing API per swipe)
    if (swipedRestaurant != null) {
      String actionStr = '';
      if (newStatus == SwipeStatus.yum)
        actionStr = 'yum';
      else if (newStatus == SwipeStatus.pass)
        actionStr = 'pass';
      else if (newStatus == SwipeStatus.fav)
        actionStr = 'fav';

      if (actionStr.isNotEmpty && newStatus != oldStatus) {
        _pendingSwipeActions.add({
          'restaurantId': swipedRestaurant.id,
          'action': actionStr,
          'dwellTime': dwellTime,
        });

        if (kDebugMode)
          print(
            "Queued swipe: $actionStr for ${swipedRestaurant.id} (queue: ${_pendingSwipeActions.length}/$_swipeBatchSize)",
          );

        // Flush when batch is full
        if (_pendingSwipeActions.length >= _swipeBatchSize) {
          _flushPendingSwipes();
        }
      }
    }
  }

  /// Flush all pending swipe actions to Cloud Function in a single batch call.
  /// Called when: batch is full (5), user leaves screen, app pauses, logout.
  Future<void> _flushPendingSwipes() async {
    if (_pendingSwipeActions.isEmpty || _isFlushingSwipes) return;
    _isFlushingSwipes = true;

    // Take a snapshot of pending actions and clear the queue
    final actionsToFlush = List<Map<String, dynamic>>.from(
      _pendingSwipeActions,
    );
    _pendingSwipeActions.clear();

    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'recordSwipeActionsBatch',
      );
      await callable.call({'actions': actionsToFlush});

      if (kDebugMode)
        print(
          "Flushed ${actionsToFlush.length} swipe actions in batch via Cloud Function",
        );
    } catch (e) {
      if (kDebugMode) print("Error flushing swipe batch: $e");
      // On failure, re-queue the actions so they aren't lost
      _pendingSwipeActions.insertAll(0, actionsToFlush);
    } finally {
      _isFlushingSwipes = false;
    }
  }

  /// Public method to force flush pending swipes (called from UI lifecycle)
  Future<void> flushPendingSwipes() => _flushPendingSwipes();

  // Optional: Reset all data
  void resetData() {
    _initializeData();
    notifyListeners();
  }

  // Reset User Swipe Data (Keeps preferences, favs)
  Future<void> resetSwipeData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _userModel == null) return;

    try {
      final db = FirebaseFirestore.instance;
      final userRef = db.collection('users').doc(user.uid);

      // 1. Get current stats
      final currentFavs = _userModel!.stats.fav;

      // 2. Clear local model lists
      _userModel!.history.yum.clear();
      _userModel!.history.passed.clear();

      // Clear stats (but keep totalSwipes equal to current favs)
      _userModel!.stats.toMap().updateAll(
        (key, value) => 0,
      ); // Not directly possible, create new
      final updatedStats = UserStats(
        totalSwipes: currentFavs,
        fav: currentFavs,
        yums: 0,
        passes: 0,
      );

      // Remove from local logs
      _swipeLogs.removeWhere(
        (log) => log['action'] == 'yum' || log['action'] == 'pass',
      );

      // 3. Update Firestore User Doc
      await userRef.update({
        'history.yum': [],
        'history.passed': [],
        'stats': updatedStats.toMap(),
        'tasteProfile': {
          'categories': {},
          'priceRange': {},
          'timeAffinity': {},
        },
        'lastActiveAt': FieldValue.serverTimestamp(),
      });

      // 4. Batch delete non-fav swipe logs from subcollection
      final swipesQuery = await userRef
          .collection('swipes')
          .where('action', whereIn: ['yum', 'pass'])
          .get();

      WriteBatch batch = db.batch();
      for (var doc in swipesQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (kDebugMode) print("Swipe data reset successfully.");

      forceRefreshRecommendations();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error resetting swipe data: $e");
      rethrow;
    }
  }

  // Fetch Full Details
  Future<RestaurantDetailsData?> getRestaurantDetails(String id) async {
    if (kDebugMode) print("Getting details for $id");

    // 1. Check Mock Data
    if (AppConfig.useMockData) {
      try {
        final mockItem = mockRestaurants.firstWhere((r) => r.id == id);
        return mockItem; // mockRestaurants is already List<RestaurantDetailsData>
      } catch (e) {
        // Not found in mock, proceed to Firestore logic if mixed mode
      }
    }

    // 2. Fetch from Firestore
    try {
      if (kDebugMode)
        print("DEBUG: Fetching details from Firestore for ID: $id");
      final doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(id)
          .get();
      if (doc.exists && doc.data() != null) {
        if (kDebugMode) print("DEBUG: Restaurant document found.");
        RestaurantDetailsData details = RestaurantDetailsData.fromFirestore(
          doc,
          doc.data(),
        );
        if (kDebugMode)
          print("DEBUG: Parsed Gallery Images: ${details.galleryImages}");

        // Fetch subcollection 'menuItems'
        List<MenuItem> fetchedMenuItems = [];
        try {
          if (kDebugMode) print("DEBUG: Fetching menuItems subcollection...");
          final menuSnapshot = await FirebaseFirestore.instance
              .collection('restaurants')
              .doc(id)
              .collection('menuItems')
              .get();

          if (menuSnapshot.docs.isNotEmpty) {
            fetchedMenuItems = menuSnapshot.docs.map((mDoc) {
              final data = mDoc.data();
              // Ensure ID is passed if needed, or just let fromJson handle it if in data
              // If data doesn't have ID, we might want to inject it.
              // But MenuItem.fromJson reads 'id' field.
              // Let's ensure 'id' is in data or add it.
              final dataWithId = Map<String, dynamic>.from(data);
              dataWithId['id'] = mDoc.id;
              return MenuItem.fromJson(dataWithId);
            }).toList();

            if (kDebugMode)
              print(
                "DEBUG: Updated details with ${fetchedMenuItems.length} menu items.",
              );
          } else {
            // If no subcollection, maybe use embedded items (parsed in fromFirestore)
            // But usually we prefer subcollection if active.
            // If fetchedMenuItems is empty, we keep details.menuItems (from embedded)
            if (details.menuItems.isNotEmpty) {
              fetchedMenuItems = details.menuItems;
            }
          }
        } catch (e) {
          if (kDebugMode) print("Error fetching menu items subcollection: $e");
          fetchedMenuItems = details.menuItems; // Fallback
        }

        // Fetch subcollection 'menuCategories'
        List<MenuCategory> fetchedCategories = [];
        try {
          if (kDebugMode)
            print("DEBUG: Fetching menuCategories subcollection...");
          final catSnapshot = await FirebaseFirestore.instance
              .collection('restaurants')
              .doc(id)
              .collection('menuCategories')
              .orderBy('order')
              .get();

          if (catSnapshot.docs.isNotEmpty) {
            fetchedCategories = catSnapshot.docs.map((cDoc) {
              final data = Map<String, dynamic>.from(cDoc.data());
              data['id'] = cDoc.id;
              return MenuCategory.fromJson(data);
            }).toList();
          } else {
            fetchedCategories = details.menuCategories;
          }
        } catch (e) {
          if (kDebugMode) print("Error fetching menu categories: $e");
          fetchedCategories = details.menuCategories;
        }

        // Merge updates
        details = details.copyWith(
          menuItems: fetchedMenuItems,
          menuCategories: fetchedCategories,
        );

        // Update local cache to trigger UI update
        final index = _restaurants.indexWhere((r) => r.id == id);
        if (index != -1) {
          // We can't replace RestaurantCardData with RestaurantDetailsData directly in the list
          // if the list is typed as RestaurantCardData. (It is).
          // But Dart allows it since Details IS Card.
          _restaurants[index] = details;
          notifyListeners();
        }

        return details;
      } else {
        if (kDebugMode)
          print("DEBUG: Restaurant document NOT found in Firestore.");
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching details: $e");
    }
    return null;
  }

  // Update temporarily closed status
  Future<void> updateRestaurantTemporarilyClosed(
    String id,
    bool isClosed,
  ) async {
    try {
      if (kDebugMode)
        print("DEBUG: Updating temporarily closed status for $id to $isClosed");
      await FirebaseFirestore.instance.collection('restaurants').doc(id).update(
        {'isTemporarilyClosed': isClosed},
      );

      // Optimistic update of list cache
      final index = _restaurants.indexWhere((r) => r.id == id);
      if (index != -1) {
        _restaurants[index] = _restaurants[index].copyWith(
          isTemporarilyClosed: isClosed,
        );
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print("Error updating store closed status: $e");
      rethrow;
    }
  }

  // Delete a restaurant and clean up all dangling data inside users collection
  Future<void> deleteRestaurantAndCleanUsers(String restaurantId) async {
    try {
      if (kDebugMode)
        print("DEBUG: Initiating cascade delete for restaurant $restaurantId");

      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      // 1. Delete Subcollections logic
      final menuItemsSnap = await db
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menuItems')
          .get();
      for (var doc in menuItemsSnap.docs) {
        batch.delete(doc.reference);
      }

      final catSnap = await db
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menuCategories')
          .get();
      for (var doc in catSnap.docs) {
        batch.delete(doc.reference);
      }

      // 2. Delete the main restaurant document
      batch.delete(db.collection('restaurants').doc(restaurantId));

      // 3. Remove 'restaurantId' from EVERY user document (favoriteIds, history.yum, history.passed)
      // ONLY RUN IF ADMIN (Skip for regular restaurant owner to prevent permission-denied error)
      if (_userModel != null && _userModel!.role == 'admin') {
        final usersSnap = await db.collection('users').get();
        for (var userDoc in usersSnap.docs) {
          final Map<String, dynamic> updateData = {};

          final userData = userDoc.data();
          final favs = List<String>.from(userData['favoriteIds'] ?? []);
          final history = userData['history'] as Map<String, dynamic>? ?? {};
          final yums = List<String>.from(history['yum'] ?? []);
          final passes = List<String>.from(history['passed'] ?? []);

          bool needsUpdate = false;

          if (favs.contains(restaurantId)) {
            updateData['favoriteIds'] = FieldValue.arrayRemove([restaurantId]);
            needsUpdate = true;
          }

          if (yums.contains(restaurantId) || passes.contains(restaurantId)) {
            // If history yum or passed has it, array remove
            updateData['history.yum'] = FieldValue.arrayRemove([restaurantId]);
            updateData['history.passed'] = FieldValue.arrayRemove([
              restaurantId,
            ]);
            needsUpdate = true;
          }

          if (needsUpdate) {
            batch.update(userDoc.reference, updateData);
          }
        }
      }

      // 4. Update the current owner document to remove from ownedRestaurantIds
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        batch.update(db.collection('users').doc(currentUser.uid), {
          'ownedRestaurantIds': FieldValue.arrayRemove([restaurantId]),
        });
      }

      // 5. Commit batch
      await batch.commit();

      // Update local cache
      _restaurants.removeWhere((r) => r.id == restaurantId);
      notifyListeners();

      if (kDebugMode)
        print("DEBUG: Success. Cascade delete is complete for $restaurantId");
    } catch (e) {
      if (kDebugMode)
        print("Error cascade deleting restaurant $restaurantId: $e");
      rethrow;
    }
  }

  // Fetch Swipe Logs from Firestore
  Future<void> _fetchSwipeLogs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      if (kDebugMode) print("DEBUG: Fetching Swipe Logs...");
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('swipes')
          .orderBy('timestamp', descending: true) // Newest first
          .get();

      _swipeLogs = snapshot.docs.map((doc) {
        final data = doc.data();
        // Convert Timestamp to DateTime
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] = (data['timestamp'] as Timestamp).toDate();
        }
        return data;
      }).toList();

      if (kDebugMode) print("DEBUG: Loaded ${_swipeLogs.length} logs.");
    } catch (e) {
      if (kDebugMode) print("Error fetching swipe logs: $e");
    }
    notifyListeners();
  }

  // --- Review Methods ---

  Future<void> addReview(String restaurantId, ReviewModel review) async {
    try {
      final db = FirebaseFirestore.instance;
      final restaurantRef = db.collection('restaurants').doc(restaurantId);
      final reviewRef = restaurantRef.collection('reviews').doc(review.id);

      await db.runTransaction((transaction) async {
        final restaurantSnap = await transaction.get(restaurantRef);
        if (!restaurantSnap.exists) {
          throw Exception("Restaurant does not exist");
        }

        final data = restaurantSnap.data() as Map<String, dynamic>;
        int currentCount = (data['reviewCount'] as num?)?.toInt() ?? 0;
        double currentRating = (data['rating'] as num?)?.toDouble() ?? 0.0;

        double newRating =
            ((currentRating * currentCount) + review.rating) /
            (currentCount + 1);
        int newCount = currentCount + 1;

        transaction.set(reviewRef, review.toJson());
        transaction.update(restaurantRef, {
          'rating': double.parse(newRating.toStringAsFixed(1)),
          'reviewCount': newCount,
        });
      });

      // Optimistically update local data
      final index = _restaurants.indexWhere((r) => r.id == restaurantId);
      if (index != -1) {
        final current = _restaurants[index];

        final currentCount = current.reviewCount;
        final currentRating = current.rating;
        double newRating =
            ((currentRating * currentCount) + review.rating) /
            (currentCount + 1);
        int newCount = currentCount + 1;

        if (current is RestaurantDetailsData) {
          _restaurants[index] = current.copyWith(
            rating: double.parse(newRating.toStringAsFixed(1)),
            reviewCount: newCount,
          );
        } else {
          _restaurants[index] = current.copyWith(
            rating: double.parse(newRating.toStringAsFixed(1)),
            reviewCount: newCount,
          );
        }
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print("Error adding review: $e");
      rethrow;
    }
  }

  Future<void> updateReview(
    String restaurantId,
    ReviewModel review,
    double oldRating,
  ) async {
    try {
      final db = FirebaseFirestore.instance;
      final restaurantRef = db.collection('restaurants').doc(restaurantId);
      final reviewRef = restaurantRef.collection('reviews').doc(review.id);

      await db.runTransaction((transaction) async {
        final restaurantSnap = await transaction.get(restaurantRef);
        if (!restaurantSnap.exists) {
          throw Exception("Restaurant does not exist");
        }

        final data = restaurantSnap.data() as Map<String, dynamic>;
        int currentCount = (data['reviewCount'] as num?)?.toInt() ?? 0;
        double currentRating = (data['rating'] as num?)?.toDouble() ?? 0.0;

        double newRating = currentRating;
        if (currentCount > 0) {
          newRating =
              ((currentRating * currentCount) - oldRating + review.rating) /
              currentCount;
          if (newRating < 0) newRating = 0.0;
        }

        transaction.update(reviewRef, {
          'rating': review.rating,
          'comment': review.comment,
          'userName': review.userName,
          'userPhotoUrl': review.userPhotoUrl,
        });

        transaction.update(restaurantRef, {
          'rating': double.parse(newRating.toStringAsFixed(1)),
        });
      });

      // Optimistically update local data
      final index = _restaurants.indexWhere((r) => r.id == restaurantId);
      if (index != -1) {
        final current = _restaurants[index];
        final currentCount = current.reviewCount;
        double newRating = current.rating;

        if (currentCount > 0) {
          newRating =
              ((current.rating * currentCount) - oldRating + review.rating) /
              currentCount;
          if (newRating < 0) newRating = 0.0;
        }

        if (current is RestaurantDetailsData) {
          _restaurants[index] = current.copyWith(
            rating: double.parse(newRating.toStringAsFixed(1)),
          );
        } else {
          _restaurants[index] = current.copyWith(
            rating: double.parse(newRating.toStringAsFixed(1)),
          );
        }
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print("Error updating review: $e");
      rethrow;
    }
  }

  Future<void> deleteReview(String restaurantId, ReviewModel review) async {
    try {
      final db = FirebaseFirestore.instance;
      final restaurantRef = db.collection('restaurants').doc(restaurantId);
      final reviewRef = restaurantRef.collection('reviews').doc(review.id);

      await db.runTransaction((transaction) async {
        final restaurantSnap = await transaction.get(restaurantRef);
        if (!restaurantSnap.exists) {
          throw Exception("Restaurant does not exist");
        }

        final data = restaurantSnap.data() as Map<String, dynamic>;
        int currentCount = (data['reviewCount'] as num?)?.toInt() ?? 1;
        double currentRating = (data['rating'] as num?)?.toDouble() ?? 0.0;

        int newCount = currentCount - 1;
        if (newCount < 0) newCount = 0;

        double newRating = 0.0;
        if (newCount > 0) {
          newRating =
              ((currentRating * currentCount) - review.rating) / newCount;
          if (newRating < 0) newRating = 0.0;
        }

        transaction.delete(reviewRef);
        transaction.update(restaurantRef, {
          'rating': double.parse(newRating.toStringAsFixed(1)),
          'reviewCount': newCount,
        });
      });

      // Optimistically update local data
      final index = _restaurants.indexWhere((r) => r.id == restaurantId);
      if (index != -1) {
        final current = _restaurants[index];
        int currentCount = current.reviewCount;
        int newCount = currentCount - 1;
        if (newCount < 0) newCount = 0;

        double newRating = 0.0;
        if (newCount > 0) {
          newRating =
              ((current.rating * currentCount) - review.rating) / newCount;
          if (newRating < 0) newRating = 0.0;
        }

        if (current is RestaurantDetailsData) {
          _restaurants[index] = current.copyWith(
            rating: double.parse(newRating.toStringAsFixed(1)),
            reviewCount: newCount,
          );
        } else {
          _restaurants[index] = current.copyWith(
            rating: double.parse(newRating.toStringAsFixed(1)),
            reviewCount: newCount,
          );
        }
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) print("Error deleting review: $e");
      rethrow;
    }
  }

  Future<List<ReviewModel>> getReviews(String restaurantId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) print("Error fetching reviews: $e");
      return [];
    }
  }
}
