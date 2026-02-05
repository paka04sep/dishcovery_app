import 'package:dishcovery_app/models/restaurant_model.dart';
import 'package:dishcovery_app/models/user_model.dart';
import 'package:dishcovery_app/utils/cuisine_keywords.dart';

class RecommendationEngine {
  final Map<String, int> _categoryScores = {};
  final Map<int, int> _priceScores = {};

  // Weights
  static const int _scoreExplicitPreference = 10;
  static const int _scoreFav = 3;
  static const int _scoreYum = 1;
  // static const int _scorePass = -1; // Optional: Penalize passed items

  void updateUserTasteProfile(
    UserModel user,
    List<RestaurantCardData> allRestaurants,
  ) {
    _categoryScores.clear();
    _priceScores.clear();

    // 1. Analyze Favorites
    for (String id in user.history.fav) {
      final restaurant = allRestaurants.firstWhere(
        (r) => r.id == id,
        orElse: () => RestaurantCardData(
          id: '',
          name: '',
          cuisine: [],
          priceRange: 1,
          rating: 0,
          latitude: 0,
          longitude: 0,
          imageUrl: '',
          description: '',
        ),
      );
      if (restaurant.id.isNotEmpty) {
        _scoreRestaurantAttributes(restaurant, _scoreFav);
      }
    }

    // 2. Analyze Yums
    for (String id in user.history.yum) {
      final restaurant = allRestaurants.firstWhere(
        (r) => r.id == id,
        orElse: () => RestaurantCardData(
          id: '',
          name: '',
          cuisine: [],
          priceRange: 1,
          rating: 0,
          latitude: 0,
          longitude: 0,
          imageUrl: '',
          description: '',
        ),
      );
      if (restaurant.id.isNotEmpty) {
        _scoreRestaurantAttributes(restaurant, _scoreYum);
      }
    }
  }

  void _scoreRestaurantAttributes(RestaurantCardData r, int scoreToAdd) {
    // Score Cuisines
    for (String c in r.cuisine) {
      _categoryScores[c] = (_categoryScores[c] ?? 0) + scoreToAdd;
    }
    // Score Price Range
    _priceScores[r.priceRange] = (_priceScores[r.priceRange] ?? 0) + scoreToAdd;
  }

  int calculateScore(RestaurantCardData r, UserModel user) {
    int score = 0;

    // 1. Explicit Preferences (Highest Priority)
    bool matchesExplicit = false;
    if (user.preferences.isNotEmpty) {
      for (final pref in user.preferences) {
        final keywords = CuisineUtils.getKeywords(pref);
        for (final keyword in keywords) {
          for (final c in r.cuisine) {
            if (c.contains(keyword) || c == 'อาหารทั่วไป') {
              matchesExplicit = true;
              break;
            }
          }
        }
      }
    }
    if (matchesExplicit) {
      score += _scoreExplicitPreference;
    }

    // 2. Implicit History (Cuisine Affinity)
    for (final c in r.cuisine) {
      if (_categoryScores.containsKey(c)) {
        score += _categoryScores[c]!;
      }
    }

    // 3. Price Affinity
    if (_priceScores.containsKey(r.priceRange)) {
      score += _priceScores[r.priceRange]!;
    }

    // 4. Rating Boost (Minor)
    score += r.rating.toInt();

    return score;
  }

  // Helper to sort a list
  List<RestaurantCardData> rankRestaurants(
    List<RestaurantCardData> list,
    UserModel user,
  ) {
    // Create a new list to avoid modifying the original during iteration if not intended,
    // though sort modifies in place.
    List<RestaurantCardData> sortedList = List.from(list);
    sortedList.sort((a, b) {
      int scoreA = calculateScore(a, user);
      int scoreB = calculateScore(b, user);
      return scoreB.compareTo(scoreA); // Descending
    });
    return sortedList;
  }
}
