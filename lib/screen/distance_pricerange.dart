import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:dishcovery_app/constants/gradient_text.dart';
import 'package:dishcovery_app/constants/app_init_screen.dart';
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

        // Navigate to SwipeScreen so user sees fresh recommendations
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SwipScreen()),
          (route) => false,
        );
      }
    } else {
      if (mounted) {
        // First login: trigger refresh and go through AppInitScreen loading
        RestaurantService.instance.forceRefreshRecommendations();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AppInitScreen()),
        );
      }
    }
  }

  Widget _buildDistanceCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDistanceHeader(),
          const SizedBox(height: 18),
          _buildDistanceSlider(),
          const SizedBox(height: 10),
          _buildDistanceScale(),
        ],
      ),
    );
  }

  Widget _buildDistanceHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GradientText(
          text: _formatDistance(_distanceValue),
          style: AppTextStyles.restaurantInDetails.copyWith(
            color: AppColors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.explore_outlined,
              size: 18,
              color: AppColors.primaryBlue,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _getDistanceDescription(_distanceValue),
                style: AppTextStyles.restaurantInDetails.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDistanceSlider() {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: AppColors.primaryBlue,
        inactiveTrackColor: Colors.grey.shade300,
        thumbColor: AppColors.black,
        overlayColor: AppColors.primaryBlue.withOpacity(0.15),
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      child: Slider(
        value: _distanceValue,
        min: 5.0,
        max: 50.0,
        onChanged: (double value) {
          setState(() {
            _distanceValue = value;
          });
        },
      ),
    );
  }

  Widget _buildDistanceScale() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "ใกล้",
          style: AppTextStyles.restaurantInDetails.copyWith(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Text(
          "กำลังดี",
          style: AppTextStyles.restaurantInDetails.copyWith(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Text(
          "ไกล",
          style: AppTextStyles.restaurantInDetails.copyWith(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  String _getDistanceDescription(double value) {
    if (value <= 10) {
      return "เน้นร้านใกล้ ๆ เดินทางสะดวก";
    } else if (value <= 25) {
      return "เพิ่มตัวเลือกมากขึ้นในย่านรอบตัวคุณ";
    } else if (value <= 40) {
      return "พร้อมลองร้านใหม่ในหลายพื้นที่";
    } else {
      return "เปิดรับร้านเด็ดทั่วเมือง";
    }
  }

  String _formatDistance(double value) {
    final rounded = value.round();

    if (rounded <= 5) {
      return "ใกล้มาก ($rounded km)";
    } else if (rounded <= 15) {
      return "ใกล้ ($rounded km)";
    } else if (rounded <= 30) {
      return "กำลังดี ($rounded km)";
    } else if (rounded < 50) {
      return "ไกลขึ้น ($rounded km)";
    } else {
      return "ไกลกว่า ($rounded km)";
    }
  }

  // String _getDistanceLabel(double value) {
  //   if (value >= 50.0) {
  //     return '> 50 KM';
  //   }
  //   return '${value.round()} KM';
  // }

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

                          GradientText(
                            text: 'ระยะทางที่สะดวกสำหรับคุณ',
                            style: AppTextStyles.signinText.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 45),

                          _buildDistanceCard(),

                          const SizedBox(height: 45),

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
                              final isSelected = _selectedPriceRanges.contains(
                                range,
                              );
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
                                activeThumbColor: AppColors.primaryBlue,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
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
