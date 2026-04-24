import 'package:dishcovery_app/screen/business/business_main_screen.dart';
import 'package:flutter/material.dart';
import 'package:dishcovery_app/constants/app_bottom_nav_business.dart';
import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dishcovery_app/services/restaurant_service.dart';
import 'package:dishcovery_app/constants/gradient_text.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() =>
      _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  String? _selectedRestaurantId;

  @override
  void initState() {
    super.initState();
    _initRestaurantId();
  }

  void _initRestaurantId() {
    final userModel = RestaurantService.instance.userModel;
    if (userModel != null && userModel.ownedRestaurantIds.isNotEmpty) {
      if (mounted) {
        setState(() {
          _selectedRestaurantId = userModel.ownedRestaurantIds.first;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchRestaurantData() async {
    if (_selectedRestaurantId == null) return null;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(_selectedRestaurantId)
          .get();
      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
    } catch (e) {
      debugPrint("Error fetching stats: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.black),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BusinessMainScreen()),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: GradientText(
          text: "แดชบอร์ดร้านค้า",
          style: AppTextStyles.profileText.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        centerTitle: true,
      ),
      body: _selectedRestaurantId == null
          ? _buildNoRestaurantView()
          : FutureBuilder<Map<String, dynamic>?>(
              future: _fetchRestaurantData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.midblue),
                  );
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return _buildErrorView();
                }

                final data = snapshot.data!;
                final String resName = data['name'] ?? 'ร้านของคุณ';
                final engagement = data['engagementStats'] ?? {};

                final int views = engagement['totalViews'] ?? 0;
                final int yums = engagement['totalYums'] ?? 0;
                final int passes = engagement['totalPasses'] ?? 0;
                final int favs = engagement['totalFavs'] ?? 0;
                final num trendingScore = engagement['trendingScore'] ?? 0.0;
                final num totalDwellTime = engagement['totalDwellTime'] ?? 0;

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  color: AppColors.primaryBlue,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Text(
                          "ภาพรวมร้าน: $resName",
                          style: AppTextStyles.profileText.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Big Card (Views)
                        _buildTotalViewsCard(views),
                        const SizedBox(height: 25),

                        // Grid for Yums, Passes, Favs
                        Text(
                          "สถิติการถูกปัด",
                          style: AppTextStyles.profileText.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                "ถูกปัดขวา (Yum)",
                                yums.toString(),
                                Icons.restaurant,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildStatCard(
                                "ถูกปัดซ้าย (Pass)",
                                passes.toString(),
                                Icons.close,
                                Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                "ถูกบันทึก (Fav)",
                                favs.toString(),
                                Icons.star,
                                Colors.amber,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildStatCard(
                                "คะแนนความนิยม",
                                trendingScore.toStringAsFixed(1),
                                Icons.trending_up_rounded,
                                Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),

                        Text(
                          "ข้อมูลเชิงลึกเพิ่มเติม",
                          style: AppTextStyles.profileText.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Extra Stats
                        _buildInfoCard(
                          title: 'ระยะเวลาที่คนดูร้านเฉลี่ย',
                          value: views > 0
                              ? '${(totalDwellTime / views).toStringAsFixed(1)} วินาที/คน'
                              : '0 วินาที',
                          icon: Icons.timer_rounded,
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: const AppBottomNavBusiness(currentIndex: 0),
    );
  }

  Widget _buildTotalViewsCard(int total) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.midblue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ยอดเข้าชมทั้งหมด",
                style: AppTextStyles.profileText.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                total.toString(),
                style: AppTextStyles.profileText.copyWith(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.visibility_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.profileText.copyWith(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            count,
            style: AppTextStyles.profileText.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.profileText.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: AppTextStyles.profileText.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoRestaurantView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.store_mall_directory_rounded,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'คุณยังไม่มีร้านค้า',
            style: AppTextStyles.profileText.copyWith(
              fontSize: 20,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'กรุณาเพิ่มร้านค้าเพื่อดูสถิติ',
            style: AppTextStyles.profileText.copyWith(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Text(
        'ไม่สามารถโหลดข้อมูลได้',
        style: AppTextStyles.profileText.copyWith(
          fontSize: 18,
          color: Colors.black87,
        ),
      ),
    );
  }
}
