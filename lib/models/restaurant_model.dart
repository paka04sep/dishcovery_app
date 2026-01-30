import 'package:flutter/material.dart';

class MenuItem {
  final String name;
  final String price;

  MenuItem({required this.name, required this.price});
}

enum SwipeStatus { yum, pass, none, fav }

class RestaurantCardData {
  final String id;
  final String name;
  final String cuisine;
  final int priceRange; // 1, 2, or 3
  final double rating;
  final double distance;
  final String imageUrl;
  final String address;
  final String phone;
  final String openingHours;
  final String description;
  final SwipeStatus status;

  final List<MenuItem> menuItems; // เก็บรายการเมนู
  final List<String> galleryImages; // เก็บ List ของ Path รูปภาพในร้าน

  RestaurantCardData({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.priceRange,
    required this.rating,
    required this.distance,
    required this.imageUrl,
    required this.address,
    required this.phone,
    required this.openingHours,
    required this.description,
    required this.status,

    this.menuItems = const [],
    this.galleryImages = const [],
  });

  RestaurantCardData copyWith({
    String? id,
    String? name,
    String? cuisine,
    int? priceRange,
    double? rating,
    double? distance,
    String? imageUrl,
    String? address,
    String? phone,
    String? openingHours,
    String? description,
    SwipeStatus? status,
    List<MenuItem>? menuItems,
    List<String>? galleryImages,
  }) {
    return RestaurantCardData(
      id: id ?? this.id,
      name: name ?? this.name,
      cuisine: cuisine ?? this.cuisine,
      priceRange: priceRange ?? this.priceRange,
      rating: rating ?? this.rating,
      distance: distance ?? this.distance,
      imageUrl: imageUrl ?? this.imageUrl,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      openingHours: openingHours ?? this.openingHours,
      description: description ?? this.description,
      status: status ?? this.status,
      menuItems: menuItems ?? this.menuItems,
      galleryImages: galleryImages ?? this.galleryImages,
    );
  }

  // ฟังก์ชันแปลง JSON เป็น Restaurant object
  factory RestaurantCardData.fromJson(Map<String, dynamic> json) {
    return RestaurantCardData(
      id: json['id'] as String,
      name: json['name'] as String,
      cuisine: json['cuisine'] as String,
      priceRange: json['priceRange'] as int,
      rating: (json['rating'] as num).toDouble(),
      distance: (json['distance'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      openingHours: json['openingHours'] as String,
      description: json['description'] as String,
      status: json['status'] as SwipeStatus,
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
      'distance': distance,
      'imageUrl': imageUrl,
      'address': address,
      'phone': phone,
      'openingHours': openingHours,
      'description': description,
      'swipeStatus': SwipeStatus,
    };
  }

  // ฟังก์ชันสำหรับแสดงสัญลักษณ์ราคา
  String getPriceSymbol() {
    return '฿' * priceRange;
  }
}
