import 'package:dishcovery_app/models/restaurant_mock.dart';
import 'package:dishcovery_app/models/restaurant_model.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

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

  void _initializeData() {
    // Reset all mock data to SwipeStatus.none so the user starts fresh
    _restaurants = mockRestaurants.map((r) {
      return r.copyWith(status: SwipeStatus.none);
    }).toList();

    // Trigger location update
    updateUserLocation();
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
    return _restaurants.where((r) => r.status == SwipeStatus.none).toList();
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
