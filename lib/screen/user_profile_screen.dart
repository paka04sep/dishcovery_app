import 'package:dishcovery_app/constants/app_bottom_nav_user.dart';
import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:dishcovery_app/screen/swipescreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dishcovery_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import '../starting_screen/loading_screen.dart';
import 'business_screen.dart';
import 'foodpreference_screen.dart';
import 'distance_pricerange.dart';
import 'package:dishcovery_app/screen/admin/admin_dashboard_screen.dart';
import 'package:dishcovery_app/services/restaurant_service.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

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
            MaterialPageRoute(builder: (context) => const SwipScreen()),
          ),
        ),
        actions: [
          ListenableBuilder(
            listenable: RestaurantService.instance,
            builder: (context, child) {
              final isAdmin =
                  RestaurantService.instance.userModel?.role == 'admin';

              if (!isAdmin) return const SizedBox.shrink();

              return IconButton(
                icon: const Icon(Icons.manage_accounts, color: Colors.black),
                tooltip: 'Admin Dashboard',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminDashboardScreen(),
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                      child: Icon(Icons.person, size: 40, color: Colors.white),
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
                          Icons.star,
                          size: 10,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    FirebaseAuth.instance.currentUser?.email?.split('@')[0] ??
                        "Guest User",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'Inter',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // View My Profile Button
            // SizedBox(
            //   width: double.infinity,
            //   height: 45,
            //   child: ElevatedButton(
            //     onPressed: () {},
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: const Color(0xFFEEF5FF), // Light blue tint
            //       foregroundColor: Colors.blueAccent,
            //       elevation: 0,
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(10),
            //       ),
            //     ),
            //     child: Text(
            //       "โปรไฟล์ของฉัน",
            //       style: AppTextStyles.profileText.copyWith(
            //         fontSize: 16,
            //         color: Colors.blue,
            //       ),
            //     ),
            //   ),
            // ),
            // const SizedBox(height: 15),

            // Credit & Challenges
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    context,
                    label: "สไตล์การกินของคุณ",
                    icon: Icons.insert_chart_outlined,
                    onTap: () {},
                  ),
                ),

                // Expanded(
                //   child: _buildActionCard(
                //     context,
                //     label: "Challenges",
                //     icon: Icons.emoji_events_outlined,
                //     onTap: () {},
                //   ),
                // ),
              ],
            ),
            const SizedBox(height: 15),

            // Quick Menu Icons
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //   children: [
            //     _buildCircleMenu(
            //       icon: Icons.bookmark,
            //       label: "Saved",
            //       color: Colors.blueAccent,
            //     ),
            //   ],
            // ),
            // const SizedBox(height: 30),

            // List Menu
            _buildListTile(
              icon: Icons.restaurant_outlined,
              title: "ประเภทอาหารที่ชอบ",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const FoodPreferenceScreen(isEditMode: true),
                  ),
                );
              },
            ),

            _buildListTile(
              icon: Icons.location_on_outlined,
              title: "ปรับการค้นหาร้านอาหาร",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const DistancePriceRangeScreen(isEditMode: true),
                  ),
                );
              },
            ),

            _buildListTile(
              icon: Icons.store_outlined,
              title: "Switch to Restaurant Menu",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RestaurantDetailsScreen(),
                  ),
                );
              },
            ),
            _buildListTile(
              icon: Icons.help_outline,
              title: "Help Center / Contact Us",
            ),
            _buildListTile(icon: Icons.settings_outlined, title: "Settings"),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () {
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Confirm Logout"),
                        content: const Text(
                          "Are you sure you want to log out?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context); // Close dialog
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
                            child: const Text(
                              "Log Out",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: const Text(
                  "Log Out",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.black87),
                const SizedBox(width: 8),
                Text(label, style: AppTextStyles.profileText.copyWith()),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleMenu({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
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
}
