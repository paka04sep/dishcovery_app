import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
    final String? fontFamily = Theme.of(
      context,
    ).textTheme.bodyLarge?.fontFamily;

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
                child: _buildRestaurantHeader(fontFamily),
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

              _buildActionButtons(context, fontFamily),
            ],
          ),

          // ปุ่ม Back ลอย (ถูกที่แล้ว)
          _buildFloatingBackButton(context),
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

  Widget _buildActionButtons(BuildContext context, String? fontFamily) {
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
                'START NAVIGATION',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.5,
                  fontFamily: fontFamily,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildActionButtons(String? fontFamily) {
  // return Column(
  // children: [ Padding( padding: const EdgeInsets.symmetric(vertical: 20),
  // child: ElevatedButton.icon( onPressed: _launchNavigation,
  // icon: const Icon(Icons.navigation),
  // label: const Text("START NAVIGATION"),
  // style: ElevatedButton.styleFrom(
  // backgroundColor: Colors.white,
  // foregroundColor: Colors.black,
  // padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
  // shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(30),
  // ),
  // ),
  // ),
  // ),
  // // _buildBottomNavBar(),
  // /],
  // /);
  // /}

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
