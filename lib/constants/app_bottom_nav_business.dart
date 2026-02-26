import 'package:flutter/material.dart';
import '../screen/business/business_dashboard_screen.dart';
import '../screen/business/business_main_screen.dart';
import '../screen/business/business_profile_screen.dart';

class AppBottomNavBusiness extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavBusiness({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
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
            icon: _gradientIcon(Icons.dashboard, currentIndex == 0),
            onPressed: () {
              if (currentIndex != 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BusinessDashboardScreen(),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: _gradientIcon(Icons.storefront, currentIndex == 1),
            onPressed: () {
              if (currentIndex != 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const BusinessMainScreen()),
                );
              }
            },
          ),
          IconButton(
            icon: _gradientIcon(Icons.manage_accounts, currentIndex == 2),
            onPressed: () {
              if (currentIndex != 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BusinessProfileScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _gradientIcon(IconData icon, bool isActive) {
    final double size = isActive ? 40 : 30;

    if (!isActive) {
      return Icon(icon, size: size, color: Colors.grey);
    }

    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF001738), Color(0xFF004C7B), Color(0xFF000F36)],
        ).createShader(bounds);
      },
      child: Icon(icon, size: size, color: Colors.white),
    );
  }
}
