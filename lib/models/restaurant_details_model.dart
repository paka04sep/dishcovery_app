import 'package:dishcovery_app/models/restaurant_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantDetailsData extends RestaurantCardData {
  final String address;
  final String phone;
  // final String openingHours; // Inherited from RestaurantCardData
  final List<MenuItem> menuItems;
  final List<String> galleryImages;

  RestaurantDetailsData({
    required super.id,
    required super.name,
    required super.cuisine,
    required super.priceRange,
    required super.rating,
    required super.latitude,
    required super.longitude,
    required super.imageUrl,
    required super.description,
    super.createdAt,
    super.openingHours, // Pass to super
    required this.address,
    required this.phone,
    // required this.openingHours, // Removed
    this.menuItems = const [],
    this.galleryImages = const [],
  });

  // Helper to parse Map safely
  static Map<String, dynamic> _parseOpeningHours(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  // HelperSafe Parse Int
  static int _parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  // Helper Safe Parse Double
  static double _parseDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  // Helper to parse cuisine safely
  static List<String> _parseCuisine(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) return [value];
    return [];
  }

  @override
  RestaurantDetailsData copyWith({
    String? id,
    String? name,
    List<String>? cuisine,
    int? priceRange,
    double? rating,
    double? latitude,
    double? longitude,
    String? imageUrl,
    String? description,
    DateTime? createdAt,
    String? address,
    String? phone,
    Map<String, dynamic>? openingHours,
    List<MenuItem>? menuItems,
    List<String>? galleryImages,
  }) {
    return RestaurantDetailsData(
      id: id ?? this.id,
      name: name ?? this.name,
      cuisine: cuisine ?? this.cuisine,
      priceRange: priceRange ?? this.priceRange,
      rating: rating ?? this.rating,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      openingHours: openingHours ?? this.openingHours,
      menuItems: menuItems ?? this.menuItems,
      galleryImages: galleryImages ?? this.galleryImages,
    );
  }

  factory RestaurantDetailsData.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return RestaurantDetailsData(
      id: id,
      name: data['name'] ?? '',
      cuisine: _parseCuisine(data['cuisine']),
      priceRange: _parseInt(data['priceRange'], 1),
      rating: _parseDouble(data['rating'], 0.0),
      latitude: _parseDouble(data['latitude'], 0.0),
      longitude: _parseDouble(data['longitude'], 0.0),
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      createdAt: data['created_at'] != null
          ? (data['created_at'] is Timestamp
                ? (data['created_at'] as Timestamp).toDate()
                : DateTime.tryParse(data['created_at'].toString()))
          : null,
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      openingHours: _parseOpeningHours(data['openingHours']),
      menuItems:
          (data['menuItems'] as List<dynamic>?)
              ?.map(
                (item) => MenuItem(
                  name: item['name'] ?? '',
                  price: _parseInt(item['price'], 0), // Changed mapping to int
                ),
              )
              .toList() ??
          [],
      galleryImages:
          (data['galleryImages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
