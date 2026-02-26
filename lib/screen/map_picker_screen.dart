import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:dishcovery_app/constants/app_constants.dart';

class MapPickerScreen extends StatefulWidget {
  final LatLng initialLocation;

  const MapPickerScreen({super.key, required this.initialLocation});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng _selectedLocation;
  late GoogleMapController _controller;
  String _currentAddress = 'กำลังค้นหาที่อยู่...';
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _useFallbackLocation();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _useFallbackLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _useFallbackLocation();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _selectedLocation = LatLng(position.latitude, position.longitude);

      await _getAddressFromLatLng(_selectedLocation);

      setState(() {
        _isMapReady = true; // พร้อมแสดง Map แล้ว
      });
    } catch (e) {
      _useFallbackLocation();
    }
  }

  void _useFallbackLocation() async {
    _selectedLocation = widget.initialLocation;
    await _getAddressFromLatLng(_selectedLocation);

    setState(() {
      _isMapReady = true;
    });
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentAddress =
              '${place.name}, ${place.subLocality}, ${place.locality}';
          if (_currentAddress.startsWith(', ')) {
            _currentAddress = _currentAddress.substring(2);
          }
        });
      } else {
        setState(() {
          _currentAddress = 'ไม่พบที่อยู่';
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = 'ไม่พบที่อยู่';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchPlace() async {
    final query = _searchController.text;
    if (query.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      FocusScope.of(context).unfocus();
      List<Location> locations = await locationFromAddress(query);

      if (locations.isNotEmpty) {
        final loc = locations.first;
        final newLoc = LatLng(loc.latitude, loc.longitude);
        _controller.animateCamera(CameraUpdate.newLatLngZoom(newLoc, 15));
        setState(() {
          _selectedLocation = newLoc;
        });
        await _getAddressFromLatLng(newLoc);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ไม่พบสถานที่นี้')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ค้นหาล้มเหลว: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    final newLoc = LatLng(position.latitude, position.longitude);
    setState(() {
      _selectedLocation = newLoc;
    });
    _controller.animateCamera(CameraUpdate.newLatLng(newLoc));
    _getAddressFromLatLng(newLoc);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'เลือกตำแหน่งที่ตั้ง',
          style: AppTextStyles.profileText.copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, {
                'location': _selectedLocation,
                'address': _currentAddress,
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isMapReady) _buildMapContent(),
          if (!_isMapReady) locationFindingOverlay(),
        ],
      ),
    );
  }

  Widget locationFindingOverlay() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            BouncingPin(),
            SizedBox(height: 16),
            AnimatedLoadingText(),
          ],
        ),
      ),
    );
  }

  Widget _buildMapContent() {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _selectedLocation,
            zoom: 16,
          ),
          onMapCreated: (controller) => _controller = controller,
          onCameraIdle: () {
            _getAddressFromLatLng(_selectedLocation);
          },
          onCameraMove: (position) {
            _selectedLocation = position.target;
          },
        ),

        const Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: 25.0),
            child: Icon(Icons.location_pin, size: 50, color: Colors.red),
          ),
        ),

        // Search Bar
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: Row(
            children: [
              //  SEARCH BOX
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'ค้นหาสถานที่...',
                            hintStyle: AppTextStyles.hintText,
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _searchPlace(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.search,
                          color: AppColors.primaryBlue,
                        ),
                        onPressed: _searchPlace,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.my_location, color: Colors.white),
                  onPressed: _getCurrentLocation,
                ),
              ),
            ],
          ),
        ),

        // Address Card Bottom
        Positioned(
          bottom: 20,
          left: 20,
          right: 80, // Leave space for FAB
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ตำแหน่งที่เลือก', style: AppTextStyles.profileText),
                const SizedBox(height: 8),
                _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _currentAddress,
                        style: AppTextStyles.profileText.copyWith(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BouncingPin extends StatefulWidget {
  const BouncingPin({super.key});

  @override
  State<BouncingPin> createState() => _BouncingPinState();
}

class _BouncingPinState extends State<BouncingPin>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0,
      end: -12,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: const Icon(Icons.location_pin, size: 56, color: Colors.red),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class AnimatedLoadingText extends StatefulWidget {
  const AnimatedLoadingText({super.key});

  @override
  State<AnimatedLoadingText> createState() => _AnimatedLoadingTextState();
}

class _AnimatedLoadingTextState extends State<AnimatedLoadingText> {
  int _dotCount = 0;

  @override
  void initState() {
    super.initState();
    _startDots();
  }

  void _startDots() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return false;
      setState(() {
        _dotCount = (_dotCount + 1) % 4;
      });
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      'กำลังค้นหาตำแหน่งของคุณ${'.' * _dotCount}',
      style: AppTextStyles.profileText.copyWith(
        fontSize: 14,
        color: Colors.grey[700],
      ),
    );
  }
}
