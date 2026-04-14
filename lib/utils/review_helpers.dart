import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dishcovery_app/models/restaurant_model.dart';
import 'package:dishcovery_app/services/restaurant_service.dart';
import 'package:dishcovery_app/constants/app_constants.dart';

class ReviewHelpers {
  static void showReviewOptionsBottomSheet(
    BuildContext context,
    ReviewModel review,
    String restaurantId,
    VoidCallback onReviewChanged,
  ) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUserId != null && currentUserId == review.userId;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isOwner) ...[
                  ListTile(
                    leading: const Icon(
                      Icons.edit_outlined,
                      color: Colors.black,
                    ),
                    title: Text(
                      'แก้ไขรีวิว',
                      style: AppTextStyles.restaurantInDetails.copyWith(
                        color: Colors.black,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      showReviewModal(
                        context,
                        restaurantId,
                        existingReview: review,
                        onReviewChanged: onReviewChanged,
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    title: Text(
                      'ลบรีวิว',
                      style: AppTextStyles.restaurantInDetails.copyWith(
                        color: Colors.red,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      showDialog(
                        context: context,
                        builder: (dialogCtx) => AlertDialog(
                          title: Text(
                            'ยืนยันการลบ',
                            style: AppTextStyles.restaurantInDetails.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.red,
                            ),
                          ),
                          content: Text(
                            'คุณต้องการลบรีวิวนี้ใช่หรือไม่?',
                            style: AppTextStyles.restaurantInDetails.copyWith(
                              color: Colors.grey[800],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogCtx),
                              child: Text(
                                'ยกเลิก',
                                style: AppTextStyles.restaurantInDetails
                                    .copyWith(color: Colors.grey),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(dialogCtx);
                                try {
                                  await RestaurantService.instance.deleteReview(
                                    restaurantId,
                                    review,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'ลบรีวิวเรียบร้อยแล้ว',
                                          style:
                                              AppTextStyles.restaurantInDetails,
                                        ),
                                        duration: Duration(milliseconds: 1500),
                                      ),
                                    );
                                    onReviewChanged();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('เกิดข้อผิดพลาด: $e'),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Text(
                                'ลบ',
                                style: AppTextStyles.restaurantInDetails
                                    .copyWith(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ] else ...[
                  ListTile(
                    leading: Icon(Icons.flag_outlined, color: Colors.red),
                    title: Text(
                      'รายงานรีวิวนี้',
                      style: AppTextStyles.restaurantInDetails.copyWith(
                        color: Colors.red,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showReportDialog(context, review, restaurantId);
                    },
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  static void showReviewModal(
    BuildContext context,
    String restaurantId, {
    ReviewModel? existingReview,
    required VoidCallback onReviewChanged,
  }) {
    double _rating = existingReview?.rating ?? 0.0;
    final TextEditingController _commentController = TextEditingController(
      text: existingReview?.comment ?? '',
    );
    bool _isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'รีวิวร้านอาหาร',
                style: AppTextStyles.restaurantInDetails.copyWith(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < _rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 32,
                          ),
                          onPressed: () {
                            setState(() {
                              _rating = index + 1.0;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _commentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'แชร์ประสบการณ์ของคุณ...',
                        hintStyle: AppTextStyles.restaurantInDetails.copyWith(
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'ยกเลิก',
                    style: AppTextStyles.restaurantInDetails.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isSubmitting || _rating == 0.0
                      ? null
                      : () async {
                          setState(() => _isSubmitting = true);
                          final user = FirebaseAuth.instance.currentUser;
                          final userModel =
                              RestaurantService.instance.userModel;

                          String userName = 'User';
                          if (userModel?.username != null &&
                              userModel!.username!.isNotEmpty) {
                            userName = userModel.username!;
                          } else if (user != null) {
                            userName =
                                user.displayName ??
                                user.email?.split('@')[0] ??
                                'User';
                          }

                          final profilePhoto =
                              userModel?.profilePictureUrl ?? user?.photoURL;

                          final review = ReviewModel(
                            id:
                                existingReview?.id ??
                                FirebaseFirestore.instance
                                    .collection('restaurants')
                                    .doc()
                                    .id,
                            userId:
                                existingReview?.userId ?? user?.uid ?? 'guest',
                            userName: userName,
                            userPhotoUrl: profilePhoto,
                            rating: _rating,
                            comment: _commentController.text.trim(),
                            createdAt:
                                existingReview?.createdAt ?? DateTime.now(),
                          );
                          try {
                            if (existingReview != null) {
                              await RestaurantService.instance.updateReview(
                                restaurantId,
                                review,
                                existingReview.rating,
                              );
                            } else {
                              await RestaurantService.instance.addReview(
                                restaurantId,
                                review,
                              );
                            }
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'ดำเนินการสำเร็จแล้ว',
                                    style: AppTextStyles.restaurantInDetails,
                                  ),
                                  duration: Duration(milliseconds: 1500),
                                ),
                              );
                              onReviewChanged();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                              );
                              setState(() => _isSubmitting = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    'บันทึก',
                    style: AppTextStyles.restaurantInDetails.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

  static void _showReportDialog(
    BuildContext context,
    ReviewModel review,
    String restaurantId,
  ) {
    final TextEditingController _reasonController = TextEditingController();
    bool _isSubmitting = false;
    String _selectedReason =
        'มีเนื้อหาที่ไม่เหมาะสมหรือหยาบคาย'; // default option
    final List<String> _reportOptions = [
      'มีเนื้อหาที่ไม่เหมาะสมหรือหยาบคาย',
      'โฆษณาแอบแฝงหรือสแปม',
      'ข้อมูลเท็จหรือรีวิวที่ไม่เป็นความจริง',
      'เนื้อหาแสดงความเกลียดชังหรือคุกคาม',
      'อื่นๆ',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'รายงานรีวิว',
                style: AppTextStyles.restaurantInDetails.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'กรุณาระบุเหตุผลที่คุณต้องการรายงานรีวิวนี้:',
                      style: AppTextStyles.restaurantInDetails.copyWith(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._reportOptions.map((option) {
                      return RadioListTile<String>(
                        title: Text(
                          option,
                          style: AppTextStyles.restaurantInDetails.copyWith(
                            fontSize: 13,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        value: option,
                        groupValue: _selectedReason,
                        onChanged: (val) {
                          if (val != null)
                            setState(() => _selectedReason = val);
                        },
                        contentPadding: EdgeInsets.zero,
                        activeColor: Colors.red,
                      );
                    }),
                    if (_selectedReason == 'อื่นๆ') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _reasonController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'โปรดระบุเหตุผลเพิ่มเติม ...',
                          hintStyle: AppTextStyles.restaurantInDetails.copyWith(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'ยกเลิก',
                    style: AppTextStyles.restaurantInDetails.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          setState(() => _isSubmitting = true);
                          try {
                            final currentUserId =
                                FirebaseAuth.instance.currentUser?.uid ??
                                'guest';
                            final reportRef = FirebaseFirestore.instance
                                .collection('reports')
                                .doc();

                            String finalReason = _selectedReason == 'อื่นๆ'
                                ? (_reasonController.text.trim().isNotEmpty
                                      ? 'อื่นๆ: ${_reasonController.text.trim()}'
                                      : 'อื่นๆ')
                                : _selectedReason;

                            // Find the restaurant to check if the current user is the owner
                            bool isOwner = false;
                            try {
                              final restaurantRow = RestaurantService.instance.restaurants.firstWhere(
                                (r) => r.id == restaurantId,
                              );
                              if (restaurantRow.ownerId == currentUserId) {
                                isOwner = true;
                              }
                            } catch (_) {
                              // If not found in memory, fallback to user_mode
                            }

                            final report = ReportModel(
                              id: reportRef.id,
                              reporterId: currentUserId,
                              reporterRole: isOwner ? 'restaurant_mode' : 'user_mode',
                              targetReviewId: review.id,
                              restaurantId: restaurantId,
                              reason: finalReason,
                              createdAt: DateTime.now(),
                            );

                            await reportRef.set(report.toJson());

                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'ส่งรายงานเรียบร้อยแล้ว',
                                    style: AppTextStyles.restaurantInDetails
                                        .copyWith(color: Colors.white),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                              );
                              setState(() => _isSubmitting = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text(
                    'ส่งรายงาน',
                    style: AppTextStyles.restaurantInDetails.copyWith(
                      color: Colors.white,
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
}
