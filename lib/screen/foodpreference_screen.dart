import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:dishcovery_app/constants/gradient_text.dart';
import 'package:dishcovery_app/screen/swipescreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dishcovery_app/services/restaurant_service.dart';

class FoodPreferenceScreen extends StatefulWidget {
  final bool isEditMode;
  const FoodPreferenceScreen({super.key, this.isEditMode = false});

  @override
  State<FoodPreferenceScreen> createState() => _FoodPreferenceScreenState();
}

class _FoodPreferenceScreenState extends State<FoodPreferenceScreen> {
  // สถานะสำหรับเก็บประเภทอาหารที่เลือก (สูงสุด 5 อย่าง)
  final List<String> _selectedFoodTypes = [];
  // สถานะสำหรับเก็บค่า Slider (เริ่มต้นที่ 25.0 KM)
  double _distanceValue = 25.0;
  final int _maxSelection = 5;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      _loadUserPreferences();
    }
  }

  Future<void> _loadUserPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            if (data['preferences'] != null) {
              _selectedFoodTypes.addAll(List<String>.from(data['preferences']));
            }
            if (data['distancePreference'] != null) {
              _distanceValue = (data['distancePreference'] as num).toDouble();
            }
          });
        }
      }
    }
  }

  // รายการตัวเลือกอาหารพร้อมไอคอน
  final List<Map<String, dynamic>> _foodOptions = [
    {'name': 'อาหารไทย', 'icon': Icons.ramen_dining_rounded},
    {'name': 'อาหารอีสาน', 'icon': Icons.local_fire_department_rounded},
    {'name': 'อาหารเหนือ', 'icon': Icons.terrain_rounded},
    {'name': 'อาหารใต้', 'icon': Icons.waves_rounded},

    {'name': 'อาหารญี่ปุ่น', 'icon': Icons.rice_bowl_rounded},
    {'name': 'อาหารเกาหลี', 'icon': Icons.restaurant_rounded},
    {'name': 'อาหารจีน', 'icon': Icons.set_meal_rounded},
    {'name': 'อาหารตะวันตก', 'icon': Icons.dinner_dining_rounded},

    {'name': 'ฟาสต์ฟู้ด', 'icon': Icons.fastfood_rounded},
    {'name': 'เบอร์เกอร์', 'icon': Icons.lunch_dining_rounded},
    {'name': 'พิซซ่า', 'icon': Icons.local_pizza_rounded},
    {'name': 'ไก่ทอด', 'icon': Icons.restaurant_menu_rounded},

    {'name': 'ก๋วยเตี๋ยว', 'icon': Icons.ramen_dining},
    {'name': 'ข้าวแกง', 'icon': Icons.rice_bowl},
    {'name': 'ข้าวมันไก่', 'icon': Icons.set_meal},
    {'name': 'อาหารตามสั่ง', 'icon': Icons.restaurant},

    {'name': 'ส้มตำ ไก่ย่าง', 'icon': Icons.food_bank},
    {'name': 'ปิ้งย่าง', 'icon': Icons.outdoor_grill_rounded},
    {'name': 'ชาบู / สุกี้', 'icon': Icons.soup_kitchen_rounded},

    {'name': 'เบเกอรี่', 'icon': Icons.cake_rounded},
    {'name': 'ของหวาน', 'icon': Icons.icecream_rounded},
    {'name': 'ไอศกรีม', 'icon': Icons.icecream},
    {'name': 'เครป', 'icon': Icons.egg},

    {'name': 'กาแฟ', 'icon': Icons.local_cafe_rounded},
    {'name': 'ชา / ชานม', 'icon': Icons.emoji_food_beverage_rounded},
    {'name': 'เครื่องดื่ม', 'icon': Icons.local_drink_rounded},

    {'name': 'อาหารเพื่อสุขภาพ', 'icon': Icons.eco_rounded},
    {'name': 'มังสวิรัติ', 'icon': Icons.grass_rounded},
    {'name': 'คลีน', 'icon': Icons.spa_rounded},
  ];

  List<List<T>> chunkList<T>(List<T> list, int chunkCount) {
    final chunks = List.generate(chunkCount, (_) => <T>[]);
    for (var i = 0; i < list.length; i++) {
      chunks[i % chunkCount].add(list[i]);
    }
    return chunks;
  }

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
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            backgroundColor: AppColors.midblue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'เลือกได้สูงสุด $_maxSelection ประเภทเท่านั้น',
                    style: AppTextStyles.refreshText.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });
  }

  // ฟังก์ชันจัดการปุ่ม NEXT
  Future<void> _goToNextScreen() async {
    if (_selectedFoodTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          backgroundColor: Colors.orange.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'กรุณาเลือกประเภทอาหารที่คุณชื่นชอบอย่างน้อย 1 ประเภทก่อนดำเนินการต่อ',
                  style: AppTextStyles.refreshText.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // Update user profile in Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Data to update
      final Map<String, dynamic> updateData = {
        'preferences': _selectedFoodTypes,
        'distancePreference': _distanceValue,
      };

      if (!widget.isEditMode) {
        updateData['isFirstLogin'] = false;
        updateData['email'] = user.email;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(updateData, SetOptions(merge: true));

      // Update local service state immediately
      RestaurantService.instance.updatePreferences(
        _selectedFoodTypes,
        _distanceValue,
      );
    }

    if (widget.isEditMode) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Preferences saved!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      // นำทางไปยังหน้าหลัก (HomePage)
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SwipScreen()),
        );
      }
    }
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
    final rows = chunkList(_foodOptions, 5);

    return Scaffold(
      // กำหนดสีพื้นหลังเป็นสีขาว
      backgroundColor: AppColors.white,
      appBar: widget.isEditMode
          ? AppBar(
              title: GradientText(
                text: 'แก้ไขประเภทอาหารที่คุณชอบ',
                style: AppTextStyles.signinText.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            )
          : null,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: widget.isEditMode ? 8 : 35),
              // 1. Header (Logo & Title) - อยู่ด้านบนสุด
              if (!widget.isEditMode) ...[
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
              ],

              // 2. ส่วนเลือกประเภทอาหาร
              GradientText(
                text:
                    'ประเภทอาหารที่คุณชอบ (${_selectedFoodTypes.length}/$_maxSelection)',
                style: AppTextStyles.signinText.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),

              // ใช้ Wrap เพื่อจัดเรียง Chip ให้พอดีกับหน้าจอ
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(rows.length, (rowIndex) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        spacing: 10, //  ระยะห่างแนวนอน (เล็กลง ดูชิดขึ้น)
                        children: rows[rowIndex].map((option) {
                          final String name = option['name'];
                          final IconData icon = option['icon'];
                          final bool isSelected = _selectedFoodTypes.contains(
                            name,
                          );

                          return ChoiceChip(
                            showCheckmark: false,
                            materialTapTargetSize: MaterialTapTargetSize
                                .shrinkWrap, //   ลดพื้นที่แฝง
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                            ),
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  name,
                                  style: AppTextStyles.restaurantDetails
                                      .copyWith(
                                        color: AppColors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.lightBlue,
                            backgroundColor: AppColors.white,
                            onSelected: (_) => _toggleFoodSelection(name),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : AppColors.black,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 10,
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 35),

              // 3. ส่วนเลือกความชอบระยะทาง
              GradientText(
                text: 'ระยะทางที่สะดวกสำหรับคุณ',
                style: AppTextStyles.signinText.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 35),

              // Slider สำหรับเลือกระยะทาง (5KM ถึง 50KM+)
              Column(
                children: [
                  //  5. ไอคอนบ่งบอกระยะแบบเคลื่อนที่ (อยู่ด้านบน)
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

                  //  6. ข้อความแสดงระยะทางแบบเคลื่อนที่ (อยู่ด้านล่าง Slider)
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
                    widget.isEditMode ? 'บันทึกค่า' : 'ต่อไป',
                    style: AppTextStyles.signinText.copyWith(
                      fontSize: 20,
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
