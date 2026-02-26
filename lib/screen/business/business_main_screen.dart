import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:dishcovery_app/constants/gradient_text.dart';
import 'package:flutter/material.dart';
import 'package:dishcovery_app/constants/app_bottom_nav_business.dart';
import 'package:dishcovery_app/services/restaurant_service.dart';
import 'package:dishcovery_app/screen/restarurant_detail_screen.dart';

class BusinessMainScreen extends StatefulWidget {
  final bool showAddSuccessDialog;

  const BusinessMainScreen({super.key, this.showAddSuccessDialog = false});

  @override
  State<BusinessMainScreen> createState() => _BusinessMainScreenState();
}

class _BusinessMainScreenState extends State<BusinessMainScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.showAddSuccessDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'เพิ่มร้านอาหารสำเร็จ',
              style: AppTextStyles.profileText.copyWith(fontSize: 20),
            ),
            content: Text(
              'กำลังส่งร้านให้ระบบตรวจสอบ\nเพื่อเปิดการมองเห็น',
              style: AppTextStyles.profileText.copyWith(
                color: Colors.grey[800],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'ตกลง',
                  style: AppTextStyles.profileText.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo1.0circle.png',
              width: 32,
              height: 32,
            ),
            const SizedBox(width: 8),
            GradientText(
              text: 'DISHCOVERY!',
              style: AppTextStyles.secondaryTitle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: RestaurantService.instance,
        builder: (context, child) {
          final user = RestaurantService.instance.userModel;
          if (user == null)
            return const Center(child: CircularProgressIndicator());

          final ownedIds = user.ownedRestaurantIds;
          if (ownedIds.isEmpty) {
            return const Center(child: Text('ไม่พบร้านอาหารของคุณ'));
          }

          final ownedRestaurants = RestaurantService.instance.restaurants
              .where((r) => ownedIds.contains(r.id))
              .toList();

          if (ownedRestaurants.isEmpty) {
            return Center(
              child: Text(
                'กำลังโหลดข้อมูล... หรือร้านของคุณยังไม่มีในระบบ',
                style: AppTextStyles.hintText.copyWith(fontSize: 14),
              ),
            );
          }

          final myRestaurant = ownedRestaurants.first;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 10),
                child: GradientText(
                  text: "My Restaurant",
                  style: AppTextStyles.secondaryTitle.copyWith(fontSize: 28),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RestaurantDetailScreen(restaurant: myRestaurant),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: 20,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          spreadRadius: 5,
                        ),
                      ],
                      image: DecorationImage(
                        image: NetworkImage(
                          myRestaurant.imageUrl.isNotEmpty
                              ? myRestaurant.imageUrl
                              : 'https://via.placeholder.com/400x300?text=No+Image',
                        ),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) =>
                            const Icon(Icons.error),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [Colors.black54, Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.bottomLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            myRestaurant.name,
                            style: AppTextStyles.restaurantDetails.copyWith(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            myRestaurant.status == 'approved'
                                ? 'สถานะ: Online'
                                : 'สถานะ: ปิดการมองเห็น (รอระบบอนุมัติ)',
                            style: AppTextStyles.restaurantDetails.copyWith(
                              color: myRestaurant.status == 'approved'
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const AppBottomNavBusiness(currentIndex: 1),
    );
  }
}
