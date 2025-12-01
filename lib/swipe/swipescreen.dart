// lib/swipscreen.dart

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'restaurant_model.dart';
import '/UserProfile/user_profile_screen.dart';

class SwipScreen extends StatefulWidget {
  const SwipScreen({super.key});

  @override
  State<SwipScreen> createState() => _SwipScreenState();
}

class _SwipScreenState extends State<SwipScreen> {
  final CardSwiperController _controller = CardSwiperController();

  // แปลงข้อมูลโมเดลให้เป็น Widget การ์ด
  late final List<Widget> cards = mockRestaurants
      .map((data) => _buildCard(data))
      .toList();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ฟังก์ชัน Callback เมื่อมีการปัด
  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    String restaurantName = mockRestaurants[previousIndex].name;
    String action;
    Color color;

    if (direction == CardSwiperDirection.right ||
        direction == CardSwiperDirection.top) {
      action = 'Liked';
      color = Colors.green;
    } else if (direction == CardSwiperDirection.left) {
      action = 'Skipped';
      color = Colors.red;
    } else {
      return true; // ไม่ทำอะไร
    }

    // แสดง SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action: $restaurantName'),
        backgroundColor: color,
        duration: const Duration(milliseconds: 500),
      ),
    );

    return true; // คืนค่า true เพื่อให้การปัดทำงานตามปกติ
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // ทำให้ body อยู่ด้านหลัง AppBar
      appBar: AppBar(
        // โลโก้และชื่อแอป
        title: const Row(
          children: [
            // ไอคอนจำลอง (คุณสามารถใช้ Image.asset แทนได้)
            Icon(Icons.fastfood, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text(
              'DISHCOVERY!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        // ไอคอนดาวมุมขวาบน
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.star, color: Colors.amber, size: 30),
          ),
        ],
        backgroundColor: Colors.transparent, // ทำให้ AppBar โปร่งใส
        elevation: 0,
      ),
      body: SafeArea(
        top: false, // ปล่อยให้ Body ขยายไปด้านหลัง AppBar
        child: Column(
          children: [
            // ส่วน Card Swiper
            Expanded(
              child: CardSwiper(
                controller: _controller,
                cardsCount: cards.length,
                onSwipe: _onSwipe,
                isLoop: false,
                allowedSwipeDirection: const AllowedSwipeDirection.only(
                  left: true,
                  right: true,
                  // คุณอาจต้องการเปิดใช้งานการปัดขึ้น (up) สำหรับ Super Like
                  up: true,
                ),
                padding: const EdgeInsets.only(
                  top: 100,
                  left: 20,
                  right: 20,
                  bottom: 20,
                ), // เพิ่ม padding ด้านบนให้พ้น AppBar
                numberOfCardsDisplayed: 2,
                cardBuilder:
                    (context, index, percentThresholdX, percentThresholdY) {
                      return cards[index];
                    },
                // แสดงเมื่อการ์ดหมด
                onEnd: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No more restaurants to show!'),
                      backgroundColor: Colors.blueGrey,
                    ),
                  );
                },
              ),
            ),

            // ปุ่มควบคุมด้านล่าง
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0, top: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.undo,
                    onPressed: () => _controller.undo(),
                    color: Colors.blueGrey,
                  ),
                  _buildActionButton(
                    icon: Icons.close,
                    color: Colors.red,
                    size: 40,
                    onPressed: () =>
                        _controller.swipe(CardSwiperDirection.left),
                  ),
                  _buildActionButton(
                    icon: Icons.star,
                    color: Colors.amber,
                    size: 40,
                    onPressed: () => _controller.swipe(
                      CardSwiperDirection.top,
                    ), // Super Like
                  ),
                  _buildActionButton(
                    icon: Icons.restaurant,
                    color: Colors.green,
                    onPressed: () =>
                        _controller.swipe(CardSwiperDirection.right),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // Widget สำหรับสร้างการ์ดร้านอาหาร
  Widget _buildCard(RestaurantCardData data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: Stack(
          children: [
            // รูปภาพพื้นหลัง
            Positioned.fill(
              child: Image.asset(
                data.imageUrl,
                fit: BoxFit.cover,

                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade600,
                  child: const Center(
                    child: Text(
                      "Image Failed to Load",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),
            // รายละเอียดร้านอาหาร
            Positioned(
              left: 25,
              right: 25,
              bottom: 25,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.restaurant_menu,
                    "RESTAURANT TYPE",
                    data.type,
                  ),
                  _buildInfoRow(
                    Icons.monetization_on,
                    "PRICE RATE",
                    data.priceRate,
                  ),
                  _buildInfoRow(
                    Icons.location_on,
                    "RESTAURANT LOCATION",
                    data.location,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget สำหรับแสดงข้อมูลเป็นแถว
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(
            "$label: ",
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Widget สำหรับปุ่มควบคุม
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color color = Colors.grey,
    double size = 30,
  }) {
    return Container(
      width: size * 1.8, // ขนาดของปุ่มใหญ่กว่าไอคอน
      height: size * 1.8,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: size * 0.8),
        onPressed: onPressed,
      ),
    );
  }

  // Widget สำหรับ Bottom Navigation Bar
  Widget _buildBottomNavBar() {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.grey, size: 30),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.fork_right, color: Colors.orange, size: 40),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.grey, size: 30),
            onPressed: () {
              // สั่งให้เปลี่ยนหน้าไปที่ UserProfileScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
