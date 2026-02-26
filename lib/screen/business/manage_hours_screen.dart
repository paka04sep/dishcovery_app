import 'package:dishcovery_app/constants/gradient_text.dart';
import 'package:flutter/material.dart';
import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:dishcovery_app/models/restaurant_details_model.dart';
import 'package:dishcovery_app/services/restaurant_service.dart';

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

  Future<TimeOfDay?> _selectTime(
    BuildContext context,
    String currentStr,
  ) async {
    final timeParts = currentStr.split(':');
    final current = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );
    return await showTimePicker(context: context, initialTime: current);
  }

  void _openHoursPicker() {
    // copy to local state for modal
    Map<String, dynamic> tempHours = Map<String, dynamic>.from(
      _openingHours.map((k, v) {
        if (v is List) {
          if (v.isEmpty) {
            return MapEntry(k, {
              'open': '09:00',
              'close': '20:00',
              'isClosed': true,
            });
          }
          return MapEntry(k, {
            'open': v.first['open'],
            'close': v.first['close'],
            'isClosed': false,
          });
        }
        return MapEntry(k, Map<String, dynamic>.from(v));
      }),
    );

    // Initialize defaults if any day is missing
    for (var day in _days) {
      if (!tempHours.containsKey(day)) {
        tempHours[day] = {'open': '09:00', 'close': '20:00', 'isClosed': true};
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'ตั้งเวลาเปิด-ปิดร้าน',
                    style: AppTextStyles.profileText.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _days.length,
                      itemBuilder: (context, index) {
                        String day = _days[index];
                        String thDay = _thDays[index];
                        bool isClosed = tempHours[day]['isClosed'];
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: 70,
                                  child: Text(
                                    thDay,
                                    style: AppTextStyles.profileText.copyWith(
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: !isClosed,
                                  activeColor: AppColors.primaryBlue,
                                  onChanged: (val) => setModalState(
                                    () => tempHours[day]['isClosed'] = !val,
                                  ),
                                ),
                                if (!isClosed)
                                  Row(
                                    children: [
                                      TextButton(
                                        onPressed: () async {
                                          final picked = await _selectTime(
                                            context,
                                            tempHours[day]['open'],
                                          );
                                          if (picked != null) {
                                            setModalState(
                                              () => tempHours[day]['open'] =
                                                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
                                            );
                                          }
                                        },
                                        child: Text(
                                          tempHours[day]['open'],
                                          style: AppTextStyles.profileText
                                              .copyWith(
                                                color: Colors.grey[800],
                                              ),
                                        ),
                                      ),
                                      const Text('-'),
                                      TextButton(
                                        onPressed: () async {
                                          final picked = await _selectTime(
                                            context,
                                            tempHours[day]['close'],
                                          );
                                          if (picked != null) {
                                            setModalState(
                                              () => tempHours[day]['close'] =
                                                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
                                            );
                                          }
                                        },
                                        child: Text(
                                          tempHours[day]['close'],
                                          style: AppTextStyles.profileText
                                              .copyWith(
                                                color: Colors.grey[800],
                                              ),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Text(
                                    ' ปิดทำการ',
                                    style: AppTextStyles.profileText.copyWith(
                                      color: Colors.red,
                                    ),
                                  ),
                              ],
                            ),
                            const Divider(),
                          ],
                        );
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        Map<String, dynamic> formattedHours = {};
                        for (var day in _days) {
                          if (tempHours[day]['isClosed']) {
                            formattedHours[day] = []; // Empty list means closed
                          } else {
                            formattedHours[day] = [
                              {
                                'open': tempHours[day]['open'],
                                'close': tempHours[day]['close'],
                              },
                            ];
                          }
                        }
                        _openingHours = formattedHours;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'ตกลง',
                      style: AppTextStyles.signinText.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveHours() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedRestaurant = widget.restaurant.copyWith(
        openingHours: _openingHours,
      );

      await RestaurantService.instance.updateRestaurantInfo(updatedRestaurant);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกเวลาเปิด-ปิดสำเร็จ')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
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

                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.edit, size: 18),
                      color: AppColors.primaryBlue,
                      onPressed: _openHoursPicker,
                      tooltip: "แก้ไขเวลาทำการ",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: List.generate(_days.length, (index) {
                    final day = _days[index];
                    final thDay = _thDays[index];
                    final hours = _openingHours[day] as List?;
                    final isOpen = hours != null && hours.isNotEmpty;

                    return Column(
                      children: [
                        ListTile(
                          title: Text(thDay, style: AppTextStyles.profileText),
                          trailing: Text(
                            isOpen
                                ? '${hours.first['open']} - ${hours.first['close']}'
                                : 'ปิดทำการ',
                            style: AppTextStyles.profileText.copyWith(
                              color: isOpen ? Colors.black : Colors.red,
                              fontWeight: isOpen
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (index < _days.length - 1)
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      ],
                    );
                  }),
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
