import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:dishcovery_app/constants/gradient_text.dart';
import 'package:dishcovery_app/screen/distance_pricerange.dart';
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
            backgroundColor: Colors.grey.shade900,
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
          backgroundColor: Colors.grey.shade900,
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
                  'กรุณาเลือกประเภทอาหารอย่างน้อย 1 ประเภท',
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
      RestaurantService.instance.updateCuisinePreferences(_selectedFoodTypes);
    }

    if (widget.isEditMode) {
      if (mounted) {
        // SwipeScreen will automatically re-fetch via the active listener in the service

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(seconds: 1),
            content: Text(
              'บันทึกค่าเรียบร้อยแล้ว! กำลังรีเฟรช...',
              style: AppTextStyles.profileText.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w100,
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to SwipeScreen so user sees the fresh recommendations
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SwipScreen()),
          (route) => false,
        );
      }
    } else {
      // นำทางไปยังหน้า DistancePriceRangeScreen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const DistancePriceRangeScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = chunkList(_foodOptions, 8);
    return Scaffold(
      // กำหนดสีพื้นหลังเป็นสีขาว
      backgroundColor: AppColors.white,

      appBar: widget.isEditMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: AppColors.black),
                onPressed: () => Navigator.pop(context),
              ),
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
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth,
                      ),
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
                                  style: AppTextStyles.secondaryTitle
                                      .copyWith(),
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

                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(rows.length, (rowIndex) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Wrap(
                                    spacing: 10,
                                    children: rows[rowIndex].map((option) {
                                      final String name = option['name'];
                                      final IconData icon = option['icon'];
                                      final bool isSelected = _selectedFoodTypes
                                          .contains(name);

                                      return ChoiceChip(
                                        showCheckmark: false,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        labelPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                        label: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(icon, size: 18),
                                            const SizedBox(width: 4),
                                            Text(
                                              name,
                                              style: AppTextStyles.signinText
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
                                        onSelected: (_) =>
                                            _toggleFoodSelection(name),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          side: BorderSide(
                                            color: isSelected
                                                ? AppColors.primaryBlue
                                                : AppColors.black,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 8,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // 6. ปุ่ม NEXT (ติดขอบล่าง)
          Container(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: 30,
              top: 10,
            ),
            color: AppColors.white,
            child: SizedBox(
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
          ),
        ],
      ),
    );
  }
}
