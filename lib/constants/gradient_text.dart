import 'package:flutter/material.dart';
import 'app_constants.dart'; // ใช้ค่า AppColors

class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const GradientText({super.key, required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      // 💡 ใช้ AppColors.textGradient ที่เรากำหนดไว้ 💡
      shaderCallback: (bounds) {
        return AppColors.textGradient.createShader(
          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
        );
      },
      child: Text(
        text,
        style: style.copyWith(
          // ต้องใช้สีขาว (หรือสีทึบ) เพื่อให้ Shader ฉายทับลงไป
          color: AppColors.white,
        ),
      ),
    );
  }
}
