import 'package:dishcovery_app/constants/gradient_text.dart';
import 'package:flutter/material.dart';
import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:dishcovery_app/services/restaurant_service.dart';
import 'package:dishcovery_app/services/auth_service.dart';
import 'package:dishcovery_app/constants/app_init_screen.dart';
import 'package:dishcovery_app/starting_screen/loading_screen.dart';

class UserProfileSettingScreen extends StatefulWidget {
  const UserProfileSettingScreen({super.key});

  @override
  State<UserProfileSettingScreen> createState() =>
      _UserProfileSettingScreenState();
}

class _UserProfileSettingScreenState extends State<UserProfileSettingScreen> {
  bool _isLoading = false;
  String? _ownedRestaurantId;

  @override
  void initState() {
    super.initState();
    _checkOwnedRestaurant();
  }

  Future<void> _checkOwnedRestaurant() async {
    final user = await AuthService().getCurrentUser();
    if (user != null && user.ownedRestaurantIds.isNotEmpty) {
      setState(() {
        _ownedRestaurantId = user.ownedRestaurantIds.first;
      });
    }
  }

  void _showResetConfirmationDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            "ยืนยันการรีเซ็ตข้อมูล",
            style: AppTextStyles.profileText.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "คุณต้องการรีเซ็ตข้อมูลการปัดร้าน (Yum/Pass) ทั้งหมดหรือไม่?\nข้อมูลร้านที่คุณชอบ (Fav) และความชอบของคุณจะยังคงอยู่",
            style: AppTextStyles.profileText.copyWith(
              fontWeight: FontWeight.w400,
              color: Colors.black.withValues(alpha: 0.8),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("ยกเลิก", style: AppTextStyles.profileText),
            ),
            TextButton(
              onPressed: () async {
                // ปิด Dialog ก่อน
                Navigator.pop(dialogContext);

                // ใช้ context ของหน้าจอหลัก (UserProfileSettingScreen)
                if (!mounted) return;
                setState(() => _isLoading = true);

                try {
                  await RestaurantService.instance.resetSwipeData();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) =>
                            const AppInitScreen(showResetSuccessDialog: true),
                      ),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text("เกิดข้อผิดพลาด"),
                        content: Text(e.toString()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text("ตกลง"),
                          ),
                        ],
                      ),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: Text(
                "รีเซ็ต",
                style: AppTextStyles.profileText.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountStep1() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            "ลบบัญชีผู้ใช้",
            style: AppTextStyles.profileText.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Text(
            "การลบบัญชีจะเป็นการลบข้อมูลทั้งหมดของคุณออกจากระบบโดยถาวร รวมถึงข้อมูลส่วนตัว ประวัติการปัดร้าน และร้านที่คุณชอบ ไม่สามารถกู้คืนได้\n\nคุณแน่ใจหรือไม่ว่าต้องการดำเนินการต่อ?",
            style: AppTextStyles.profileText.copyWith(
              fontWeight: FontWeight.w400,
              color: Colors.black.withValues(alpha: 0.8),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("ยกเลิก", style: AppTextStyles.profileText),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _showDeleteAccountStep2();
              },
              child: Text(
                "ดำเนินการต่อ",
                style: AppTextStyles.profileText.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountStep2() {
    final TextEditingController passwordController = TextEditingController();
    bool isObscure = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (statefulContext, setDialogState) {
            return AlertDialog(
              title: Text(
                "ยืนยันตัวตน",
                style: AppTextStyles.profileText.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "โปรดใส่รหัสผ่านของคุณเพื่อยืนยันการลบบัญชี",
                    style: AppTextStyles.profileText.copyWith(
                      fontWeight: FontWeight.w400,
                      color: Colors.black.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: isObscure,
                    decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: AppTextStyles.profileText.copyWith(
                        fontWeight: FontWeight.w400,
                        color: Colors.black.withValues(alpha: 0.4),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isObscure ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            isObscure = !isObscure;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text("ยกเลิก", style: AppTextStyles.profileText),
                ),
                TextButton(
                  onPressed: () async {
                    final password = passwordController.text.trim();
                    if (password.isNotEmpty) {
                      setDialogState(
                        () => _isLoading = true,
                      ); // To show loading if you want, but local is fine
                      try {
                        // verify password first
                        await AuthService().reauthenticate(password);
                        if (mounted) {
                          Navigator.pop(dialogContext); // Close Step 2
                          _showDeleteAccountStep3(password); // Open Step 3
                        }
                      } catch (e) {
                        if (mounted) {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(
                                "รหัสผ่านไม่ถูกต้อง",
                                style: AppTextStyles.profileText.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red,
                                ),
                              ),
                              content: Text(
                                "โปรดตรวจสอบรหัสผ่านของคุณอีกครั้งและลองใหม่",
                                style: AppTextStyles.profileText.copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black.withValues(alpha: 0.8),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(
                                    "ตกลง",
                                    style: AppTextStyles.profileText.copyWith(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setDialogState(() => _isLoading = false);
                      }
                    }
                  },
                  child: Text(
                    "ตกลง",
                    style: AppTextStyles.profileText.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountStep3(String password) {
    int countdown = 3;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (statefulContext, setDialogState) {
            if (countdown == 3) {
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  setDialogState(() => countdown--);
                }
              });
            } else if (countdown > 0) {
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  setDialogState(() => countdown--);
                }
              });
            }

            return AlertDialog(
              title: Text(
                "การยืนยันครั้งสุดท้าย",
                style: AppTextStyles.profileText.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              content: Text(
                "นี่คือการยืนยันครั้งสุดท้าย บัญชีของคุณกำลังจะถูกลบอย่างถาวร",
                style: AppTextStyles.profileText.copyWith(
                  fontWeight: FontWeight.w400,
                  color: Colors.black.withValues(alpha: 0.8),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text("ยกเลิก", style: AppTextStyles.profileText),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: countdown == 0 ? Colors.red : Colors.grey,
                  ),
                  onPressed: countdown == 0
                      ? () async {
                          // ปิด Dialog ก่อน
                          Navigator.pop(dialogContext);

                          if (!mounted) return;
                          setState(() => _isLoading = true);

                          try {
                            await AuthService().deleteAccount(password);

                            if (mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const LoadingScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  content: Text(
                                    "เกิดข้อผิดพลาดในการลบบัญชี: $e",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text("ตกลง"),
                                    ),
                                  ],
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        }
                      : null,
                  child: Text(
                    countdown > 0 ? "ยืนยัน ($countdown)" : "ยืนยันการลบ",
                    style: AppTextStyles.profileText.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteRestaurantStep1() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            "ลบร้านอาหาร",
            style: AppTextStyles.profileText.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Text(
            "การลบร้านอาหารจะเป็นการลบข้อมูลร้านของคุณทั้งหมด รวมถึงเมนูอาหาร และประวัติที่เกี่ยวข้องจากผู้ใช้อื่นอย่างถาวร ไม่สามารถกู้คืนได้\n\nคุณแน่ใจหรือไม่ว่าต้องการดำเนินการต่อ?",
            style: AppTextStyles.profileText.copyWith(
              fontWeight: FontWeight.w400,
              color: Colors.black.withValues(alpha: 0.8),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("ยกเลิก", style: AppTextStyles.profileText),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _showDeleteRestaurantStep2();
              },
              child: Text(
                "ดำเนินการต่อ",
                style: AppTextStyles.profileText.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteRestaurantStep2() {
    int countdown = 3;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (statefulContext, setDialogState) {
            if (countdown > 0) {
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  setDialogState(() => countdown--);
                }
              });
            }

            return AlertDialog(
              title: Text(
                "การยืนยันครั้งสุดท้าย",
                style: AppTextStyles.profileText.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              content: Text(
                "นี่คือการยืนยันครั้งสุดท้าย ข้อมูลร้านอาหารทั้งหมดจะถูกลบอย่างถาวร",
                style: AppTextStyles.profileText.copyWith(
                  fontWeight: FontWeight.w400,
                  color: Colors.black.withValues(alpha: 0.8),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text("ยกเลิก", style: AppTextStyles.profileText),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: countdown == 0 ? Colors.red : Colors.grey,
                  ),
                  onPressed: countdown == 0
                      ? () async {
                          Navigator.pop(dialogContext);
                          if (!mounted) return;

                          setState(() => _isLoading = true);

                          try {
                            if (_ownedRestaurantId != null) {
                              // Execute delete
                              await RestaurantService.instance
                                  .deleteRestaurantAndCleanUsers(
                                    _ownedRestaurantId!,
                                  );
                            }

                            if (mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const AppInitChangeMode(
                                    isToBusinessMode: false,
                                  ),
                                ),
                                (route) => false,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text("เกิดข้อผิดพลาด"),
                                  content: Text(e.toString()),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text("ตกลง"),
                                    ),
                                  ],
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        }
                      : null,
                  child: Text(
                    countdown > 0 ? "ยืนยัน ($countdown)" : "ยืนยันการลบ",
                    style: AppTextStyles.profileText.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: GradientText(
          text: 'ตั้งค่าบัญชี',
          style: AppTextStyles.signinText.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            children: [
              _buildSettingSection(
                title: "จัดการข้อมูล",
                children: [
                  _buildListTile(
                    icon: Icons.refresh,
                    title: "รีเซ็ตข้อมูลการปัดร้าน",
                    subtitle: "ลบประวัติ Yums และ Passes",
                    isDestructive: false,
                    onTap: _showResetConfirmationDialog,
                  ),
                  if (_ownedRestaurantId != null)
                    _buildListTile(
                      icon: Icons.storefront_outlined,
                      title: "ลบร้านอาหาร",
                      subtitle: "ลบข้อมูลร้านของคุณทั้งหมดอย่างถาวร",
                      isDestructive: true,
                      onTap: _showDeleteRestaurantStep1,
                    ),
                ],
              ),
              const SizedBox(height: 30),
              _buildSettingSection(
                title: "จัดการบัญชี",
                children: [
                  _buildListTile(
                    icon: Icons.person_off_outlined,
                    title: "ลบบัญชีผู้ใช้",
                    subtitle: "ลบข้อมูลทั้งหมดอย่างถาวร",
                    isDestructive: true,
                    onTap: _showDeleteAccountStep1,
                  ),
                ],
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: AppTextStyles.profileText.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDestructive,
    required VoidCallback onTap,
  }) {
    final color = isDestructive ? Colors.red : Colors.black87;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: AppTextStyles.profileText.copyWith(
          color: color,
          fontWeight: isDestructive ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.profileText.copyWith(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}
