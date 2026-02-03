import 'package:flutter/material.dart';

// --- App Configuration ---
class AppConfig {
  // เปลี่ยนเป็น true เพื่อใช้ Mock Data (ไม่เปลือง Quota API)
  // เปลี่ยนเป็น false เพื่อใช้ Google Places API (ข้อมูลจริง)
  static const bool useMockData = false;
}

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

  // ข้อความชื่อร้านหน้าการ์ด
  static const TextStyle restaurantName = TextStyle(
    fontFamily: 'Sukumvit',
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  // ข้อความรายละเอียดชื่อร้านหน้าการ์ด
  static const TextStyle restaurantDetails = TextStyle(
    fontFamily: 'Sukumvit',
    fontSize: 18,
    color: AppColors.white,
  );

  // ข้อความรายละเอียดชื่อร้านในการ์ด
  static const TextStyle restaurantInDetails = TextStyle(
    fontFamily: 'Sukumvit',
    fontSize: 16,
    color: AppColors.white,
  );

  // ข้อความชื่อเมนูอาหาร
  static const TextStyle restaurantMenuItemName = TextStyle(
    fontFamily: 'Sukumvit',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );

  // ข้อความ refresh
  static const TextStyle refreshText = TextStyle(
    fontFamily: 'Sukumvit',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.grey,
  );
}
