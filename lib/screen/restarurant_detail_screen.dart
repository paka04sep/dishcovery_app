import 'package:dishcovery_app/constants/app_bottom_nav_user.dart';
import 'package:dishcovery_app/screen/restaurant_map_screen.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../constants/gradient_text.dart';
import '../models/restaurant_model.dart';

class RestaurantDetailScreen extends StatelessWidget {
  final RestaurantCardData restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    // ดึงค่า Font Family จาก Theme เพื่อความสม่ำเสมอ
    final String? fontFamily = Theme.of(
      context,
    ).textTheme.bodyLarge?.fontFamily;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. ส่วนของเนื้อหาที่เลื่อนได้ทั้งหมด
          SingleChildScrollView(
            physics:
                const BouncingScrollPhysics(), // เพิ่มเอฟเฟกต์การเลื่อนให้ดูพรีเมียม
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ระยะห่างจากด้านบน (SafeArea)
                const SizedBox(height: 60),

                // 2. ส่วนหัว: รูปภาพหลักของร้านพร้อม Overlay ชื่อร้าน
                _buildHeaderSection(fontFamily),

                const SizedBox(height: 30),

                // 3. ส่วนแกลเลอรี (Gallery Images)
                // จะแสดงผลก็ต่อเมื่อใน Model มีรูปภาพแกลเลอรีเท่านั้น
                if (restaurant.galleryImages.isNotEmpty) ...[
                  _buildSectionTitle('GALLERY', fontFamily),
                  const SizedBox(height: 12),
                  _buildGalleryHorizontalList(),
                  const SizedBox(height: 30),
                ],

                // 4. ส่วนรายการเมนูและราคา (Dynamic Menu Section)
                _buildMenuHeader(fontFamily),
                const SizedBox(height: 15),
                _buildDynamicMenuList(fontFamily),

                const SizedBox(height: 40),

                // 5. ปุ่มดูสถานที่ (Location Button)
                _buildLocationButton(context, fontFamily),

                // เว้นที่ว่างด้านล่างเพื่อให้เนื้อหาไม่โดน Bottom Bar บัง
                const SizedBox(height: 120),
              ],
            ),
          ),

          // 6. ปุ่มย้อนกลับ (Back Button)
          _buildFloatingBackButton(context),
        ],
      ),
      // 7. แถบนำทางด้านล่าง (Bottom Navigation Bar)
      // bottomNavigationBar: _buildCustomBottomNavBar(),
    );
  }

  // --- Widget ส่วนประกอบย่อย (Sub-Widgets) ---

  // ส่วนหัว: รูปภาพใหญ่และ Gradient
  Widget _buildHeaderSection(String? fontFamily) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // รูปภาพหลัก
              Image.asset(
                restaurant.imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
              // Gradient Overlay เพื่อให้อ่านชื่อร้านง่ายขึ้น
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              // ชื่อร้านและรายละเอียด
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name.toUpperCase(),
                      style: AppTextStyles.restaurantName.copyWith(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${restaurant.cuisine}  •  ${restaurant.address}',
                      style: AppTextStyles.restaurantInDetails.copyWith(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // หัวข้อ Section
  Widget _buildSectionTitle(String title, String? fontFamily) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          fontFamily: fontFamily,
        ),
      ),
    );
  }

  // แกลเลอรีรูปภาพแนวนอน
  Widget _buildGalleryHorizontalList() {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: restaurant.galleryImages.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return Container(
            width: 150,
            margin: const EdgeInsets.only(right: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey[100],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                restaurant.galleryImages[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.image_not_supported)),
              ),
            ),
          );
        },
      ),
    );
  }

  // หัวข้อเมนูและราคา
  Widget _buildMenuHeader(String? fontFamily) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'MENU',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: fontFamily,
            ),
          ),
          Text(
            'PRICE',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  // ส่วนสำคัญ: วนลูปสร้างรายการเมนูตามข้อมูลที่มีจริง (Dynamic)
  Widget _buildDynamicMenuList(String? fontFamily) {
    if (restaurant.menuItems.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text("No items available."),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        children: restaurant.menuItems.map((item) {
          return _buildMenuItemRow(item.name, item.price, fontFamily);
        }).toList(),
      ),
    );
  }

  // แถวของแต่ละเมนู
  Widget _buildMenuItemRow(String name, String price, String? fontFamily) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // จุดหน้าเมนู
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // ชื่ออาหาร
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: AppTextStyles.restaurantMenuItemName.copyWith(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // เส้นประตรงกลาง (Simulated Dashed Line)
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '------------------------------------------------------------',
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: TextStyle(color: Colors.grey, letterSpacing: 2),
              ),
            ),
          ),
          // ราคา
          Text(
            price,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  // ปุ่ม Location
  Widget _buildLocationButton(BuildContext context, String? fontFamily) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            // โค้ดสำหรับเปิด Map
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    RestaurantMapScreen(restaurant: restaurant),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
              side: const BorderSide(color: Colors.black12),
            ),
          ),
          child: Text(
            'LOCATION',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.5,
              fontFamily: fontFamily,
            ),
          ),
        ),
      ),
    );
  }

  // ปุ่ม Back ลอยตัว
  Widget _buildFloatingBackButton(BuildContext context) {
    return Positioned(
      top: 50,
      left: 20,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
