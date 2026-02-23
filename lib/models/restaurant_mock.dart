import '../models/restaurant_model.dart';
import '../models/restaurant_details_model.dart';

final List<RestaurantDetailsData> mockRestaurants = [
  RestaurantDetailsData(
    id: '1',
    name: 'บ้านสวนผัดไทย',
    cuisine: ['ไทย', 'ผัดไทย'],
    priceRange: 2,
    rating: 4.5,
    latitude: 13.7205,
    longitude: 100.5702,
    imageUrl: 'assets/images/res/r1/2.jpg',
    address: '123 ถนนสุขุมวิท แขวงคลองเตย กรุงเทพฯ',
    phone: '0212345678',
    openingHours: {
      'mon': [
        {'open': '10:00', 'close': '22:00'},
      ],
      'tue': [
        {'open': '10:00', 'close': '22:00'},
      ],
      'wed': [
        {'open': '10:00', 'close': '22:00'},
      ],
      'thu': [
        {'open': '10:00', 'close': '22:00'},
      ],
      'fri': [
        {'open': '10:00', 'close': '22:00'},
      ],
      'sat': [
        {'open': '10:00', 'close': '22:00'},
      ],
      'sun': [
        {'open': '10:00', 'close': '22:00'},
      ],
    },
    description: 'ร้านอาหารไทยต้นตำรับ เมนูแนะนำ ผัดไทย',
    menuItems: [
      MenuItem(name: 'ผัดไทยกุ้งสด', price: 150),
      MenuItem(name: 'ผัดไทยไข่เค็ม', price: 80),
      MenuItem(name: 'ผัดไทยกุ้งกรอบ', price: 60),
      MenuItem(name: 'ผัดไทยวุ้นเส้น', price: 70),
      MenuItem(name: 'ผัดไทยทรงเครื่อง', price: 130),
      MenuItem(name: 'ผัดไทยไข่เค็ม', price: 90),
    ],
    galleryImages: [
      'assets/images/res/r1/1_1.jpg',
      'assets/images/res/r1/1_2.jpg',
      'assets/images/res/r1/1_3.jpg',
      'assets/images/res/r1/1_1.jpg',
    ],
  ),
  RestaurantDetailsData(
    id: '2',
    name: 'ครัวคุณยาย',
    cuisine: ['ไทย'],
    priceRange: 1,
    rating: 4.3,
    latitude: 13.7150,
    longitude: 100.5650,
    imageUrl: 'assets/images/res/r2.jpg',
    address: '456 ถนนพระราม 4 แขวงคลองเตย กรุงเทพฯ',
    phone: '0223456789',
    openingHours: {
      'mon': [
        {'open': '09:00', 'close': '21:00'},
      ],
      'tue': [
        {'open': '09:00', 'close': '21:00'},
      ],
      'wed': [
        {'open': '09:00', 'close': '21:00'},
      ],
      'thu': [
        {'open': '09:00', 'close': '21:00'},
      ],
      'fri': [
        {'open': '09:00', 'close': '21:00'},
      ],
      'sat': [
        {'open': '09:00', 'close': '21:00'},
      ],
      'sun': [
        {'open': '09:00', 'close': '21:00'},
      ],
    },
    description: 'อาหารไทยรสชาติต้นตำรับ บรรยากาศอบอุ่น',
  ),
  RestaurantDetailsData(
    id: '3',
    name: 'Sushi Masa',
    cuisine: ['ญี่ปุ่น'],
    priceRange: 3,
    rating: 4.8,
    // distance: 0,
    latitude: 13.7280,
    longitude: 100.5350,
    imageUrl: 'assets/images/res/r3.jpg',
    address: '789 ถนนสีลม แขวงสีลม กรุงเทพฯ',
    phone: '0234567890',
    openingHours: {
      'mon': [
        {'open': '11:30', 'close': '23:00'},
      ],
      'tue': [
        {'open': '11:30', 'close': '23:00'},
      ],
      'wed': [
        {'open': '11:30', 'close': '23:00'},
      ],
      'thu': [
        {'open': '11:30', 'close': '23:00'},
      ],
      'fri': [
        {'open': '11:30', 'close': '23:00'},
      ],
      'sat': [
        {'open': '11:30', 'close': '23:00'},
      ],
      'sun': [
        {'open': '11:30', 'close': '23:00'},
      ],
    },
    description: 'ร้านซูชิพรีเมียม วัตถุดิบสดใหม่จากญี่ปุ่น',
  ),
  RestaurantDetailsData(
    id: '4',
    name: 'Tokyo Ramen House',
    cuisine: ['ญี่ปุ่น', 'ราเมน'],
    priceRange: 2,
    rating: 4.4,
    // distance: 0,
    latitude: 13.7220,
    longitude: 100.5180,
    imageUrl: 'assets/images/res/r4.jpg',
    address: '321 ถนนสาทร แขวงสาทร กรุงเทพฯ',
    phone: '0245678901',
    openingHours: {
      'mon': [
        {'open': '11:00', 'close': '22:00'},
      ],
      'tue': [
        {'open': '11:00', 'close': '22:00'},
      ],
      'wed': [
        {'open': '11:00', 'close': '22:00'},
      ],
      'thu': [
        {'open': '11:00', 'close': '22:00'},
      ],
      'fri': [
        {'open': '11:00', 'close': '22:00'},
      ],
      'sat': [
        {'open': '11:00', 'close': '22:00'},
      ],
      'sun': [
        {'open': '11:00', 'close': '22:00'},
      ],
    },
    description: 'ราเมนสไตล์โตเกียว น้ำซุปเข้มข้น',
  ),
  RestaurantDetailsData(
    id: '5',
    name: 'Bella Italia',
    cuisine: ['อิตาเลียน'],
    priceRange: 3,
    rating: 4.6,
    // distance: 2.8,
    latitude: 13.7400,
    longitude: 100.5480,
    imageUrl: 'assets/images/res/r5.jpg',
    address: '654 ถนนวิทยุ แขวงลุมพินี กรุงเทพฯ',
    phone: '0256789012',
    openingHours: {
      'mon': [
        {'open': '12:00', 'close': '23:00'},
      ],
      'tue': [
        {'open': '12:00', 'close': '23:00'},
      ],
      'wed': [
        {'open': '12:00', 'close': '23:00'},
      ],
      'thu': [
        {'open': '12:00', 'close': '23:00'},
      ],
      'fri': [
        {'open': '12:00', 'close': '23:00'},
      ],
      'sat': [
        {'open': '12:00', 'close': '23:00'},
      ],
      'sun': [
        {'open': '12:00', 'close': '23:00'},
      ],
    },
    description: 'ร้านอาหารอิตาเลียนต้นตำรับ พาสต้าทำสด',
  ),
];
