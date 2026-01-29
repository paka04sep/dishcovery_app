import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/app_constants.dart';
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
  final double resLat = 13.7563;
  final double resLng = 100.5018;

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
    // final String appleMapsUrl = "http://maps.apple.com/?daddr=$resLat,$resLng";
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
    final String? fontFamily = Theme.of(
      context,
    ).textTheme.bodyLarge?.fontFamily;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ส่วนบน: ปุ่มย้อนกลับและ Card
          Padding(
            padding: const EdgeInsets.only(
              top: 50,
              left: 20,
              right: 20,
              bottom: 10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFloatingBackButton(context),
                const SizedBox(height: 10),

                _buildRestaurantHeader(fontFamily),
              ],
            ),
          ),

          // ส่วนแผนที่
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                        zoom: 15.0,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      markers: {
                        Marker(
                          markerId: const MarkerId('res_1'),
                          position: LatLng(resLat, resLng),
                          infoWindow: InfoWindow(title: widget.restaurant.name),
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

          // ปุ่ม Navigation และ Bottom Bar (คงเดิม)
          _buildActionButtons(fontFamily),
        ],
      ),
    );
  }

  Widget _buildRestaurantHeader(String? fontFamily) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        image: DecorationImage(
          image: AssetImage(widget.restaurant.imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.restaurant.name.toUpperCase(),
              style: AppTextStyles.restaurantName.copyWith(fontSize: 26),
            ),

            // const Text(
            //   'DETAILS',
            //   style: TextStyle(color: Colors.white70, fontSize: 14),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(String? fontFamily) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: ElevatedButton.icon(
            onPressed: _launchNavigation,
            icon: const Icon(Icons.navigation),
            label: const Text("START NAVIGATION"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
        // _buildBottomNavBar(),
      ],
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

  // Widget _buildBottomNavBar() {
  //   return Container(
  //     height: 70,
  //     decoration: const BoxDecoration(
  //       color: Colors.white,
  //       border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
  //     ),
  //     child: const Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceAround,
  //       children: [
  //         Icon(Icons.history, color: Colors.grey, size: 28),
  //         Icon(Icons.restaurant_menu, color: Colors.black, size: 34),
  //         Icon(Icons.person_outline, color: Colors.grey, size: 28),
  //       ],
  //     ),
  //   );
  // }
}
