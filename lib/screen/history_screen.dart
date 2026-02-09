import 'package:dishcovery_app/constants/app_bottom_nav_user.dart';
import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:dishcovery_app/services/restaurant_service.dart';
import 'package:dishcovery_app/screen/user_profile_screen.dart';
import 'package:dishcovery_app/utils/time_utils.dart';
import 'package:dishcovery_app/widgets/pulse_status_widget.dart';
import 'package:flutter/material.dart';
import '../models/restaurant_model.dart';
import 'restarurant_detail_screen.dart';
import 'swipescreen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  // Widget สำหรับสร้างการ์ดในหน้า History
  Widget _buildHistoryCard(BuildContext context, RestaurantCardData data) {
    // กำหนดสีและข้อความตามสถานะการปัด
    Color statusColor;
    String statusText;
    final openStatus = TimeUtils.getRestaurantStatus(data.openingHours);
    final currentStatus = RestaurantService.instance.getRestaurantStatus(
      data.id,
    );
    final bool isClosed = openStatus == RestaurantStatus.closed;

    switch (currentStatus) {
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
      child: GestureDetector(
        onTap: () => _onRestaurantTap(context, data),
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
                  child: ColorFiltered(
                    colorFilter: openStatus == RestaurantStatus.closed
                        ? const ColorFilter.mode(
                            Colors.grey,
                            BlendMode.saturation,
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
                              openStatus == RestaurantStatus.closed ? 0.6 : 0.4,
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
                              openStatus == RestaurantStatus.closed ? 0.6 : 0.4,
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
                // Overlay สีเขียว/แดง ตามสถานะ
                // Positioned.fill(
                //   child: Container(
                //     color: statusColor.withOpacity(0.2), // สีโปร่งใสตามสถานะ
                //   ),
                // ),

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
                          color: Colors.white.withOpacity(isClosed ? 0.4 : 1),
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              offset: const Offset(3, 2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${data.cuisine.join(' | ')} · ',
                            style: AppTextStyles.restaurantDetails.copyWith(
                              fontSize: 16,
                              color: Colors.white.withOpacity(
                                isClosed ? 0.6 : 1,
                              ),
                            ),
                          ),
                          Text(
                            '${data.getPriceSymbol()} ',
                            style: AppTextStyles.restaurantDetails.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(
                                isClosed ? 0.6 : 1,
                              ),
                            ),
                          ),
                          Text(
                            ' · ${RestaurantService.instance.getDistance(data)} กม.',
                            style: AppTextStyles.restaurantDetails.copyWith(
                              fontSize: 16,
                              color: Colors.white.withOpacity(
                                isClosed ? 0.6 : 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.description,
                        style: AppTextStyles.restaurantDetails.copyWith(
                          fontSize: 14,
                          color: Colors.white.withOpacity(isClosed ? 0.6 : 1),
                        ),
                      ),
                    ],
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
      ),
    );
  }

  void _onRestaurantTap(BuildContext context, RestaurantCardData data) {
    final status = RestaurantService.instance.getRestaurantStatus(data.id);
    if (status == SwipeStatus.pass) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

          title: Row(
            children: [
              const Icon(Icons.refresh_rounded, color: Colors.red, size: 36),
              const SizedBox(width: 8),
              Text(
                'ดูร้านนี้อีกครั้งไหม?',
                style: AppTextStyles.refreshText.copyWith(
                  color: Colors.black,
                  fontSize: 24,
                ),
              ),
            ],
          ),

          content: RichText(
            text: TextSpan(
              style: AppTextStyles.refreshText.copyWith(
                color: Colors.black.withOpacity(0.7),

                fontSize: 18,
              ),
              children: [
                const TextSpan(text: 'คุณเคยปัด '),
                TextSpan(
                  text: '“PASS”',
                  style: AppTextStyles.refreshText.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(
                  text:
                      ' ร้านนี้มาก่อน\n\n'
                      'หากต้องการดูรายละเอียด ระบบจะเปลี่ยนสถานะเป็น ',
                ),
                TextSpan(
                  text: '"Yum"',
                  style: AppTextStyles.refreshText.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(
                  text: ' เพื่อช่วยให้เราแนะนำร้านได้ตรงใจคุณมากขึ้น',
                ),
              ],
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
                _navigateToDetail(context, data);
              },
              child: Text(
                'ยืนยัน',
                style: AppTextStyles.refreshText.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      _navigateToDetail(context, data);
    }
  }

  void _navigateToDetail(BuildContext context, RestaurantCardData data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RestaurantDetailScreen(restaurant: data),
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
        final historyList = RestaurantService.instance.history;

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
                        "ไม่มีประวัติการปัด",
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
