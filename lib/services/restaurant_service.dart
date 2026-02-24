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
      if (kDebugMode) print("DEBUG: Using Mock Data + Firestore");

      // Process Mock Data
      List<RestaurantCardData> mockList = mockRestaurants;

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

        // Finish loading
        _isLoadingUser = false;
        notifyListeners(); // UI should show content
      }
    });
  }

  void clearUserData() {
    _userModel = null;
    _userPreferences = [];
    _userPriceRangePreferences = [];
    _showClosedRestaurants = false;
    _swipeLogs = []; // Clear logs
    _isLoadingUser = false;
    _isReady = false;
    _restaurants = [];
    notifyListeners();
    // Do not call reset() here to avoid loop if called from listener.
    // Reset is manually called or handled in auth listener
  }

  @override
  void dispose() {
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

  // Getters for different states
  List<RestaurantCardData> get restaurants => _restaurants;

  List<RestaurantCardData> get swipableRestaurants {
    List<RestaurantCardData> filtered = _restaurants
        .where((r) => getRestaurantStatus(r.id) == SwipeStatus.none)
        .toList();

    // Filter by Distance
    if (_userMaxDistance < 50.0) {
      filtered = filtered
          .where((r) => getDistance(r) <= _userMaxDistance)
          .toList();
    }

    // Filter by Preferences (Cuisine)
    if (_userPreferences.isNotEmpty) {
      filtered = filtered.where((r) {
        for (final pref in _userPreferences) {
          final keywords = CuisineUtils.getKeywords(pref);
          for (final keyword in keywords) {
            // Check if any of the restaurant's cuisines contain the keyword
            for (final c in r.cuisine) {
              if (c.contains(keyword) || c == 'อาหารทั่วไป') {
                return true;
              }
            }
          }
        }
        return false;
      }).toList();
      if (kDebugMode)
        print("Debug: After Preference Filter: ${filtered.length}");
    } else {
      if (kDebugMode) print("Debug: No User Preferences, skipping filter.");
    }

    // Filter by Price Range
    if (_userPriceRangePreferences.isNotEmpty) {
      filtered = filtered.where((r) {
        return _userPriceRangePreferences.any((priceRange) {
          final prefix = priceRange.split(' ').first; // e.g. '฿', '฿฿', '฿฿฿'
          final requiredPriceInt = prefix.length;
          return r.priceRange == requiredPriceInt;
        });
      }).toList();
    }

    // Sort by Recommendation Score
    if (_userModel != null) {
      // Update profile based on current history
      _recommendationEngine.updateUserTasteProfile(_userModel!, _restaurants);
      // Rank
      filtered = _recommendationEngine.rankRestaurants(filtered, _userModel!);
    }

    // NEW: Filter out "Closed" restaurants
    // "ร้านที่ปิดจะไม่แสดงที่หน้า swipescreen.dart"
    if (!_showClosedRestaurants) {
      filtered = filtered.where((r) {
        final status = TimeUtils.getRestaurantStatus(r.openingHours);
        return status != RestaurantStatus.closed;
      }).toList();
    }

    return filtered;
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
  Future<void> swipeRestaurant(String id, SwipeStatus newStatus) async {
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

        // Optimistic Update Swipe Logs (Add to Top)
        _swipeLogs.insert(0, {
          'restaurantId': id,
          'action': actionStr,
          'timestamp': DateTime.now(), // Local time for immediate UI update
        });
      }

      notifyListeners();
    }

    // 2. Persist to Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && swipedRestaurant != null) {
      await _recordSwipeToFirestore(
        user.uid,
        swipedRestaurant,
        newStatus,
        oldStatus,
      );
    }
  }

  Future<void> _recordSwipeToFirestore(
    String uid,
    RestaurantCardData restaurant,
    SwipeStatus newStatus,
    SwipeStatus oldStatus,
  ) async {
    final db = FirebaseFirestore.instance;
    final userRef = db.collection('users').doc(uid);
    final swipeRef = userRef.collection('swipes').doc(); // Auto ID

    String action = '';
    String newHistoryField = '';
    String newStatsField = '';

    String? oldHistoryField;
    String? oldStatsField;

    // Determine New Fields
    switch (newStatus) {
      case SwipeStatus.yum:
        action = 'yum';
        newHistoryField = 'history.yum';
        newStatsField = 'stats.yums';
        break;
      case SwipeStatus.pass:
        action = 'pass';
        newHistoryField = 'history.passed';
        newStatsField = 'stats.passes';
        break;
      case SwipeStatus.fav:
        action = 'fav';
        newHistoryField = 'history.fav';
        newStatsField = 'stats.fav';
        break;
      default:
        return;
    }

    // Determine Old Fields
    switch (oldStatus) {
      case SwipeStatus.yum:
        oldHistoryField = 'history.yum';
        oldStatsField = 'stats.yums';
        break;
      case SwipeStatus.pass:
        oldHistoryField = 'history.passed';
        oldStatsField = 'stats.passes';
        break;
      case SwipeStatus.fav:
        oldHistoryField = 'history.fav';
        oldStatsField = 'stats.fav';
        break;
      default:
        break;
    }

    if (newStatus == oldStatus) return;

    try {
      await db.runTransaction((transaction) async {
        transaction.set(swipeRef, {
          'restaurantId': restaurant.id,
          'action': action,
          'timestamp': FieldValue.serverTimestamp(),
          'restaurantSnapshot': {
            'name': restaurant.name,
            'cuisine': restaurant.cuisine,
            'priceRange': restaurant.priceRange,
          },
        });

        Map<String, dynamic> updateData = {
          'lastActiveAt': FieldValue.serverTimestamp(),
        };

        updateData[newHistoryField] = FieldValue.arrayUnion([restaurant.id]);
        updateData[newStatsField] = FieldValue.increment(1);

        if (oldHistoryField != null && oldStatsField != null) {
          updateData[oldHistoryField] = FieldValue.arrayRemove([restaurant.id]);
          updateData[oldStatsField] = FieldValue.increment(-1);
        } else {
          updateData['stats.totalSwipes'] = FieldValue.increment(1);
        }

        transaction.update(userRef, updateData);
      });

      if (kDebugMode)
        print("Recorded swipe: $action (from $oldStatus) for ${restaurant.id}");
    } catch (e) {
      if (kDebugMode) print("Error recording swipe: $e");
    }
  }

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
}
