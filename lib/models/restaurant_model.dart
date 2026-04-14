import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItem {
  final String id;
  final String name;
  final int price;
  final String menuImage;
  final String category; // categoryId or name
  final bool isRecommended;
  final bool isAvailable;

  MenuItem({
    required this.name,
    required this.price,
    this.id = '',
    this.menuImage = '',
    this.category = '',
    this.isRecommended = false,
    this.isAvailable = true,
  });

  MenuItem copyWith({
    String? id,
    String? name,
    int? price,
    String? menuImage,
    String? category,
    bool? isRecommended,
    bool? isAvailable,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      menuImage: menuImage ?? this.menuImage,
      category: category ?? this.category,
      isRecommended: isRecommended ?? this.isRecommended,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      price: (json['price'] as num?)?.toInt() ?? 0,
      menuImage: json['menuImage'] as String? ?? '',
      category: json['category'] as String? ?? '',
      isRecommended: json['isRecommended'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }

  // maintain compatibility if used
  factory MenuItem.fromFirestore(Map<String, dynamic> data) =>
      MenuItem.fromJson(data);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'menuImage': menuImage,
      'category': category,
      'isRecommended': isRecommended,
      'isAvailable': isAvailable,
    };
  }
}

class MenuCategory {
  final String id;
  final String name;
  final int order;

  MenuCategory({required this.id, required this.name, required this.order});

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    return MenuCategory(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  MenuCategory copyWith({String? id, String? name, int? order}) {
    return MenuCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'order': order};
  }
}

enum SwipeStatus { yum, pass, none, fav }

class RestaurantCardData {
  final String id;
  final String name;
  final List<String> cuisine; // Changed to List<String>
  final int priceRange; // 1, 2, or 3
  final double rating;
  final double latitude; // Added latitude
  final double longitude; // Added longitude
  final String imageUrl;
  final String description;
  final Map<String, dynamic> openingHours; // Changed to Map
  final DateTime? createdAt;
  final String status; // 'pending', 'approved', 'rejected'
  final String? ownerId;
  final String? rejectionReason;
  final bool isTemporarilyClosed;
  final int reviewCount; // Added reviewCount

  RestaurantCardData({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.priceRange,
    required this.rating,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.description,
    this.openingHours = const {}, // Default empty map
    this.createdAt,
    this.status = 'approved', // Default to approved for legacy data
    this.ownerId,
    this.rejectionReason,
    this.isTemporarilyClosed = false,
    this.reviewCount = 0,
  });

  RestaurantCardData copyWith({
    String? id,
    String? name,
    List<String>? cuisine,
    int? priceRange,
    double? rating,
    double? latitude,
    double? longitude,
    String? imageUrl,
    String? description,
    Map<String, dynamic>? openingHours,
    DateTime? createdAt,
    String? status,
    String? ownerId,
    String? rejectionReason,
    bool? isTemporarilyClosed,
    int? reviewCount,
  }) {
    return RestaurantCardData(
      id: id ?? this.id,
      name: name ?? this.name,
      cuisine: cuisine ?? this.cuisine,
      priceRange: priceRange ?? this.priceRange,
      rating: rating ?? this.rating,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      openingHours: openingHours ?? this.openingHours,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      ownerId: ownerId ?? this.ownerId,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isTemporarilyClosed: isTemporarilyClosed ?? this.isTemporarilyClosed,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }

  // ฟังก์ชันแปลง JSON เป็น Restaurant object
  factory RestaurantCardData.fromJson(Map<String, dynamic> json) {
    // Helper to parse cuisine safely
    List<String> parseCuisine(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.map((e) => e.toString()).toList();
      if (value is String) return [value];
      return [];
    }

    // Helper to parse openingHours safely
    Map<String, dynamic> parseOpeningHours(dynamic value) {
      if (value == null) return {};
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return {};
    }

    return RestaurantCardData(
      id: json['id'] as String,
      name: json['name'] as String,
      cuisine: parseCuisine(json['cuisine']),
      priceRange: json['priceRange'] as int,
      rating: (json['rating'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      description: json['description'] as String,
      openingHours: parseOpeningHours(json['openingHours']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      status: json['status'] as String? ?? 'approved',
      ownerId: json['ownerId'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      isTemporarilyClosed: json['isTemporarilyClosed'] as bool? ?? false,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  // Factory for Firestore
  factory RestaurantCardData.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    // Helper to parse int safely
    int parseInt(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    // Helper to parse double safely
    double parseDouble(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    // Helper to parse cuisine safely
    List<String> parseCuisine(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.map((e) => e.toString()).toList();
      if (value is String) return [value];
      return [];
    }

    // Helper to parse openingHours safely
    Map<String, dynamic> parseOpeningHours(dynamic value) {
      if (value == null) return {};
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return {};
    }

    return RestaurantCardData(
      id: id,
      name: data['name'] ?? '',
      cuisine: parseCuisine(data['cuisine']),
      priceRange: parseInt(data['priceRange'], 1),
      rating: parseDouble(data['rating'], 0.0),
      latitude: parseDouble(data['latitude'], 0.0),
      longitude: parseDouble(data['longitude'], 0.0),
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      openingHours: parseOpeningHours(data['openingHours']),
      createdAt: data['created_at'] != null
          ? (data['created_at'] is Timestamp
                ? (data['created_at'] as Timestamp).toDate()
                : DateTime.tryParse(data['created_at'].toString()))
          : null,
      status: data['status'] as String? ?? 'approved',
      ownerId: data['ownerId'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
      isTemporarilyClosed: data['isTemporarilyClosed'] as bool? ?? false,
      reviewCount: parseInt(data['reviewCount'], 0),
    );
  }

  // ฟังก์ชันแปลง Restaurant object เป็น JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cuisine': cuisine,
      'priceRange': priceRange,
      'rating': rating,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'description': description,
      'openingHours': openingHours,
      'created_at': createdAt?.toIso8601String(),
      'status': status,
      'ownerId': ownerId,
      'rejectionReason': rejectionReason,
      'isTemporarilyClosed': isTemporarilyClosed,
      'reviewCount': reviewCount,
    };
  }

  // ฟังก์ชันสำหรับแสดงสัญลักษณ์ราคา
  String getPriceSymbol() {
    return '฿' * priceRange;
  }
}

class ReviewModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final double rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ReviewModel(
      id: id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Anonymous',
      userPhotoUrl: data['userPhotoUrl'] as String?,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'] as String? ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
