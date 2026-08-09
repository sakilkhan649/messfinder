import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';

class MapLocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const MapLocationPickerScreen({super.key, this.initialLocation});

  @override
  State<MapLocationPickerScreen> createState() => _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  late LatLng _selectedLocation;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Default to Dhaka if no location provided
    _selectedLocation = widget.initialLocation ?? const LatLng(23.8103, 90.4125);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF059669);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          'Pick Location',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(result: _selectedLocation);
            },
            child: Text(
              'Confirm',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 14.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mess_finder',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 40.r,
                    height: 40.r,
                    child: Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40.r,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 32.h,
            left: 24.w,
            right: 24.w,
            child: Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10.r,
                    offset: Offset(0, 5.h),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: primaryColor),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Tap anywhere on the map to place the pin for your mess location.',
                      style: GoogleFonts.poppins(fontSize: 14.sp),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
