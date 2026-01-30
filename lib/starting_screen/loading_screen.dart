import 'dart:async';
import '/starting_screen/onboarding_screen.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../constants/app_constants.dart';
import 'package:geolocator/geolocator.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _initApp();
  }

  Future<void> _initApp() async {
    try {
      // 1. เริ่มเล่น Animation ของตัวอักษร
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _controller.forward();
      });

      // 2. ขอสิทธิ์ Location (ใส่ try-catch แยกเพื่อให้ทำงานต่อได้)
      try {
        await _handleLocationPermission();
      } catch (e) {
        debugPrint("Error handling location permission: $e");
      }
    } catch (e) {
      debugPrint("Error in _initApp: $e");
    } finally {
      // 3. รอให้ครบ 3 วินาทีตามดีไซน์เดิม (หรือจนกว่างานอื่นจะเสร็จ)
      // ใช้ finally เพื่อให้มั่นใจว่า Code ส่วนนี้จะถูกรันเสนอ
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        }
      });
    }
  }

  Future<void> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // ตรวจสอบว่าเปิด Service หรือยัง
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // สามารถแจ้งเตือนให้ผู้ใช้เปิด GPS ได้ที่นี่
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // ขอสิทธิ์จากผู้ใช้
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // กรณีผู้ใช้ปฏิเสธแบบถาวร
      return;
    }

    // หากผ่านการขอสิทธิ์ สามารถดึงตำแหน่งไว้รอได้เลย (Optional)
    // Position position = await Geolocator.getCurrentPosition();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildAnimatedText(String text) {
    final characters = text.split('');

    // กำหนด Gradient ที่คุณต้องการ
    const gradient = LinearGradient(
      colors: [Color(0xFF001738), Color(0xFF004C7B), Color(0xFF000F36)],
      // กำหนดทิศทางการไล่สี (เช่น จากซ้ายไปขวา)
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: characters.asMap().entries.map((entry) {
            final index = entry.key;
            final char = entry.value;
            final step = 1.0 / characters.length;
            final start = index * step;
            final end = (index + 1) * step;

            double opacity;
            if (progress >= end) {
              opacity = 1.0;
            } else if (progress < start) {
              opacity = 0.0;
            } else {
              opacity = (progress - start) / step;
            }

            return Opacity(
              opacity: opacity,
              // 💡 ใช้ ShaderMask ครอบตัวอักษรแต่ละตัว
              child: ShaderMask(
                // กำหนด Shader เป็น LinearGradient ที่เราสร้างไว้
                shaderCallback: (bounds) {
                  return gradient.createShader(
                    Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                  );
                },
                child: Text(
                  char,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    // 💡 ต้องใช้สีขาว (หรือสีใดๆ ที่มี opacity เต็ม 1.0)
                    // เพื่อให้ Gradient ฉายลงไปได้อย่างสมบูรณ์
                    color: Colors.white,
                    letterSpacing: 1.5,
                    fontFamily: 'inter',
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... โค้ด Container ...

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.lightBlue,
              AppColors.midblue,
              AppColors.primaryBlue,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset('assets/images/logo1.0.png', width: 156, height: 156),
            const SizedBox(height: 15),

            // 💡 เรียกใช้ Widget ที่สร้างใหม่แทน FadeTransition
            _buildAnimatedText('DISHCOVERY!'),
          ],
        ),
      ),
    );
  }
}
