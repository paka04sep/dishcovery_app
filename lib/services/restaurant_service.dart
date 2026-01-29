import 'package:dishcovery_app/models/restaurant_mock.dart';
import 'package:dishcovery_app/models/restaurant_model.dart';
import 'package:flutter/foundation.dart';

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
