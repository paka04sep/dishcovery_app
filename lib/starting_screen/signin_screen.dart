import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dishcovery_app/constants/gradient_text.dart';
import 'package:dishcovery_app/screen/foodpreference_screen.dart';
import 'package:dishcovery_app/screen/swipescreen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../starting_screen/auth_wrapper.dart';
import '../utils/waveclipper.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

// สร้าง State class พร้อม TickerProviderStateMixin
class _SignInScreenState extends State<SignInScreen>
    with TickerProviderStateMixin {
  bool _showEmailForm = false;
  bool _isSignUp = false;
  bool _obscurePassword = true;
  // ตัวแปรสำหรับเก็บค่า Email และ Password
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  //  ประกาศตัวแปร Animation
  late AnimationController _controller;
  late Animation<double> _animation; // สำหรับ Opacity

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    //  2. ตั้งค่า Animation Controller
    _controller = AnimationController(
      duration: const Duration(seconds: 1), // ความเร็วในการวนลูป (1 วินาที)
      vsync: this,
    )..repeat(reverse: true); // วนลูปต่อเนื่อง และย้อนกลับ (กระพริบ)

    // 3. ตั้งค่า Animation (ช่วง Opacity)
    _animation = Tween<double>(
      begin: 0.5, // เริ่มจากความทึบ 50%
      end: 1.0, // ไปยังความทึบ 100%
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -2, end: 2), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 2, end: -2), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -2, end: 0), weight: 1),
    ]).animate(_shakeController);
  }

  @override
  void dispose() {
    _controller.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _signIn(BuildContext context, String method) async {
    if (method == 'Google') {
      setState(() {
        _isLoading = true;
      });

      try {
        final userCredential = await _authService.signInWithGoogle();
        if (userCredential != null) {
          if (userCredential != null && mounted) {
            // Navigation is handled by AuthWrapper listening to auth state changes
            // However, to ensure we switch context:
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AuthWrapper()),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to sign in with Google: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      // Implement other methods later
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$method sign-in is not implemented yet.')),
      );
    }
  }

  // ฟังก์ชันสำหรับเคลียร์ค่า
  void _clearFields() {
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _clearValidation();
    _obscurePassword = true;
  }

  void _clearValidation() {
    _emailError = null;
    _passwordError = null;
    _confirmPasswordError = null;
  }

  void _submitEmailForm() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    setState(() {
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    bool hasError = false;

    if (email.isEmpty) {
      _emailError = 'กรุณากรอกอีเมล';
      hasError = true;
    }

    if (password.isEmpty) {
      _passwordError = 'กรุณากรอกรหัสผ่าน';
      hasError = true;
    }

    if (_isSignUp && confirmPassword.isEmpty) {
      _confirmPasswordError = 'กรุณายืนยันรหัสผ่าน';
      hasError = true;
    }

    if (_isSignUp && password.isNotEmpty && confirmPassword.isNotEmpty) {
      if (password != confirmPassword) {
        _confirmPasswordError = 'รหัสผ่านไม่ตรงกัน';
        hasError = true;
      }
    }

    if (hasError) {
      setState(() {});
      _shakeController.forward(from: 0.0);
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential? userCredential;
      if (_isSignUp) {
        userCredential = await _authService.signUpWithEmail(email, password);
      } else {
        userCredential = await _authService.signInWithEmail(email, password);
      }

      if (userCredential != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    } on FirebaseAuthException catch (e) {
      /// map error จาก firebase ลง field
      setState(() {
        switch (e.code) {
          case 'invalid-credential':
            _emailError = '';
            _passwordError = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
            break;
          case 'email-already-in-use':
            _emailError = 'อีเมลนี้ถูกใช้งานแล้ว';
            break;
          case 'weak-password':
            _passwordError = '';
            _confirmPasswordError = 'รหัสผ่านอ่อนเกินไป';
            break;
          case 'invalid-email':
            _emailError = 'รูปแบบอีเมลไม่ถูกต้อง';
            break;
          default:
            _emailError = 'เกิดข้อผิดพลาด กรุณาลองใหม่';
        }
      });

      _shakeController.forward(from: 0);
    } catch (e) {
      setState(() {
        _emailError = 'เกิดข้อผิดพลาด กรุณาลองใหม่';
      });
      _shakeController.forward(from: 0);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // --- Layer 1: พื้นหลัง Gradient หลัก ---
          Container(
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
          ),

          // --- Layer 2: ข้อความที่จะโผล่มาในส่วนพื้นที่ว่างด้านบน (25%) ---
          if (_showEmailForm)
            GestureDetector(
              onTap: () => setState(() {
                _showEmailForm = false;
                _isSignUp = false;
                _clearFields();
              }),
              child: Container(
                width: double.infinity,
                height: screenHeight * 0.3, // พื้นที่ 30%
                color: Colors.transparent,
              ),
            ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: _showEmailForm ? 1.0 : 0.0,
            child: SafeArea(
              child: Container(
                width: double.infinity,
                height: screenHeight * 0.25,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSignUp ? 'สร้างบัญชีใหม่' : 'ยินดีต้อนรับกลับมา!',
                      style: AppTextStyles.signinText.copyWith(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSignUp
                          ? "ลงทะเบียนเพื่อเริ่มต้นค้นหา"
                          : "กรุณาเข้าสู่ระบบเพื่อใช้งาน",
                      style: AppTextStyles.signinText.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- Layer 3: เนื้อหาหน้าหลัก (Logo + Google Button) ---
          // จะจางหายไป (Fade Out) เมื่อฟอร์มเลื่อนขึ้นมา
          AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: _showEmailForm ? 0.0 : 1.0,
            child: IgnorePointer(
              ignoring:
                  _showEmailForm ||
                  _isLoading, // ป้องกันการกดโดนปุ่มด้านหลังเมื่อฟอร์มเปิด

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Logo
                  const SizedBox(height: 55),
                  Image.asset(
                    'assets/images/logo1.0.png',
                    width: 150,
                    height: 150,
                  ),
                  const SizedBox(height: 20),

                  // 2. ใช้ FadeTransition ครอบ GradientText
                  FadeTransition(
                    opacity: _animation,
                    child: GradientText(
                      text: 'DISHCOVERY!',
                      style: AppTextStyles.primaryTitle.copyWith(
                        fontFamily: 'balooda',
                        fontSize: 36,
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),
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
                          SvgPicture.asset(
                            'assets/icons/google_icon.svg',
                            width: 24,
                            height: 24,
                          ),
                          () => _signIn(context, 'Google'),
                        ),

                        // const SizedBox(height: 15),
                        // // ปุ่ม Facebook
                        // _buildSignInButton(
                        //   context,
                        //   'Facebook',
                        //   SvgPicture.asset(
                        //     'assets/icons/facebook_icon.svg',
                        //     width: 24,
                        //     height: 24,
                        //   ),
                        //   () => _signIn(context, 'Facebook'),
                        // ),
                        // const SizedBox(height: 15),

                        // // ปุ่ม Phone
                        // _buildSignInButton(
                        //   context,
                        //   'phone',
                        //   Icons.call,
                        //   () => _signIn(context, 'Phone'),
                        // ),
                        // const SizedBox(height: 15),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            setState(() => _showEmailForm = true);
                          },
                          child: Container(
                            padding: const EdgeInsets.only(bottom: 0.5),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.white.withOpacity(
                                    0.5,
                                  ), // สีเส้นใต้
                                  width: 1.0, // ความหนาเส้นใต้
                                ),
                              ),
                            ),
                            child: Text(
                              'เข้าสู่ระบบด้วยอีเมล',
                              style: AppTextStyles.signinText.copyWith(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // --- Layer 4: ตัว WaveClipper (ฟอร์มสีขาวลอยขึ้นมา) ---
          AnimatedPositioned(
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutQuart, // เลื่อนขึ้นนุ่มๆ เหมือนระดับน้ำเพิ่ม
            left: 0,
            right: 0,
            // ถ้า _showEmailForm = true ให้ bottom = 0 (ชิดขอบล่างพอดี)
            bottom: _showEmailForm ? 0 : -screenHeight,

            child: ClipPath(
              clipper: WaveClipper(),
              child: Container(
                color: Colors.white, // คลื่นสีขาว
                height:
                    MediaQuery.of(context).size.height *
                    0.75, // ความสูงของคลื่นที่ลอยขึ้นมา
                child: Padding(
                  padding: const EdgeInsets.only(top: 50, left: 30, right: 30),
                  child: Column(
                    // ใส่ TextField แบบเส้นใต้ตามดีไซน์ของคุณที่นี่
                    children: [
                      Text(
                        _isSignUp ? "สมัครสมาชิก" : "เข้าสู่ระบบ",
                        style: AppTextStyles.signinText.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _shakeField(
                        errorText: _emailError,
                        child: _buildUnderlineField(
                          "Email",
                          controller: _emailController,
                          errorText: _emailError,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _shakeField(
                        errorText: _emailError,
                        child: _buildUnderlineField(
                          "Password",
                          controller: _passwordController,
                          errorText: _passwordError,
                          isPassword: _obscurePassword,
                        ),
                      ),
                      if (_isSignUp) ...[
                        const SizedBox(height: 15),
                        _shakeField(
                          errorText: _emailError,
                          child: _buildUnderlineField(
                            "Confirm Password",
                            controller: _confirmPasswordController,
                            isPassword: _obscurePassword,
                            errorText: _confirmPasswordError,
                          ),
                        ),

                        const SizedBox(height: 15),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: 30,
                              width: 30,
                              child: Checkbox(
                                value: !_obscurePassword,
                                onChanged: (value) {
                                  setState(() {
                                    _obscurePassword = !value!;
                                  });
                                },
                                activeColor: AppColors.primaryBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            Text(
                              "แสดงรหัสผ่าน",
                              style: AppTextStyles.signinText.copyWith(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],

                      SizedBox(height: _isSignUp ? 20 : 40),

                      Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.black,
                        ),
                        child: ElevatedButton(
                          onPressed: _submitEmailForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            _isSignUp ? "REGISTER" : "SIGN IN",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),

                        // Section: Don't have account? Sign up
                      ),

                      if (!_isSignUp)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () async {
                              final email = _emailController.text.trim();

                              if (email.isEmpty) {
                                setState(() {
                                  _emailError = 'กรุณากรอกอีเมลก่อน';
                                });
                                return;
                              }

                              try {
                                await _authService.sendPasswordReset(email);

                                if (mounted) {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      title: Text(
                                        'รีเซ็ตรหัสผ่าน',
                                        style: AppTextStyles.signinText
                                            .copyWith(
                                              color: Colors.red,
                                              fontSize: 18,
                                            ),
                                      ),
                                      content: Text(
                                        'หากอีเมลนี้อยู่ในระบบ เราได้ส่งลิงก์รีเซ็ตรหัสผ่านให้แล้ว',
                                        style: AppTextStyles.signinText
                                            .copyWith(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w100,
                                            ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text(
                                            'ตกลง',
                                            style: AppTextStyles.signinText
                                                .copyWith(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              } on FirebaseAuthException catch (e) {
                                setState(() {
                                  if (e.code == 'invalid-email') {
                                    _emailError = 'รูปแบบอีเมลไม่ถูกต้อง';
                                  } else {
                                    _emailError = 'ไม่สามารถส่งอีเมลได้';
                                  }
                                });
                              }
                            }, // TODO: Forgot Password Logic
                            child: Text(
                              "ลืมรหัสผ่าน?",
                              style: AppTextStyles.signinText.copyWith(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),

                      // ปุ่มปิดแบบกลมกลืน
                      const Spacer(),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isSignUp ? "มีบัญชีอยู่แล้ว? " : "ยังไม่มีบัญชี? ",
                            style: AppTextStyles.signinText.copyWith(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isSignUp = !_isSignUp;
                                _clearFields(); // เพิ่มการเคลียร์ฟิลด์ตรงนี้
                              });
                            },
                            child: Text(
                              _isSignUp ? "เข้าสู่ระบบ" : "สมัครสมาชิก",
                              style: AppTextStyles.signinText.copyWith(
                                color: AppColors.primaryBlue,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUnderlineField(
    String hint, {
    required TextEditingController controller,
    bool isPassword = false,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : Colors.grey[300]!,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : AppColors.primaryBlue,
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: AppTextStyles.signinText.copyWith(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  Widget _shakeField({required Widget child, required String? errorText}) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, _) {
        final offset = errorText != null ? _shakeAnimation.value : 0.0;

        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
    );
  }

  void _guestLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const FoodPreferenceScreen()),
    );
  }

  //  Widget สำหรับสร้างปุ่ม Sign In แต่ละปุ่ม
  Widget _buildSignInButton(
    BuildContext context,
    String method,
    Widget icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      height: 55,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 2,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            /// text อยู่กลางปุ่มเสมอ
            Center(
              child: Text(
                'Continue with $method',
                style: AppTextStyles.signinText,
              ),
            ),

            /// icon ชิดซ้าย
            Align(alignment: Alignment.centerLeft, child: icon),
          ],
        ),
      ),
    );
  }
}
