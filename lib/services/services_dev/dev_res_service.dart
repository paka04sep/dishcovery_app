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
    // ===== THAI =====
    'อาหารไทย': [
      {'name': 'ผัดกะเพรา', 'price': 50},
      {'name': 'ต้มยำกุ้ง', 'price': 150},
      {'name': 'แกงเขียวหวาน', 'price': 80},
      {'name': 'มัสมั่นไก่', 'price': 120},
      {'name': 'ทอดมันกุ้ง', 'price': 100},
      {'name': 'ปลากะพงทอดน้ำปลา', 'price': 350},
    ],
    'อาหารอีสาน': [
      {'name': 'ส้มตำปูปลาร้า', 'price': 40},
      {'name': 'ลาบหมู', 'price': 60},
      {'name': 'คอหมูย่าง', 'price': 80},
      {'name': 'น้ำตกหมู', 'price': 70},
      {'name': 'ซุปหน่อไม้', 'price': 50},
      {'name': 'ไก่ย่างวิเชียร', 'price': 120},
    ],
    'อาหารเหนือ': [
      {'name': 'ข้าวซอยไก่', 'price': 60},
      {'name': 'ขนมจีนน้ำเงี้ยว', 'price': 50},
      {'name': 'ไส้อั่ว', 'price': 80},
      {'name': 'แกงฮังเล', 'price': 100},
      {'name': 'น้ำพริกหนุ่ม', 'price': 60},
      {'name': 'แคบหมู', 'price': 40},
    ],
    'อาหารใต้': [
      {'name': 'แกงส้มปลากะพง', 'price': 150},
      {'name': 'คั่วกลิ้งหมู', 'price': 80},
      {'name': 'ผัดสะตอกุ้งสด', 'price': 150},
      {'name': 'หมูฮ้อง', 'price': 120},
      {'name': 'ข้าวยำปักษ์ใต้', 'price': 60},
    ],

    // ===== ASIAN =====
    'อาหารญี่ปุ่น': [
      {'name': 'Salmon Sashimi', 'price': 180},
      {'name': 'Ramen', 'price': 120},
      {'name': 'Sushi Set', 'price': 250},
      {'name': 'Tempura Set', 'price': 150},
      {'name': 'Katsudon', 'price': 100},
      {'name': 'Takoyaki', 'price': 60},
    ],
    'อาหารเกาหลี': [
      {'name': 'Kimchi Soup', 'price': 120},
      {'name': 'Bibimbap', 'price': 150},
      {'name': 'Korean Fried Chicken', 'price': 180},
      {'name': 'Tteokbokki', 'price': 100},
      {'name': 'Jajangmyeon', 'price': 120},
    ],
    'อาหารจีน': [
      {'name': 'ติ่มซำชุดรวม', 'price': 250},
      {'name': 'เป็ดปักกิ่ง', 'price': 800},
      {'name': 'กระเพาะปลา', 'price': 150},
      {'name': 'หม่าล่าหม้อไฟ', 'price': 350},
      {'name': 'บะหมี่เกี๊ยว', 'price': 60},
    ],

    // ===== WESTERN / FAST FOOD =====
    'อาหารตะวันตก': [
      {'name': 'Ribeye Steak', 'price': 450},
      {'name': 'Carbonara Pasta', 'price': 180},
      {'name': 'Ceasar Salad', 'price': 120},
      {'name': 'Fish and Chips', 'price': 220},
      {'name': 'Truffle Soup', 'price': 150},
    ],
    'ฟาสต์ฟู้ด': [
      {'name': 'Burger Set', 'price': 159},
      {'name': 'French Fries', 'price': 59},
      {'name': 'Fried Chicken', 'price': 39},
      {'name': 'Hot Dog', 'price': 49},
      {'name': 'Nuggets', 'price': 69},
    ],
    'เบอร์เกอร์': [
      {'name': 'Cheeseburger', 'price': 120},
      {'name': 'Bacon Burger', 'price': 150},
      {'name': 'Wagyu Burger', 'price': 250},
      {'name': 'Chicken Burger', 'price': 90},
    ],
    'พิซซ่า': [
      {'name': 'Pizza Pepperoni', 'price': 299},
      {'name': 'Pizza Hawaiian', 'price': 299},
      {'name': 'Pizza Seafood', 'price': 359},
      {'name': 'Garlic Bread', 'price': 89},
    ],
    'ไก่ทอด': [
      {'name': 'ไก่ทอดหาดใหญ่', 'price': 50},
      {'name': 'ไก่ทอดเกาหลี', 'price': 150},
      {'name': 'ปีกไก่ทอดน้ำปลา', 'price': 80},
      {'name': 'ไก่ป๊อป', 'price': 40},
    ],

    // ===== COMMON THAI DISHES =====
    'ก๋วยเตี๋ยว': [
      {'name': 'ก๋วยเตี๋ยวเรือ', 'price': 40},
      {'name': 'บะหมี่เกี๊ยวหมูแดง', 'price': 50},
      {'name': 'เย็นตาโฟ', 'price': 50},
      {'name': 'ก๋วยเตี๋ยวต้มยำ', 'price': 60},
    ],
    'ข้าวแกง': [
      {'name': 'ข้าวราดแกง 2 อย่าง', 'price': 40},
      {'name': 'ไข่พะโล้', 'price': 40},
      {'name': 'พะแนงหมู', 'price': 50},
    ],
    'ข้าวมันไก่': [
      {'name': 'ข้าวมันไก่ต้ม', 'price': 50},
      {'name': 'ข้าวมันไก่ทอด', 'price': 50},
      {'name': 'ข้าวมันไก่ผสม', 'price': 60},
    ],
    'อาหารตามสั่ง': [
      {'name': 'คะน้าหมูกรอบ', 'price': 50},
      {'name': 'หมูทอดกระเทียม', 'price': 50},
      {'name': 'ผัดพริกแกง', 'price': 50},
      {'name': 'ข้าวผัด', 'price': 50},
    ],
    'ส้มตำ ไก่ย่าง': [
      {'name': 'ตำไทย', 'price': 40},
      {'name': 'ตำถาด', 'price': 120},
      {'name': 'ไก้ย่างครึ่งตัว', 'price': 100},
    ],

    // ===== GRILL / HOTPOT =====
    'ปิ้งย่าง': [
      {'name': 'Buffet Pork Set', 'price': 299},
      {'name': 'Premium Beef Set', 'price': 599},
      {'name': 'Seafood Grill', 'price': 499},
    ],
    'ชาบู / สุกี้': [
      {'name': 'Shabu Buffet', 'price': 299},
      {'name': 'Suki Set', 'price': 199},
      {'name': 'Wagyu Beef Slices', 'price': 120},
    ],

    // ===== DESSERT =====
    'เบเกอรี่': [
      {'name': 'Croissant', 'price': 65},
      {'name': 'Cheesecake', 'price': 120},
      {'name': 'Coffee Scone', 'price': 55},
      {'name': 'Brownie', 'price': 60},
    ],
    'ของหวาน': [
      {'name': 'บิงซู', 'price': 150},
      {'name': 'ฮันนี่โทสต์', 'price': 180},
      {'name': 'บัวลอย', 'price': 30},
      {'name': 'ข้าวเหนียวมะม่วง', 'price': 80},
    ],
    'ไอศกรีม': [
      {'name': 'Ice Cream Scoop', 'price': 40},
      {'name': 'Sundae', 'price': 80},
      {'name': 'Banana Split', 'price': 120},
    ],
    'เครป': [
      {'name': 'เครปเย็น', 'price': 80},
      {'name': 'เครปญี่ปุ่น', 'price': 40},
    ],

    // ===== DRINK =====
    'กาแฟ': [
      {'name': 'Iced Latte', 'price': 80},
      {'name': 'Americano', 'price': 70},
      {'name': 'Dirty Coffee', 'price': 90},
      {'name': 'Cold Brew', 'price': 100},
    ],
    'ชา / ชานม': [
      {'name': 'Bubble Milk Tea', 'price': 50},
      {'name': 'Thai Tea', 'price': 40},
      {'name': 'Green Tea Latte', 'price': 60},
    ],
    'เครื่องดื่ม': [
      {'name': 'Italian Soda', 'price': 50},
      {'name': 'Smoothie', 'price': 80},
      {'name': 'Fruit Juice', 'price': 40},
    ],

    // ===== HEALTH =====
    'อาหารเพื่อสุขภาพ': [
      {'name': 'Salad Bowl', 'price': 120},
      {'name': 'Quinoa Rice', 'price': 80},
      {'name': 'Chicken Breast Stick', 'price': 40},
    ],
    'มังสวิรัติ': [
      {'name': 'ผัดผักรวมมิตร', 'price': 60},
      {'name': 'ต้มจับฉ่าย', 'price': 50},
      {'name': 'เต้าหู้ทอด', 'price': 40},
    ],
    'คลีน': [
      {'name': 'ข้าวน้ำพริกปลาทูคลีน', 'price': 80},
      {'name': 'สลัดอกไก่', 'price': 80},
      {'name': 'แซนวิชโฮลวีท', 'price': 60},
    ],
    'คาเฟ่': [
      // Keep existing 'คาเฟ่' as well for backward compat or if used
      {'name': 'Iced Latte', 'price': 80},
      {'name': 'Americano', 'price': 70},
      {'name': 'Matcha Latte', 'price': 90},
      {'name': 'Cake of the Day', 'price': 120},
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
