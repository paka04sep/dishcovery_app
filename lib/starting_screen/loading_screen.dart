import 'dart:async';
import '/starting_screen/onboarding_screen.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../constants/app_constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _controller.forward();
      }
    });

    _controller.forward();

    // Timer(const Duration(seconds: 3), () {
    //   Navigator.of(context).pushReplacement(
    //     MaterialPageRoute(builder: (context) => const OnboardingScreen()),
    //   );
    // });
    _initApp();
  }

  Future<Position?> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // เช็คว่าเปิด Location service ไหม
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location service disabled');
      return null;
    }

    // เช็ค permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permission denied');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permission denied forever');
      return null;
    }

    // ดึงตำแหน่ง
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _initApp() async {
    // หน่วงให้เห็น animation
    await Future.delayed(const Duration(seconds: 2));

    final position = await _getUserLocation();

    if (position != null) {
      debugPrint('User location: ${position.latitude}, ${position.longitude}');

      // TODO: เก็บไว้ใน Provider / Global / Firebase
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
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
