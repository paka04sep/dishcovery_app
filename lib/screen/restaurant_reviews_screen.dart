import 'package:flutter/material.dart';
import 'package:dishcovery_app/models/restaurant_model.dart';
import 'package:dishcovery_app/constants/app_constants.dart';
import 'package:dishcovery_app/services/restaurant_service.dart';
import 'package:intl/intl.dart';

class RestaurantReviewsScreen extends StatelessWidget {
  final RestaurantCardData restaurant;

  const RestaurantReviewsScreen({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'รีวิวทั้งหมด - ${restaurant.name}',
          style: AppTextStyles.restaurantInDetails.copyWith(
            fontSize: 18,
            color: Colors.black,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<List<ReviewModel>>(
        future: RestaurantService.instance.getReviews(restaurant.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("เกิดข้อผิดพลาดในการโหลดรีวิว"));
          }

          final reviews = snapshot.data ?? [];
          if (reviews.isEmpty) {
            return const Center(child: Text("ยังไม่มีรีวิว"));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: reviews.length,
            separatorBuilder: (context, index) => const Divider(height: 30),
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: review.userPhotoUrl != null
                            ? NetworkImage(review.userPhotoUrl!)
                            : null,
                        child: review.userPhotoUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 20,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          review.userName.isNotEmpty
                              ? review.userName
                              : 'Anonymous',
                          style: AppTextStyles.restaurantMenuItemName.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Colors.grey.shade200, height: 1, thickness: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < review.rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    review.comment,
                    style: AppTextStyles.restaurantInDetails.copyWith(
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(review.createdAt),
                    style: AppTextStyles.restaurantInDetails.copyWith(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
