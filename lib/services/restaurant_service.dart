import 'package:dishcovery_app/models/restaurant_mock.dart';
import 'package:dishcovery_app/models/restaurant_model.dart';
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

  void _initializeData() {
    // Reset all mock data to SwipeStatus.none so the user starts fresh
    _restaurants = mockRestaurants.map((r) {
      return r.copyWith(status: SwipeStatus.none);
    }).toList();

    // Trigger location update
    updateUserLocation();

    // Fetch preferences
    fetchUserPreferences();
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

  Future<void> updateUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {
      Position position = await Geolocator.getCurrentPosition();

      List<RestaurantCardData> updatedRestaurants = [];

      for (var restaurant in _restaurants) {
        double distanceInMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          restaurant.latitude,
          restaurant.longitude,
        );

        // Convert to Kilometers and round to 1 decimal place
        double distanceInKm = double.parse(
          (distanceInMeters / 1000).toStringAsFixed(1),
        );

        updatedRestaurants.add(restaurant.copyWith(distance: distanceInKm));
      }

      _restaurants = updatedRestaurants;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print("Error getting location: $e");
      }
    }
  }

  // Getters for different states
  List<RestaurantCardData> get restaurants => _restaurants;

  List<RestaurantCardData> get swipableRestaurants {
    List<RestaurantCardData> filtered = _restaurants
        .where((r) => r.status == SwipeStatus.none)
        .toList();

    // Filter by Distance
    // If _userMaxDistance is >= 50, consider it as "unlimited" (or very far).
    // But requirement says "filter according to truth". Let's say 50+ means > 50.
    // If logic is strict:
    if (_userMaxDistance < 50.0) {
      filtered = filtered.where((r) => r.distance <= _userMaxDistance).toList();
    }

    // Filter by Preferences (Cuisine)
    if (_userPreferences.isNotEmpty) {
      filtered = filtered.where((r) {
        // Check if restaurant cuisine matches any of the user preferences keywords
        // User Pref: "อาหารไทย" -> Keyword: "ไทย"
        // User Pref: "อาหารญี่ปุ่น" -> Keyword: "ญี่ปุ่น"

        for (final pref in _userPreferences) {
          final keywords = _getCuisineKeywords(pref);
          for (final keyword in keywords) {
            if (r.cuisine.contains(keyword)) {
              return true;
            }
          }
        }
        return false;
      }).toList();
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
}
