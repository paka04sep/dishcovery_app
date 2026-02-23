import 'package:dishcovery_app/models/restaurant_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantDetailsData extends RestaurantCardData {
  final String address;
  final String phone;
  final List<MenuItem> menuItems;
  final List<String> galleryImages;
  final List<MenuCategory> menuCategories;

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
    super.openingHours,
    required this.address,
    required this.phone,
    this.menuItems = const [],
    this.galleryImages = const [],
    this.menuCategories = const [],
  });

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
    List<MenuCategory>? menuCategories,
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
      menuCategories: menuCategories ?? this.menuCategories,
    );
  }

  factory RestaurantDetailsData.fromFirestore(
    DocumentSnapshot doc,
    Map<String, dynamic>? data,
  ) {
    if (data == null) {
      return RestaurantDetailsData(
        id: doc.id,
        name: '',
        cuisine: [],
        priceRange: 1,
        rating: 0.0,
        latitude: 0.0,
        longitude: 0.0,
        imageUrl: '',
        address: '',
        phone: '',
        openingHours: {},
        description: '',
      );
    }

    // Helper to parse cuisine
    List<String> parseCuisine(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.map((e) => e.toString()).toList();
      if (value is String) return [value];
      return [];
    }

    // Helper to parse openingHours
    Map<String, dynamic> parseOpeningHours(dynamic value) {
      if (value == null) return {};
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return {};
    }

    // Helper to parse menu items
    List<MenuItem> parseMenuItems(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) {
          if (e is Map<String, dynamic>) {
            return MenuItem.fromJson(e);
          }
          return MenuItem(name: 'Unknown', price: 0);
        }).toList();
      }
      return [];
    }

    // Helper to parse menu categories
    List<MenuCategory> parseMenuCategories(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) {
          if (e is Map<String, dynamic>) {
            return MenuCategory.fromJson(e);
          }
          return MenuCategory(id: '', name: 'Unknown', order: 0);
        }).toList();
      }
      return [];
    }

    return RestaurantDetailsData(
      id: doc.id,
      name: data['name'] ?? '',
      cuisine: parseCuisine(data['cuisine']),
      priceRange: (data['priceRange'] as num?)?.toInt() ?? 1,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['imageUrl'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      openingHours: parseOpeningHours(data['openingHours']),
      description: data['description'] ?? '',
      galleryImages: data['galleryImages'] != null
          ? List<String>.from(data['galleryImages'])
          : [],
      menuItems: parseMenuItems(data['menuItems']),
      menuCategories: parseMenuCategories(data['menuCategories']),
    );
  }
}
