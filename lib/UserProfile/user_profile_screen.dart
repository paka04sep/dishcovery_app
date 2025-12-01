import 'package:flutter/material.dart';
import 'business_screens.dart'; // อย่าลืมเช็คว่าไฟล์นี้วางอยู่ข้างๆ กันนะครับ

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  // ตัวแปรเก็บสถานะ (Default = Consumer)
  String _currentAccountType = 'Consumer';

  // กำหนดสีหลักตามรูปภาพ UI
  final Color _mainBlue = const Color(0xFF64A0FF); // สีฟ้าพื้นหลัง
  final Color _lightOrange = const Color(0xFFFFEEDD); // สีพื้นหลังไอคอนส้ม
  final Color _iconOrange = const Color(0xFFFFAA55); // สีไอคอนส้ม
  final Color _lightRed = const Color(0xFFFFE5E5); // สีพื้นหลังไอคอนแดง
  final Color _iconRed = const Color(0xFFFF5555); // สีไอคอนแดง

  @override
  Widget build(BuildContext context) {
    // ตรวจสอบโหมดปัจจุบัน
    final bool isBusiness = _currentAccountType == 'Business';

    return Scaffold(
      backgroundColor: _mainBlue, // พื้นหลังสีฟ้าทึบตามรูป
      appBar: AppBar(
        backgroundColor: Colors.transparent, // โปร่งใสให้เห็นพื้นหลังสีฟ้า
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // ปุ่ม Settings เพื่อกดเปลี่ยนโหมด
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              _showAccountTypeSelector(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // --- ส่วนหัว: โปรไฟล์และชื่อ ---
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    // วงกลมสีขาวขอบหนา
                    Container(
                      padding: const EdgeInsets.all(5), // ความหนาขอบขาว
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.white,
                        // ใช้ Icon แทนรูปภาพเพื่อให้เหมือนในดีไซน์ (ถ้ามีรูปจริงค่อยเปลี่ยนเป็น NetworkImage)
                        child: Icon(
                          Icons.account_circle,
                          size: 110,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    // ไอคอนแก้ไขเล็กๆ
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
                Text(
                  isBusiness
                      ? "BUSINESS NAME"
                      : "USERNAME", // เปลี่ยนชื่อตามโหมด
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // --- ส่วนการ์ดสีขาวด้านล่าง ---
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
                  // 1. ส่วนสถิติ (Stats Row) - เปลี่ยนข้อมูลตามโหมด
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: isBusiness
                          ? [
                              // สถิติสำหรับ Business
                              _buildStatItem("Views", "1.2k", Colors.blue),
                              _buildVerticalDivider(),
                              _buildStatItem("Orders", "85", Colors.green),
                              _buildVerticalDivider(),
                              _buildStatItem("Rating", "4.8", Colors.amber),
                            ]
                          : [
                              // สถิติสำหรับ Consumer (ตามรูปต้นฉบับ)
                              _buildStatItem("Liked", "12", _iconRed),
                              _buildVerticalDivider(),
                              _buildStatItem("Matched", "5", _iconOrange),
                              _buildVerticalDivider(),
                              _buildStatItem("Reviews", "3", Colors.blue),
                            ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Divider(
                    height: 1,
                    color: Color(0xFFEEEEEE),
                  ), // เส้นคั่นบางๆ
                  const SizedBox(height: 10),

                  // 2. เมนูตัวเลือก (Menu List) - เปลี่ยนตามโหมด
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      children: isBusiness
                          ? [
                              // --- เมนู Business ---
                              _buildMenuItem(
                                Icons.store,
                                "Manage Restaurant",
                                "Edit info, Menu",
                                _lightOrange,
                                _iconOrange,
                                onTap: () {
                                  // ลิ้งค์ไปหน้า Restaurant Details
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RestaurantDetailsScreen(),
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
                                  // ลิ้งค์ไปหน้า Dashboard
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const BusinessDashboardScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildMenuItem(
                                Icons.campaign,
                                "Promotions",
                                "Create ads",
                                Colors.green[50]!,
                                Colors.green,
                              ),
                            ]
                          : [
                              // --- เมนู Consumer (ตามรูปต้นฉบับ) ---
                              _buildMenuItem(
                                Icons.restaurant_menu,
                                "Food Preferences",
                                "Italian, Thai",
                                _lightOrange,
                                _iconOrange,
                              ),
                              _buildMenuItem(
                                Icons.favorite,
                                "Favorite Restaurants",
                                "12 places",
                                _lightOrange,
                                _iconOrange,
                              ),
                              _buildMenuItem(
                                Icons.history,
                                "History",
                                "Last viewed",
                                _lightOrange,
                                _iconOrange,
                              ),
                            ],
                    ),
                  ),

                  // เมนู Logout (มีทุกโหมด)
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
                  // พื้นที่สีเข้มด้านล่างสุด (เพื่อให้เหมือนในรูป)
                  Container(height: 30, color: const Color(0xFF444444)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= WIDGETS ย่อยสำหรับสร้าง UI =================

  // สร้างไอเท็มสถิติ (ตัวเลข + ข้อความ)
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

  // สร้างเส้นแบ่งแนวตั้งในส่วนสถิติ
  Widget _buildVerticalDivider() {
    return Container(height: 40, width: 1, color: Colors.grey[200]);
  }

  // สร้างรายการเมนู (ListTile) ตามดีไซน์
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
        decoration: BoxDecoration(
          color: bgColor, // สีพื้นหลังวงกลม
          shape: BoxShape.circle,
        ),
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
      onTap: onTap, // รับค่าการกดตรงนี้
    );
  }

  // ================= MODAL เลือกโหมด (Logic เดิม) =================
  void _showAccountTypeSelector(BuildContext context) {
    String tempSelectedType = _currentAccountType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.55,
              decoration: BoxDecoration(
                color: _mainBlue, // ใช้สีฟ้าเดียวกับพื้นหลัง
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
                      width: double.infinity,
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
                                setState(() {
                                  _currentAccountType = tempSelectedType;
                                });
                                Navigator.pop(context);
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
        );
      },
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
