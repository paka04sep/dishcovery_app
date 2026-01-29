import 'package:dishcovery_app/constants/app_bottom_nav_user.dart';
import 'package:dishcovery_app/services/restaurant_service.dart';
import 'package:dishcovery_app/screen/history_screen.dart';
import 'package:dishcovery_app/screen/swipescreen.dart';
import 'package:dishcovery_app/screen/user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:dishcovery_app/models/restaurant_model.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  // Widget สำหรับสร้างการ์ดในหน้า Favorite
  Widget _buildFavoriteCard(BuildContext context, RestaurantCardData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: Stack(
            children: [
              // รูปภาพพื้นหลัง
              Positioned.fill(
                child: Image.asset(
                  data.imageUrl,
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.2), // Overlay สีดำจาง ๆ
                  colorBlendMode: BlendMode.darken,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade600,
                    child: const Center(
                      child: Text(
                        "No Image",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),

              // รายละเอียดร้านอาหาร
              Positioned(
                top: 20,
                left: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black, blurRadius: 3)],
                      ),
                    ),
                    const Text(
                      "DETAILS",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        shadows: [Shadow(color: Colors.black, blurRadius: 3)],
                      ),
                    ),
                  ],
                ),
              ),

              // ไอคอนดาวมุมขวาล่าง
              Positioned(
                right: 20,
                bottom: 20,
                child: Icon(
                  Icons.star,
                  color: Colors.amber.shade600,
                  size: 40,
                  shadows: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 5,
                      offset: const Offset(2, 2),
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

  // Widget สำหรับ Bottom Navigation Bar
  // Widget _buildBottomNavBar(BuildContext context) {
  //   return Container(
  //     height: 70,
  //     decoration: const BoxDecoration(
  //       color: Colors.white,
  //       border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 1.0)),
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceAround,
  //       children: [
  //         IconButton(
  //           icon: const Icon(Icons.history, color: Colors.grey, size: 30),
  //           onPressed: () {
  //             Navigator.pushReplacement(
  //               context,
  //               MaterialPageRoute(builder: (context) => const HistoryScreen()),
  //             );
  //           },
  //         ),
  //         IconButton(
  //           icon: const Icon(Icons.fork_right, color: Colors.grey, size: 30),
  //           onPressed: () {
  //             Navigator.pushReplacement(
  //               context,
  //               MaterialPageRoute(builder: (context) => const SwipScreen()),
  //             );
  //           },
  //         ),
  //         IconButton(
  //           icon: const Icon(
  //             Icons.person,
  //             color: Colors.grey,
  //             size: 30,
  //           ), // เน้นไอคอน Profile
  //           onPressed: () {
  //             Navigator.pushReplacement(
  //               context,
  //               MaterialPageRoute(
  //                 builder: (context) => const UserProfileScreen(),
  //               ),
  //             );
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget สำหรับ AppBar ในหน้า Favorite
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      // ปุ่มย้อนกลับ
      // leading: IconButton(
      //   icon: const Icon(Icons.arrow_back_ios, color: AppColors.black),
      //   onPressed: () => Navigator.pop(context),
      // ),

      // จัด Title ให้อยู่ทางขวา
      centerTitle: false,
      titleSpacing: 0,
      title: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A384F),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                "FAVORITE RESTAURANT", // 💡 แก้ไขข้อความ
                style: AppTextStyles.primaryTitle.copyWith(
                  fontSize: 24, // ปรับขนาดข้อความให้พอดี
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      // ไม่ใช้ actions
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RestaurantService.instance,
      builder: (context, child) {
        final favoriteList = RestaurantService.instance.favorites;
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: _buildAppBar(context),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.white,
                  AppColors.white, // ใช้สีฟ้าอ่อนเพื่อความแตกต่าง
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              top: true,
              child: favoriteList.isEmpty
                  ? Center(
                      child: Text(
                        "ไม่มีร้านอาหารที่ถูกใจ",
                        style: AppTextStyles.refreshText.copyWith(),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 20),
                      itemCount: favoriteList.length,
                      itemBuilder: (context, index) {
                        return _buildFavoriteCard(context, favoriteList[index]);
                      },
                    ),
            ),
          ),
          bottomNavigationBar: const AppBottomNav(currentIndex: 4),
        );
      },
    );
  }
}
