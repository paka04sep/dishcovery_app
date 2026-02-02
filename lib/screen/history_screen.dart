// lib/history_screen.dart

import 'package:dishcovery_app/constants/app_bottom_nav_user.dart';
import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:dishcovery_app/services/restaurant_service.dart';
import 'package:dishcovery_app/screen/user_profile_screen.dart';
import 'package:flutter/material.dart';
import '../models/restaurant_model.dart';
import 'swipescreen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  // Widget สำหรับสร้างการ์ดในหน้า History
  Widget _buildHistoryCard(BuildContext context, RestaurantCardData data) {
    // กำหนดสีและข้อความตามสถานะการปัด
    Color statusColor;
    String statusText;

    switch (data.status) {
      case SwipeStatus.yum:
        statusColor = Colors.green.shade700;
        statusText = "YUM!";
        break;
      case SwipeStatus.fav:
        statusColor = Colors.amber.shade700;
        statusText = "FAV!";
        break;
      case SwipeStatus.pass:
      default:
        statusColor = Colors.red.shade700;
        statusText = "PASS";
        break;
    }

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
                    0.4,
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
                      style: AppTextStyles.restaurantName.copyWith(
                        fontSize: 28,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${data.cuisine} · ',
                          style: AppTextStyles.restaurantDetails.copyWith(
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${data.getPriceSymbol()} ',
                          style: AppTextStyles.restaurantDetails.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ' · ${data.distance} กม.',
                          style: AppTextStyles.restaurantDetails.copyWith(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.description,
                      style: AppTextStyles.restaurantDetails.copyWith(
                        fontSize: 16,
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

  // Widget สำหรับ AppBar ในหน้า History
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,

      // leading: IconButton(
      //   icon: const Icon(Icons.arrow_back_ios, color: AppColors.black),
      //   onPressed: () => Navigator.pop(context),
      // ),
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
    return ListenableBuilder(
      listenable: RestaurantService.instance,
      builder: (context, child) {
        final historyList = RestaurantService.instance.history.reversed
            .toList();
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
              child: historyList.isEmpty
                  ? Center(
                      child: Text(
                        "ไม่มีประวัติ",
                        style: AppTextStyles.refreshText.copyWith(),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                        top: 20,
                      ), // เพิ่ม padding ด้านบน
                      itemCount: historyList.length,
                      itemBuilder: (context, index) {
                        return _buildHistoryCard(context, historyList[index]);
                      },
                    ),
            ),
          ),
          bottomNavigationBar: const AppBottomNav(currentIndex: 0),
        );
      },
    );
  }
}
