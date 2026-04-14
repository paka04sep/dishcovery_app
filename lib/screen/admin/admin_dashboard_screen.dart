import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dishcovery_app/constants/app_constants.dart';
import 'admin_manage_restaurants_screen.dart';
import 'admin_restaurant_requests_screen.dart';
import 'admin_reports_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<Map<String, int>> _fetchDashboardData() async {
    final restaurantsCountQuery = await FirebaseFirestore.instance.collection('restaurants').count().get();
    final usersCountQuery = await FirebaseFirestore.instance.collection('users').count().get();
    
    return {
      'restaurants': restaurantsCountQuery.count ?? 0,
      'users': usersCountQuery.count ?? 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Dashboard Data
              const Text(
                "ภาพรวมระบบ",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<Map<String, int>>(
                future: _fetchDashboardData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  final data = snapshot.data ?? {'restaurants': 0, 'users': 0};

                  return Row(
                    children: [
                      Expanded(
                        child: _buildDataCard(
                          title: "ร้านอาหารทั้งหมด",
                          count: data['restaurants']!,
                          icon: Icons.restaurant,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDataCard(
                          title: "ผู้ใช้งานทั้งหมด",
                          count: data['users']!,
                          icon: Icons.people,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // Section 2: Settings / Management
              const Text(
                "การจัดการและการตั้งค่า",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildSettingItem(
                context,
                title: "จัดการร้านอาหาร",
                subtitle: "ดูและจัดการร้านอาหารทั้งหมดในระบบ",
                icon: Icons.storefront,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminManageRestaurantsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildSettingItem(
                context,
                title: "คำขอของร้านอาหาร",
                subtitle: "อนุมัติหรือปฏิเสธร้านอาหารที่รอการตรวจสอบ",
                icon: Icons.assignment_turned_in,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminRestaurantRequestsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildSettingItem(
                context,
                title: "รายงานรีพอท",
                subtitle: "ตรวจสอบการรายงานจากผู้ใช้และร้านอาหาร",
                icon: Icons.report_problem,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminReportsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
