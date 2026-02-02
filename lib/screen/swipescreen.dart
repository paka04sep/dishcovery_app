import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:dishcovery_app/constants/gradient_text.dart';

import 'package:dishcovery_app/screen/favorite_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'history_screen.dart';
import '../models/restaurant_model.dart';
import 'user_profile_screen.dart';
import 'package:dishcovery_app/services/restaurant_service.dart';
import 'restarurant_detail_screen.dart';
import '../constants/app_bottom_nav_user.dart';

class SwipScreen extends StatefulWidget {
  const SwipScreen({super.key});

  @override
  State<SwipScreen> createState() => _SwipScreenState();
}

class _SwipScreenState extends State<SwipScreen>
    with SingleTickerProviderStateMixin {
  final CardSwiperController _controller = CardSwiperController();

  // เก็บ Animation Controller สำหรับการกดปุ่ม
  late AnimationController _buttonAnimationController;

  String _buttonOverlayText = '';
  Color _buttonOverlayColor = Colors.transparent;

  // ข้อมูลการ์ดจริง (ใช้ในการอ้างอิงและนับจำนวน)
  late List<RestaurantCardData> restaurantCards;
  // เพิ่มตัวแปรเช็คว่าปัดหมดหรือยังเพื่อให้แสดงผลทันที
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    // restaurantCards = RestaurantService.instance.swipableRestaurants;
    RestaurantService.instance.addListener(_onServiceUpdate); // Add listener
    restaurantCards = RestaurantService.instance.swipableRestaurants;
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _buttonAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _buttonAnimationController.reverse();
        });
      } else if (status == AnimationStatus.dismissed) {
        setState(() {
          _buttonOverlayText = '';
          _buttonOverlayColor = Colors.transparent;
        });
      }
    });
  }

  void _loadRestaurants() {
    final swipable = RestaurantService.instance.swipableRestaurants;
    setState(() {
      restaurantCards = swipable;
      _isFinished =
          restaurantCards.isEmpty; // ถ้าโหลดมาแล้วว่างเลยให้ set finished
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _buttonAnimationController.dispose();
    RestaurantService.instance.removeListener(
      _onServiceUpdate,
    ); // Remove listener
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) {
      final freshSwipable = RestaurantService.instance.swipableRestaurants;
      final allRestaurants = RestaurantService.instance.restaurants;

      // 1. Check if we need to reload due to Filtering Changes.
      // If `restaurantCards` contains items with status=none that are NOT in `freshSwipable`,
      // it means they were filtered out by preferences/distance. We must reload.
      bool hasInvalidItems = restaurantCards.any((card) {
        if (card.status == SwipeStatus.none) {
          return !freshSwipable.any((r) => r.id == card.id);
        }
        return false;
      });

      // Also reload if we are empty but data came in (initial load case)
      if (restaurantCards.isEmpty && freshSwipable.isNotEmpty) {
        hasInvalidItems = true;
      }

      if (hasInvalidItems) {
        setState(() {
          restaurantCards = freshSwipable;
          _isFinished = restaurantCards.isEmpty;
        });
        return;
      }

      // 2. Standard Update (Status Changes)
      // Update existing cards in place without changing list order/size
      setState(() {
        restaurantCards = restaurantCards.map((card) {
          return allRestaurants.firstWhere(
            (r) => r.id == card.id,
            orElse: () => card,
          );
        }).toList();
      });
    }
  }

  // ฟังก์ชัน Callback เมื่อมีการปัด (ใช้สำหรับ logic การบันทึกเท่านั้น)
  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    debugPrint(
      'Card ${restaurantCards[previousIndex].name} swiped to: ${direction.name}',
    );
    // Logic การบันทึก/ส่งข้อมูลหลังการปัดเสร็จสิ้น
    // ...
    SwipeStatus newStatus = SwipeStatus.none;

    if (direction == CardSwiperDirection.right) {
      newStatus = SwipeStatus.yum;
      // Navigate to detail as before
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RestaurantDetailScreen(
            restaurant: restaurantCards[previousIndex], // ส่งข้อมูลร้านที่ปัดไป
          ),
        ),
      );
    } else if (direction == CardSwiperDirection.left) {
      newStatus = SwipeStatus.pass;
    } else if (direction == CardSwiperDirection.top) {
      newStatus = SwipeStatus.fav;
    }

    if (newStatus != SwipeStatus.none) {
      RestaurantService.instance.swipeRestaurant(
        restaurantCards[previousIndex].id,
        newStatus,
      );
    }

    if (currentIndex == null) {
      setState(() {
        _isFinished = true;
      });
    }

    return true;
  }

  // ฟังก์ชันสำหรับการกดปุ่ม
  void _onActionButtonPressed(CardSwiperDirection direction) {
    if (_isFinished || restaurantCards.isEmpty) return;
    String text;
    Color color;

    // 💡 แก้ไข: ใช้ right สำหรับ YUM และ up สำหรับ FAV!
    if (direction == CardSwiperDirection.right) {
      text = 'YUM!';
      color = Colors.green.withOpacity(0.8);
    } else if (direction == CardSwiperDirection.left) {
      text = 'PASS';
      color = Colors.red.withOpacity(0.8);
    } else if (direction == CardSwiperDirection.top) {
      text = 'FAV!';
      color = Colors.amber.withOpacity(0.8);
    } else {
      return;
    }

    // debugPrint('Action Button Pressed: $text');

    setState(() {
      _buttonOverlayText = text;
      _buttonOverlayColor = color;
      _buttonAnimationController.forward(from: 0.0);
    });

    _controller.swipe(direction);
  }

  @override
  Widget build(BuildContext context) {
    final double appBarHeight =
        MediaQuery.of(context).padding.top + kToolbarHeight;

    if (!RestaurantService.instance.isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false, // ซ่อนปุ่มย้อนกลับ
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo1.0circle.png',
              width: 32,
              height: 32,
            ),
            const SizedBox(width: 8),
            GradientText(
              text: 'DISHCOVERY!',
              style: AppTextStyles.secondaryTitle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.star, color: Colors.amber, size: 30),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FavoriteScreen()),
                );
              },
            ),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // 1. Card Swiper (ขยายให้ใหญ่ที่สุด)
            Padding(
              padding: EdgeInsets.only(top: appBarHeight, bottom: 10),
              child: (_isFinished || restaurantCards.isEmpty)
                  ? _buildEmptyState()
                  : CardSwiper(
                      controller: _controller,
                      cardsCount: restaurantCards.length,
                      onSwipe: _onSwipe,
                      isLoop: false,
                      allowedSwipeDirection: const AllowedSwipeDirection.only(
                        left: true,
                        right: true,
                        up: true,
                      ),
                      //
                      numberOfCardsDisplayed: restaurantCards.length >= 2
                          ? 2
                          : 1,
                      cardBuilder:
                          (
                            context,
                            index,
                            percentThresholdX,
                            percentThresholdY,
                          ) {
                            return _buildInteractiveCard(
                              data: restaurantCards[index],
                              percentX: percentThresholdX.toDouble(),
                              percentY: percentThresholdY.toDouble(),
                            );
                          },
                    ),
            ),

            // 2. ปุ่มควบคุมบนการ์ด
            if (!_isFinished && restaurantCards.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 40.0,
                    horizontal: 30,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // ปุ่ม PASS (Icons.close)
                      _buildActionButton(
                        icon: Icons.close,
                        color: Colors.red,
                        size: 40,
                        onPressed: () =>
                            _onActionButtonPressed(CardSwiperDirection.left),
                      ),
                      // ปุ่ม STAR (FAV)
                      _buildActionButton(
                        icon: Icons.star,
                        color: Colors.amber,
                        size: 35,
                        onPressed: () =>
                            _onActionButtonPressed(CardSwiperDirection.top),
                      ),
                      // ปุ่ม YUM (LIKE)
                      _buildActionButton(
                        icon: Icons.restaurant,
                        color: Colors.green,
                        size: 40,
                        onPressed: () =>
                            _onActionButtonPressed(CardSwiperDirection.right),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      // bottomNavigationBar: _buildBottomNavBar(context),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text("รีเฟรช", style: AppTextStyles.refreshText.copyWith()),
          const SizedBox(height: 10),
          Text(
            "เราหามาให้คุณจนหมดพอร์ตแล้ว\nลองรีเฟรชหรือเปลี่ยนระยะทางดูนะ",
            textAlign: TextAlign.center,
            style: AppTextStyles.refreshText.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 30),
          // ElevatedButton(
          //   onPressed: () {
          //     setState(() {
          //       _isFinished = false; // รีเซ็ตค่าเพื่อกลับไปแสดง Swiper
          //     });
          //     _loadRestaurants();
          //   },
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: AppColors.primaryBlue,
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(30),
          //     ),
          //   ),
          //   child: Text(
          //     "Refresh List",
          //     style: AppTextStyles.refreshText.copyWith(fontSize: 14),
          //   ),
          // ),
        ],
      ),
    );
  }

  // Widget สำหรับสร้างการ์ดที่รองรับ Interactive Animation
  Widget _buildInteractiveCard({
    required RestaurantCardData data,
    required double percentX,
    required double percentY,
  }) {
    // ----------------------------------------------------
    // Interactive Animation Logic
    // ----------------------------------------------------
    final double rotate = percentX.clamp(-0.5, 0.5) / 2;
    final double threshold =
        0.2; // จุดที่ Overlay เริ่มแสดง (ลดลงเพื่อให้แสดงเร็วขึ้น)

    // Logic ป้องกันการแสดงซ้อนกัน (Priority: Vertical > Horizontal)
    bool isVerticalSwipe = percentY.abs() > percentX.abs();

    // คำนวณ Opacity และ Progress ตามทิศทางที่เด่นชัดที่สุด
    double yumProgress = 0.0;
    double passProgress = 0.0;
    double favProgress = 0.0;

    if (isVerticalSwipe) {
      // ถ้าปัดขึ้นเป็นหลัก
      if (percentY < 0) {
        favProgress = (percentY.abs() / threshold).clamp(0.0, 1.0);
      }
    } else {
      // ถ้าปัดซ้าย/ขวาเป็นหลัก
      if (percentX > 0) {
        yumProgress = (percentX / threshold).clamp(0.0, 1.0);
      } else if (percentX < 0) {
        passProgress = (percentX.abs() / threshold).clamp(0.0, 1.0);
      }
    }

    // ----------------------------------------------------

    return Transform.rotate(
      angle: rotate,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: Stack(
            children: [
              // 1. รูปภาพและ Gradient
              Positioned.fill(
                child: Image.asset(
                  data.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade600,
                    child: const Center(
                      child: Text(
                        "No Image",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.3, 0.9],
                    ),
                  ),
                ),
              ),

              // 2. Interactive Overlays (YUM, PASS, FAV)
              // YUM Overlay (สีเขียว, ขวา)
              if (yumProgress > 0)
                _buildSwipeOverlay(
                  text: 'YUM!',
                  color: Colors.green,
                  progress: yumProgress,
                  alignment: Alignment.center,
                  angle: -0.2,
                ),

              // PASS Overlay (สีแดง, ซ้าย)
              if (passProgress > 0)
                _buildSwipeOverlay(
                  text: 'PASS',
                  color: Colors.red,
                  progress: passProgress,
                  alignment: Alignment.center,
                  angle: 0.2,
                ),

              // FAV Overlay (สีเหลือง, บน)
              if (favProgress > 0)
                _buildSwipeOverlay(
                  text: 'FAV!',
                  color: Colors.amber,
                  progress: favProgress,
                  alignment: Alignment.center,
                  angle: 0.0,
                ),

              // 3. รายละเอียดร้านอาหาร
              Positioned(
                left: 20,
                right: 20,
                bottom: 115,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ชื่อร้าน
                    Text(
                      data.name,
                      style: AppTextStyles.restaurantName.copyWith(),
                    ),
                    const SizedBox(height: 6),

                    // ประเภท · ราคา · ระยะทาง
                    Row(
                      children: [
                        Text(
                          '${data.cuisine} · ',
                          style: AppTextStyles.restaurantDetails.copyWith(),
                        ),
                        Text(
                          data.getPriceSymbol(), // เช่น ฿฿฿
                          style: AppTextStyles.restaurantDetails.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ' · ${data.distance} กม.',
                          style: AppTextStyles.restaurantDetails.copyWith(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // เรตติ้ง
                    // Row(
                    //   children: [
                    //     const Icon(Icons.star, color: Colors.amber, size: 18),
                    //     const SizedBox(width: 4),
                    //     Text(
                    //       data.rating.toString(),
                    //       style: AppTextStyles.restaurantDetails.copyWith(),
                    //     ),
                    //     // Text(
                    //     //   ' · เปิด-ปิด ${data.openingHours} ',
                    //     //   style: AppTextStyles.restaurantDetails.copyWith(),
                    //     // ),
                    //   ],
                    // ),
                    // const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          ' " ${data.description.toString()} " ',
                          style: AppTextStyles.restaurantDetails.copyWith(
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget ย่อยสำหรับสร้าง Overlay Text สำหรับการปัด
  Widget _buildSwipeOverlay({
    required String text,
    required Color color,
    required double progress, // รับค่า Progress (0.0 - 1.0) แทน Opacity
    required Alignment alignment,
    required double angle,
  }) {
    // คำนวณ Scale: เริ่มจาก 0.5 ไปถึง 1.5
    final double scale = 0.5 + (progress * 1.0);

    // คำนวณ Opacity: เริ่มจาก 0 ไป 1 (แต่ให้เริ่มเห็นเร็วหน่อย)
    final double opacity = (progress * 1.5).clamp(0.0, 1.0);

    // คำนวณ Glow (Shadow): ยิ่ง Progress เยอะ ยิ่งฟุ้ง
    final double blurRadius = 10 + (progress * 40);
    final double spreadRadius = 2 + (progress * 10);

    return Positioned.fill(
      child: Opacity(
        opacity: opacity,
        child: Align(
          alignment: alignment,
          child: Transform.rotate(
            angle: angle,
            child: Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  // พื้นหลังโปร่งใส แต่มีขอบและเงาเรืองแสง
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: color, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.6 * opacity),
                      blurRadius: blurRadius,
                      spreadRadius: spreadRadius,
                    ),
                  ],
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: color, // ตัวหนังสือสีเดียวกับธีม (หรือจะเอาขาวก็ได้)
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 5,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget สำหรับแสดงข้อมูลเป็นแถว
  // Widget _buildInfoRow(IconData icon, String label, String value) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 4.0),
  //     child: Row(
  //       children: [
  //         Icon(icon, color: Colors.white, size: 18),
  //         const SizedBox(width: 10),
  //         Text(
  //           "$label: ",
  //           style: const TextStyle(
  //             color: Colors.white70,
  //             fontWeight: FontWeight.w500,
  //             fontSize: 14,
  //           ),
  //         ),
  //         Flexible(
  //           child: Text(
  //             value,
  //             style: const TextStyle(
  //               color: Colors.white,
  //               fontWeight: FontWeight.bold,
  //               fontSize: 14,
  //             ),
  //             overflow: TextOverflow.ellipsis,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget สำหรับปุ่มควบคุม
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color color = Colors.grey,
    double size = 30,
  }) {
    return Container(
      width: size * 1.8,
      height: size * 1.8,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: size * 0.8),
        onPressed: onPressed,
      ),
    );
  }
}
