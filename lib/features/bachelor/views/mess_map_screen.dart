import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_helper.dart';
import '../../landlord/controllers/post_controller.dart';
import '../../landlord/models/post_model.dart';
import 'room_detail_screen.dart';

class MessMapScreen extends StatefulWidget {
  const MessMapScreen({super.key});

  @override
  State<MessMapScreen> createState() => _MessMapScreenState();
}

class _MessMapScreenState extends State<MessMapScreen> {
  final PostController _postController = Get.find<PostController>();
  final MapController _mapController = MapController();

  // Default center (Dhaka)
  final LatLng _center = const LatLng(23.8103, 90.4125);

  @override
  Widget build(BuildContext context) {
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
            onPressed: () => _postController.refreshPosts(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(64.h),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
            child: Container(
              height: 42.h,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: TextField(
                onChanged: (val) => _postController.searchQuery.value = val,
                style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
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
        if (_postController.isLoading.value && _postController.allPosts.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: emeraldTheme));
        }

        // Use filteredPosts instead of allPosts so the search bar works!
        final List<PostModel> activePosts = _postController.filteredPosts
            .where((post) => post.isPublished && post.isAvailable)
            .toList();

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 12.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.mess_finder',
                ),
                MarkerLayer(
                  markers: activePosts.map((post) {
                    return Marker(
                      point: LatLng(post.latitude, post.longitude),
                      width: 36.r,
                      height: 36.r,
                      child: GestureDetector(
                        onTap: () => _showPostDetailsBottomSheet(context, post),
                        child: Container(
                          decoration: BoxDecoration(
                            color: emeraldTheme,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          child: Icon(
                            Icons.home_work_rounded,
                            color: Colors.white,
                            size: 18.r,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
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
                      final currentZoom = _mapController.camera.zoom;
                      final currentCenter = _mapController.camera.center;
                      _mapController.move(currentCenter, currentZoom + 1);
                    },
                    child: Icon(Icons.add_rounded, color: primaryColor),
                  ),
                  SizedBox(height: 8.h),
                  FloatingActionButton(
                    heroTag: 'zoom_out',
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: () {
                      final currentZoom = _mapController.camera.zoom;
                      final currentCenter = _mapController.camera.center;
                      _mapController.move(currentCenter, currentZoom - 1);
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
}
