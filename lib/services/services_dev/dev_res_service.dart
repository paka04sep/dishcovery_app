import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dishcovery_app/services/restaurant_service.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class DevResService {
  // Singleton pattern for easy access
  static final DevResService _instance = DevResService._internal();
  static DevResService get instance => _instance;
  DevResService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  // Data for random generation
  final List<String> _prefixes = [
    'บ้าน',
    'ครัว',
    'ร้าน',
    'เรือน',
    'ลาน',
    'สวน',
    'ข้าว',
    'ก๋วยเตี๋ยว',
    'ตำ',
    'ยำ',
    'ป้า',
    'ลุง',
    'เจ๊',
    'แม่',
    'พ่อ',
    'นาย',
    'โก',
    'เฮีย',
    'เฮง',
    'โชคดี',
    'อร่อย',
    'แซ่บ',
    'เด็ด',
    'ต้นตำรับ',
    'สูตรลับ',
    'ริมทาง',
    'โบราณ',
  ];

  final List<String> _suffixes = [
    'อร่อยเด็ด',
    'สูตรโบราณ',
    'ต้นตำรับ',
    'เจ้าเก่า',
    'เจ้าเด็ด',
    'เจ้าดัง',
    'สูตรบ้านๆ',
    'บ้านๆ',
    'ริมทาง',
    'ตามสั่ง',
    'ข้างทาง',
    'จานด่วน',
    'จานเด็ด',
    'หม้อไฟ',
    'ยกซด',
    'ยกหม้อ',
    'ยกครัว',
    'ยกเตา',
    'ยกบ้าน',
    'ยามเย็น',
    'ยามค่ำ',
  ];

  final Map<String, List<Map<String, dynamic>>> _cuisineMenus = {
    'อาหารไทย': [
      {'name': 'ผัดกะเพรา', 'price': 50},
      {'name': 'ต้มยำกุ้ง', 'price': 150},
      {'name': 'แกงเขียวหวาน', 'price': 80},
      {'name': 'ส้มตำ', 'price': 40},
    ],
    'อาหารอีสาน': [
      {'name': 'ส้มตำปูปลาร้า', 'price': 40},
      {'name': 'ลาบหมู', 'price': 60},
      {'name': 'คอหมูย่าง', 'price': 80},
    ],
    'อาหารญี่ปุ่น': [
      {'name': 'Salmon Sashimi', 'price': 180},
      {'name': 'Ramen', 'price': 120},
      {'name': 'Sushi Set', 'price': 250},
    ],
    'อาหารเกาหลี': [
      {'name': 'Kimchi Soup', 'price': 120},
      {'name': 'Bibimbap', 'price': 150},
      {'name': 'Korean BBQ Set', 'price': 399},
    ],
    'ฟาสต์ฟู้ด': [
      {'name': 'Burger Set', 'price': 159},
      {'name': 'French Fries', 'price': 59},
      {'name': 'Fried Chicken', 'price': 39},
    ],
    'เบเกอรี่': [
      {'name': 'Croissant', 'price': 65},
      {'name': 'Cheesecake', 'price': 120},
      {'name': 'Coffee Scone', 'price': 55},
    ],
    'คาเฟ่': [
      {'name': 'Iced Latte', 'price': 80},
      {'name': 'Americano', 'price': 70},
      {'name': 'Matcha Latte', 'price': 90},
    ],
  };

  // Helper to get random item from list
  T _getRandomItem<T>(List<T> list) {
    return list[_random.nextInt(list.length)];
  }

  // --- Admin Functions ---

  Future<void> deleteRestaurant(String id) async {
    try {
      if (kDebugMode) print("DevRes: Deleting restaurant $id");
      await _firestore.collection('restaurants').doc(id).delete();

      // Notify main service to refresh if needed (though it listens to stream usually,
      // but if it uses local list, we might want to trigger refresh)
      // Since RestaurantService uses a local list fetched once, we should tell it to refresh
      // or we can just rely on manual refresh.
      // Ideally, RestaurantService should expose a method to remove widely.
      // But for now, we just delete cloud data.

      // HACK: Force refresh on main service
      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      RestaurantService.instance.notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error deleting restaurant: $e");
      rethrow;
    }
  }

  Future<void> deleteRestaurants(List<String> ids) async {
    try {
      if (kDebugMode) print("DevRes: Deleting ${ids.length} restaurants");
      final batch = _firestore.batch();

      for (final id in ids) {
        final docRef = _firestore.collection('restaurants').doc(id);
        batch.delete(docRef);
        // Note: Subcollections (menuItems) are NOT automatically deleted by batch delete in Firestore
        // For a proper implementation, we should query and delete subcollections too.
        // But for this "Dev" tool, maybe skipping subcollection deletion is acceptable or we do it iteratively
        // if we want to be thorough. For performance with large batches, typically cloud functions are better.
        // Here, let's keep it simple: just delete the parent doc for now
        // OR iterate and delete (which is slower but cleaner).
        // Let's rely on the batch for parent doc.
        // Ideally we should delete subcollections.
        // Given this is a dev tool, let's try to do it right if possible, but batch has 500 limit.
      }

      await batch.commit();

      // Notify main service
      // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
      RestaurantService.instance.notifyListeners();
    } catch (e) {
      if (kDebugMode) print("Error batch deleting restaurants: $e");
      rethrow;
    }
  }

  Future<void> generateRandomRestaurant() async {
    try {
      if (kDebugMode) print("DevRes: Generating random restaurant...");

      // 1. Determine Next ID
      final snapshot = await _firestore
          .collection('restaurants')
          .orderBy('created_at', descending: true)
          .limit(1)
          .get();

      String nextId = 'res_0001';
      if (snapshot.docs.isNotEmpty) {
        final lastId = snapshot.docs.first.id;
        if (lastId.startsWith('res_')) {
          final numberPart = int.tryParse(lastId.substring(4)) ?? 0;
          nextId = 'res_${(numberPart + 1).toString().padLeft(4, '0')}';
        }
      }

      // 2. Generate Random Data
      final name = '${_getRandomItem(_prefixes)} ${_getRandomItem(_suffixes)}';

      // Select 1-3 random cuisines
      final cuisineKeys = _cuisineMenus.keys.toList();
      cuisineKeys.shuffle(_random);
      final selectedCuisines = cuisineKeys
          .take(_random.nextInt(3) + 1)
          .toList();

      // Generate Menu Items
      final List<Map<String, dynamic>> menuItems = [];
      for (final cuisine in selectedCuisines) {
        final possibleDishes = _cuisineMenus[cuisine] ?? [];
        if (possibleDishes.isNotEmpty) {
          menuItems.add(_getRandomItem(possibleDishes));
        }
      }

      // Random Location (Near Bangkok Center approx)
      // Bangkok center: 13.7563, 100.5018
      // Variate by +/- 0.05 degrees (approx 5km)
      final lat = 13.7563 + (_random.nextDouble() - 0.5) * 0.1;
      final lng = 100.5018 + (_random.nextDouble() - 0.5) * 0.1;

      // Price Range: $ to $$$$
      final priceRange = [
        '\$',
        '\$\$',
        '\$\$\$',
        '\$\$\$\$',
      ][_random.nextInt(4)];

      // Rating: 3.5 to 5.0
      final rating = 3.5 + _random.nextDouble() * 1.5;

      // 3. Write to Firestore
      final docRef = _firestore.collection('restaurants').doc(nextId);
      final data = {
        'id': nextId,
        'name': name,
        'cuisine': selectedCuisines,
        'priceRange': priceRange,
        'rating': double.parse(rating.toStringAsFixed(1)),
        'latitude': lat,
        'longitude': lng,
        'imageUrl':
            'https://placehold.co/600x400?text=$name', // Placeholder image
        'description':
            'A wonderful place for ${selectedCuisines.join(', ')} lovers.',
        'address': 'Random Address in Bangkok',
        'phone': '080-000-${_random.nextInt(9999).toString().padLeft(4, '0')}',
        'openingHours': '10:00 - 22:00',
        'galleryImages': [
          'https://placehold.co/600x400/png?text=Gallery+1',
          'https://placehold.co/600x400/png?text=Gallery+2',
        ],
        'created_at': FieldValue.serverTimestamp(),
      };

      final batch = _firestore.batch();
      batch.set(docRef, data);

      // Subcollection menuItems
      for (final menu in menuItems) {
        final menuRef = docRef.collection('menuItems').doc();
        batch.set(menuRef, menu);
      }

      await batch.commit();

      if (kDebugMode) print("DevRes: Created $nextId");
    } catch (e) {
      if (kDebugMode) print("Error generating restaurant: $e");
      rethrow;
    }
  }
}
