import 'package:flutter/material.dart';
import 'package:dishcovery_app/constants/app_bottom_nav_business.dart';

class BusinessDashboardScreen extends StatelessWidget {
  const BusinessDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: const Center(child: Text('สถิติและข้อมูลร้านค้า (เร็วๆนี้)')),
      bottomNavigationBar: const AppBottomNavBusiness(currentIndex: 0),
    );
  }
}
