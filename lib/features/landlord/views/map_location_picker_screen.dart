import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/services/location_service.dart';

class MapLocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const MapLocationPickerScreen({super.key, this.initialLocation});

  @override
  State<MapLocationPickerScreen> createState() => _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  late Rx<LatLng> selectedLocation;
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final RxBool _isSearching = false.obs;
  final RxBool _myLocationEnabled = false.obs;
  late final CameraPosition _initialCameraPosition;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialLocation ?? const LatLng(23.8103, 90.4125);
    selectedLocation = initial.obs;
    _initialCameraPosition = CameraPosition(target: initial, zoom: 14.0);
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    // If the user already provided an initial location, we don't strictly need to fetch,
    // but typically we want to jump to current location if they are adding a new post.
    if (widget.initialLocation == null) {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        _myLocationEnabled.value = true;
        final newLatLng = LatLng(position.latitude, position.longitude);
        selectedLocation.value = newLatLng;
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 15.0));
      }
    } else {
      _myLocationEnabled.value = true;
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    
    _isSearching.value = true;
    try {
      // Append ", Bangladesh" for better local context accuracy
      final searchQuery = '$query, Bangladesh';
      
      List<Location> locations = await locationFromAddress(searchQuery);
      
      if (locations.isNotEmpty) {
        final newLatLng = LatLng(locations.first.latitude, locations.first.longitude);
        selectedLocation.value = newLatLng;
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 15.0));
      } else {
        _showErrorSnackbar();
      }
    } catch (e) {
      debugPrint('Error searching location: $e');
      _showErrorSnackbar();
    } finally {
      _isSearching.value = false;
    }
  }

  void _showErrorSnackbar() {
    Get.snackbar(
      'Not Found',
      'Could not find any location matching your search.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade600,
      colorText: Colors.white,
      margin: EdgeInsets.all(16.r),
      borderRadius: 12.r,
      icon: const Icon(Icons.error_outline_rounded, color: Colors.white),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF059669);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Google Map
          Obx(() => GoogleMap(
                initialCameraPosition: _initialCameraPosition,
                myLocationEnabled: _myLocationEnabled.value,
                myLocationButtonEnabled: _myLocationEnabled.value,
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                onTap: (LatLng point) {
                  selectedLocation.value = point;
                },
                markers: {
                  Marker(
                    markerId: const MarkerId('selected_location'),
                    position: selectedLocation.value,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  ),
                },
              )),
              
          // 2. Top UI: Floating Back Button & Search Bar
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  // Back Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 8.r, offset: Offset(0, 2.h)),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20.r),
                      onPressed: () => Get.back(),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  
                  // Search Bar
                  Expanded(
                    child: Container(
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30.r),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 8.r, offset: Offset(0, 2.h)),
                        ],
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 16.w),
                          Icon(Icons.search_rounded, color: Colors.grey.shade500, size: 20.r),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              onSubmitted: _searchLocation,
                              style: GoogleFonts.poppins(fontSize: 14.sp),
                              decoration: InputDecoration(
                                hintText: 'Search for area, road...',
                                hintStyle: GoogleFonts.poppins(fontSize: 13.5.sp, color: Colors.grey.shade400),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                              ),
                            ),
                          ),
                          Obx(() => _isSearching.value
                              ? Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                                  child: SizedBox(
                                    width: 18.r,
                                    height: 18.r,
                                    child: const CircularProgressIndicator(color: primaryColor, strokeWidth: 2.5),
                                  ),
                                )
                              : IconButton(
                                  icon: Icon(Icons.clear_rounded, color: Colors.grey.shade400, size: 20.r),
                                  onPressed: () => _searchController.clear(),
                                )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 3. Bottom UI: Info Box & Confirm Button
          Positioned(
            bottom: 32.h,
            left: 20.w,
            right: 20.w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Info Box
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10.r, offset: Offset(0, 4.h)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.touch_app_rounded, color: primaryColor, size: 20.r),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'Tap or drag the map to place the pin precisely.',
                          style: GoogleFonts.poppins(fontSize: 12.5.sp, color: Colors.black87, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                
                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  height: 54.h,
                  child: ElevatedButton(
                    onPressed: () => Get.back(result: selectedLocation.value),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                      elevation: 4,
                    ),
                    child: Text(
                      'Confirm Location',
                      style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
