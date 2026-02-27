import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:dishcovery_app/constants/gradient_text.dart';
import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:dishcovery_app/models/restaurant_details_model.dart';
import 'package:dishcovery_app/services/restaurant_service.dart';
import 'package:dishcovery_app/constants/app_init_screen.dart';

class ManageHoursScreen extends StatefulWidget {
  final RestaurantDetailsData restaurant;

  const ManageHoursScreen({super.key, required this.restaurant});

  @override
  State<ManageHoursScreen> createState() => _ManageHoursScreenState();
}

class _ManageHoursScreenState extends State<ManageHoursScreen> {
  bool _isLoading = false;
  late bool _isTemporarilyClosed;
  late Map<String, dynamic> _openingHours;

  @override
  void initState() {
    super.initState();
    _isTemporarilyClosed = widget.restaurant.isTemporarilyClosed;
    // Deep copy opening hours
    _openingHours = Map<String, dynamic>.from(widget.restaurant.openingHours);
  }

  Future<void> _toggleTemporaryClosure(bool value) async {
    if (value) {
      // Show confirm dialog
      bool confirm =
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                "ปิดร้านชั่วคราว",
                style: AppTextStyles.profileText.copyWith(fontSize: 18),
              ),
              content: Text(
                "คุณแน่ใจหรือไม่ว่าต้องการหยุดรับลูกค้าชั่วคราว?",
                style: AppTextStyles.profileText.copyWith(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text("ยกเลิก", style: AppTextStyles.profileText),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    "ยืนยัน",
                    style: AppTextStyles.profileText.copyWith(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirm) return;
    }

    setState(() {
      _isTemporarilyClosed = value;
      _isLoading = true;
    });

    try {
      await RestaurantService.instance.updateRestaurantTemporarilyClosed(
        widget.restaurant.id,
        value,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('บันทึกสำเร็จ')));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTemporarilyClosed = !value;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  final List<String> _days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  final List<String> _thDays = [
    'จันทร์',
    'อังคาร',
    'พุธ',
    'พฤหัสบดี',
    'ศุกร์',
    'เสาร์',
    'อาทิตย์',
  ];

  void _showTimePicker3Wheels() {
    final List<String> dayOptions = [
      'ทุกวัน',
      'เสาร์ - อาทิตย์',
      'จันทร์',
      'อังคาร',
      'พุธ',
      'พฤหัสบดี',
      'ศุกร์',
      'เสาร์',
      'อาทิตย์',
    ];

    List<String> times = [];
    for (int h = 0; h < 24; h++) {
      times.add('${h.toString().padLeft(2, '0')}:00');
      times.add('${h.toString().padLeft(2, '0')}:30');
    }

    int selectedDayIdx = 0;
    int selectedOpenIdx = 18; // 09:00
    int selectedCloseIdx = 40; // 20:00

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: 350,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'ยกเลิก',
                      style: AppTextStyles.profileText.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final selDay = dayOptions[selectedDayIdx];
                      final selOpen = times[selectedOpenIdx];
                      final selClose = times[selectedCloseIdx];

                      List<String> daysToUpdate = [];
                      if (selDay == 'ทุกวัน') {
                        daysToUpdate = [
                          'mon',
                          'tue',
                          'wed',
                          'thu',
                          'fri',
                          'sat',
                          'sun',
                        ];
                      } else if (selDay == 'เสาร์ - อาทิตย์') {
                        daysToUpdate = ['sat', 'sun'];
                      } else if (selDay == 'จันทร์') {
                        daysToUpdate = ['mon'];
                      } else if (selDay == 'อังคาร') {
                        daysToUpdate = ['tue'];
                      } else if (selDay == 'พุธ') {
                        daysToUpdate = ['wed'];
                      } else if (selDay == 'พฤหัสบดี') {
                        daysToUpdate = ['thu'];
                      } else if (selDay == 'ศุกร์') {
                        daysToUpdate = ['fri'];
                      } else if (selDay == 'เสาร์') {
                        daysToUpdate = ['sat'];
                      } else if (selDay == 'อาทิตย์') {
                        daysToUpdate = ['sun'];
                      }

                      setState(() {
                        for (var d in daysToUpdate) {
                          _openingHours[d] = [
                            {'open': selOpen, 'close': selClose},
                          ];
                        }
                      });
                      Navigator.pop(context);
                    },
                    child: Text(
                      'แก้ไข',
                      style: AppTextStyles.profileText.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: selectedDayIdx,
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (idx) => selectedDayIdx = idx,
                        children: dayOptions
                            .map(
                              (d) => Center(
                                child: Text(
                                  d,
                                  style: AppTextStyles.profileText.copyWith(
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: selectedOpenIdx,
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (idx) => selectedOpenIdx = idx,
                        children: times
                            .map(
                              (t) => Center(
                                child: Text(
                                  t,
                                  style: AppTextStyles.profileText.copyWith(
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const Center(
                      child: Text(
                        ' - ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: selectedCloseIdx,
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (idx) => selectedCloseIdx = idx,
                        children: times
                            .map(
                              (t) => Center(
                                child: Text(
                                  t,
                                  style: AppTextStyles.profileText.copyWith(
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveHours() async {
    final updatedRestaurant = widget.restaurant.copyWith(
      openingHours: _openingHours,
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppInitUpdateData(
          onUpdate: () => RestaurantService.instance.updateRestaurantInfo(
            updatedRestaurant,
          ),
        ),
      ),
    );

    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกเวลาเปิด-ปิดสำเร็จ')),
        );
        Navigator.pop(context);
      }
    } else if (result != null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $result')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: GradientText(
          text: "เวลาเปิด - ปิดร้าน",
          style: AppTextStyles.profileText.copyWith(fontSize: 20),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SwitchListTile(
                title: Text(
                  "ปิดร้านชั่วคราว",
                  style: AppTextStyles.profileText.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  "หยุดรับลูกค้าชั่วคราว",
                  style: AppTextStyles.profileText.copyWith(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                value: _isTemporarilyClosed,
                onChanged: _isLoading ? null : _toggleTemporaryClosure,
                activeThumbColor: AppColors.primaryBlue,
              ),
              const Divider(),
              const SizedBox(height: 20),
              // Current Working Hours Display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "เวลาทำการปัจจุบัน",
                    style: AppTextStyles.profileText.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      'แก้ไข',
                      style: AppTextStyles.profileText.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: _showTimePicker3Wheels,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (() {
                bool hasOpen = false;
                for (var v in _openingHours.values) {
                  if (v is List && v.isNotEmpty) {
                    hasOpen = true;
                  } else if (v is Map && v['isClosed'] == false) {
                    hasOpen = true;
                  }
                }
                return hasOpen;
              }())
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: () {
                      List<Widget> rows = [];
                      for (int i = 0; i < _days.length; i++) {
                        final d = _days[i];
                        final val = _openingHours[d];
                        bool isOpen = false;
                        String openTime = '';
                        String closeTime = '';

                        if (val != null) {
                          if (val is List && val.isNotEmpty) {
                            isOpen = true;
                            openTime = val.first['open'];
                            closeTime = val.first['close'];
                          } else if (val is Map && val['isClosed'] == false) {
                            isOpen = true;
                            openTime = val['open'];
                            closeTime = val['close'];
                          }
                        }

                        if (isOpen) {
                          rows.add(
                            ListTile(
                              title: Text(
                                _thDays[i],
                                style: AppTextStyles.profileText.copyWith(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$openTime - $closeTime',
                                    style: AppTextStyles.profileText.copyWith(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  IconButton(
                                    alignment: Alignment.centerRight,
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                      size: 14,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _openingHours[d] =
                                            []; // list empty means closed
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                          rows.add(
                            const Divider(height: 1, indent: 16, endIndent: 16),
                          );
                        }
                      }
                      if (rows.isNotEmpty)
                        rows.removeLast(); // remove trailing divider
                      return rows;
                    }(),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'ยังไม่ได้กำหนดเวลาเปิด-ปิด',
                      style: AppTextStyles.profileText.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveHours,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  "บันทึกข้อมูล",
                  style: AppTextStyles.profileText.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
