import 'package:dishcovery_app/models/restaurant_model.dart';
import 'package:dishcovery_app/models/restaurant_details_model.dart';
import 'package:dishcovery_app/models/restaurant_mock.dart';
import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:dishcovery_app/services/places_service.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RestaurantService extends ChangeNotifier {
  // Singleton pattern
  static final RestaurantService instance = RestaurantService._internal();

  factory RestaurantService() {
    return instance;
  }

  RestaurantService._internal() {
    _initializeData();
  }

  List<RestaurantCardData> _restaurants = [];
  List<String> _userPreferences = [];
  double _userMaxDistance = 50.0; // Default max distance
  bool _isReady = false; // Add isReady flag

  bool get isReady => _isReady;

  double _lastKnownLat = 0.0; // Cache location
  double _lastKnownLng = 0.0;

  Future<void> _initializeData() async {
    // 1. Fetch User Preferences first (independent)
    await fetchUserPreferences();

    // 2. Get User Location
    Position? position = await _getCurrentLocation();
    if (position != null) {
      _lastKnownLat = position.latitude;
      _lastKnownLng = position.longitude;
    }

    // CRM: Toggle for Mock Data vs Real Data
    if (AppConfig.useMockData) {
      if (kDebugMode) print("DEBUG: Using Mock Data + Firestore");

      // 1. Process Mock Data
      List<RestaurantCardData> mockList = mockRestaurants.map((r) {
        return r.copyWith(status: SwipeStatus.none);
      }).toList();

      // 2. Process Firestore Data (Merge with Mock)
      List<RestaurantCardData> firestoreList = [];
      try {
        final firestoreData = await fetchRestaurantsFromFirestore();
        if (firestoreData.isNotEmpty) {
          firestoreList = firestoreData.map((r) {
            return r.copyWith(status: SwipeStatus.none);
          }).toList();
        }
      } catch (e) {
        if (kDebugMode) print("Error fetching/merging Firestore data: $e");
      }

      // Combine lists
      _restaurants = [...mockList, ...firestoreList];
      _isReady = true;
      notifyListeners();
      return;
    }

    // Try fetching from Firestore first
    List<RestaurantCardData> firestoreRestaurants =
        await fetchRestaurantsFromFirestore();

    if (firestoreRestaurants.isNotEmpty) {
      if (kDebugMode)
        print(
          "DEBUG: Using Firestore Data (${firestoreRestaurants.length} items)",
        );
      _restaurants = firestoreRestaurants.map((r) {
        return r.copyWith(status: SwipeStatus.none);
      }).toList();
    } else if (position != null) {
      // Fallback: Fetch Restaurants from Google Places API
      try {
        if (kDebugMode) print("DEBUG: Using Places API Data");
        final places = await PlacesService().fetchNearbyRestaurants(
          latitude: position.latitude,
          longitude: position.longitude,
        );

        // 4. Update status
        _restaurants = places.map((r) {
          return r.copyWith(status: SwipeStatus.none);
        }).toList();
      } catch (e) {
        if (kDebugMode) print("Error fetching places: $e");
      }
    } else {
      // Handle no location permission or service disabled
      if (kDebugMode)
        print("Location not available, cannot fetch nearby places.");
    }

    _isReady = true;
    notifyListeners();
  }

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

  Future<List<RestaurantCardData>> fetchRestaurantsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .get();
      return snapshot.docs.map((doc) {
        return RestaurantCardData.fromFirestore(doc.data(), doc.id);
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

  Future<void> fetchUserPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            if (data['preferences'] != null) {
              _userPreferences = List<String>.from(data['preferences']);
            }
            if (data['distancePreference'] != null) {
              _userMaxDistance = (data['distancePreference'] as num).toDouble();
            }
            notifyListeners();
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error fetching preferences: $e");
        }
      }
    }
  }

  void updatePreferences(List<String> prefs, double distance) {
    _userPreferences = prefs;
    _userMaxDistance = distance;
    notifyListeners();
  }

  // Getters for different states
  List<RestaurantCardData> get restaurants => _restaurants;

  List<RestaurantCardData> get swipableRestaurants {
    List<RestaurantCardData> filtered = _restaurants
        .where((r) => r.status == SwipeStatus.none)
        .toList();

    // Filter by Distance
    if (_userMaxDistance < 50.0) {
      filtered = filtered
          .where((r) => getDistance(r) <= _userMaxDistance)
          .toList();
    }
    // print(
    // "Debug: After Distance Filter (< $_userMaxDistance km): ${filtered.length}",
    // );

    // Filter by Preferences (Cuisine)
    if (_userPreferences.isNotEmpty) {
      // print("Debug: User Preferences: $_userPreferences");
      filtered = filtered.where((r) {
        for (final pref in _userPreferences) {
          final keywords = _getCuisineKeywords(pref);
          for (final keyword in keywords) {
            // Basic contains check
            if (r.cuisine.contains(keyword) || r.cuisine == 'อาหารทั่วไป') {
              return true;
            }
          }
        }
        return false;
      }).toList();
      print("Debug: After Preference Filter: ${filtered.length}");
    } else {
      print("Debug: No User Preferences, skipping filter.");
    }

    return filtered;
  }

  List<String> _getCuisineKeywords(String preference) {
    if (preference.contains("อาหารไทย") ||
        preference == "อาหารอีสาน" ||
        preference == "อาหารเหนือ" ||
        preference == "อาหารใต้") {
      return ["ไทย", "อีสาน", "เหนือ", "ใต้"];
    }
    if (preference.contains("ญี่ปุ่น")) return ["ญี่ปุ่น", "ซูชิ", "ราเมน"];
    if (preference.contains("เกาหลี")) return ["เกาหลี", "ปิ้งย่าง"];
    if (preference.contains("จีน")) return ["จีน", "ติ่มซำ"];
    if (preference.contains("ตะวันตก") ||
        preference.contains("ฟาสต์ฟู้ด") ||
        preference.contains("เบอร์เกอร์") ||
        preference == "พิซซ่า") {
      return ["อิตาเลียน", "เม็กซิกัน", "เบอร์เกอร์", "สเต็ก", "พิซซ่า"];
    }
    if (preference.contains("อินเดีย")) return ["อินเดีย"];
    if (preference.contains("เวียดนาม")) return ["เวียดนาม"];

    // Default fallback: trim "อาหาร" out
    return [preference.replaceAll("อาหาร", "").trim()];
  }

  List<RestaurantCardData> get history {
    // History shows everything that is NOT none (YUM or PASS)
    return _restaurants.where((r) => r.status != SwipeStatus.none).toList();
  }

  List<RestaurantCardData> get favorites {
    // Favorites only shows FAV (Swipe Up)
    return _restaurants.where((r) => r.status == SwipeStatus.fav).toList();
  }

  // Update status (Swipe Action)
  void swipeRestaurant(String id, SwipeStatus newStatus) {
    if (newStatus == SwipeStatus.none) return;

    final index = _restaurants.indexWhere((r) => r.id == id);
    if (index != -1) {
      _restaurants[index] = _restaurants[index].copyWith(status: newStatus);
      notifyListeners();
    }
  }

  // Optional: Reset all data
  void resetData() {
    _initializeData();
    notifyListeners();
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
          doc.data()!,
          doc.id,
        );
        if (kDebugMode)
          print("DEBUG: Parsed Gallery Images: ${details.galleryImages}");

        // Fetch subcollection 'menuItems'
        try {
          if (kDebugMode) print("DEBUG: Fetching menuItems subcollection...");
          final menuSnapshot = await FirebaseFirestore.instance
              .collection('restaurants')
              .doc(id)
              .collection('menuItems')
              .get();

          if (kDebugMode)
            print(
              "DEBUG: Subcollection docs count: ${menuSnapshot.docs.length}",
            );

          if (menuSnapshot.docs.isNotEmpty) {
            final menuList = menuSnapshot.docs.map((mDoc) {
              final data = mDoc.data();
              // if (kDebugMode)
              //   print("DEBUG: Menu item data: $data"); // debug แสดงรายการอาหาร
              return MenuItem.fromFirestore(data);
            }).toList();

            // Override empty menu with subcollection data
            details = details.copyWith(menuItems: menuList);
            if (kDebugMode)
              print(
                "DEBUG: Updated details with ${menuList.length} menu items.",
              );
          } else {
            if (kDebugMode)
              print("DEBUG: No menu items found in subcollection.");
          }
        } catch (e) {
          if (kDebugMode) print("Error fetching menu items subcollection: $e");
        }

        // Update local cache to trigger UI update
        final index = _restaurants.indexWhere((r) => r.id == id);
        if (index != -1) {
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
}
