// lib/business_screens.dart

import 'package:flutter/material.dart';

// ================= 1. หน้า DASHBOARD =================
class BusinessDashboardScreen extends StatelessWidget {
  const BusinessDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "DASHBOARD",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("MY RESTAURANT", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildStatCard("Total View", "102 eyes", Colors.white),
                  _buildStatCard("Total YUM!", "66 fork", Colors.green[50]!),
                  _buildStatCard("Total FAV!", "12 star", Colors.yellow[50]!),
                  _buildStatCard("Total PASS", "33 cross", Colors.red[50]!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ================= 2. หน้า MY RESTAURANT DETAILS (เหมือน UserProfileScreen 100%) =================
// แทนที่คลาส RestaurantDetailsScreen เดิมทั้งหมดด้วยโค้ดนี้

class RestaurantDetailsScreen extends StatefulWidget {
  const RestaurantDetailsScreen({super.key});

  @override
  State<RestaurantDetailsScreen> createState() =>
      _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {
  // สีเดียวกับหน้า Profile
  final Color _mainBlue = const Color(0xFF64A0FF);
  final Color _lightOrange = const Color(0xFFFFEEDD);
  final Color _iconOrange = const Color(0xFFFFAA55);
  final Color _lightRed = const Color(0xFFFFE5E5);
  final Color _iconRed = const Color(0xFFFF5555);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mainBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              // ใช้ฟังก์ชันเดิมจาก UserProfileScreen ได้เลย (คัดลอกมา)
              _showAccountTypeSelector(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // === ส่วนหัว: โลโก้ร้าน + ชื่อร้าน ===
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    // ปุ่มแก้ไขเล็ก ๆ
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.black,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Text(
                  "MY RESTAURANT", // หรือดึงชื่อร้านจริง
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const Text(
                  "Fine Dining • Italian",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // === การ์ดสีขาวด้านล่าง (เหมือนหน้า Profile เป๊ะ) ===
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 25),

                  // 1. Stats Row สำหรับ Business
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem("Views", "1.2k", Colors.blue),
                        _buildVerticalDivider(),
                        _buildStatItem("Orders", "85", Colors.green),
                        _buildVerticalDivider(),
                        _buildStatItem("Rating", "4.8", Colors.amber),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 10),

                  // 2. เมนูต่าง ๆ
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      children: [
                        _buildMenuItem(
                          Icons.menu_book,
                          "Menu Management",
                          "Add, edit or remove dishes",
                          _lightOrange,
                          _iconOrange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddMenuScreen(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          Icons.analytics,
                          "Analytics",
                          "Check performance",
                          Colors.blue[50]!,
                          Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BusinessDashboardScreen(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          Icons.photo_library,
                          "Gallery",
                          "Restaurant photos",
                          _lightOrange,
                          _iconOrange,
                        ),
                        _buildMenuItem(
                          Icons.location_on,
                          "Address & Hours",
                          "Update opening hours",
                          _lightOrange,
                          _iconOrange,
                        ),
                        _buildMenuItem(
                          Icons.campaign,
                          "Promotions",
                          "Create ads & offers",
                          Colors.green[50]!,
                          Colors.green,
                        ),
                      ],
                    ),
                  ),

                  // Logout
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: _buildMenuItem(
                      Icons.logout,
                      "Log Out",
                      "",
                      _lightRed,
                      _iconRed,
                      isDestructive: true,
                    ),
                  ),

                  // พื้นที่สีเทาด้านล่างสุด
                  Container(height: 30, color: const Color(0xFF444444)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==== Widget ย่อย (คัดลอกมาจาก UserProfileScreen) ====
  Widget _buildStatItem(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 40, width: 1, color: Colors.grey[200]);
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle,
    Color bgColor,
    Color iconColor, {
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: isDestructive ? _iconRed : Colors.black87,
        ),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle, style: const TextStyle(color: Colors.grey))
          : null,
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  // Modal สลับโหมด (คัดลอกมาจากหน้า Profile)
  void _showAccountTypeSelector(BuildContext context) {
    String tempSelectedType = 'Business'; // Default เป็น Business

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.55,
            decoration: BoxDecoration(
              color: _mainBlue,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        "ACCOUNT TYPES",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          "CHANGE TYPES",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildRadioOption(
                          "CONSUMER",
                          tempSelectedType == 'Consumer',
                          () => setModalState(
                            () => tempSelectedType = 'Consumer',
                          ),
                        ),
                        const Divider(),
                        _buildRadioOption(
                          "BUSINESS",
                          tempSelectedType == 'Business',
                          () => setModalState(
                            () => tempSelectedType = 'Business',
                          ),
                        ),
                        const Divider(),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              // ที่นี่ควรจะเปลี่ยนโหมดจริงของแอป (เช่น Provider หรือ Global variable)
                              // เดี๋ยวนี้แค่ปิด modal
                              Navigator.pop(context);
                              if (tempSelectedType == 'Consumer') {
                                Navigator.pop(
                                  context,
                                ); // กลับไปหน้า Consumer Profile
                              }
                            },
                            child: const Text(
                              "CONFIRM",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRadioOption(String title, bool isSelected, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isSelected ? Colors.greenAccent : Colors.grey[300],
          shape: BoxShape.circle,
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

// ================= 3. หน้า ADD YOUR MENU =================
class AddMenuScreen extends StatelessWidget {
  const AddMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ADD YOUR MENU")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("MENU NAME"),
            _buildTextField(),
            const SizedBox(height: 15),
            _buildLabel("MENU PRICE"),
            _buildTextField(),
            const SizedBox(height: 15),
            _buildLabel("DESCRIPTION"),
            _buildTextField(maxLines: 4),
            const SizedBox(height: 15),
            _buildLabel("ADD PICTURE"),
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_a_photo, color: Colors.grey),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: const Text("ADD"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
    ),
  );
  Widget _buildTextField({int maxLines = 1}) => TextField(
    maxLines: maxLines,
    decoration: InputDecoration(
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
