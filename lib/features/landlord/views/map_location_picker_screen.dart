import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';


class MapLocationPickerScreen extends StatelessWidget {
  final LatLng? initialLocation;

  const MapLocationPickerScreen({super.key, this.initialLocation});

  @override
  Widget build(BuildContext context) {
    final Rx<LatLng> selectedLocation = (initialLocation ?? const LatLng(23.8103, 90.4125)).obs;
    final MapController mapController = MapController();
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
              Get.back(result: selectedLocation.value);
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
          Obx(() => FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: selectedLocation.value,
              initialZoom: 14.0,
              onTap: (tapPosition, point) {
                selectedLocation.value = point;
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
                    point: selectedLocation.value,
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
          )),
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
