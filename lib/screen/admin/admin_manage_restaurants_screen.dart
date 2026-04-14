import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dishcovery_app/models/restaurant_model.dart';
import 'package:dishcovery_app/screen/restarurant_detail_screen.dart'; // assuming typo is handled or using exact import from project

class AdminManageRestaurantsScreen extends StatefulWidget {
  const AdminManageRestaurantsScreen({super.key});

  @override
  State<AdminManageRestaurantsScreen> createState() => _AdminManageRestaurantsScreenState();
}

class _AdminManageRestaurantsScreenState extends State<AdminManageRestaurantsScreen> {
  String _selectedCategory = 'ทั้งหมด';

  // Available categories (you can expand this list based on data or fetch dynamically, but here is mock)
  final List<String> _categories = [
    'ทั้งหมด',
    'อาหารไทย',
    'อาหารญี่ปุ่น',
    'อาหารเกาหลี',
    'ของหวาน',
    'เครื่องดื่ม',
    'ฟาสต์ฟู้ด'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text("จัดการร้านอาหาร", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = category);
                        }
                      },
                      selectedColor: Colors.black,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                      backgroundColor: Colors.grey.shade100,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('restaurants').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("ไม่พบร้านอาหาร"));
                }

                var restaurants = snapshot.data!.docs
                    .map((doc) => RestaurantCardData.fromFirestore(doc.data(), doc.id))
                    .toList();

                if (_selectedCategory != 'ทั้งหมด') {
                  restaurants = restaurants.where((r) => r.cuisine.contains(_selectedCategory)).toList();
                }

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
                      child: ListTile(
                        onTap: () {
                          // Navigate to details
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RestaurantDetailScreen(
                                restaurant: r,
                              ),
                            ),
                          );
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          "หมวดหมู่: ${r.cuisine.isEmpty ? '-' : r.cuisine.join(', ')}\nสถานะ: ${r.status}",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
