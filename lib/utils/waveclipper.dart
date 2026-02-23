import 'package:flutter/material.dart';

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    double radius = 55.0; // ปรับความมนของมุมซ้าย-ขวาตรงนี้ (ยิ่งมากยิ่งมน)

    // 1. เริ่มจากมุมซ้ายล่างขึ้นไปจนถึงจุดเริ่มโค้งของมุมซ้ายบน
    path.moveTo(0, size.height);
    path.lineTo(0, radius);

    // 2. วาดโค้งมุมซ้ายบน
    // controlPoint คือมุมแหลมเดิม (0,0), endPoint คือจุดที่เริ่มเป็นเส้นตรงด้านบน
    path.quadraticBezierTo(0, 0, radius, 0);

    // 3. ลากเส้นตรงยาวไปจนถึงจุดเริ่มโค้งของมุมขวาบน
    path.lineTo(size.width - radius, 0);

    // 4. วาดโค้งมุมขวาบน
    path.quadraticBezierTo(size.width, 0, size.width, radius);

    // 5. ลากเส้นตรงลงไปปิดที่มุมขวาล่าง
    path.lineTo(size.width, size.height);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
