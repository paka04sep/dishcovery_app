class RestaurantCardData {
  final String name;
  final String imageUrl;
  final String type;
  final String priceRate;
  final String location;

  RestaurantCardData({
    required this.name,
    required this.imageUrl,
    required this.type,
    required this.priceRate,
    required this.location,
  });
}

// ข้อมูลจำลอง (Mock Data) สำหรับการใช้งาน
final List<RestaurantCardData> mockRestaurants = [
  RestaurantCardData(
    name: "RESTAURANT NAME1",
    imageUrl: "assets/images/r1.jpg",
    type: "Italian/Pizza",
    priceRate: "\$\$\$",
    location: "Downtown, City A",
  ),
  RestaurantCardData(
    name: "The Fusion Spot",
    imageUrl:
        "https://images.unsplash.com/photo-1555513560-5a3d4d42b6a2?q=80&w=1740&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D", // ภาพร้านอาหารแนวเอเชียน
    type: "Fusion/Asian",
    priceRate: "\$\$",
    location: "Uptown, City B",
  ),
  RestaurantCardData(
    name: "Steak House Elite",
    imageUrl:
        "https://images.unsplash.com/photo-1585577678996-51e44f8f4115?q=80&w=1740&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D", // ภาพร้านสเต็ก
    type: "Steak/Grill",
    priceRate: "\$\$\$\$",
    location: "Midtown, City C",
  ),
];
