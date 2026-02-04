import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dishcovery_app/constants/api_constants.dart';
import 'package:dishcovery_app/models/restaurant_model.dart';

class PlacesService {
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

  Future<List<RestaurantCardData>> fetchNearbyRestaurants({
    required double latitude,
    required double longitude,
    double radius = 1500, // in meters
    String type = 'restaurant',
  }) async {
    final String url =
        '$_baseUrl?location=$latitude,$longitude&radius=$radius&type=$type&key=${ApiConstants.googlePlacesApiKey}&language=th';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final List<dynamic> results = data['results'];
          print(
            ' Google Places API Call Successful! Found ${results.length} restaurants.',
          );
          return results.map((json) => _mapToRestaurant(json)).toList();
        } else if (data['status'] == 'REQUEST_DENIED') {
          print(
            'Error: API Key Restricted. Go to Google Cloud Console > Credentials > API Key.',
          );
          print(
            'Set "Application restrictions" to "None" or add IP: ${data['error_message']}',
          );
          return [];
        } else {
          print(
            'Places API Error: ${data['status']} - ${data['error_message']}',
          );
          return [];
        }
      } else {
        print('Failed to load places: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception fetching places: $e');
      return [];
    }
  }

  RestaurantCardData _mapToRestaurant(Map<String, dynamic> json) {
    final geometry = json['geometry']['location'];
    final photos = json['photos'] as List<dynamic>?;
    String? photoUrl;

    if (photos != null && photos.isNotEmpty) {
      final photoReference = photos[0]['photo_reference'];
      photoUrl =
          'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=$photoReference&key=${ApiConstants.googlePlacesApiKey}';
    }

    // Map Price Level to 1-3 range
    int priceLevel = 2;
    if (json.containsKey('price_level')) {
      // Google: 0-4 (Free, Inexpensive, Moderate, Expensive, Very Expensive)
      // App: 1-3
      int gl = json['price_level'];
      if (gl <= 1)
        priceLevel = 1;
      else if (gl == 2)
        priceLevel = 2;
      else
        priceLevel = 3;
    }

    // Map Types to Cuisine
    List<dynamic> types = json['types'] ?? [];
    List<String> cuisines = [];

    if (types.contains('bakery')) cuisines.add("เบเกอรี่");
    if (types.contains('cafe')) cuisines.add("คาเฟ่");
    if (types.contains('bar')) cuisines.add("บาร์");
    if (types.contains('restaurant')) cuisines.add("อาหารทั่วไป");

    if (cuisines.isEmpty) cuisines.add("อาหารทั่วไป");

    return RestaurantCardData(
      id: json['place_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      cuisine: cuisines,
      priceRange: priceLevel,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      latitude: (geometry['lat'] as num).toDouble(),
      longitude: (geometry['lng'] as num).toDouble(),
      imageUrl:
          photoUrl ??
          'https://via.placeholder.com/400x300?text=No+Image', // Placeholder if no image
      description: 'A great place to eat!', // Placeholder
    );
  }
}
