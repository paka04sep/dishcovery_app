import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/restaurant_model.dart';

class RestaurantMapScreen extends StatefulWidget {
  final RestaurantCardData restaurant;

  const RestaurantMapScreen({super.key, required this.restaurant});

  @override
  State<RestaurantMapScreen> createState() => _RestaurantMapScreenState();
}

class _RestaurantMapScreenState extends State<RestaurantMapScreen> {
  late GoogleMapController mapController;
  Position? _currentPosition;

  // พิกัดจำลองของร้านอาหาร (ในแอปจริงควรดึงจาก restaurant.latitude/longitude)
  // ที่นี่ผมขอสมมติพิกัดใจกลางกรุงเทพฯ สำหรับร้านนี้ครับ
  final LatLng _restaurantLocation = const LatLng(13.7563, 100.5018);

  @override
  void initState() {
    super.initState();
    _determinePosition(); // เรียกขอ Permission และตำแหน่งเมื่อเริ่มหน้าจอ
  }

  /// ฟังก์ชันสำหรับขอ Permission และดึงตำแหน่งปัจจุบัน
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // ตรวจสอบว่าเปิด Service Location หรือยัง
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    // ดึงตำแหน่งปัจจุบัน
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
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
          // 1. ส่วนบน: ปุ่มย้อนกลับและ Card ข้อมูลร้าน (ตามรูป image_41fdb8.png)
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
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 10),
                // Restaurant Card Header
                Container(
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
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.restaurant.name.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: fontFamily,
                          ),
                        ),
                        Text(
                          'DETAILS',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontFamily: fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. ส่วนแผนที่ (Google Map)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _restaurantLocation,
                    zoom: 14.0,
                  ),
                  myLocationEnabled: true, // แสดงจุดตำแหน่งของเราบนแผนที่
                  myLocationButtonEnabled: true,
                  markers: {
                    Marker(
                      markerId: const MarkerId('restaurant_pos'),
                      position: _restaurantLocation,
                      infoWindow: InfoWindow(title: widget.restaurant.name),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                    ),
                  },
                ),
              ),
            ),
          ),

          // 3. ปุ่ม Navigation (จำลองปุ่มข้างล่างแผนที่)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: ElevatedButton.icon(
              onPressed: () {
                // ในเครื่องจริงจะใช้ url_launcher เพื่อเปิด Google Maps App สำหรับนำทาง
                print("นำทางไปที่: ${widget.restaurant.name}");
              },
              icon: const Icon(Icons.navigation),
              label: const Text("START NAVIGATION"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),

          // 4. Bottom Navigation Bar (คงไว้ตามดีไซน์)
          Container(
            height: 70,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Icon(Icons.history, color: Colors.grey, size: 30),
                Icon(Icons.restaurant_menu, color: Colors.grey, size: 30),
                Icon(Icons.person_outline, color: Colors.grey, size: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
