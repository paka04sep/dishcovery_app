import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:dishcovery_app/constants/gradient_text.dart';
import 'package:dishcovery_app/foodpreferencescreen.dart';
import 'package:flutter/material.dart';
import '../mainscreen.dart';

// 💡 เปลี่ยนจาก StatelessWidget เป็น StatefulWidget 💡
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

// 💡 สร้าง State class พร้อม SingleTickerProviderStateMixin 💡
class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  // 💡 1. ประกาศตัวแปร Animation 💡
  late AnimationController _controller;
  late Animation<double> _animation; // สำหรับ Opacity

  @override
  void initState() {
    super.initState();

    // 💡 2. ตั้งค่า Animation Controller 💡
    _controller = AnimationController(
      duration: const Duration(seconds: 1), // ความเร็วในการวนลูป (1 วินาที)
      vsync: this,
    )..repeat(reverse: true); // วนลูปต่อเนื่อง และย้อนกลับ (กระพริบ)

    // 💡 3. ตั้งค่า Animation (ช่วง Opacity) 💡
    _animation = Tween<double>(
      begin: 0.5, // เริ่มจากความทึบ 50%
      end: 1.0, // ไปยังความทึบ 100%
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose(); // 💡 4. ทำความสะอาด Controller 💡
    super.dispose();
  }

  // ฟังก์ชันสำหรับจัดการการกดปุ่ม (ใช้ในการจำลองการนำทาง)
  void _signIn(BuildContext context, String method) {
    print('Signing in with $method...');

    // 💡 นำทางไปยังหน้าหลัก (HomePage) เมื่อล็อกอินสำเร็จ 💡
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const FoodPreferenceScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // กำหนด Font Family ถ้ามีการตั้งค่าใน Theme (จาก main.dart)
    final String? fontFamily = Theme.of(
      context,
    ).textTheme.bodyLarge?.fontFamily;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // ใช้ Gradient แบบเดียวกับหน้า Loading และ Onboarding
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

        // ใช้ Column จัดวางองค์ประกอบทั้งหมด
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Logo
            // (Logo อาจมี Animation อื่น ๆ แยกกัน หากต้องการ)
            const SizedBox(height: 55),
            Image.asset(
              'assets/images/logo1.0.png', // ตรวจสอบ Path ของ Logo
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 20),

            // 💡 2. ใช้ FadeTransition ครอบ GradientText 💡
            FadeTransition(
              opacity: _animation,
              child: GradientText(
                text: 'DISHCOVERY!',
                style: AppTextStyles.primaryTitle.copyWith(
                  fontFamily: fontFamily,
                ),
              ),
            ),

            const SizedBox(height: 120), // ระยะห่างระหว่างโลโก้กับปุ่ม
            // 3. ปุ่ม Sign In (จัดวางใน Padding)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ปุ่ม Google
                  _buildSignInButton(
                    context,
                    'Google',
                    Icons.g_mobiledata, // ใช้ไอคอน Google (g_mobiledata)
                    () => _signIn(context, 'Google'),
                  ),
                  const SizedBox(height: 15),

                  // ปุ่ม Facebook
                  _buildSignInButton(
                    context,
                    'facebook',
                    Icons.facebook,
                    () => _signIn(context, 'Facebook'),
                  ),
                  const SizedBox(height: 15),

                  // ปุ่ม Phone
                  _buildSignInButton(
                    context,
                    'phone',
                    Icons.call,
                    () => _signIn(context, 'Phone'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 💡 Widget สำหรับสร้างปุ่ม Sign In แต่ละปุ่ม 💡
  Widget _buildSignInButton(
    BuildContext context,
    String method,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      height: 55, // กำหนดความสูงของปุ่ม
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.black, size: 24),
        label: Text(
          'Sign in with $method',
          style: AppTextStyles.buttonText.copyWith(
            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white, // ใช้ AppColors.white
          alignment: Alignment.centerLeft, // จัดให้ไอคอนอยู่ด้านซ้าย
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // ขอบมน
          ),
          elevation: 5,
        ),
      ),
    );
  }
}
