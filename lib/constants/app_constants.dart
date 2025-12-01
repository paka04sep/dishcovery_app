import 'package:flutter/material.dart';

// --- Color Constants ---
class AppColors {
  // สีหลักของแอป (Gradient Background)
  static const Color primaryBlue = Color(0xFF276FDA); // Darker blue
  static const Color midblue = Color(0xFF5E9FFF); // Midblue
  static const Color lightBlue = Color(0xFF76ADFF); // Lighter blue

  // สีข้อความและปุ่ม
  static const Color white = Colors.white;
  static const Color black = Colors.black87;
  static const Color disabled = Colors.white54; // สีสำหรับจุด indicator/skip

  // ไล่สีข้อความ
  static const Gradient textGradient = LinearGradient(
    colors: [Color(0xFF001738), Color(0xFF004C7B), Color(0xFF000F36)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// --- Spacing Constants ---
class AppSpacing {
  static const double large = 40.0;
  static const double medium = 20.0;
  static const double small = 15.0;
  static const double tiny = 10.0;

  // Padding สำหรับปุ่มและขอบหน้าจอ
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.medium,
  );
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.large,
    vertical: AppSpacing.small,
  );
}

class AppTextStyles {
  // หัวข้อหลัก (DISHCOVERY!)
  static const TextStyle primaryTitle = TextStyle(
    fontFamily: 'inter',
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: AppColors.white,
  );

  // (DISHCOVERY!) ฟอนต์หัวข้อในตัวแอป
  static const TextStyle secondaryTitle = TextStyle(
    fontFamily: 'balooda',
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: AppColors.white,
  );

  // ข้อความ Description
  static TextStyle description = TextStyle(
    fontSize: 16,
    color: AppColors.white.withOpacity(0.8),
  );

  // ข้อความปุ่ม Sign In
  static const TextStyle buttonText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );
}
