import 'package:dishcovery_app/screen/business/business_main_screen.dart';
import 'package:flutter/material.dart';
import 'package:dishcovery_app/constants/app_bottom_nav_business.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:dishcovery_app/services/auth_service.dart';
import 'package:dishcovery_app/starting_screen/loading_screen.dart';
import 'package:dishcovery_app/screen/user_profile_setting.dart';
import '../../constants/app_init_changemode.dart';

class BusinessProfileScreen extends StatelessWidget {
  const BusinessProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // Light background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.black),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BusinessMainScreen()),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  // Header Profile
                  Row(
                    children: [
                      Stack(
                        children: [
                          const CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.grey,
                            child: Icon(
                              Icons.store,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: const Icon(
                                Icons.verified,
                                size: 10,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              FirebaseAuth.instance.currentUser?.email?.split(
                                    '@',
                                  )[0] ??
                                  "Business User",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontFamily: 'Inter',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "บัญชีธุรกิจ (Business Mode)",
                              style: AppTextStyles.profileText.copyWith(
                                color: AppColors.primaryBlue,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Action Menus
                  _buildListTile(
                    icon: Icons.person_outline,
                    title: "กลับสู่โหมดผู้ใช้ปกติ",
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AppInitChangeMode(isToBusinessMode: false),
                        ),
                      );
                    },
                  ),
                  _buildListTile(
                    icon: Icons.help_outline,
                    title: "ศูนย์ช่วยเหลือ / ติดต่อเรา",
                  ),
                  _buildListTile(
                    icon: Icons.settings_outlined,
                    title: "ตั้งค่าบัญชี",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const UserProfileSettingScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title: Text(
                    "ออกจากระบบ",
                    style: AppTextStyles.profileText.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBusiness(currentIndex: 2),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: AppTextStyles.profileText.copyWith()),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "ยืนยันการออกจากระบบ",
          style: AppTextStyles.profileText.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?",
          style: AppTextStyles.profileText.copyWith(
            fontWeight: FontWeight.w400,
            color: Colors.black.withValues(alpha: 0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("ยกเลิก", style: AppTextStyles.profileText),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService().signOut();

              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const LoadingScreen(),
                  ),
                  (route) => false,
                );
              }
            },
            child: Text(
              "ออกจากระบบ",
              style: AppTextStyles.profileText.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
