import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_constants.dart';
import '../../../core/utils/image_helper.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';
import '../../auth/repositories/auth_repo.dart';
import '../../landlord/controllers/post_controller.dart';
import '../../landlord/models/post_model.dart';
import 'room_detail_screen.dart';

class BachelorHomeScreen extends StatelessWidget {
  final UserModel user;

  const BachelorHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final postController = Get.put(PostController());
    const primaryBlue = Color(0xFF0EA5E9);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Find Mess (Bachelor)',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              user.name,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              final authCtrl = Get.find<AuthController>();
              authCtrl.selectedRole.value = AppConstants.roleLandlord;
              authCtrl.handleNavigation(authCtrl.currentUser.value!);
              Get.snackbar(
                'Landlord Mode 🔄',
                'You can now add and manage mess listings',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: const Color(0xFF7C3AED),
                colorText: Colors.white,
              );
            },
            icon: const Icon(Icons.swap_horizontal_circle_rounded,
                color: Colors.white),
            tooltip: 'Switch to Landlord Mode',
          ),
          // Test Reset Button (to easily test payment dialog when account is already approved)
          IconButton(
            onPressed: () async {
              final authCtrl = Get.find<AuthController>();
              final currentUser = authCtrl.currentUser.value;
              if (currentUser != null) {
                final updatedUser = currentUser.copyWith(isPaid: false);
                authCtrl.currentUser.value = updatedUser;
                await Get.find<AuthRepository>().saveUserData(updatedUser);
                Get.snackbar(
                  'Test Mode Reset 🧪',
                  'Account reset to Unpaid! Clicking "View & Contact" on any mess will trigger the payment dialog.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.amber.shade800,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 4),
                );
              }
            },
            icon: const Icon(Icons.science_outlined, color: Colors.white),
            tooltip: 'Test Mode: Reset to Unpaid',
          ),
          IconButton(
            onPressed: () => Get.find<AuthController>().logout(),
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Logout',
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(24.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withValues(alpha: 0.25),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search field & Budget Filter Button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) =>
                            postController.searchQuery.value = val,
                        decoration: InputDecoration(
                          hintText: 'Search by area or mess name...',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            color: Colors.grey.shade600,
                          ),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: primaryBlue),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 12.h),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14.r),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    _buildBudgetFilterButton(context, postController),
                  ],
                ),
                SizedBox(height: 12.h),

                // Horizontal Category Filter Chips (ONLY ONE chip can be selected at a time!)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Obx(() {
                    return Row(
                      children: [
                        _buildGenderFilterChip(
                            postController, 'all', 'All Mess'),
                        SizedBox(width: 8.w),
                        _buildGenderFilterChip(
                            postController, 'male', 'Male Only'),
                        SizedBox(width: 8.w),
                        _buildGenderFilterChip(
                            postController, 'female', 'Female Only'),
                        SizedBox(width: 8.w),
                        _buildGenderFilterChip(
                            postController, 'both', 'Any Bachelor'),
                        if (postController.selectedBudgetFilter.value >
                            0) ...[
                          SizedBox(width: 12.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade400,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Budget: < ৳${postController.selectedBudgetFilter.value}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                GestureDetector(
                                  onTap: () => postController
                                      .selectedBudgetFilter.value = 0,
                                  child: Icon(Icons.close_rounded,
                                      size: 14.r, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),

          // Feed List
          Expanded(
            child: Obx(() {
              if (postController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final posts = postController.filteredPosts;

              if (posts.isEmpty) {
                return RefreshIndicator(
                  onRefresh: postController.refreshPosts,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: 100.h),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.r),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded,
                                  size: 64.r, color: Colors.grey.shade400),
                              SizedBox(height: 16.h),
                              Text(
                                'No Listings Found',
                                style: GoogleFonts.poppins(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                'No mess listings match your current filters. Pull down to refresh or try adjusting your search.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.sp,
                                  color: AppTheme.textSecondary,
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

              return RefreshIndicator(
                onRefresh: postController.refreshPosts,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16.r),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _BachelorPostCard(post: post);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderFilterChip(
      PostController controller, String value, String label) {
    const primaryBlue = Color(0xFF0EA5E9);
    final isSelected = controller.selectedGenderFilter.value == value;

    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? primaryBlue : Colors.white,
        ),
      ),
      selected: isSelected,
      selectedColor: Colors.white,
      backgroundColor: primaryBlue.withValues(alpha: 0.6),
      checkmarkColor: primaryBlue,
      onSelected: (val) {
        if (val) controller.selectedGenderFilter.value = value;
      },
    );
  }

  Widget _buildBudgetFilterButton(
      BuildContext context, PostController controller) {
    const primaryBlue = Color(0xFF0EA5E9);
    return Obx(() {
      final isFiltered = controller.selectedBudgetFilter.value > 0;
      return InkWell(
        onTap: () => _showBudgetBottomSheet(context, controller),
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isFiltered ? Colors.amber.shade400 : Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withValues(alpha: 0.15),
                blurRadius: 8.r,
                offset: Offset(0, 3.h),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 20.r,
                color: isFiltered ? Colors.black87 : primaryBlue,
              ),
              SizedBox(width: 4.w),
              Text(
                isFiltered
                    ? '< ৳${controller.selectedBudgetFilter.value}'
                    : 'Budget',
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: isFiltered ? Colors.black87 : primaryBlue,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showBudgetBottomSheet(BuildContext context, PostController controller) {
    const primaryBlue = Color(0xFF0EA5E9);
    final List<Map<String, dynamic>> budgetOptions = [
      {'label': 'All Budgets (No Limit)', 'value': 0},
      {'label': 'Under ৳4,000', 'value': 4000},
      {'label': 'Under ৳5,000', 'value': 5000},
      {'label': 'Under ৳6,000', 'value': 6000},
      {'label': 'Under ৳7,000', 'value': 7000},
      {'label': 'Under ৳8,000', 'value': 8000},
      {'label': 'Under ৳10,000', 'value': 10000},
    ];

    Get.bottomSheet(
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: EdgeInsets.all(20.r),
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
            Text(
              'Filter by Budget',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Select your maximum monthly rent limit',
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: 16.h),
            Obx(() {
              return Column(
                children: budgetOptions.map((opt) {
                  final int val = opt['value'];
                  final String label = opt['label'];
                  final bool isSelected =
                      controller.selectedBudgetFilter.value == val;
                  return ListTile(
                    onTap: () {
                      controller.selectedBudgetFilter.value = val;
                      Get.back();
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    tileColor: isSelected
                        ? primaryBlue.withValues(alpha: 1)
                        : Colors.transparent,
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? primaryBlue : Colors.grey.shade400,
                    ),
                    title: Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color:
                            isSelected ? primaryBlue : AppTheme.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    ));
  }
}

class _BachelorPostCard extends StatelessWidget {
  final PostModel post;

  const _BachelorPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF0EA5E9);
    final String genderText = post.bachelorType == 'female'
        ? 'Female Only'
        : post.bachelorType == 'both'
            ? 'Any Bachelor'
            : 'Male Only';

    return GestureDetector(
      onTap: () {
        Get.to(
          () => RoomDetailScreen(post: post),
          transition: Transition.rightToLeft,
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Banner
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16.r)),
                  child: post.images.isNotEmpty
                      ? AppImageHelper.buildImage(
                          post.images.first,
                          height: 170.h,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 170.h,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.home_work_rounded,
                              size: 48, color: Colors.grey),
                        ),
                ),
                // Price Badge Top Left
                Positioned(
                  top: 12.h,
                  left: 12.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      '৳${post.rent.toInt()} / mo',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Gender Badge
                Positioned(
                  top: 12.h,
                  right: 54.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      genderText,
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Favorite Button Top Right
                Positioned(
                  top: 10.h,
                  right: 10.w,
                  child: Obx(() {
                    final postCtrl = Get.find<PostController>();
                    final isFav = postCtrl.isSaved(post.postId);
                    return GestureDetector(
                      onTap: () => postCtrl.toggleSavePost(post.postId),
                      child: Container(
                        padding: EdgeInsets.all(7.r),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8.r,
                              offset: Offset(0, 2.h),
                            ),
                          ],
                        ),
                        child: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFav
                              ? Colors.redAccent
                              : Colors.grey.shade700,
                          size: 20.r,
                        ),
                      ),
                    );
                  }),
                ),
                // Seat count badge bottom left
                Positioned(
                  bottom: 12.h,
                  left: 12.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppTheme.statusApproved,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.single_bed_rounded,
                            size: 14.r, color: Colors.white),
                        SizedBox(width: 4.w),
                        Text(
                          'Available Seats: ${post.seatCount}',
                          style: GoogleFonts.poppins(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Card Body
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 16.r, color: AppTheme.textSecondary),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          post.address,
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.school_rounded,
                                size: 13.r, color: AppTheme.primaryColor),
                            SizedBox(width: 5.w),
                            Text(
                              post.preferredTenant,
                              style: GoogleFonts.poppins(
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Facilities preview chips
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 4.h,
                    children: post.facilities.take(4).map((facility) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          facility,
                          style: GoogleFonts.poppins(
                            fontSize: 11.sp,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 14.h),
                  const Divider(),

                  // Footer action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Verified Member ✓',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.statusApproved,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'View & Contact',
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(Icons.arrow_forward_rounded,
                              size: 16.r, color: primaryBlue),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
