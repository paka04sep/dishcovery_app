import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:dishcovery_app/constants/gradient_text.dart';
import 'package:dishcovery_app/screen/swipescreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dishcovery_app/services/restaurant_service.dart';

class DistancePriceRangeScreen extends StatefulWidget {
  final bool isEditMode;
  const DistancePriceRangeScreen({super.key, this.isEditMode = false});

  @override
  State<DistancePriceRangeScreen> createState() =>
      _DistancePriceRangeScreenState();
}

class _DistancePriceRangeScreenState extends State<DistancePriceRangeScreen> {
  double _distanceValue = 25.0;
  List<String> _selectedPriceRanges = [];
  bool _showClosedRestaurants = false;

  final List<String> _priceRanges = [
    '฿ ถูกกว่า 100',
    '฿฿ 100-250',
    '฿฿฿ 251-500',
    '฿฿฿฿ 500+',
    // '฿฿฿฿฿ 1,000+',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
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
            if (data['distancePreference'] != null) {
              _distanceValue = (data['distancePreference'] as num).toDouble();
            }
            if (data['priceRangePreference'] != null) {
              _selectedPriceRanges = List<String>.from(
                data['priceRangePreference'],
              );
            }
            if (data['showClosedRestaurants'] != null) {
              _showClosedRestaurants = data['showClosedRestaurants'] as bool;
            }
          });
        }
      }
    }
  }

  void _togglePriceRange(String priceRange) {
    setState(() {
      if (_selectedPriceRanges.contains(priceRange)) {
        _selectedPriceRanges.remove(priceRange);
      } else {
        _selectedPriceRanges.add(priceRange);
      }
    });
  }

  Future<void> _goToNextScreen() async {
    if (_selectedPriceRanges.isEmpty) {
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
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'กรุณาเลือกเรทราคาอย่างน้อย 1 ตัวเลือก',
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

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final Map<String, dynamic> updateData = {
        'distancePreference': _distanceValue,
        'priceRangePreference': _selectedPriceRanges,
        'showClosedRestaurants': _showClosedRestaurants,
      };

      if (!widget.isEditMode) {
        updateData['isFirstLogin'] = false;
        updateData['email'] = user.email;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(updateData, SetOptions(merge: true));

      RestaurantService.instance.updateDistanceAndPriceRange(
        _distanceValue,
        _selectedPriceRanges,
        _showClosedRestaurants,
      );
    }

    if (widget.isEditMode) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(seconds: 1),
            content: Text(
              'บันทึกค่าเรียบร้อยแล้ว!',
              style: AppTextStyles.profileText.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w100,
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SwipScreen()),
        );
      }
    }
  }

  String _getDistanceLabel(double value) {
    if (value >= 50.0) {
      return '> 50 KM';
    }
    return '${value.round()} KM';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: widget.isEditMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: AppColors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: GradientText(
                text: 'ปรับการค้นหาร้านอาหาร',
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
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: widget.isEditMode ? 8 : 35),
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

                    GradientText(
                      text: 'ระยะทางที่สะดวกสำหรับคุณ',
                      style: AppTextStyles.signinText.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 55),

                    Column(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final trackWidth = constraints.maxWidth;
                            const double minDistance = 5.0;
                            const double maxDistance = 50.0;
                            final double ratio =
                                (_distanceValue - minDistance) /
                                (maxDistance - minDistance);
                            const double iconSize = 30;
                            final double position =
                                (trackWidth * ratio) - (iconSize / 2);

                            return SizedBox(
                              height: iconSize,
                              width: double.infinity,
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: position.clamp(
                                      0.0,
                                      trackWidth - iconSize,
                                    ),
                                    child: const Icon(
                                      Icons.person_pin_circle_rounded,
                                      color: AppColors.black,
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
                            thumbColor: AppColors.black,
                            overlayColor: AppColors.primaryBlue.withOpacity(
                              0.2,
                            ),
                            trackHeight: 6.0,
                            valueIndicatorColor: AppColors.primaryBlue,
                          ),
                          child: Slider(
                            value: _distanceValue,
                            min: 5.0,
                            max: 50.0,
                            label: _getDistanceLabel(_distanceValue),
                            onChanged: (double newValue) {
                              setState(() {
                                _distanceValue = newValue;
                              });
                            },
                          ),
                        ),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final trackWidth = constraints.maxWidth;
                            const double minDistance = 5.0;
                            const double maxDistance = 50.0;
                            final double ratio =
                                (_distanceValue - minDistance) /
                                (maxDistance - minDistance);
                            const double textWidthApprox = 50.0;
                            final double position =
                                (trackWidth * ratio) - (textWidthApprox / 2);

                            return SizedBox(
                              height: 20,
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
                    const SizedBox(height: 65),

                    GradientText(
                      text: 'เรทราคาที่คุณต้องการ',
                      style: AppTextStyles.signinText.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 25),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _priceRanges.map((range) {
                        final isSelected = _selectedPriceRanges.contains(range);
                        return ChoiceChip(
                          showCheckmark: false,
                          label: Text(
                            range,
                            style: AppTextStyles.signinText.copyWith(
                              color: AppColors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.lightBlue,
                          backgroundColor: AppColors.white,
                          onSelected: (_) => _togglePriceRange(range),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : AppColors.black,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 45),

                    if (widget.isEditMode) ...[
                      GradientText(
                        text: 'แสดงร้านอาหารทั้งหมด',
                        style: AppTextStyles.signinText.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 25),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: SwitchListTile(
                          title: Text(
                            'แสดงร้านที่ปิดแล้ว',
                            style: AppTextStyles.profileText.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                          subtitle: Text(
                            'หากเปิดจะแสดงร้านที่ปิดอยู่ด้วย',
                            style: AppTextStyles.profileText.copyWith(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          value: _showClosedRestaurants,
                          onChanged: (bool value) {
                            setState(() {
                              _showClosedRestaurants = value;
                            });
                          },
                          activeColor: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: 50,
              top: 10,
            ),
            color: AppColors.white,
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _goToNextScreen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 15,
                ),
                child: Text(
                  widget.isEditMode ? 'บันทึกค่า' : 'เริ่มค้นหาร้านอาหาร!',
                  style: AppTextStyles.signinText.copyWith(
                    fontSize: 20,
                    color: AppColors.black,
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
