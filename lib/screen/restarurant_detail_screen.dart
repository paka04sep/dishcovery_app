import 'package:dishcovery_app/screen/restaurant_map_screen.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/restaurant_model.dart';
import '../services/restaurant_service.dart';

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
          AnimatedBuilder(
            animation: RestaurantService.instance,
            builder: (context, child) {
              final currentRestaurant = RestaurantService.instance.restaurants
                  .firstWhere(
                    (r) => r.id == restaurant.id,
                    orElse: () => restaurant,
                  );

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ระยะห่างจากด้านบน (SafeArea)
                    const SizedBox(height: 60),

                    // 2. ส่วนหัว: รูปภาพหลักของร้านพร้อม Overlay ชื่อร้าน
                    _buildHeaderSection(context, fontFamily, currentRestaurant),

                    const SizedBox(height: 30),

                    // 3. ส่วนแกลเลอรี (Gallery Images)
                    // จะแสดงผลก็ต่อเมื่อใน Model มีรูปภาพแกลเลอรีเท่านั้น
                    if (currentRestaurant.galleryImages.isNotEmpty) ...[
                      _buildSectionTitle('GALLERY', fontFamily),
                      const SizedBox(height: 12),
                      _buildGalleryHorizontalList(currentRestaurant),
                      const SizedBox(height: 30),
                    ],

                    // 4. ส่วนรายการเมนูและราคา (Dynamic Menu Section)
                    _buildMenuHeader(fontFamily),
                    const SizedBox(height: 15),
                    _buildDynamicMenuList(fontFamily, currentRestaurant),

                    const SizedBox(height: 40),

                    // 5. ปุ่มดูสถานที่ (Location Button)
                    _buildLocationButton(
                      context,
                      fontFamily,
                      currentRestaurant,
                    ),

                    // เว้นที่ว่างด้านล่างเพื่อให้เนื้อหาไม่โดน Bottom Bar บัง
                    const SizedBox(height: 120),
                  ],
                ),
              );
            },
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
  Widget _buildHeaderSection(
    BuildContext context,
    String? fontFamily,
    RestaurantCardData data,
  ) {
    bool isFav = data.status == SwipeStatus.fav;

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
                data.imageUrl,
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
                    colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                    stops: const [0.4, 0.9],
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
                      data.name.toUpperCase(),
                      style: AppTextStyles.restaurantName.copyWith(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.cuisine}  •  ${data.address}',
                      style: AppTextStyles.restaurantInDetails.copyWith(),
                    ),
                  ],
                ),
              ),

              // Favorite Icon
              Positioned(
                top: 15,
                right: 15,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _showFavoriteConfirmation(context, data.id, isFav);
                    },
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white54, width: 1),
                      ),
                      child: Icon(
                        isFav ? Icons.star : Icons.star_border,
                        color: isFav ? Colors.amber : Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFavoriteConfirmation(
    BuildContext context,
    String restaurantId,
    bool isFav,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

        title: Row(
          children: [
            Icon(
              isFav ? Icons.star_border_rounded : Icons.star,
              color: isFav ? Colors.amber : Colors.amber,
              size: 32,
            ),
            const SizedBox(width: 8),
            Text(
              isFav ? 'ลบออกจากรายการโปรด?' : 'เพิ่มในรายการโปรด?',
              style: AppTextStyles.restaurantName.copyWith(
                fontSize: 22,
                color: Colors.black,
              ),
            ),
          ],
        ),

        content: Text(
          isFav
              ? 'ร้านนี้จะถูกลบออกจากรายการโปรด'
              : 'ร้านนี้จะถูกบันทึกลงในรายการโปรด',
          style: AppTextStyles.refreshText.copyWith(
            color: Colors.black.withOpacity(0.7),
            fontSize: 16,
          ),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'ยกเลิก',
              style: AppTextStyles.refreshText.copyWith(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final newStatus = isFav ? SwipeStatus.yum : SwipeStatus.fav;
              RestaurantService.instance.swipeRestaurant(
                restaurantId,
                newStatus,
              );
              Navigator.of(ctx).pop();
            },
            child: Text(
              'ยืนยัน',
              style: AppTextStyles.refreshText.copyWith(
                color: isFav ? Colors.red : Colors.green,
              ),
            ),
          ),
        ],
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
  Widget _buildGalleryHorizontalList(RestaurantCardData data) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: data.galleryImages.length,
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
                data.galleryImages[index],
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
  Widget _buildDynamicMenuList(String? fontFamily, RestaurantCardData data) {
    if (data.menuItems.isEmpty) {
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
        children: data.menuItems.map((item) {
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
  Widget _buildLocationButton(
    BuildContext context,
    String? fontFamily,
    RestaurantCardData data,
  ) {
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
                builder: (context) => RestaurantMapScreen(restaurant: data),
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
              color: Colors.white.withOpacity(0.8),
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
