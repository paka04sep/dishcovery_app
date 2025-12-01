import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:dishcovery_app/constants/gradient_text.dart';
import 'package:dishcovery_app/screen/swipescreen.dart';
import 'package:flutter/material.dart';

class FoodPreferenceScreen extends StatefulWidget {
  const FoodPreferenceScreen({super.key});

  @override
  State<FoodPreferenceScreen> createState() => _FoodPreferenceScreenState();
}

class _FoodPreferenceScreenState extends State<FoodPreferenceScreen> {
  // สถานะสำหรับเก็บประเภทอาหารที่เลือก (สูงสุด 5 อย่าง)
  final List<String> _selectedFoodTypes = [];
  // สถานะสำหรับเก็บค่า Slider (เริ่มต้นที่ 25.0 KM)
  double _distanceValue = 25.0;
  final int _maxSelection = 5;

  // รายการตัวเลือกอาหารพร้อมไอคอน
  final List<Map<String, dynamic>> _foodOptions = [
    {'name': 'Thai Food', 'icon': Icons.ramen_dining_rounded},
    {'name': 'Fast Food', 'icon': Icons.fastfood_rounded},
    {'name': 'Noodles', 'icon': Icons.set_meal_rounded},
    {'name': 'Seafood', 'icon': Icons.restaurant_menu_rounded},
    {'name': 'Bakery', 'icon': Icons.cake_rounded},
    {'name': 'Japanese', 'icon': Icons.rice_bowl_rounded},
    // สามารถเพิ่มตัวเลือกอื่น ๆ ได้
    {'name': 'Coffee & Tea', 'icon': Icons.local_cafe_rounded},
    {'name': 'Healthy', 'icon': Icons.local_florist_rounded},
    {'name': 'egg', 'icon': Icons.egg},
    {'name': 'cookie', 'icon': Icons.cookie},
    {'name': 'upcoming', 'icon': Icons.upcoming},
    {'name': 'upcoming', 'icon': Icons.upcoming},
  ];

  // ฟังก์ชันจัดการการเลือกชิปอาหาร
  void _toggleFoodSelection(String foodType) {
    setState(() {
      if (_selectedFoodTypes.contains(foodType)) {
        _selectedFoodTypes.remove(foodType);
      } else if (_selectedFoodTypes.length < _maxSelection) {
        _selectedFoodTypes.add(foodType);
      } else {
        // หากเกิน 5 ชนิด ให้แสดงข้อความแจ้งเตือน (แทนการใช้ alert)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เลือกได้สูงสุดเพียง $_maxSelection ประเภทเท่านั้น!'),
            duration: const Duration(seconds: 1),
            backgroundColor: AppColors.midblue,
          ),
        );
      }
    });
  }

  // ฟังก์ชันจัดการปุ่ม NEXT
  void _goToNextScreen() {
    if (_selectedFoodTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('โปรดเลือกประเภทอาหารที่คุณชื่นชอบอย่างน้อย 1 ประเภท'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // นำทางไปยังหน้าหลัก (HomePage)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SwipScreen()),
    );
  }

  // ฟังก์ชันแปลงค่า Slider เป็นข้อความ (ใช้ภาษาอังกฤษ)
  String _getDistanceLabel(double value) {
    // 50KM+
    if (value >= 50.0) {
      return '> 50 KM';
    }
    // ปัดเศษให้เป็นจำนวนเต็มสำหรับค่า KM
    return '${value.round()} KM';
  }

  @override
  Widget build(BuildContext context) {
    // กำหนด Font Family ถ้ามีการตั้งค่าใน Theme
    final String? fontFamily = Theme.of(
      context,
    ).textTheme.bodyLarge?.fontFamily;

    return Scaffold(
      // กำหนดสีพื้นหลังเป็นสีขาว
      backgroundColor: AppColors.white,
      // ลบ AppBar
      // appBar: AppBar(
      //   title: const Text('MAIN SCREEN'),
      //   backgroundColor: AppColors.darkBackground,
      //   foregroundColor: AppColors.white,
      // ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 35),
              // 1. Header (Logo & Title) - อยู่ด้านบนสุด
              Row(
                children: [
                  Image.asset(
                    'assets/images/logo1.0circle.png',
                    width: 36,
                    height: 36,
                  ),
                  const SizedBox(width: 10),
                  GradientText(
                    text: 'DISHCOVERY!',
                    style: AppTextStyles.secondaryTitle.copyWith(),
                  ),
                ],
              ),
              const SizedBox(height: 35),

              // 2. ส่วนเลือกประเภทอาหาร
              GradientText(
                text:
                    'Choose your favorite type food (${_selectedFoodTypes.length}/$_maxSelection)',
                style: AppTextStyles.secondaryTitle.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(height: 15),

              // ใช้ Wrap เพื่อจัดเรียง Chip ให้พอดีกับหน้าจอ
              Wrap(
                spacing: 8.0, // ระยะห่างแนวนอน
                runSpacing: 8.0, // ระยะห่างแนวตั้ง
                children: _foodOptions.map((option) {
                  final String name = option['name'];
                  final IconData icon = option['icon'];
                  final bool isSelected = _selectedFoodTypes.contains(name);

                  return ChoiceChip(
                    showCheckmark: false,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 18,
                          color: isSelected ? AppColors.black : AppColors.black,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          name,
                          style: AppTextStyles.description.copyWith(
                            color: isSelected
                                ? AppColors.black
                                : AppColors.black,
                            fontSize: 16,
                            fontFamily: 'balooda',
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.lightBlue,
                    backgroundColor: AppColors.white,
                    onSelected: (selected) => _toggleFoodSelection(name),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : AppColors.black,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 15,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 25),

              // 3. ส่วนเลือกความชอบระยะทาง
              GradientText(
                text: 'What is your preferred distance?',
                style: AppTextStyles.secondaryTitle.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(height: 35),

              // Slider สำหรับเลือกระยะทาง (5KM ถึง 50KM+)
              Column(
                children: [
                  // 💡 5. ไอคอนบ่งบอกระยะแบบเคลื่อนที่ (อยู่ด้านบน) 💡
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // ความกว้างที่ใช้ได้สำหรับ Slider (Track Width)
                      final trackWidth = constraints.maxWidth;
                      // ระยะ min/max ของ Slider
                      const double minDistance = 5.0;
                      const double maxDistance = 50.0;
                      // คำนวณตำแหน่ง (0.0 ถึง 1.0)
                      final double ratio =
                          (_distanceValue - minDistance) /
                          (maxDistance - minDistance);

                      // ตำแหน่ง Pixel สำหรับ Icon (ลบขนาด Icon ออกครึ่งหนึ่งเพื่อให้ Icon อยู่กึ่งกลาง)
                      const double iconSize = 30;
                      // ปรับค่า position เล็กน้อยเพื่อชดเชย padding ของ Slider
                      final double position =
                          (trackWidth * ratio) - (iconSize / 2);

                      return SizedBox(
                        height: iconSize,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            Positioned(
                              left: position.clamp(0.0, trackWidth - iconSize),
                              child: const Icon(
                                Icons.person_pin_circle_rounded,
                                color:
                                    AppColors.black, // เปลี่ยนสีให้เป็นสีเด่น
                                size: iconSize,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primaryBlue,
                      inactiveTrackColor: AppColors.black,
                      thumbColor: AppColors.black, // เปลี่ยนเป็นสีดำให้เห็นชัด
                      overlayColor: AppColors.primaryBlue.withOpacity(0.2),
                      trackHeight: 6.0,
                      valueIndicatorColor: AppColors.primaryBlue,
                    ),
                    child: Slider(
                      value: _distanceValue,
                      min: 5.0, // เริ่มที่ 5 KM
                      max: 50.0, // สิ้นสุดที่ 50 KM (แสดงผลเป็น 50 KM+)
                      label: _getDistanceLabel(_distanceValue),
                      onChanged: (double newValue) {
                        setState(() {
                          _distanceValue = newValue;
                        });
                      },
                    ),
                  ),

                  // 💡 6. ข้อความแสดงระยะทางแบบเคลื่อนที่ (อยู่ด้านล่าง Slider) 💡
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final trackWidth = constraints.maxWidth;
                      const double minDistance = 5.0;
                      const double maxDistance = 50.0;
                      final double ratio =
                          (_distanceValue - minDistance) /
                          (maxDistance - minDistance);

                      // ประมาณความกว้างของข้อความ (Text) เพื่อการจัดกึ่งกลาง
                      const double textWidthApprox = 50.0;
                      // คำนวณตำแหน่งให้กึ่งกลางข้อความอยู่ใต้ Thumb
                      final double position =
                          (trackWidth * ratio) - (textWidthApprox / 2);

                      return SizedBox(
                        height: 20, // ความสูงสำหรับข้อความ
                        width: double.infinity,
                        child: Stack(
                          children: [
                            Positioned(
                              left: position.clamp(
                                0.0,
                                trackWidth - textWidthApprox,
                              ),
                              child: Text(
                                _getDistanceLabel(_distanceValue),
                                style: AppTextStyles.buttonText.copyWith(
                                  color: AppColors.black,
                                  fontFamily: fontFamily,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 55),

              // 6. ปุ่ม NEXT
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _goToNextScreen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white, // เปลี่ยนเป็นปุ่มสีดำ
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 15,
                  ),
                  child: Text(
                    'NEXT',
                    style: AppTextStyles.buttonText.copyWith(
                      fontFamily: fontFamily,
                      color: AppColors.black, // ข้อความเป็นสีขาวบนปุ่มสีดำ
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
