import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dishcovery_app/models/restaurant_model.dart';
import 'package:dishcovery_app/screen/restarurant_detail_screen.dart'; // Ensure correct import

class AdminRestaurantRequestsScreen extends StatefulWidget {
  const AdminRestaurantRequestsScreen({super.key});

  @override
  State<AdminRestaurantRequestsScreen> createState() => _AdminRestaurantRequestsScreenState();
}

class _AdminRestaurantRequestsScreenState extends State<AdminRestaurantRequestsScreen> {
  Future<void> _updateStatus(String id, String status, [String rejectionReason = '']) async {
    try {
      await FirebaseFirestore.instance.collection('restaurants').doc(id).update({
        'status': status,
        if (rejectionReason.isNotEmpty) 'rejectionReason': rejectionReason,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('อัปเดตสถานะเป็น $status แล้ว')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<void> _showRejectDialog(String id) async {
    String reason = '';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ปฏิเสธคำขอ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('โปรดระบุเหตุผลการปฏิเสธ:'),
            TextField(
              onChanged: (val) => reason = val,
              decoration: const InputDecoration(hintText: 'เหตุผล'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กรุณาระบุเหตุผล')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('ปฏิเสธ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _updateStatus(id, 'rejected', reason);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text("คำขอของร้านอาหาร", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('restaurants').where('status', isEqualTo: 'pending').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("ไม่มีคำขอร้านอาหารใหม่"));
          }

          final restaurants = snapshot.data!.docs
              .map((doc) => RestaurantCardData.fromFirestore(doc.data(), doc.id))
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: restaurants.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final r = restaurants[index];
              return Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: () {
                          // View details
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RestaurantDetailScreen(
                                restaurant: r,
                              ),
                            ),
                          );
                        },
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            r.imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[300],
                              child: const Icon(Icons.restaurant),
                            ),
                          ),
                        ),
                        title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          "เมื่อ ${r.createdAt?.day ?? '-'}/${r.createdAt?.month ?? '-'}/${r.createdAt?.year ?? '-'}",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => _showRejectDialog(r.id),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("ปฏิเสธ"),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () => _updateStatus(r.id, 'approved'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("อนุมัติ"),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
