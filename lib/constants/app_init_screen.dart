import 'dart:io';
import 'package:flutter/material.dart';
import '../services/restaurant_service.dart';
import '/screen/swipescreen.dart';
import '/screen/business/business_main_screen.dart';
import 'package:dishcovery_app/models/restaurant_details_model.dart';
import 'gradient_text.dart';
import 'app_constants.dart';

class AppInitScreen extends StatefulWidget {
  final bool showResetSuccessDialog;

  const AppInitScreen({super.key, this.showResetSuccessDialog = false});

  @override
  State<AppInitScreen> createState() => _AppInitScreenState();
}

class _AppInitScreenState extends State<AppInitScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoPulseController;
  late AnimationController _statusController;
  late AnimationController _exitController;

  late Animation<double> _logoScale;
  late Animation<Offset> _statusSlide;

  bool _isExiting = false;

  @override
  void initState() {
    super.initState();

    /// โลโก้ pulse เบา ๆ
    _logoPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _logoScale = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _logoPulseController, curve: Curves.easeInOut),
    );

    /// status text ขยับเหมือนกำลังโหลด
    _statusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _statusSlide =
        Tween(
          begin: const Offset(-0.03, 0),
          end: const Offset(0.03, 0),
        ).animate(
          CurvedAnimation(parent: _statusController, curve: Curves.easeInOut),
        );

    /// animation ตอนออกจากหน้า
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    /// ฟังสถานะ service
    RestaurantService.instance.addListener(_onServiceUpdate);

    // Initial check in case it's already ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (RestaurantService.instance.isReady && !_isExiting) {
        _isExiting = true;
        _playExitAnimation();
      }
    });
  }

  void _onServiceUpdate() {
    if (!mounted) return;

    if (RestaurantService.instance.isReady && !_isExiting) {
      _isExiting = true;
      _playExitAnimation();
    }
  }

  Future<void> _playExitAnimation() async {
    _logoPulseController.stop();
    _statusController.stop();
    await _exitController.forward();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SwipScreen(showResetSuccessDialog: widget.showResetSuccessDialog),
      ),
    );
  }

  @override
  void dispose() {
    RestaurantService.instance.removeListener(_onServiceUpdate);
    _logoPulseController.dispose();
    _statusController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          /// Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _logoScale,
                      child: Image.asset(
                        'assets/images/logo1.0circle.png',
                        width: 56,
                        height: 56,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GradientText(
                      text: 'DISHCOVERY!',
                      style: AppTextStyles.secondaryTitle.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                SlideTransition(
                  position: _statusSlide,
                  child: Text(
                    'กำลังจับคู่ร้านอาหารตามความชอบของคุณ…',
                    style: AppTextStyles.refreshText.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// Loader ด้านล่าง
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppInitChangeMode extends StatefulWidget {
  final bool isToBusinessMode;
  const AppInitChangeMode({super.key, required this.isToBusinessMode});
  @override
  State<AppInitChangeMode> createState() => _AppInitChangeModeState();
}

class _AppInitChangeModeState extends State<AppInitChangeMode>
    with TickerProviderStateMixin {
  late AnimationController _logoPulseController;
  late AnimationController _statusController;
  late AnimationController _exitController;
  late Animation<double> _logoScale;
  late Animation<Offset> _statusSlide;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _logoPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _logoScale = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _logoPulseController, curve: Curves.easeInOut),
    );
    _statusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _statusSlide =
        Tween(
          begin: const Offset(-0.03, 0),
          end: const Offset(0.03, 0),
        ).animate(
          CurvedAnimation(parent: _statusController, curve: Curves.easeInOut),
        );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _toggleAndNavigate();
  }

  Future<void> _toggleAndNavigate() async {
    await RestaurantService.instance.toggleBusinessMode(
      widget.isToBusinessMode,
    );
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted || _isExiting) return;
    _isExiting = true;
    _playExitAnimation();
  }

  Future<void> _playExitAnimation() async {
    _logoPulseController.stop();
    _statusController.stop();
    await _exitController.forward();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => widget.isToBusinessMode
            ? const BusinessMainScreen()
            : const SwipScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _logoPulseController.dispose();
    _statusController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _logoScale,
                      child: Image.asset(
                        'assets/images/logo1.0circle.png',
                        width: 56,
                        height: 56,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GradientText(
                      text: 'DISHCOVERY!',
                      style: AppTextStyles.secondaryTitle.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SlideTransition(
                  position: _statusSlide,
                  child: Text(
                    widget.isToBusinessMode
                        ? 'กำลังไปหน้าจัดการร้านอาหารของคุณ. . .'
                        : 'กำลังไปหน้าหาร้านอาหาร. . .',
                    style: AppTextStyles.refreshText.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppInitAddRestaurant extends StatefulWidget {
  final RestaurantDetailsData details;
  final File? coverImage;
  final List<File> galleryImages;
  final Map<String, File> menuImages;

  const AppInitAddRestaurant({
    super.key,
    required this.details,
    this.coverImage,
    this.galleryImages = const [],
    this.menuImages = const {},
  });

  @override
  State<AppInitAddRestaurant> createState() => _AppInitAddRestaurantState();
}

class _AppInitAddRestaurantState extends State<AppInitAddRestaurant>
    with TickerProviderStateMixin {
  late AnimationController _logoPulseController;
  late AnimationController _statusController;
  late AnimationController _exitController;
  late Animation<double> _logoScale;
  late Animation<Offset> _statusSlide;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _logoPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _logoScale = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _logoPulseController, curve: Curves.easeInOut),
    );
    _statusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _statusSlide =
        Tween(
          begin: const Offset(-0.03, 0),
          end: const Offset(0.03, 0),
        ).animate(
          CurvedAnimation(parent: _statusController, curve: Curves.easeInOut),
        );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _submitAndNavigate();
  }

  Future<void> _submitAndNavigate() async {
    try {
      await RestaurantService.instance.addRestaurantWithDetails(
        widget.details,
        coverImage: widget.coverImage,
        galleryImages: widget.galleryImages,
        menuImages: widget.menuImages,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        Navigator.pop(context); // Go back if failed
      }
      return;
    }

    if (!mounted || _isExiting) return;
    _isExiting = true;
    _playExitAnimation();
  }

  Future<void> _playExitAnimation() async {
    _logoPulseController.stop();
    _statusController.stop();
    await _exitController.forward();
    if (!mounted) return;

    // Navigate clear stack to BusinessMainScreen with dialog flag
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const BusinessMainScreen(showAddSuccessDialog: true),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _logoPulseController.dispose();
    _statusController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _logoScale,
                      child: const Icon(
                        Icons.storefront_rounded,
                        size: 56,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GradientText(
                      text: 'DISHCOVERY!',
                      style: AppTextStyles.secondaryTitle.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SlideTransition(
                  position: _statusSlide,
                  child: Text(
                    'กำลังเพิ่มร้านอาหาร. . .',
                    style: AppTextStyles.refreshText.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppInitUpdateData extends StatefulWidget {
  final Future<void> Function() onUpdate;

  const AppInitUpdateData({super.key, required this.onUpdate});

  @override
  State<AppInitUpdateData> createState() => _AppInitUpdateDataState();
}

class _AppInitUpdateDataState extends State<AppInitUpdateData>
    with TickerProviderStateMixin {
  late AnimationController _logoPulseController;
  late AnimationController _statusController;
  late AnimationController _exitController;
  late Animation<double> _logoScale;
  late Animation<Offset> _statusSlide;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _logoPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _logoScale = Tween(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _logoPulseController, curve: Curves.easeInOut),
    );
    _statusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _statusSlide =
        Tween(
          begin: const Offset(-0.03, 0),
          end: const Offset(0.03, 0),
        ).animate(
          CurvedAnimation(parent: _statusController, curve: Curves.easeInOut),
        );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _submitAndNavigate();
  }

  Future<void> _submitAndNavigate() async {
    try {
      await widget.onUpdate();
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context, e); // Go back if failed returning error
      }
      return;
    }

    if (!mounted || _isExiting) return;
    _isExiting = true;
    _playExitAnimation();
  }

  Future<void> _playExitAnimation() async {
    _logoPulseController.stop();
    _statusController.stop();
    await _exitController.forward();
    if (!mounted) return;

    // Pop the loading screen returning true for success
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _logoPulseController.dispose();
    _statusController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: _logoScale,
                      child: const Icon(
                        Icons.update,
                        size: 56,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GradientText(
                      text: 'DISHCOVERY!',
                      style: AppTextStyles.secondaryTitle.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SlideTransition(
                  position: _statusSlide,
                  child: Text(
                    'กำลังอัพเดตร้านอาหารของคุณ. . .',
                    style: AppTextStyles.refreshText.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
