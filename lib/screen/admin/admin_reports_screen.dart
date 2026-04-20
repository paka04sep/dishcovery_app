import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dishcovery_app/models/restaurant_model.dart';
import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:dishcovery_app/services/restaurant_service.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          "รายงานรีพอท",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          _buildSettingSection(
            title: 'รายงานรีวิว',
            children: [
              _buildListTile(
                icon: Icons.person_outline,
                title: 'รายงานจากผู้ใช้',
                subtitle: 'รอดำเนินการ',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminReportListScreen(
                      title: 'รายงานจากผู้ใช้',
                      reporterRole: 'user_mode',
                      statusFilter: 'pending',
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildListTile(
                icon: Icons.storefront_outlined,
                title: 'รายงานจากร้านอาหาร',
                subtitle: 'รอดำเนินการ',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminReportListScreen(
                      title: 'รายงานจากร้านอาหาร',
                      reporterRole: 'restaurant_mode',
                      statusFilter: 'pending',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingSection(
            title: 'รีวิวที่ดำเนินการเรียบร้อย',
            children: [
              _buildListTile(
                icon: Icons.cancel_outlined,
                title: 'รีวิวที่ถูกปฏิเสธ',
                subtitle: 'เพิกเฉยแล้ว',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminReportListScreen(
                      title: 'รีวิวที่ถูกปฏิเสธ',
                      reporterRole: null,
                      statusFilter: 'dismissed',
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _buildListTile(
                icon: Icons.delete_outline,
                title: 'รีวิวที่ถูกลบ',
                subtitle: 'ลบแล้ว',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminReportListScreen(
                      title: 'รีวิวที่ถูกลบ',
                      reporterRole: null,
                      statusFilter: 'resolved',
                    ),
                  ),
                ),
              ),
            ],
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
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
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
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

class AdminReportListScreen extends StatefulWidget {
  final String title;
  final String? reporterRole;
  final String statusFilter;

  const AdminReportListScreen({
    super.key,
    required this.title,
    this.reporterRole,
    required this.statusFilter,
  });

  @override
  State<AdminReportListScreen> createState() => _AdminReportListScreenState();
}

class _AdminReportListScreenState extends State<AdminReportListScreen> {
  List<ReportModel> _reports = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
        'reports',
      );

      if (widget.reporterRole != null) {
        query = query.where('reporterRole', isEqualTo: widget.reporterRole);
      }
      query = query.where('status', isEqualTo: widget.statusFilter);

      final snapshot = await query.get(); // One-time fetch instead of .snapshots()

      final reports = snapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc.data(), doc.id))
          .toList();

      // Sort locally to avoid Firestore Composite Index requirement
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateReportStatus(
    String reportId,
    String newStatus,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .update({'status': newStatus});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('อัปเดตสถานะรายงานแล้ว ( $newStatus )')),
        );
        // Re-fetch after action
        _fetchReports();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    "Error: $_error",
                    textAlign: TextAlign.center,
                  ),
                )
              : _reports.isEmpty
                  ? const Center(child: Text("ไม่มีข้อมูลรายงาน"))
                  : RefreshIndicator(
                      onRefresh: _fetchReports,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reports.length,
                        itemBuilder: (context, index) {
                          final report = _reports[index];
                          return _ReportCard(
                            report: report,
                            onUpdateStatus: (String reportId, String status) {
                              _updateReportStatus(reportId, status);
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportModel report;
  final Function(String, String) onUpdateStatus;

  const _ReportCard({required this.report, required this.onUpdateStatus});

  Future<Map<String, dynamic>> _fetchDetails() async {
    final futures = await Future.wait([
      FirebaseFirestore.instance
          .collection('users')
          .doc(report.reporterId)
          .get(),
      FirebaseFirestore.instance
          .collection('restaurants')
          .doc(report.restaurantId)
          .get(),
      FirebaseFirestore.instance
          .collection('restaurants')
          .doc(report.restaurantId)
          .collection('reviews')
          .doc(report.targetReviewId)
          .get(),
    ]);

    final userDoc = futures[0];
    final restDoc = futures[1];
    final reviewDoc = futures[2];

    String? reviewUserName;
    String? reviewUserPhotoUrl;
    if (reviewDoc.exists) {
      final reviewData = reviewDoc.data() as Map<String, dynamic>?;
      if (reviewData != null && reviewData['userId'] != null) {
        final reviewerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(reviewData['userId'])
            .get();
        if (reviewerDoc.exists) {
          final data = reviewerDoc.data() as Map<String, dynamic>?;
          if (data != null) {
            String? uname = data['username'];
            if (uname == null || uname.trim().isEmpty) {
              String? email = data['email'];
              uname = (email != null && email.contains('@'))
                  ? email.split('@')[0]
                  : 'ผู้ใช้งานไม่ทราบชื่อ';
            }
            reviewUserName = uname;
            reviewUserPhotoUrl = data['profilePictureUrl'];
          }
        }
      }
    }

    return {
      'reporterUser': userDoc.exists ? userDoc.data() : null,
      'restaurant': restDoc.exists ? restDoc.data() : null,
      'review': reviewDoc.exists ? reviewDoc.data() : null,
      'reviewUserName': reviewUserName ?? 'Anonymous',
      'reviewUserPhotoUrl': reviewUserPhotoUrl ?? '',
    };
  }

  void _showManageModal(
    BuildContext context,
    Map<String, dynamic>? reviewData,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                "จัดการรีพอท",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  "ลบรีวิว",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  // ลบรีวิว
                  if (reviewData != null) {
                    try {
                      final reviewModel = ReviewModel(
                        id: report.targetReviewId,
                        userId: reviewData['userId'] ?? '',
                        userName: reviewData['userName'] ?? 'Anonymous',
                        userPhotoUrl: reviewData['userPhotoUrl'],
                        rating: (reviewData['rating'] ?? 0).toDouble(),
                        comment: reviewData['comment'] ?? '',
                        createdAt: (reviewData['createdAt'] is Timestamp)
                            ? (reviewData['createdAt'] as Timestamp).toDate()
                            : (DateTime.tryParse(
                                    reviewData['createdAt'].toString(),
                                  ) ??
                                  DateTime.now()),
                      );

                      // เรียก Restaurant Service เพื่อลบรีวิว (เพื่ออัปเดต Rating อัตโนมัติ)
                      await RestaurantService.instance.deleteReview(
                        report.restaurantId,
                        reviewModel,
                      );

                      // Update report status to resolved
                      onUpdateStatus(report.id, 'resolved');

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'ทำการลบรีวิวพร้อมจัดการรีพอทเรียบร้อยแล้ว',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('เกิดข้อผิดพลาดในการลบรีวิว: $e'),
                          ),
                        );
                      }
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ไม่พบข้อมูลรีวิว (อาจถูกลบไปแล้ว)'),
                        ),
                      );
                      onUpdateStatus(report.id, 'resolved');
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel_outlined, color: Colors.grey),
                title: const Text("ปฏิเสธ Report"),
                onTap: () {
                  Navigator.pop(ctx);
                  onUpdateStatus(report.id, 'dismissed');
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            margin: EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final data = snapshot.data ?? {};
        final reporterUser = data['reporterUser'];
        final restaurant = data['restaurant'];
        final review = data['review'];
        final reviewUserName = data['reviewUserName'];
        final reviewUserPhotoUrl = data['reviewUserPhotoUrl'] ?? '';

        String avatarUrl = '';
        String reporterName = '';

        if (report.reporterRole == 'restaurant_mode' && restaurant != null) {
          avatarUrl =
              (restaurant['images'] != null &&
                  (restaurant['images'] as List).isNotEmpty)
              ? restaurant['images'][0]
              : '';
          reporterName = restaurant['name'] ?? 'ร้านอาหาร';
        } else {
          avatarUrl = reporterUser?['profilePictureUrl'] ?? '';

          String? uname = reporterUser?['username'];
          if (uname == null || uname.trim().isEmpty) {
            String? email = reporterUser?['email'];
            uname = (email != null && email.contains('@'))
                ? email.split('@')[0]
                : 'ผู้ใช้งานไม่ทราบชื่อ';
          }
          reporterName = uname;
        }

        return Card(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  size: 20,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          reporterName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "เหตุผลที่รายงาน:",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  report.reason,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "(ร้าน ${restaurant?['name'] ?? '...'})",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (review != null) ...[
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.grey.shade300,
                              backgroundImage: reviewUserPhotoUrl.isNotEmpty
                                  ? NetworkImage(reviewUserPhotoUrl)
                                  : null,
                              child: reviewUserPhotoUrl.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      size: 12,
                                      color: Colors.grey,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              reviewUserName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: List.generate(5, (index) {
                                double rating = (review['rating'] ?? 0)
                                    .toDouble();

                                if (index < rating.floor()) {
                                  return const Icon(
                                    Icons.star,
                                    size: 14,
                                    color: Colors.amber,
                                  );
                                } else if (index < rating && rating % 1 != 0) {
                                  return const Icon(
                                    Icons.star_half,
                                    size: 14,
                                    color: Colors.amber,
                                  );
                                } else {
                                  return const Icon(
                                    Icons.star_border,
                                    size: 14,
                                    color: Colors.amber,
                                  );
                                }
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          review['comment'] ?? "ไม่มีข้อความรีวิว",
                          style: const TextStyle(fontSize: 13),
                        ),
                      ] else ...[
                        const Text(
                          "ไม่พบข้อมูลรีวิวนี้ หรือถูกลบไปแล้ว",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: report.status == 'pending'
                            ? Colors.orange.withOpacity(0.1)
                            : (report.status == 'resolved'
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        report.status == 'pending'
                            ? 'รอการดำเนินการ'
                            : (report.status == 'resolved'
                                  ? 'จัดการแล้ว'
                                  : 'ปฏิเสธแล้ว'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: report.status == 'pending'
                              ? Colors.orange
                              : (report.status == 'resolved'
                                    ? Colors.green
                                    : Colors.red),
                        ),
                      ),
                    ),
                    if (report.status == 'pending') ...[
                      ElevatedButton(
                        onPressed: () => _showManageModal(context, review),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("จัดการ"),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
