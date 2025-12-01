// lib/history_screen.dart

import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:dishcovery_app/screen/user_profile_screen.dart';
import 'package:flutter/material.dart';
import '../models/restaurant_model.dart';
import 'swipescreen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  // Widget สำหรับสร้างการ์ดในหน้า History
  Widget _buildHistoryCard(BuildContext context, RestaurantCardData data) {
    // กำหนดสีและข้อความตามสถานะการปัด
    final Color statusColor = data.status == SwipeStatus.yum
        ? Colors.green.shade700
        : Colors.red.shade700;
    final String statusText = data.status == SwipeStatus.yum ? "YUM!" : "PASS";

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
                  color: Colors.black.withOpacity(
                    0.2,
                  ), // เพิ่ม Overlay สีดำจาง ๆ
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

              // Overlay สีเขียว/แดง ตามสถานะ
              Positioned.fill(
                child: Container(
                  color: statusColor.withOpacity(0.3), // สีโปร่งใสตามสถานะ
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

              // ข้อความสถานะ "YUM!" / "PASS"
              Positioned(
                right: -15, // เลื่อนออกจากขอบเล็กน้อย
                bottom: -5,
                child: Transform.rotate(
                  angle: 0.3, // หมุนข้อความ
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor.withOpacity(0.8),
                      fontSize: 50,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 5,
                          offset: const Offset(3, 3),
                        ),
                      ],
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

  // Widget สำหรับ Bottom Navigation Bar (คัดลอกมาจาก SwipScreen)
  Widget _buildBottomNavBar(BuildContext context) {
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
            icon: const Icon(
              Icons.history,
              color: Colors.black,
              size: 32,
            ), // เน้นไอคอน History
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.fork_right, color: Colors.grey, size: 30),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SwipScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.grey, size: 30),
            onPressed: () {
              Navigator.pushReplacement(
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

  // Widget สำหรับ AppBar ในหน้า History
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,

      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.black),
        onPressed: () => Navigator.pop(context),
      ),

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
                "HISTORY",
                style: AppTextStyles.primaryTitle.copyWith(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 0),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Container(
        // พื้นหลังเป็น Gradient
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 255, 255, 255), // สีอ่อนด้านบน
              const Color.fromARGB(255, 218, 218, 218), // สีอ่อนลงมา
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          // กำหนดให้เริ่มต้นด้านบนสูงกว่าปกติเล็กน้อย
          top: true,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 20), // เพิ่ม padding ด้านบน
            itemCount: mockRestaurants.length,
            itemBuilder: (context, index) {
              return _buildHistoryCard(context, mockRestaurants[index]);
            },
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }
}
