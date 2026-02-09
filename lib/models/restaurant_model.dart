import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItem {
  final String name;
  final int price;

  MenuItem({required this.name, required this.price});

  factory MenuItem.fromFirestore(Map<String, dynamic> data) {
    int parseInt(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return MenuItem(
      name: data['name'] ?? '',
      price: parseInt(data['price'], 0),
    );
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
    };
  }

  // ฟังก์ชันสำหรับแสดงสัญลักษณ์ราคา
  String getPriceSymbol() {
    return '฿' * priceRange;
  }
}
