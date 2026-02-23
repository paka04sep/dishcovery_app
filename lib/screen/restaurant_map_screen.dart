import 'package:dishcovery_app/services/restaurant_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/app_constants.dart';
import '../models/restaurant_details_model.dart';
import '../models/restaurant_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class RestaurantMapScreen extends StatefulWidget {
  final RestaurantCardData restaurant;

  const RestaurantMapScreen({super.key, required this.restaurant});

  @override
  State<RestaurantMapScreen> createState() => _RestaurantMapScreenState();
}

class _RestaurantMapScreenState extends State<RestaurantMapScreen> {
  late GoogleMapController mapController;
  bool _isMapReady = false;

  // พิกัดร้านอาหาร (ควรดึงจาก Model จริง)
  // final LatLng _restaurantLocation = const LatLng(13.7563, 100.5018);
  double get resLat => widget.restaurant.latitude;
  double get resLng => widget.restaurant.longitude;

  @override
  void initState() {
    super.initState();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    setState(() {
      _isMapReady = true;
    });
  }

  Future<void> _launchNavigation() async {
    // สร้าง URL สำหรับ Google Maps และ Apple Maps
    final String googleMapsUrl = "google.navigation:q=$resLat,$resLng&mode=d";

    final String webUrl =
        "https://www.google.com/maps/dir/?api=1&destination=$resLat,$resLng";

    if (Platform.isAndroid) {
      // สำหรับ Android: พยายามเปิด Google Maps App
      final Uri intentUri = Uri.parse(googleMapsUrl);
      if (await canLaunchUrl(intentUri)) {
        await launchUrl(intentUri);
      } else {
        // ถ้าไม่มีแอป ให้เปิดผ่าน Browser
        await launchUrl(
          Uri.parse(webUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    } else if (Platform.isIOS) {
      // สำหรับ iOS: พยายามเปิด Apple Maps หรือ Google Maps
      // final Uri appleUri = Uri.parse(appleMapsUrl);
      final Uri googleUri = Uri.parse(googleMapsUrl);

      if (await canLaunchUrl(googleUri)) {
        await launchUrl(googleUri);
        // } else if (await canLaunchUrl(appleUri)) {
        //   await launchUrl(appleUri);
      } else {
        // ถ้าไม่มีแอป ให้เปิดผ่าน Browser
        await launchUrl(
          Uri.parse(webUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // เนื้อหาหลัก
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: 50,
                  left: 20,
                  right: 20,
                  bottom: 10,
                ),
                child: _buildRestaurantHeader(),
              ),

              // แผนที่
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.grey.shade200, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(23),
                    child: Stack(
                      children: [
                        GoogleMap(
                          onMapCreated: _onMapCreated,
                          initialCameraPosition: CameraPosition(
                            target: LatLng(resLat, resLng),
                            zoom: 15,
                          ),
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          markers: {
                            Marker(
                              markerId: const MarkerId('res_1'),
                              position: LatLng(resLat, resLng),
                              infoWindow: InfoWindow(
                                title: widget.restaurant.name,
                              ),
                            ),
                          },
                        ),
                        if (!_isMapReady)
                          const Center(child: CircularProgressIndicator()),
                      ],
                    ),
                  ),
                ),
              ),

              _buildActionButtons(context),
            ],
          ),

          // ปุ่ม Back ลอย (ถูกที่แล้ว)
          _buildFloatingBackButton(context),
        ],
      ),
    );
  }

  Widget _buildRestaurantHeader() {
    final currentRestaurant = RestaurantService.instance.restaurants.firstWhere(
      (r) => r.id == widget.restaurant.id,
      orElse: () => widget.restaurant,
    );

    final details = currentRestaurant is RestaurantDetailsData
        ? currentRestaurant
        : null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        image: DecorationImage(
          image: widget.restaurant.imageUrl.startsWith('http')
              ? NetworkImage(widget.restaurant.imageUrl)
              : AssetImage(widget.restaurant.imageUrl) as ImageProvider,
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(10, 60, 10, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
            stops: const [0.4, 0.9],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // ทำให้มีความสูงตามเนื้อหา
          children: [
            Text(
              widget.restaurant.name.toUpperCase(),
              style: AppTextStyles.restaurantName.copyWith(fontSize: 26),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    details?.address ?? 'กำลังโหลดที่อยู่...',
                    style: AppTextStyles.restaurantDetails.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.directions_car,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'ระยะห่าง: ${RestaurantService.instance.getDistance(currentRestaurant)} กม.',
                  style: AppTextStyles.restaurantDetails.copyWith(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _launchNavigation,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
              side: const BorderSide(color: Colors.black12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.navigation),
              const SizedBox(width: 8),
              Text(
                'นำทางเลย',
                style: AppTextStyles.restaurantInDetails.copyWith(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //  ปุ่ม Back ลอยตัว
  Widget _buildFloatingBackButton(BuildContext context) {
    return Positioned(
      top: 50,
      left: 20,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
