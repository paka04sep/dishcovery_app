import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dishcovery_app/constants/gradient_text.dart';
import 'package:flutter/material.dart';
import 'package:dishcovery_app/services/restaurant_service.dart';
import 'package:dishcovery_app/constants/app_constants.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  bool _isLoading = true;
  String _eatingStyle = "กำลังวิเคราะห์สไตล์การกินของคุณ...";
  Map<String, int> _rightCuisineCount = {};

  @override
  void initState() {
    super.initState();
    _analyzeEatingStyle();
  }

  Future<void> _analyzeEatingStyle() async {
    final userModel = RestaurantService.instance.userModel;
    if (userModel == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _eatingStyle = "ไม่พบข้อมูล กรุณาล็อกอินใหม่";
        });
      }
      return;
    }

    // เอาเฉพาะ 30 รายการล่าสุดเพื่อความรวดเร็วและไม่เปลืองโควต้า Firestore
    List<String> allRight = [
      ...userModel.history.yum,
      ...userModel.history.fav,
    ];
    List<String> rightSwipeIds = allRight.reversed.take(30).toList();
    List<String> leftSwipeIds = userModel.history.passed.reversed
        .take(30)
        .toList();

    if (rightSwipeIds.isEmpty && leftSwipeIds.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _eatingStyle = "ยังไม่มีข้อมูล ลองปัดการ์ดร้านอาหารดูก่อนนะ";
        });
      }
      return;
    }

    Map<String, int> rightCuisineCount = {};
    Map<String, int> leftCuisineCount = {};
    final db = FirebaseFirestore.instance;

    try {
      // Analyze right swipes
      for (int i = 0; i < rightSwipeIds.length; i += 10) {
        int end = (i + 10 < rightSwipeIds.length)
            ? i + 10
            : rightSwipeIds.length;
        List<String> chunk = rightSwipeIds.sublist(i, end);
        if (chunk.isEmpty) continue;

        final snap = await db
            .collection('restaurants')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (var doc in snap.docs) {
          final data = doc.data();
          List<dynamic> cuisines = data['cuisine'] ?? [];
          for (var c in cuisines) {
            String cuisine = c.toString();
            rightCuisineCount[cuisine] = (rightCuisineCount[cuisine] ?? 0) + 1;
          }
        }
      }

      // Analyze left swipes
      for (int i = 0; i < leftSwipeIds.length; i += 10) {
        int end = (i + 10 < leftSwipeIds.length) ? i + 10 : leftSwipeIds.length;
        List<String> chunk = leftSwipeIds.sublist(i, end);
        if (chunk.isEmpty) continue;

        final snap = await db
            .collection('restaurants')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (var doc in snap.docs) {
          final data = doc.data();
          List<dynamic> cuisines = data['cuisine'] ?? [];
          for (var c in cuisines) {
            String cuisine = c.toString();
            leftCuisineCount[cuisine] = (leftCuisineCount[cuisine] ?? 0) + 1;
          }
        }
      }

      if (rightCuisineCount.isEmpty && leftCuisineCount.isEmpty) {
        _eatingStyle = "หลากหลายสไตล์ อาหารแนวไหนก็กินได้";
      } else {
        var sortedRightKeys = rightCuisineCount.keys.toList()
          ..sort(
            (a, b) => rightCuisineCount[b]!.compareTo(rightCuisineCount[a]!),
          );

        var sortedLeftKeys = leftCuisineCount.keys.toList()
          ..sort(
            (a, b) => leftCuisineCount[b]!.compareTo(leftCuisineCount[a]!),
          );

        String result = "";
        if (sortedRightKeys.isNotEmpty) {
          if (sortedRightKeys.length >= 2) {
            result +=
                "คุณชื่นชอบอาหารประเภท ${sortedRightKeys[0]} และ ${sortedRightKeys[1]} เป็นพิเศษ ";
          } else {
            result += "คุณชื่นชอบอาหารประเภท ${sortedRightKeys[0]} เป็นพิเศษ ";
          }
        }

        if (sortedLeftKeys.isNotEmpty) {
          if (sortedLeftKeys.length >= 2) {
            result +=
                "\n\nแต่ส่วนใหญ่คุณมักจะปัดผ่านร้านแนว ${sortedLeftKeys[0]} และ ${sortedLeftKeys[1]}";
          } else {
            result +=
                "\n\nแต่คุณมักจะปัดผ่านร้านแนว ${sortedLeftKeys[0]} ซะมากกว่า";
          }
        }

        _eatingStyle = result.trim();
      }
    } catch (e) {
      debugPrint("Error analyzing style: $e");
      _eatingStyle = "เกิดข้อผิดพลาดในการคำนวณสไตล์การกิน ($e)";
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _rightCuisineCount = rightCuisineCount;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RestaurantService.instance,
      builder: (context, child) {
        final userModel = RestaurantService.instance.userModel;
        int yums = userModel?.history.yum.length ?? 0;
        int passes = userModel?.history.passed.length ?? 0;
        int favs = userModel?.history.fav.length ?? 0;
        int totalSwipes = yums + passes + favs;

        return Scaffold(
          backgroundColor: const Color(0xFFF9F9F9),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: GradientText(
              text: "ข้อมูลการปัดของคุณ",
              style: AppTextStyles.profileText.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTotalSwipeCard(totalSwipes),
                const SizedBox(height: 20),

                // Section: สถิติการปัด
                Text(
                  "สถิติการปัด",
                  style: AppTextStyles.profileText.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        "ปัดขวา (YUM)",
                        yums.toString(),
                        Icons.restaurant,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildStatCard(
                        "ปัดซ้าย (PASS)",
                        passes.toString(),
                        Icons.close,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                _buildStatCard(
                  "กดถูกใจ (FAV)",
                  favs.toString(),
                  Icons.star,
                  Colors.amber,
                ),

                const SizedBox(height: 35),

                // Section: วิเคราะห์การกิน
                Text(
                  "สไตล์การกินของคุณ",
                  style: AppTextStyles.profileText.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (_isLoading)
                  _buildLoadingStyleCard()
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStyleCard(_eatingStyle),
                      if (_rightCuisineCount.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildCuisineTags(),
                      ],
                    ],
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotalSwipeCard(int total) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.midblue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "จำนวนครั้งที่ปัดทั้งหมด",
                style: AppTextStyles.profileText.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                total.toString(),
                style: AppTextStyles.profileText.copyWith(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.swipe, size: 40, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.profileText.copyWith(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            count,
            style: AppTextStyles.profileText.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStyleCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppColors.primaryBlue),
          const SizedBox(height: 15),
          Text(
            "กำลังประมวลผลสไตล์ของคุณ...",
            style: AppTextStyles.profileText.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleCard(String desc) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.insights,
              size: 30,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              desc,
              style: AppTextStyles.profileText.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCuisineTags() {
    // Show top 5 types
    var sortedKeys = _rightCuisineCount.keys.toList()
      ..sort(
        (a, b) => _rightCuisineCount[b]!.compareTo(_rightCuisineCount[a]!),
      );

    var topCuisines = sortedKeys.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "ประเภทที่ถูกใจบ่อยที่สุด",
          style: AppTextStyles.profileText.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: topCuisines.map((cuisine) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                cuisine,
                style: AppTextStyles.profileText.copyWith(
                  color: Colors.green.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
