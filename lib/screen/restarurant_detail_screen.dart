import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dishcovery_app/models/restaurant_details_model.dart';
import 'package:dishcovery_app/screen/restaurant_map_screen.dart';
import 'package:dishcovery_app/utils/image_viewer.dart';
import 'package:dishcovery_app/utils/time_utils.dart';
import 'package:dishcovery_app/utils/waveclipper.dart';
import 'package:dishcovery_app/utils/review_helpers.dart';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/restaurant_model.dart';
import '../services/restaurant_service.dart';
import 'package:dishcovery_app/screen/restaurant_reviews_screen.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final RestaurantCardData restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 200 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 200 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });

    // Fetch details when screen loads
    // Checks if details are already in memory, if not fetches from Firestore/Mock
    RestaurantService.instance.getRestaurantDetails(widget.restaurant.id);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: RestaurantService.instance,
        builder: (context, child) {
          final currentRestaurant = RestaurantService.instance.restaurants
              .firstWhere(
                (r) => r.id == widget.restaurant.id,
                orElse: () => widget.restaurant,
              );

          // Check if we have details
          final details = currentRestaurant is RestaurantDetailsData
              ? currentRestaurant
              : null;

          return Stack(
            children: [
              // 1. ส่วนของเนื้อหาที่เลื่อนได้ทั้งหมด
              SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ระยะห่างจากด้านบน (SafeArea)
                    const SizedBox(height: 60),

                    // 2. ส่วนหัว: รูปภาพหลักของร้านพร้อม Overlay ชื่อร้าน
                    _buildHeaderSection(context, currentRestaurant, details),

                    const SizedBox(height: 30),

                    // 3. ส่วนแกลเลอรี (Gallery Images)
                    if (details != null &&
                        details.galleryImages.isNotEmpty) ...[
                      _buildAtmosphereGallery(details.galleryImages),
                      const SizedBox(height: 30),
                    ] else if (details == null) ...[
                      // Loading state for gallery or hidden
                      const Center(child: CircularProgressIndicator()),
                      const SizedBox(height: 30),
                    ],

                    if (details != null) _buildReviewSection(details),

                    _buildHighlightedMenu(details?.menuItems ?? []),
                    // 4. ส่วนรายการเมนูและราคา (Dynamic Menu Section)
                    if (details != null && details.menuCategories.isNotEmpty)
                      _buildCategorizedMenuList(details)
                    else if (details != null && details.menuItems.isNotEmpty)
                      // Fallback if no categories but items exist (legacy or simple)
                      _buildMenuCategory('Menu', details.menuItems)
                    else
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('No menu available'),
                        ),
                      ),

                    // เว้นที่ว่างด้านล่างเพื่อให้เนื้อหาไม่โดน Bottom Bar บัง
                    const SizedBox(height: 120),
                  ],
                ),
              ),

              // 6. Header/Floating Buttons dynamically
              _buildDynamicHeader(context, currentRestaurant),
            ],
          );
        },
      ),
    );
  }

  // --- Widget ส่วนประกอบย่อย (Sub-Widgets) ---

  // ส่วนหัว: รูปภาพใหญ่และ Gradient
  Widget _buildHeaderSection(
    BuildContext context,
    RestaurantCardData data,
    RestaurantDetailsData? details,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // รูปภาพหลัก กดแล้วดูเต็มจอ
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    ImageViewer.showSingle(context, data.imageUrl);
                  },
                  child: data.imageUrl.startsWith('http')
                      ? Image.network(
                          data.imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                        )
                      : Image.asset(
                          data.imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                        ),
                ),
              ),
              // Gradient Overlay เพื่อให้อ่านชื่อร้านง่ายขึ้น
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.9),
                      ],
                      stops: const [0.4, 0.9],
                    ),
                  ),
                ),
              ),

              // ชื่อร้านและรายละเอียด
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: IgnorePointer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.name.toUpperCase(),
                        style: AppTextStyles.restaurantName.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        details != null
                            ? '${data.cuisine.join(' | ')}  •  ${details.phone}'
                            : '${data.cuisine.join(' |')} ...', // Loading address
                        style: AppTextStyles.restaurantInDetails.copyWith(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFavoriteConfirmation(
    BuildContext context,
    String restaurantId,
    bool isFav,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

        title: Row(
          children: [
            Icon(
              isFav ? Icons.star_border_rounded : Icons.star,
              color: isFav ? Colors.amber : Colors.amber,
              size: 32,
            ),
            const SizedBox(width: 8),
            Text(
              isFav ? 'ลบออกจากรายการโปรด?' : 'เพิ่มในรายการโปรด?',
              style: AppTextStyles.refreshText.copyWith(
                fontSize: 22,
                color: Colors.black,
              ),
            ),
          ],
        ),

        content: Text(
          isFav
              ? 'ร้านนี้จะถูกลบออกจากรายการโปรด'
              : 'ร้านนี้จะถูกบันทึกลงในรายการโปรด',
          style: AppTextStyles.refreshText.copyWith(
            color: Colors.black.withOpacity(0.7),
            fontSize: 16,
          ),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'ยกเลิก',
              style: AppTextStyles.refreshText.copyWith(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final newStatus = isFav ? SwipeStatus.yum : SwipeStatus.fav;
              RestaurantService.instance.swipeRestaurant(
                restaurantId,
                newStatus,
              );
              Navigator.of(ctx).pop();
            },
            child: Text(
              'ยืนยัน',
              style: AppTextStyles.refreshText.copyWith(
                color: isFav ? Colors.red : Colors.amber.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Highlighed Menu (Recommended)
  Widget _buildHighlightedMenu(List<MenuItem> items) {
    // Filter recommended items
    final recommendedItems = items.where((i) => i.isRecommended).toList();

    if (recommendedItems.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'เมนูแนะนำ',
            style: AppTextStyles.restaurantHeaderDetails.copyWith(),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recommendedItems.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              final item = recommendedItems[index];

              return GestureDetector(
                onTap: () {
                  if (item.menuImage.isNotEmpty) {
                    ImageViewer.showSingle(context, item.menuImage);
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      item.menuImage.isNotEmpty
                          ? Image.network(
                              item.menuImage,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: Colors.grey[300]),
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.fastfood, color: Colors.grey),
                              ),
                            ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withOpacity(0.4),
                              Colors.black.withOpacity(0.6),
                            ],
                            stops: const [0.0, 0.65, 0.80, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        bottom: 8,
                        right: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: AppTextStyles.restaurantMenuItemName
                                  .copyWith(
                                    fontSize: 16,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        offset: Offset(0, 0),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                            ),

                            Text(
                              '${item.price} บาท',
                              style: AppTextStyles.restaurantMenuItemName
                                  .copyWith(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        offset: Offset(0, 0),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Categorized Menu List
  Widget _buildCategorizedMenuList(RestaurantDetailsData details) {
    return Column(
      children: details.menuCategories.map((category) {
        // Filter items for this category
        final categoryItems = details.menuItems.where((item) {
          // Check by ID or Name (legacy support)
          return item.category == category.id || item.category == category.name;
        }).toList();

        if (categoryItems.isEmpty) return const SizedBox.shrink();

        return _buildMenuCategory(category.name, categoryItems);
      }).toList(),
    );
  }

  // Single Category Section
  Widget _buildMenuCategory(String title, List<MenuItem> items) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: Colors.black, width: 4)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                title,
                style: AppTextStyles.restaurantHeaderDetails.copyWith(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _buildMenuItemRow(item)),
        ],
      ),
    );
  }

  // Menu Item Row
  Widget _buildMenuItemRow(MenuItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          GestureDetector(
            onTap: () {
              if (item.menuImage.isNotEmpty) {
                ImageViewer.showSingle(context, item.menuImage);
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item.menuImage.isNotEmpty
                  ? Image.network(
                      item.menuImage,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        width: 70,
                        height: 70,
                      ),
                    )
                  : Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey[200],
                      child: const Icon(Icons.fastfood, color: Colors.grey),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: AppTextStyles.restaurantMenuItemName.copyWith(),
                      ),
                    ),
                    if (item.isRecommended)
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.price} บาท',
                  style: AppTextStyles.restaurantMenuItemName.copyWith(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ),
                if (!item.isAvailable)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Sold Out',
                      style: TextStyle(color: Colors.red[300], fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtmosphereGallery(List<String> images) {
    final hasExtra = images.length > 4;
    final displayImages = hasExtra ? images.take(5).toList() : images;
    final extraCount = images.length - 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'ภาพบรรยากาศร้าน',
            style: AppTextStyles.restaurantHeaderDetails.copyWith(),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: displayImages.length,
            itemBuilder: (context, index) {
              final isLast = hasExtra && index == 4;

              return GestureDetector(
                onTap: () {
                  if (isLast) {
                    ImageViewer.showGallery(context, images);
                  } else {
                    ImageViewer.showSingle(context, displayImages[index]);
                  }
                },
                child: Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          displayImages[index],
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (isLast)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: Colors.black.withOpacity(0.6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '+$extraCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Dynamic Header: Sticky AppBar or Floating Buttons
  Widget _buildDynamicHeader(BuildContext context, RestaurantCardData data) {
    bool isFav =
        RestaurantService.instance.getRestaurantStatus(data.id) ==
        SwipeStatus.fav;

    if (_isScrolled) {
      // Sticky AppBar
      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            right: 10,
            bottom: 15,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  data.name,
                  style: AppTextStyles.restaurantInDetails.copyWith(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              IconButton(
                icon: const Icon(
                  Icons.access_time,
                  color: Colors.black,
                  size: 22,
                ),
                onPressed: () => _showOpeningHoursBottomSheet(context, data),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),

              IconButton(
                icon: const Icon(
                  Icons.map_outlined,
                  color: Colors.black,
                  size: 22,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          RestaurantMapScreen(restaurant: data),
                    ),
                  );
                },
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              IconButton(
                icon: Icon(
                  isFav ? Icons.star : Icons.star_border,
                  color: isFav ? Colors.amber : Colors.black,
                  size: 26,
                ),
                onPressed: () =>
                    _showFavoriteConfirmation(context, data.id, isFav),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              _buildShareDropdownSticky(data),
            ],
          ),
        ),
      );
    } else {
      // Floating Buttons
      return Positioned(
        top: MediaQuery.of(context).padding.top + 10, // Avoid safe area
        left: 20,
        right: 20,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ปุ่ม Back ลอยตัว
            _buildFloatingIcon(
              icon: Icons.arrow_back_ios_new,
              onTap: () => Navigator.pop(context),
            ),
            // ปุ่มฝั่งขวา
            Row(
              children: [
                _buildFloatingIcon(
                  icon: Icons.access_time,
                  onTap: () => _showOpeningHoursBottomSheet(context, data),
                ),

                const SizedBox(width: 8),
                _buildFloatingIcon(
                  icon: Icons.map_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RestaurantMapScreen(restaurant: data),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildFloatingIcon(
                  icon: isFav ? Icons.star : Icons.star_border,
                  iconColor: isFav ? Colors.amber : Colors.black,
                  onTap: () =>
                      _showFavoriteConfirmation(context, data.id, isFav),
                ),
                const SizedBox(width: 8),
                _buildShareDropdownFloating(data),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildFloatingIcon({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.black,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }

  void _showOpeningHoursBottomSheet(
    BuildContext context,
    RestaurantCardData data,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Important for custom shape
      isScrollControlled: true,
      builder: (context) {
        final groupedHours = TimeUtils.buildGroupedOpeningHours(
          data.openingHours,
        );
        return ClipPath(
          clipper: WaveClipper(),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.only(
              top: 40,
              left: 32,
              right: 32,
              bottom: 40,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'เวลาเปิด - ปิดร้าน',
                    style: AppTextStyles.restaurantInDetails.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (groupedHours.isEmpty)
                  Center(
                    child: Text(
                      'ไม่มีข้อมูลเวลาเปิด-ปิด',
                      style: AppTextStyles.restaurantInDetails.copyWith(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  )
                else
                  ...groupedHours.map((g) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            g.label,
                            style: AppTextStyles.restaurantInDetails.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black.withAlpha(179),
                            ),
                          ),
                          Text(
                            g.time,
                            style: AppTextStyles.restaurantInDetails.copyWith(
                              fontSize: 18,
                              color: Colors.black.withAlpha(179),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareDropdownSticky(RestaurantCardData data) {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.share_outlined, color: Colors.black, size: 22),
      offset: const Offset(0, 55),
      onSelected: (value) {
        if (value == 1) {
          ReviewHelpers.showReviewModal(
            context,
            data.id,
            onReviewChanged: () => setState(() {}),
          );
        } else if (value == 2) {
          // Share logic
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.reviews_outlined, color: Colors.black87),
              SizedBox(width: 12),
              Text(
                'รีวิวร้านนี้',
                style: AppTextStyles.restaurantInDetails.copyWith(
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 2,
          child: Row(
            children: [
              Image.asset('assets/icons/share.png', width: 24, height: 24),
              SizedBox(width: 12),
              Text(
                'แชร์ร้านนี้',
                style: AppTextStyles.restaurantInDetails.copyWith(
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShareDropdownFloating(RestaurantCardData data) {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: PopupMenuButton<int>(
        offset: const Offset(0, 50),
        onSelected: (value) {
          if (value == 1) {
            ReviewHelpers.showReviewModal(
              context,
              data.id,
              onReviewChanged: () => setState(() {}),
            );
          } else if (value == 2) {
            // Share logic
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 1,
            child: Row(
              children: [
                Icon(Icons.reviews_outlined, color: Colors.black87),
                SizedBox(width: 12),
                Text(
                  'รีวิวร้านนี้',
                  style: AppTextStyles.restaurantInDetails.copyWith(
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 2,
            child: Row(
              children: [
                Image.asset('assets/icons/share.png', width: 24, height: 24),
                SizedBox(width: 12),
                Text(
                  'แชร์ร้านนี้',
                  style: AppTextStyles.restaurantInDetails.copyWith(
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
            ],
          ),
          child: const Icon(
            Icons.share_outlined,
            color: Colors.black,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewSection(RestaurantDetailsData details) {
    return FutureBuilder<List<ReviewModel>>(
      future: RestaurantService.instance.getReviews(details.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reviews = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'รีวิวร้านอาหารนี้',
                style: AppTextStyles.restaurantHeaderDetails.copyWith(),
              ),
            ),
            const SizedBox(height: 12),
            if (reviews.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () => ReviewHelpers.showReviewModal(
                    context,
                    details.id,
                    onReviewChanged: () => setState(() {}),
                  ),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 36,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'คุณเป็นคนแรกที่รีวิวร้านนี้',
                          style: AppTextStyles.restaurantInDetails.copyWith(
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: reviews.length > 3 ? 4 : reviews.length,
                  itemBuilder: (context, index) {
                    if (index == 3) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  RestaurantReviewsScreen(restaurant: details),
                            ),
                          );
                        },
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 12),
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
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'ดูทั้งหมด\n(${reviews.length})',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.restaurantInDetails.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }

                    final review = reviews[index];
                    return Container(
                      width: 240,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(16),
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
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: review.userPhotoUrl != null
                                    ? NetworkImage(review.userPhotoUrl!)
                                    : null,
                                child: review.userPhotoUrl == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 16,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  review.userName.isNotEmpty
                                      ? review.userName
                                      : 'Anonymous',
                                  style: AppTextStyles.restaurantInDetails
                                      .copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    ReviewHelpers.showReviewOptionsBottomSheet(
                                      context,
                                      review,
                                      widget.restaurant.id!,
                                      () => setState(() {}),
                                    ),
                                child: const Icon(
                                  Icons.more_vert,
                                  size: 20,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Divider(
                            color: Colors.grey.shade200,
                            height: 1,
                            thickness: 1,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: List.generate(5, (starIndex) {
                              return Icon(
                                starIndex < review.rating
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: Colors.amber,
                                size: 16,
                              );
                            }),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              review.comment,
                              style: AppTextStyles.restaurantInDetails.copyWith(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMM yyyy').format(review.createdAt),
                            style: AppTextStyles.restaurantInDetails.copyWith(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 30),
          ],
        );
      },
    );
  }
}
