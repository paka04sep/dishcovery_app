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
  bool isShopOpen = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF9F9F9,
      ), // Light background match Profile
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header Section
            _buildHeader(),

            // 2. Sales & Quality Card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _buildSalesCard(),
            ),

            // 3. Marketing Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(child: _buildMarketingCard(isCampaign: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildMarketingCard(isCampaign: false)),
                ],
              ),
            ),
            // Switch to User Profile Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.person_outline),
                  label: const Text("Switch to User Profile"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF539DF3),
                    side: const BorderSide(color: Color(0xFF539DF3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 70,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 1.0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(
                Icons.home,
                color: Color(0xFFFF5555),
                size: 30,
              ), // Home is active
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.fastfood, color: Colors.grey, size: 30),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.grey, size: 30),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF9F9F9), // Match Profile background
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Restaurant Image/Logo
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        30,
                      ), // Circle like Profile
                      image: const DecorationImage(
                        image: AssetImage(
                          'assets/images/logo1.0.png',
                        ), // Placeholder
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 15),
                  // Name and Branch
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Riff and Co. Restaurant",
                          style: TextStyle(
                            color: Colors.black, // Black text
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            fontFamily: 'Inter', // Match Profile font
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text(
                              "Thong Lo Branch",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.verified,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "Very Good",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Notification
                  Stack(
                    children: [
                      const Icon(
                        Icons.notifications_outlined, // Outlined
                        color: Colors.black,
                        size: 28,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            "1",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Status Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
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
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: isShopOpen ? "Open" : "Closed",
                          style: TextStyle(
                            color: isShopOpen ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const TextSpan(
                          text: " (Auto-accept until 16:00)",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isShopOpen = !isShopOpen;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFEEF5FF,
                        ), // Light blue tint like Profile button
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isShopOpen ? "Set Close" : "Set Open",
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Today's Views",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "10,000",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Last Week's Order Quality",
                style: TextStyle(color: Colors.grey),
              ),
              Icon(Icons.info_outline, size: 16, color: Colors.grey),
              Spacer(),
              Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPerformanceItem(
                Icons.sentiment_satisfied_alt,
                "Excellent",
                Colors.green,
                true,
              ),
              _buildVerticalDivider(),
              _buildPerformanceItem(Icons.thumb_up, "120", Colors.grey, true),
              _buildVerticalDivider(),
              _buildPerformanceItem(Icons.bookmark, "50", Colors.grey, true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceItem(
    IconData? icon,
    String text,
    Color color,
    bool isIcon,
  ) {
    return Expanded(
      child: Column(
        children: [
          if (isIcon && icon != null) Icon(icon, color: color, size: 28),
          if (!isIcon) const SizedBox(height: 5), // Spacer to align with icon
          const SizedBox(height: 4),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 40, width: 1, color: Colors.grey[300]);
  }

  Widget _buildMarketingCard({required bool isCampaign}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCampaign
                  ? Colors.greenAccent.withOpacity(0.2)
                  : Colors.orangeAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCampaign ? Icons.local_offer : Icons.campaign,
              color: isCampaign ? Colors.green : Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCampaign)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "NEW",
                    style: TextStyle(color: Colors.white, fontSize: 8),
                  ),
                ),
              if (!isCampaign)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "Active",
                    style: TextStyle(color: Colors.green, fontSize: 8),
                  ),
                ),
              Text(
                isCampaign ? "Campaign" : "Ads",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                isCampaign ? "Boost Sales" : "Boost Visibility",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
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
