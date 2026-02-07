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
  bool _playAnimation = false;

  //   ข้อมูลสำหรับแต่ละหน้าแนะนำ (ตามรูปภาพ)
  final List<Map<String, String>> onboardingData = [
    {
      'title': 'หิวเมื่อไหร่ ก็ปัดเลย',
      'description': 'เจอร้านถูกใจได้เร็วแบบทันใจ',
      'button_text': 'ถัดไป',
    },
    {
      'title': 'เปิดตำแหน่ง เพื่อดูร้านใกล้ตัว',
      'description': 'เราจะช่วยแนะนำร้านเด็ด ๆ รอบตัวคุณแบบเรียลไทม์',
      'button_text': 'ถัดไป',
    },
    {
      'title': 'ได้เวลาหาของอร่อยแล้ว',
      'description': 'ปัดดูร้านอาหารที่ชอบ แล้วไปอิ่มกันเลย',
      'button_text': 'เริ่มต้นใช้งาน',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPageChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _playAnimation = true;
      });
    });
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
                return buildOnboardingPage(onboardingData[index], index);
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
                        activeDotColor: AppColors.white,
                        dotColor: AppColors.white.withOpacity(0.5),
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
                          style: AppTextStyles.signinText.copyWith(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
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
                            'ข้าม',
                            style: AppTextStyles.signinText.copyWith(
                              color: Colors.white.withValues(alpha: 0.5),
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
  Widget buildOnboardingPage(Map<String, String> data, int index) {
    final bool active = _playAnimation && index == _currentPageIndex;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /// LOGO
          AnimatedScale(
            scale: active ? 1 : 0.8,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            child: AnimatedOpacity(
              opacity: active ? 1 : 0,
              duration: const Duration(milliseconds: 400),
              child: Image.asset(
                'assets/images/logo1.0.png',
                width: 156,
                height: 156,
              ),
            ),
          ),

          const SizedBox(height: 30),

          /// TITLE
          AnimatedSlide(
            offset: active ? Offset.zero : const Offset(0, 0.3),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: active ? 1 : 0,
              duration: const Duration(milliseconds: 500),
              child: Text(
                data['title']!,
                textAlign: TextAlign.center,
                style: AppTextStyles.signinText.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          /// DESCRIPTION
          AnimatedSlide(
            offset: active ? Offset.zero : const Offset(0, 0.5),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: active ? 1 : 0,
              duration: const Duration(milliseconds: 600),
              child: Text(
                data['description']!,
                textAlign: TextAlign.center,
                style: AppTextStyles.signinText.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
