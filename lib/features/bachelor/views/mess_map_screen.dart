import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_helper.dart';
import '../../notifications/views/widgets/notification_bell_action.dart';
import '../../landlord/controllers/post_controller.dart';
import '../../landlord/models/post_model.dart';
import 'room_detail_screen.dart';

class MessMapScreen extends StatefulWidget {
  const MessMapScreen({super.key});

  @override
  State<MessMapScreen> createState() => _MessMapScreenState();
}

class _MessMapScreenState extends State<MessMapScreen> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final PostController postController = Get.find<PostController>();
    const emeraldTheme = Color(0xFF059669);
    final Color primaryColor = const Color(0xFF059669);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16.w,
        title: Text(
          'Map View',
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: Colors.white, size: 24.r),
            onPressed: () => postController.refreshPosts(),
          ),
          const NotificationBellAction(),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(64.h),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(50.r),
              ),
              child: TextField(
                textAlignVertical: TextAlignVertical.center,
                onChanged: (val) => postController.updateSearchQuery(val),
                style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.transparent,
                  hintText: 'Search rooms, areas...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: Colors.white70,
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.white70, size: 22.r),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (postController.isLoading.value && postController.allPosts.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: emeraldTheme));
        }

        // Use filteredPosts instead of allPosts so the search bar works!
        final List<PostModel> activePosts = postController.filteredPosts
            .where((post) => post.isPublished && post.isAvailable)
            .toList();

        return Stack(
          children: [
            GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _fitMapToMarkers(activePosts);
              },
              initialCameraPosition: const CameraPosition(
                target: LatLng(23.8103, 90.4125),
                zoom: 12.0,
              ),
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              markers: activePosts.asMap().entries.map((entry) {
                final index = entry.key;
                final post = entry.value;
                
                // Offset existing posts that have the exact same hardcoded default location
                double lat = post.latitude;
                double lng = post.longitude;
                if (lat == 23.8103 && lng == 90.4125) {
                  lat += (index % 5) * 0.003 - 0.006;
                  lng += (index ~/ 5) * 0.003 - 0.006;
                }

                return Marker(
                  markerId: MarkerId('post_${post.postId}'),
                  position: LatLng(lat, lng),
                  icon: BitmapDescriptor.defaultMarkerWithHue(150.0), // Emerald green hue
                  onTap: () => _showPostDetailsBottomSheet(context, post),
                );
              }).toSet(),
            ),
            
            // Zoom Buttons
            Positioned(
              right: 16.w,
              bottom: 100.h, // Adjusted to avoid overlapping with FAB if any, though map might not have FAB
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: 'zoom_in',
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: () {
                      _mapController?.animateCamera(CameraUpdate.zoomIn());
                    },
                    child: Icon(Icons.add_rounded, color: primaryColor),
                  ),
                  SizedBox(height: 8.h),
                  FloatingActionButton(
                    heroTag: 'zoom_out',
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: () {
                      _mapController?.animateCamera(CameraUpdate.zoomOut());
                    },
                    child: Icon(Icons.remove_rounded, color: primaryColor),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showPostDetailsBottomSheet(BuildContext context, PostModel post) {
    const emeraldTheme = Color(0xFF059669);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: SizedBox(
                    width: 80.w,
                    height: 80.w,
                    child: AppImageHelper.buildImage(post.images.first),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Tk.${post.rent.toInt()} / month',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                          color: emeraldTheme,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  Get.to(() => RoomDetailScreen(post: post),
                      transition: Transition.rightToLeft);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: emeraldTheme,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'View Details',
                  style: GoogleFonts.poppins(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _fitMapToMarkers(List<PostModel> posts) {
    if (_mapController == null || posts.isEmpty) return;

    if (posts.length == 1) {
      // If only one post, just center it
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(posts.first.latitude, posts.first.longitude),
        14.0,
      ));
      return;
    }

    double minLat = posts.first.latitude;
    double maxLat = posts.first.latitude;
    double minLng = posts.first.longitude;
    double maxLng = posts.first.longitude;

    for (var post in posts) {
      if (post.latitude < minLat) minLat = post.latitude;
      if (post.latitude > maxLat) maxLat = post.latitude;
      if (post.longitude < minLng) minLng = post.longitude;
      if (post.longitude > maxLng) maxLng = post.longitude;
    }

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      ),
      50.0, // Padding
    ));
  }
}
