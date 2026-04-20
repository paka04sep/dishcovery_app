import 'package:auto_size_text/auto_size_text.dart';
import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:dishcovery_app/constants/gradient_text.dart';

import 'package:dishcovery_app/screen/favorite_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../constants/app_init_screen.dart';
import 'history_screen.dart';
import '../models/restaurant_model.dart';
import 'user_profile_screen.dart';
import 'package:dishcovery_app/services/restaurant_service.dart';
import 'restarurant_detail_screen.dart';
import 'package:dishcovery_app/constants/app_bottom_nav_user.dart';
import 'package:dishcovery_app/utils/pulse_status_widget.dart';
import 'package:dishcovery_app/utils/time_utils.dart';

class SwipScreen extends StatefulWidget {
  final bool showResetSuccessDialog;

  const SwipScreen({super.key, this.showResetSuccessDialog = false});

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

  // สำหรับจับเวลา Dwell Time
  DateTime? _cardAppearanceTime;

  bool _wasLoading = false;

  @override
  void initState() {
    super.initState();
    _cardAppearanceTime = DateTime.now();
    // restaurantCards = RestaurantService.instance.swipableRestaurants;
    RestaurantService.instance.addListener(_onServiceUpdate); // Add listener
    restaurantCards = List.from(RestaurantService.instance.swipableRestaurants);
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

    if (widget.showResetSuccessDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showResetSuccessDialog();
      });
    }
  }

  void _showResetSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "รีเซ็ตข้อมูลสำเร็จ",
            style: AppTextStyles.profileText.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            "ประวัติการปัดร้านของคุณถูกล้างเรียบร้อย\nมาเริ่มค้นหาร้านอาหารใหม่กันเถอะ!",
            style: AppTextStyles.profileText.copyWith(
              fontWeight: FontWeight.w400,
              color: Colors.black.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "ตกลง",
                style: AppTextStyles.profileText.copyWith(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
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

      if (_wasLoading) {
        setState(() {
          restaurantCards = List.from(freshSwipable);
          _isFinished = restaurantCards.isEmpty;
          _wasLoading = false;
        });
        return;
      }

      final allRestaurants = RestaurantService.instance.restaurants;

      // New Robust Logic:
      // If the user finished swiping the previous batch, we MUST completely reset the queue
      // so the new cards start at index 0 without dragging along old, swiped cards.
      if (_isFinished) {
        if (freshSwipable.isNotEmpty) {
          setState(() {
            restaurantCards = List.from(freshSwipable);
            _isFinished = false;
          });
        }
      } else {
        // User is still swiping. Safely append to avoid breaking indexing.
        final currentIds = restaurantCards.map((r) => r.id).toSet();
        final toAdd = freshSwipable
            .where((r) => !currentIds.contains(r.id))
            .toList();

        if (toAdd.isNotEmpty) {
          setState(() {
            restaurantCards.addAll(toAdd);
            // _isFinished is already false, so we don't need to update it
          });
        } else {
          // Just update content of existing cards in case details changed
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
    }
  }

  // ฟังก์ชัน Callback เมื่อมีการปัด (ใช้สำหรับ logic การบันทึกเท่านั้น)
  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    // FIX: reject bottom swipe — เปิด down ไว้ใน CardSwiper เพื่อแก้ gesture lock
    // แต่ไม่ให้ปัดลงล่างจริงๆ → return false เพื่อ cancel และเด้งกลับ
    if (direction == CardSwiperDirection.bottom) {
      return false;
    }

    debugPrint(
      'Card ${restaurantCards[previousIndex].name} swiped to: ${direction.name}',
    );
    SwipeStatus newStatus = SwipeStatus.none;

    if (direction == CardSwiperDirection.right) {
      newStatus = SwipeStatus.yum;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RestaurantDetailScreen(
            restaurant: restaurantCards[previousIndex],
          ),
        ),
      );
    } else if (direction == CardSwiperDirection.left) {
      newStatus = SwipeStatus.pass;
    } else if (direction == CardSwiperDirection.top) {
      newStatus = SwipeStatus.fav;
    }

    int dwellTime = 0;
    if (_cardAppearanceTime != null) {
      dwellTime = DateTime.now().difference(_cardAppearanceTime!).inSeconds;
    }
    _cardAppearanceTime = DateTime.now();

    if (newStatus != SwipeStatus.none) {
      RestaurantService.instance.swipeRestaurant(
        restaurantCards[previousIndex].id,
        newStatus,
        dwellTime: dwellTime,
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

    // แก้ไข: ใช้ right สำหรับ YUM และ up สำหรับ FAV!
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

    if (!RestaurantService.instance.isReady ||
        (RestaurantService.instance.isFetchingBatch &&
            RestaurantService.instance.isManualRefresh)) {
      _wasLoading = true;
      return const AppInitScreen();
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
                      // FIX: อนุญาต down ด้วยเพื่อป้องกัน gesture lock
                      // เวลาจับมุมล่างแล้ว touch jitter ดัน top เป็นบวก
                      // → reject bottom swipe ใน _onSwipe แทน
                      allowedSwipeDirection: const AllowedSwipeDirection.only(
                        left: true,
                        right: true,
                        up: true,
                        down: true,
                      ),
                      maxAngle: 20, // ลดจาก default 30 ให้หมุนอ่อนลง
                      threshold: 40, // ลดจาก 50 ให้ swipe ง่ายขึ้น
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
    // ============================================================
    // Overlay Progress — ใช้ smoothstep curve
    // ============================================================
    const double threshold = 0.18;
    final bool isVerticalSwipe = percentY.abs() > percentX.abs();

    double smoothStep(double x) {
      final t = x.clamp(0.0, 1.0);
      return t * t * (3.0 - 2.0 * t);
    }

    double yumProgress = 0.0;
    double passProgress = 0.0;
    double favProgress = 0.0;

    if (isVerticalSwipe) {
      if (percentY < 0) {
        favProgress = smoothStep(percentY.abs() / threshold);
      }
    } else {
      if (percentX > 0) yumProgress = smoothStep(percentX / threshold);
      if (percentX < 0) passProgress = smoothStep(percentX.abs() / threshold);
    }

    // ============================================================
    // Dynamic Direction Shadow — เงาเปลี่ยนสีตามทิศทางที่ปัด
    // ============================================================
    final double swipeIntensity = (percentX.abs() + percentY.abs() * 0.5).clamp(
      0.0,
      1.0,
    );
    final double shadowBlur = 10 + swipeIntensity * 18;
    final double shadowSpread = 1 + swipeIntensity * 3;

    // คำนวณสีเงาตามทิศทาง
    Color shadowColor;
    if (yumProgress > passProgress &&
        yumProgress > favProgress &&
        yumProgress > 0.05) {
      // ปัดขวา = เขียวอ่อน
      shadowColor = Color.lerp(
        Colors.black.withOpacity(0.25),
        const Color(0xFF4CAF50).withOpacity(0.4),
        (yumProgress * 0.6).clamp(0.0, 1.0),
      )!;
    } else if (passProgress > yumProgress &&
        passProgress > favProgress &&
        passProgress > 0.05) {
      // ปัดซ้าย = แดงอ่อน
      shadowColor = Color.lerp(
        Colors.black.withOpacity(0.25),
        const Color(0xFFE53935).withOpacity(0.4),
        (passProgress * 0.6).clamp(0.0, 1.0),
      )!;
    } else if (favProgress > 0.05) {
      // ปัดขึ้น = ทองอ่อน
      shadowColor = Color.lerp(
        Colors.black.withOpacity(0.25),
        const Color(0xFFFFC107).withOpacity(0.4),
        (favProgress * 0.6).clamp(0.0, 1.0),
      )!;
    } else {
      shadowColor = Colors.black.withOpacity(0.25);
    }

    // ไม่ต้อง Transform.rotate เอง — CardSwiper จัดการ rotation ให้แล้ว
    // เพิ่ม ValueKey เพื่อให้ Flutter รู้ว่าเป็นการ์ดคนละใบกัน
    // ป้องกัน Animation ของการ์ดเก่าติดไปหน้าการ์ดใหม่ (Ghosting overlay)
    return Container(
      key: ValueKey(data.id),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: shadowBlur,
            spreadRadius: shadowSpread,
            offset: Offset(
              percentX.clamp(-1.0, 1.0) * 4,
              6 + swipeIntensity * 4,
            ),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: Stack(
          children: [
            // 1. รูปภาพและ Gradient
            Positioned.fill(
              child: data.imageUrl.startsWith('http')
                  ? Image.network(
                      data.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade600,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    )
                  : Image.asset(
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
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.3, 0.9],
                  ),
                ),
              ),
            ),

            // 2. Pulse Status Widget (Top Right)
            Positioned(
              top: 15,
              right: 15,
              child: PulseStatusWidget(
                status: TimeUtils.getRestaurantStatus(data.openingHours),
              ),
            ),

            // 3. Interactive Overlays (YUM, PASS, FAV)
            // ใช้ AnimatedOpacity + AnimatedScale แทน raw widget
            // เพื่อให้มี time-based interpolation ที่นุ่มนวล
            _buildSwipeOverlay(
              text: 'YUM!',
              color: const Color(0xFF4CAF50),
              progress: yumProgress,
              position: const Alignment(-0.85, -0.78),
              angle: -0.30,
            ),
            _buildSwipeOverlay(
              text: 'PASS',
              color: const Color(0xFFE53935),
              progress: passProgress,
              position: const Alignment(0.85, -0.78),
              angle: 0.30,
            ),
            _buildSwipeOverlay(
              text: '★ FAV',
              color: const Color(0xFFFFC107),
              progress: favProgress,
              position: const Alignment(0.0, -0.5),
              angle: 0.0,
            ),

            // 4. รายละเอียดร้านอาหาร
            Positioned(
              left: 20,
              right: 20,
              bottom: 115, // ถ้าด้านล่างมีปุ่มกดเว้นระยะนี้ไว้ถือว่าโอเคครับ
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- แถวที่ 1: ชื่อร้าน และ Badge เรตติ้ง ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ใช้ Expanded ครอบชื่อร้าน เพื่อให้ตัดคำเมื่อยาวเกิน 2 บรรทัด
                      Expanded(
                        child: AutoSizeText(
                          data.name,
                          style: AppTextStyles.restaurantName.copyWith(
                            height: 1.2, // ปรับระยะบรรทัดให้พอดี
                          ),
                          maxLines: 2,
                          minFontSize: 14,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Rating Badge (กล่องเรตติ้งดูพรีเมียมและเป็นระเบียบ)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.amber.shade400,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: Colors.amber.shade400,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              (data.reviewCount == 0 || data.rating == 0.0)
                                  ? "N/A ยังไม่มีรีวิว"
                                  : data.rating.toString(),
                              style: AppTextStyles.restaurantDetails.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // --- แถวที่ 2: ประเภท · ราคา · ระยะทาง ---
                  // จับรวบเป็น Text เดียวแล้วใช้ Expanded กันล้น เผื่อของกินหลายประเภท
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${data.cuisine.join(', ')} • ${data.getPriceSymbol()} • ${RestaurantService.instance.getDistance(data)} km',
                          style: AppTextStyles.restaurantDetails.copyWith(
                            color: Colors.grey.shade300,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // --- แถวที่ 3: คำอธิบายร้าน ---
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '"${data.description}"',
                          style: AppTextStyles.restaurantDetails.copyWith(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.white70,
                          ),
                          maxLines:
                              2, // ให้โควตา 2 บรรทัดจะอ่านง่ายกว่าบรรทัดเดียวครับ
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget ย่อยสำหรับสร้าง Overlay Text สำหรับการปัด
  // ใช้ AnimatedOpacity + AnimatedScale เพื่อให้ transition
  // มีความ smooth แบบ time-based ไม่กระโดดตามนิ้ว
  Widget _buildSwipeOverlay({
    required String text,
    required Color color,
    required double progress, // 0.0 – 1.0
    required Alignment position,
    required double angle,
  }) {
    final double t = progress.clamp(0.0, 1.0);
    final double eased = t * t * (3.0 - 2.0 * t); // smoothstep

    // Glow intensity ตาม progress
    final double glowSpread = eased * 5.0;
    final double glowBlur = 8.0 + eased * 18.0;

    // IgnorePointer เพื่อไม่ block gesture
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: position,
          child: AnimatedOpacity(
            opacity: t < 0.01 ? 0.0 : eased, // ถ้าแทบไม่ปัด ให้ดับสนิททันที
            duration: const Duration(
              milliseconds: 100,
            ), // เร็วขึ้นเล็กน้อยเพื่อความไว
            curve: Curves.easeOut,
            child: Transform.rotate(
              angle: angle,
              child: AnimatedScale(
                scale: t < 0.01 ? 0.8 : (0.80 + eased * 0.20),
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOutCubic,
                child: _SwipeLabel(
                  text: text,
                  color: color,
                  glowBlur: glowBlur,
                  glowSpread: glowSpread,
                  opacity: eased,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

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

class _SwipeLabel extends StatelessWidget {
  const _SwipeLabel({
    required this.text,
    required this.color,
    required this.glowBlur,
    required this.glowSpread,
    required this.opacity,
  });

  final String text;
  final Color color;
  final double glowBlur;
  final double glowSpread;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        // Fill โปร่งใสเล็กน้อย ให้ตัวอักษรอ่านง่ายขึ้น
        color: color.withOpacity(0.12 * opacity),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 3.5),
        boxShadow: [
          // Inner glow (ทำให้ขอบดูเรืองแสง)
          BoxShadow(
            color: color.withOpacity(0.45 * opacity),
            blurRadius: glowBlur,
            spreadRadius: glowSpread,
          ),
          // Outer soft shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          // ใช้สีขาว + stroke สี theme เพื่อให้อ่านง่ายบนทุกพื้นหลัง
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.w900,
          letterSpacing: 4,
          shadows: [
            // Drop shadow ด้านล่าง
            Shadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 4,
              offset: const Offset(1, 2),
            ),
            // Colored glow รอบตัวหนังสือ
            Shadow(color: color.withOpacity(0.8), blurRadius: 12),
          ],
        ),
      ),
    );
  }
}
