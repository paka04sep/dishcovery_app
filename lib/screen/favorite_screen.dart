import 'dart:ui';

import 'package:dishcovery_app/constants/app_bottom_nav_user.dart';
import 'package:dishcovery_app/services/restaurant_service.dart';
import 'package:dishcovery_app/screen/history_screen.dart';
import 'package:dishcovery_app/screen/swipescreen.dart';
import 'package:dishcovery_app/screen/user_profile_screen.dart';
import 'package:dishcovery_app/utils/time_utils.dart';
import 'package:dishcovery_app/widgets/pulse_status_widget.dart';
import 'package:flutter/material.dart';
import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:dishcovery_app/models/restaurant_model.dart';
import 'package:dishcovery_app/screen/restarurant_detail_screen.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  // Widget สำหรับสร้างการ์ดในหน้า Favorite
  Widget _buildFavoriteCard(BuildContext context, RestaurantCardData data) {
    final openStatus = TimeUtils.getRestaurantStatus(data.openingHours);
    final bool isClosed = openStatus == RestaurantStatus.closed;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RestaurantDetailScreen(restaurant: data),
            ),
          );
        },
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

          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // รูปภาพพื้นหลัง
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: ColorFiltered(
                    colorFilter: isClosed
                        ? const ColorFilter.mode(
                            Colors.grey,
                            BlendMode.saturation, // ตัดสีออก
                          )
                        : const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.dst,
                          ),
                    child: data.imageUrl.startsWith('http')
                        ? Image.network(
                            data.imageUrl,
                            fit: BoxFit.cover,
                            color: Colors.black.withOpacity(
                              isClosed ? 0.55 : 0.28,
                            ),
                            colorBlendMode: BlendMode.darken,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.grey.shade600,
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                          )
                        : Image.asset(
                            data.imageUrl,
                            fit: BoxFit.cover,
                            color: Colors.black.withOpacity(
                              isClosed ? 0.55 : 0.28,
                            ),
                            colorBlendMode: BlendMode.darken,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
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
                ),
              ),
              Positioned(
                top: 15,
                right: 15,
                child: PulseStatusWidget(
                  status: TimeUtils.getRestaurantStatus(data.openingHours),
                  size: 11,
                ),
              ),
              // รายละเอียดร้านอาหาร
              Positioned(
                top: 20,
                left: 20,
                right: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name,
                      style: AppTextStyles.restaurantName.copyWith(
                        fontSize: 28,
                        color: Colors.white.withOpacity(isClosed ? 0.5 : 1),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${data.cuisine.join(' | ')} · ',
                          style: AppTextStyles.restaurantDetails.copyWith(
                            fontSize: 16,
                            color: Colors.white.withOpacity(isClosed ? 0.5 : 1),
                          ),
                        ),
                        Text(
                          '${data.getPriceSymbol()} ',
                          style: AppTextStyles.restaurantDetails.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(isClosed ? 0.5 : 1),
                          ),
                        ),
                        Text(
                          ' · ${RestaurantService.instance.getDistance(data)} กม.',
                          style: AppTextStyles.restaurantDetails.copyWith(
                            fontSize: 16,
                            color: Colors.white.withOpacity(isClosed ? 0.5 : 1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.description,
                      style: AppTextStyles.restaurantDetails.copyWith(
                        fontSize: 14,
                        color: Colors.white.withOpacity(isClosed ? 0.5 : 1),
                      ),
                    ),
                  ],
                ),
              ),

              // ไอคอนดาวมุมขวาล่าง
              Positioned(
                right: -12,
                bottom: -12,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Material(
                      color: Colors.white.withOpacity(0.15),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () => _showRemoveFavoriteDialog(context, data),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.star_rounded,
                            color: Colors.amber.shade400,
                            size: 26,
                          ),
                        ),
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

  void _showRemoveFavoriteDialog(
    BuildContext context,
    RestaurantCardData data,
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
            const Icon(
              Icons.star_border_rounded,
              color: Colors.amber,
              size: 32,
            ),
            const SizedBox(width: 8),
            Text(
              'ลบออกจากรายการโปรด?',
              style: AppTextStyles.refreshText.copyWith(
                fontSize: 22,
                color: Colors.black,
              ),
            ),
          ],
        ),
        content: Text(
          'ร้านนี้จะถูกลบออกจากรายการโปรด',
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
              RestaurantService.instance.swipeRestaurant(
                data.id,
                SwipeStatus.yum,
              );
              Navigator.of(ctx).pop();
            },
            child: Text(
              'ยืนยัน',
              style: AppTextStyles.refreshText.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

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
                colors: [AppColors.white, AppColors.white],
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
