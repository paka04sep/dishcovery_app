enum SwipeStatus { yum, pass }

class RestaurantCardData {
  final String name;
  final String imageUrl;
  final String type;
  final String priceRate;
  final String location;
  final SwipeStatus status;

  RestaurantCardData({
    required this.name,
    required this.imageUrl,
    required this.type,
    required this.priceRate,
    required this.location,
    required this.status,
  });
}

// ข้อมูลจำลอง (Mock Data) สำหรับการใช้งาน
final List<RestaurantCardData> mockRestaurants = [
  RestaurantCardData(
    name: "RESTAURANT NAME1",
    imageUrl: "assets/images/res/r1.jpg",
    type: "Italian/Pizza",
    priceRate: "\$\$\$",
    location: "Downtown, City A",
    status: SwipeStatus.yum,
  ),
  RestaurantCardData(
    name: "RESTAURANT NAME2",
    imageUrl: "assets/images/res/r2.jpg",
    type: "Fusion/Asian",
    priceRate: "\$\$",
    location: "Uptown, City B",
    status: SwipeStatus.pass,
  ),
  RestaurantCardData(
    name: "RESTAURANT NAME3",
    imageUrl: "assets/images/res/r3.jpg",
    type: "Steak/Grill",
    priceRate: "\$\$\$\$",
    location: "Midtown, City C",
    status: SwipeStatus.pass,
  ),
  RestaurantCardData(
    name: "RESTAURANT NAME4",
    imageUrl: "assets/images/res/r4.jpg",
    type: "Steak/Grill",
    priceRate: "\$\$\$\$",
    location: "Midtown, City C",
    status: SwipeStatus.pass,
  ),
  RestaurantCardData(
    name: "RESTAURANT NAME5",
    imageUrl: "assets/images/res/r5.jpg",
    type: "Steak/Grill",
    priceRate: "\$\$\$\$",
    location: "Midtown, City C",
    status: SwipeStatus.pass,
  ),
  RestaurantCardData(
    name: "RESTAURANT NAME6",
    imageUrl: "assets/images/res/r6.jpg",
    type: "Steak/Grill",
    priceRate: "\$\$\$\$",
    location: "Midtown, City C",
    status: SwipeStatus.pass,
  ),
  RestaurantCardData(
    name: "RESTAURANT NAME7",
    imageUrl: "assets/images/res/r7.jpg",
    type: "Steak/Grill",
    priceRate: "\$\$\$\$",
    location: "Midtown, City C",
    status: SwipeStatus.pass,
  ),
  RestaurantCardData(
    name: "RESTAURANT NAME8",
    imageUrl: "assets/images/res/r8.jpg",
    type: "Steak/Grill",
    priceRate: "\$\$\$\$",
    location: "Midtown, City C",
    status: SwipeStatus.yum,
  ),
  RestaurantCardData(
    name: "RESTAURANT NAME9",
    imageUrl: "assets/images/res/r9.jpg",
    type: "Steak/Grill",
    priceRate: "\$\$\$\$",
    location: "Midtown, City C",
    status: SwipeStatus.yum,
  ),
  RestaurantCardData(
    name: "RESTAURANT NAME10",
    imageUrl: "assets/images/res/r10.jpg",
    type: "Steak/Grill",
    priceRate: "\$\$\$\$",
    location: "Midtown, City C",
    status: SwipeStatus.pass,
  ),
];
