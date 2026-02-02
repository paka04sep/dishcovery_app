import 'package:flutter/material.dart';
import '../services/restaurant_service.dart';
import '/screen/swipescreen.dart';
import 'gradient_text.dart';
import 'app_constants.dart';

class AppInitScreen extends StatefulWidget {
  const AppInitScreen({super.key});

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
  late Animation<Offset> _exitSlide;
  late Animation<double> _exitFade;

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

    _exitSlide = Tween(begin: Offset.zero, end: const Offset(-0.4, -0.4))
        .animate(
          CurvedAnimation(parent: _exitController, curve: Curves.easeInOut),
        );

    _exitFade = Tween(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _exitController, curve: Curves.easeOut));

    /// ฟังสถานะ service
    RestaurantService.instance.addListener(_onServiceUpdate);
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
      MaterialPageRoute(builder: (_) => const SwipScreen()),
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
            child: FadeTransition(
              opacity: _exitFade,
              child: SlideTransition(
                position: _exitSlide,
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
