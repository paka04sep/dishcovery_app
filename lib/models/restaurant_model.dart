import 'package:flutter/material.dart';

// class RestaurantCardData {
//   final String name;
//   final String imageUrl;
//   final String type;
//   final String priceRate;
//   final String location;
//   final SwipeStatus status;

//   RestaurantCardData({
//     required this.name,
//     required this.imageUrl,
//     required this.type,
//     required this.priceRate,
//     required this.location,
//     required this.status,
//   });
// }

// // ข้อมูลจำลอง (Mock Data) สำหรับการใช้งาน
// final List<RestaurantCardData> mockRestaurants = [
//   RestaurantCardData(
//     name: "RESTAURANT NAME1",
//     imageUrl: "assets/images/res/r1.jpg",
//     type: "Italian/Pizza",
//     priceRate: "\$\$\$",
//     location: "Downtown, City A",
//     status: SwipeStatus.yum,
//   ),
//   RestaurantCardData(
//     name: "RESTAURANT NAME2",
//     imageUrl: "assets/images/res/r2.jpg",
//     type: "Fusion/Asian",
//     priceRate: "\$\$",
//     location: "Uptown, City B",
//     status: SwipeStatus.pass,
//   ),
//   RestaurantCardData(
//     name: "RESTAURANT NAME3",
//     imageUrl: "assets/images/res/r3.jpg",
//     type: "Steak/Grill",
//     priceRate: "\$\$\$\$",
//     location: "Midtown, City C",
//     status: SwipeStatus.pass,
//   ),
//   RestaurantCardData(
//     name: "RESTAURANT NAME4",
//     imageUrl: "assets/images/res/r4.jpg",
//     type: "Steak/Grill",
//     priceRate: "\$\$\$\$",
//     location: "Midtown, City C",
//     status: SwipeStatus.pass,
//   ),
//   RestaurantCardData(
//     name: "RESTAURANT NAME5",
//     imageUrl: "assets/images/res/r5.jpg",
//     type: "Steak/Grill",
//     priceRate: "\$\$\$\$",
//     location: "Midtown, City C",
//     status: SwipeStatus.pass,
//   ),
//   RestaurantCardData(
//     name: "RESTAURANT NAME6",
//     imageUrl: "assets/images/res/r6.jpg",
//     type: "Steak/Grill",
//     priceRate: "\$\$\$\$",
//     location: "Midtown, City C",
//     status: SwipeStatus.pass,
//   ),
//   RestaurantCardData(
//     name: "RESTAURANT NAME7",
//     imageUrl: "assets/images/res/r7.jpg",
//     type: "Steak/Grill",
//     priceRate: "\$\$\$\$",
//     location: "Midtown, City C",
//     status: SwipeStatus.pass,
//   ),
//   RestaurantCardData(
//     name: "RESTAURANT NAME8",
//     imageUrl: "assets/images/res/r8.jpg",
//     type: "Steak/Grill",
//     priceRate: "\$\$\$\$",
//     location: "Midtown, City C",
//     status: SwipeStatus.yum,
//   ),
//   RestaurantCardData(
//     name: "RESTAURANT NAME9",
//     imageUrl: "assets/images/res/r9.jpg",
//     type: "Steak/Grill",
//     priceRate: "\$\$\$\$",
//     location: "Midtown, City C",
//     status: SwipeStatus.yum,
//   ),
//   RestaurantCardData(
//     name: "RESTAURANT NAME10",
//     imageUrl: "assets/images/res/r10.jpg",
//     type: "Steak/Grill",
//     priceRate: "\$\$\$\$",
//     location: "Midtown, City C",
//     status: SwipeStatus.pass,
//   ),
// ];

class MenuItem {
  final String name;
  final String price;

  MenuItem({required this.name, required this.price});
}

enum SwipeStatus { yum, pass }

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
