import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:dishcovery_app/screen/foodpreference_screen.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '/starting_screen/signin_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0; // สถานะปัจจุบันของหน้า

  //   ข้อมูลสำหรับแต่ละหน้าแนะนำ (ตามรูปภาพ)
  final List<Map<String, String>> onboardingData = [
    {
      'title': 'Swipe. Discover. Dine.',
      'description': 'Turn every swipe into a new dining adventure.',
      'button_text': 'NEXT',
    },
    {
      'title': 'Turn On GPS',
      'description':
          'Enable location to discover the best restaurants near you.',
      'button_text': 'NEXT',
    },
    {
      'title': 'Ready to Dishcover?',
      'description': 'Find your next favorite meal in just one swipe.',
      'button_text': 'GET START', // ปุ่มสุดท้าย
    },
  ];

  //   กำหนดสีหลักของแอป (ใช้จาก LoadingScreen หรือตามต้องการ)

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPageChange);
  }

  void _onPageChange() {
    if (_pageController.page != null) {
      setState(() {
        _currentPageIndex = _pageController.page!.round();
      });
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChange);
    _pageController.dispose();
    super.dispose();
  }

  //   สร้าง Logic การกดปุ่ม (ใช้ร่วมกันสำหรับ NEXT/GET START)
  void _onNextPressed() {
    if (_currentPageIndex == onboardingData.length - 1) {
      // หน้าสุดท้าย: ไปหน้าหลัก
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const FoodPreferenceScreen()),
      );
    } else {
      // หน้าอื่นๆ: เลื่อนไปหน้าถัดไป
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onSkipPressed() {
    // เลื่อนไปหน้าสุดท้าย (GET START)
    _pageController.animateToPage(
      onboardingData.length - 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
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

        //   ใช้ Stack เพื่อวาง PageView และปุ่มซ้อนกัน
        child: Stack(
          children: [
            // 1. PageView (แสดงเนื้อหาแต่ละหน้า)
            PageView.builder(
              controller: _pageController,
              itemCount: onboardingData.length,
              itemBuilder: (context, index) {
                return buildOnboardingPage(onboardingData[index]);
              },
            ),

            // 2. ปุ่มควบคุมด้านล่าง (Positioned at the bottom)
            Positioned(
              bottom: 80, // กำหนดตำแหน่งจากด้านล่าง (ปรับค่าได้)
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Page Indicator (จุดวงกลม)
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: onboardingData.length,
                      effect: ExpandingDotsEffect(
                        activeDotColor: AppColors.black,
                        dotColor: AppColors.black.withOpacity(0.5),
                        dotHeight: 8,
                        dotWidth: 8,
                        spacing: 8,
                      ),
                    ),
                    const SizedBox(height: 25),

                    // ปุ่ม NEXT / GET START
                    SizedBox(
                      width: 300,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            _onNextPressed, // เรียกใช้ Logic ที่สร้างไว้ด้านบน
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          elevation: 8,
                        ),
                        child: Text(
                          onboardingData[_currentPageIndex]['button_text']!,
                        ),
                      ),
                    ),

                    // ปุ่ม SKIP (ถ้าไม่ใช่หน้าสุดท้าย)
                    Opacity(
                      // Opacity: 1.0 ถ้าไม่ใช่หน้าสุดท้าย, 0.0 ถ้าเป็นหน้าสุดท้าย
                      opacity: _currentPageIndex != onboardingData.length - 1
                          ? 1.0
                          : 0.0,

                      // IgnorePointer: true เมื่ออยู่หน้าสุดท้าย (ป้องกันการกดปุ่มที่มองไม่เห็น)
                      child: IgnorePointer(
                        ignoring:
                            _currentPageIndex == onboardingData.length - 1,
                        child: TextButton(
                          onPressed:
                              _onSkipPressed, // Logic การกดปุ่ม SKIP ยังคงเดิม
                          child: Text(
                            'SKIP',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 16,
                            ),
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
      ),
    );
  }

  //   Widget สำหรับสร้างเนื้อหาของแต่ละหน้า (ไม่มีการเปลี่ยนแปลง)
  Widget buildOnboardingPage(Map<String, String> data) {
    final String? fontFamily = Theme.of(
      context,
    ).textTheme.bodyLarge?.fontFamily;

    // เราต้องปรับ padding ด้านล่างของเนื้อหาแต่ละหน้า
    // เพื่อให้ไม่ชนกับปุ่มควบคุมที่ Positioned ไว้
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        100,
      ), // เพิ่ม Padding ด้านล่าง 220
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/logo1.0.png', width: 156, height: 156),
          const SizedBox(height: 30),
          Text(
            data['title']!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
              fontFamily: fontFamily,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            data['description']!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.black.withOpacity(0.8),
              fontFamily: fontFamily,
            ),
          ),
        ],
      ),
    );
  }
}
