import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_constants.dart';
import '../../../core/utils/image_helper.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';
import '../controllers/post_controller.dart';
import '../models/post_model.dart';
import 'add_post_screen.dart';

class LandlordHomeScreen extends StatelessWidget {
  final UserModel user;

  const LandlordHomeScreen({super.key, required this.user});

  void _onAddPostPressed(BuildContext context) {
    Get.to(() => const AddPostScreen(), transition: Transition.rightToLeft);
  }

  @override
  Widget build(BuildContext context) {
    final postController = Get.put(PostController());
    const emeraldTheme = Color(0xFF059669);
    const darkEmerald = Color(0xFF064E3B);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: darkEmerald,
        elevation: 0,
        title: Text(
          'Landlord Home',
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              final authCtrl = Get.find<AuthController>();
              authCtrl.selectedRole.value = AppConstants.roleBachelor;
              authCtrl.handleNavigation(authCtrl.currentUser.value!);
              Get.snackbar(
                'Bachelor Mode',
                'Switched to Seeker view',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: darkEmerald,
                colorText: Colors.white,
              );
            },
            icon: const Icon(
              Icons.swap_horizontal_circle_rounded,
              color: Colors.white,
            ),
            tooltip: 'Switch Mode',
          ),
          IconButton(
            onPressed: () => Get.find<AuthController>().logout(),
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Logout',
          ),
          SizedBox(width: 8.w),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onAddPostPressed(context),
        backgroundColor: emeraldTheme,
        icon: const Icon(Icons.add_home_rounded, color: Colors.white),
        label: Text(
          'Add Room',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Obx(() {
        if (postController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: emeraldTheme),
          );
        }

        final posts = postController.myPosts;
        final totalPosts = posts.length;
        final availablePosts = posts.where((p) => p.isAvailable).length;
        final totalSeats = posts.fold<int>(0, (sum, p) => sum + p.seatCount);

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Luxury Emerald Stats Banner
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.all(16.r),
                padding: EdgeInsets.all(18.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [darkEmerald, emeraldTheme],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: emeraldTheme.withValues(alpha: 0.28),
                      blurRadius: 12.r,
                      offset: Offset(0, 5.h),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Icon(
                                Icons.home_work_rounded,
                                color: Colors.white,
                                size: 18.r,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              'Room Overview',
                              style: GoogleFonts.poppins(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            'Live Stats',
                            style: GoogleFonts.poppins(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    Divider(
                      color: Colors.white.withValues(alpha: 0.22),
                      height: 1,
                      thickness: 1,
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem('Total Posts', '$totalPosts'),
                        ),
                        _buildVerticalDivider(),
                        Expanded(
                          child: _buildStatItem(
                            'Active Posts',
                            '$availablePosts',
                          ),
                        ),
                        _buildVerticalDivider(),
                        Expanded(
                          child: _buildStatItem('Total Seats', '$totalSeats'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Section Title
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(7.r),
                          decoration: BoxDecoration(
                            color: emeraldTheme.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(
                            Icons.bedroom_parent_rounded,
                            color: emeraldTheme,
                            size: 18.r,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'My Posts',
                          style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (totalPosts > 0)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: emeraldTheme.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          '$totalPosts Added',
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: emeraldTheme,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Post List or Empty State
            if (posts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(context),
              )
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final post = posts[index];
                    return _LandlordPostCard(
                      post: post,
                      postController: postController,
                    );
                  }, childCount: posts.length),
                ),
              ),
            SliverToBoxAdapter(child: SizedBox(height: 80.h)),
          ],
        );
      }),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 11.5.sp,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 42.h,
      width: 1,
      color: Colors.white.withValues(alpha: 0.22),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    const emeraldTheme = Color(0xFF059669);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: emeraldTheme.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.home_work_outlined,
                size: 60.r,
                color: emeraldTheme,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'No Rooms Yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Tap + below to add your first room.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () => _onAddPostPressed(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: emeraldTheme,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Add Room',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LandlordPostCard extends StatelessWidget {
  final PostModel post;
  final PostController postController;

  const _LandlordPostCard({required this.post, required this.postController});

  void _confirmDelete() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20.r,
                offset: Offset(0, 10.h),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_forever_rounded,
                  color: AppTheme.errorColor,
                  size: 44.r,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Delete Room?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Are you sure you want to delete "${post.title}"?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        postController.deleteMessPost(post.postId);
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Delete',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPostOptionsPopup(BuildContext context) {
    const emeraldTheme = Color(0xFF059669);
    const darkEmerald = Color(0xFF064E3B);

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20.r,
              offset: Offset(0, -4.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
            SizedBox(height: 18.h),

            // Mini Preview Banner
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    emeraldTheme.withValues(alpha: 0.12),
                    emeraldTheme.withValues(alpha: 0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: emeraldTheme.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: emeraldTheme,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.home_work_rounded,
                      color: Colors.white,
                      size: 24.r,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '৳${post.rent.toInt()} / mo  •  ${post.address}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),
            Text(
              'Manage Room',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),

            // Edit Option Card
            InkWell(
              onTap: () {
                Get.back();
                Get.to(
                  () => AddPostScreen(existingPost: post),
                  transition: Transition.rightToLeft,
                );
              },
              borderRadius: BorderRadius.circular(16.r),
              child: Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: emeraldTheme.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [darkEmerald, emeraldTheme],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                            color: emeraldTheme.withValues(alpha: 0.25),
                            blurRadius: 8.r,
                            offset: Offset(0, 3.h),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 22.r,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Room',
                            style: GoogleFonts.poppins(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Update rent, seats, or photos',
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: emeraldTheme,
                      size: 18.r,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 12.h),

            // Delete Option Card
            InkWell(
              onTap: () {
                Get.back();
                _confirmDelete();
              },
              borderRadius: BorderRadius.circular(16.r),
              child: Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7F7),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppTheme.errorColor.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.errorColor.withValues(alpha: 0.25),
                            blurRadius: 8.r,
                            offset: Offset(0, 3.h),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                        size: 22.r,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delete Room',
                            style: GoogleFonts.poppins(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.errorColor,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Remove room from app',
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppTheme.errorColor,
                      size: 18.r,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 6.h),
          ],
        ),
      ),
    );
  }

  String _cleanEnglishText(String input) {
    String clean = input
        .replaceAll('০', '0')
        .replaceAll('১', '1')
        .replaceAll('২', '2')
        .replaceAll('৩', '3')
        .replaceAll('৪', '4')
        .replaceAll('৫', '5')
        .replaceAll('৬', '6')
        .replaceAll('৭', '7')
        .replaceAll('৮', '8')
        .replaceAll('৯', '9');

    // Remove bracketed Bangla text e.g. "WiFi (ওয়াইফাই)" -> "WiFi"
    clean = clean.replaceAll(RegExp(r'\s*\([\u0980-\u09FF\s/a-zA-Z-]+\)'), '');
    clean = clean.replaceAll(RegExp(r'\s*\([\u0980-\u09FF\s]+\)'), '');

    // Translate common Bangla words
    final map = {
      'ওয়াইফাই': 'WiFi',
      'ওয়াইফাই': 'WiFi',
      'ফিল্টার পানি': 'Water Filter',
      'পানি': 'Water',
      'সিসিটিভি': 'CCTV',
      'জেনারেটর': 'Generator',
      'লিফট': 'Lift',
      'অ্যাটাচড বাথরুম': 'Attached Bath',
      'বাথরুম': 'Bathroom',
      'বেলকনি': 'Balcony',
      'খাবার ব্যবস্থা': 'Meal Available',
      'খাবার': 'Meal',
      'টি সিট': ' Seat',
      'টা সিট': ' Seat',
      'টি রুম': ' Room',
      'টা রুম': ' Room',
      'সিট': 'Seat',
      'রুম': 'Room',
      'মেস': 'Mess',
      'ভাড়া': 'Rent',
      'ভারা': 'Rent',
      'ছেলে': 'Male',
      'মেয়ে': 'Female',
      'মেয়ে': 'Female',
    };

    map.forEach((bangla, english) {
      clean = clean.replaceAll(bangla, english);
    });

    // Remove any remaining standalone Bangla characters
    clean = clean.replaceAll(RegExp(r'[\u0980-\u09FF]'), '').trim();
    // Fix multiple spaces
    clean = clean.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (clean == '1 Seat' || clean == '1 Seats') return '1 Seat';
    if (clean == '2 Seat') return '2 Seats';
    if (clean == '3 Seat') return '3 Seats';
    if (clean == '4 Seat') return '4 Seats';
    if (clean == '5 Seat') return '5 Seats';

    if (clean.isEmpty) return 'Available';
    return clean;
  }

  @override
  Widget build(BuildContext context) {
    const emeraldTheme = Color(0xFF059669);
    const darkEmerald = Color(0xFF064E3B);

    final String genderText = post.bachelorType == 'female'
        ? 'Female Only'
        : post.bachelorType == 'both'
        ? 'Any Bachelor'
        : 'Male Only';

    return Container(
      margin: EdgeInsets.only(bottom: 18.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 16.r,
            offset: Offset(0, 6.h),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Luxury Image banner with gradient overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                child: post.images.isNotEmpty
                    ? AppImageHelper.buildImage(
                        post.images.first,
                        height: 180.h,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 180.h,
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Icon(
                            Icons.home_work_rounded,
                            size: 50.r,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
              ),
              // Dark subtle gradient at bottom of photo
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20.r),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                ),
              ),
              // Top-Left Price Badge
              Positioned(
                top: 14.h,
                left: 14.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 7.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [darkEmerald, emeraldTheme],
                    ),
                    borderRadius: BorderRadius.circular(25.r),
                    boxShadow: [
                      BoxShadow(
                        color: darkEmerald.withValues(alpha: 0.35),
                        blurRadius: 8.r,
                        offset: Offset(0, 3.h),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sell_rounded, color: Colors.white, size: 13.r),
                      SizedBox(width: 5.w),
                      Text(
                        '৳${post.rent.toInt()} / month',
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Top-Right Gender Badge
              Positioned(
                top: 14.h,
                right: 14.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 14.r,
                        color: darkEmerald,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        genderText,
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: darkEmerald,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom-Right Photo Counter Badge (if multiple photos)
              if (post.images.length > 1)
                Positioned(
                  bottom: 12.h,
                  right: 14.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.photo_library_rounded,
                          color: Colors.white,
                          size: 12.r,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${post.images.length} Photos',
                          style: GoogleFonts.poppins(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Details Section
          Padding(
            padding: EdgeInsets.all(18.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Approval Status Banner
                _buildStatusBanner(post.paymentStatus),
                SizedBox(height: 10.h),
                // Title
                Text(
                  _cleanEnglishText(post.title),
                  style: GoogleFonts.poppins(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 6.h),
                // Location
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 16.r,
                      color: emeraldTheme,
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        _cleanEnglishText(post.address),
                        style: GoogleFonts.poppins(
                          fontSize: 12.5.sp,
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: emeraldTheme.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.school_rounded,
                            size: 13.r,
                            color: emeraldTheme,
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            post.preferredTenant,
                            style: GoogleFonts.poppins(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w600,
                              color: emeraldTheme,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),

                // Real-Estate Specs Container (Seats & Contact)
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      // Seats Column
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(7.r),
                              decoration: BoxDecoration(
                                color: emeraldTheme.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Icon(
                                Icons.single_bed_rounded,
                                size: 18.r,
                                color: emeraldTheme,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Available Seats',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10.sp,
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    _cleanEnglishText(post.displaySeats),
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.5.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Vertical separator
                      Container(
                        height: 32.h,
                        width: 1,
                        color: const Color(0xFFE2E8F0),
                      ),
                      SizedBox(width: 12.w),
                      // Phone Column
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(7.r),
                              decoration: BoxDecoration(
                                color: emeraldTheme.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Icon(
                                Icons.phone_in_talk_rounded,
                                size: 18.r,
                                color: emeraldTheme,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Contact Number',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10.sp,
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    (post.ownerPhone != null &&
                                            post.ownerPhone!.isNotEmpty)
                                        ? post.ownerPhone!
                                        : 'N/A',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),

                // Facilities wrap with emerald check badges
                if (post.facilities.isNotEmpty)
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: post.facilities.take(4).map((f) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 5.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 13.r,
                              color: emeraldTheme,
                            ),
                            SizedBox(width: 5.w),
                            Text(
                              _cleanEnglishText(f),
                              style: GoogleFonts.poppins(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF065F46),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                SizedBox(height: 12.h),
                Divider(color: const Color(0xFFE2E8F0), height: 24.h),

                // Bottom Action Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Active status badge with indicator dot
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: post.isAvailable
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: post.isAvailable
                              ? const Color(0xFFA7F3D0)
                              : const Color(0xFFFECACA),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8.r,
                            height: 8.r,
                            decoration: BoxDecoration(
                              color: post.isAvailable
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            post.isAvailable ? 'Active Listing' : 'Booked',
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: post.isAvailable
                                  ? const Color(0xFF065F46)
                                  : const Color(0xFF991B1B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Premium Manage Button
                    InkWell(
                      onTap: () => _showPostOptionsPopup(context),
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 9.h,
                        ),
                        decoration: BoxDecoration(
                          color: emeraldTheme,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: emeraldTheme.withValues(alpha: 0.28),
                              blurRadius: 8.r,
                              offset: Offset(0, 3.h),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Manage Room',
                              style: GoogleFonts.poppins(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Icon(
                              Icons.tune_rounded,
                              color: Colors.white,
                              size: 16.r,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(String status) {
    final s = status.trim().toLowerCase();
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    if (s == 'pending') {
      bgColor = const Color(0xFFFEF3C7); // Amber 100
      textColor = const Color(0xFFB45309); // Amber 700
      icon = Icons.pending_actions_rounded;
      label = '⏳ PENDING ADMIN REVIEW';
    } else if (s == 'rejected') {
      bgColor = const Color(0xFFFEE2E2); // Red 100
      textColor = const Color(0xFFB91C1C); // Red 700
      icon = Icons.cancel_rounded;
      label = '❌ REJECTED BY ADMIN';
    } else {
      bgColor = const Color(0xFFD1FAE5); // Green 100
      textColor = const Color(0xFF047857); // Green 700
      icon = Icons.check_circle_rounded;
      label = '✅ ACTIVE & LIVE';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16.r, color: textColor),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
