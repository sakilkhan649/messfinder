import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_helper.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';
import '../../auth/views/role_selection_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  final UserModel user;

  const ProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final UserModel activeUser = Get.isRegistered<AuthController>()
          ? (Get.find<AuthController>().currentUser.value ?? user)
          : user;

      final isLandlord = activeUser.isLandlord;
      final Color primaryColor = isLandlord
          ? const Color(0xFF059669) // Emerald for Landlord
          : const Color(0xFF0EA5E9); // Sky Blue for Bachelor
      final Color accentColor = isLandlord
          ? const Color(0xFF10B981)
          : const Color(0xFF38BDF8);

      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Ultra-Premium Header
            SliverAppBar(
              expandedHeight: 310.h,
              pinned: true,
              backgroundColor: primaryColor,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 20.h),
                          // Avatar with Glow
                          Container(
                            width: 100.r,
                            height: 100.r,
                            padding: EdgeInsets.all(4.r),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.2),
                              border: Border.all(
                                color: Colors.white,
                                width: 3.r,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 20.r,
                                  offset: Offset(0, 8.h),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child:
                                  (activeUser.photoUrl != null &&
                                      activeUser.photoUrl!.isNotEmpty)
                                  ? AppImageHelper.buildImage(
                                      activeUser.photoUrl!,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: Colors.white,
                                      child: Icon(
                                        isLandlord
                                            ? Icons.home_work_rounded
                                            : Icons.person_rounded,
                                        size: 45.r,
                                        color: primaryColor,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: 16.h),

                          // Name
                          Text(
                            activeUser.name,
                            style: GoogleFonts.poppins(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 4.h),

                          // Phone
                          if (activeUser.phone.isNotEmpty)
                            Text(
                              activeUser.phone,
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          SizedBox(height: 12.h),

                          // Role Badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(30.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: 16.r,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  isLandlord
                                      ? 'Verified Landlord'
                                      : 'Verified Bachelor',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Content Below Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Settings',
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Menu Items
                    _buildMenuItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Edit Profile',
                      subtitle: 'Update your personal details',
                      color: primaryColor,
                      onTap: () {
                        Get.to(() => EditProfileScreen(user: activeUser));
                      },
                    ),

                    _buildMenuItem(
                      icon: Icons.swap_horiz_rounded,
                      title: 'Switch Role',
                      subtitle: 'Change between Landlord and Bachelor',
                      color: const Color(0xFFF59E0B),
                      onTap: () {
                        Get.to(
                          () => const RoleSelectionScreen(),
                          transition: Transition.cupertino,
                        );
                      },
                    ),

                    _buildMenuItem(
                      icon: Icons.headset_mic_rounded,
                      title: 'Help & Support',
                      subtitle: 'Get assistance when you need it',
                      color: primaryColor,
                      onTap: () => Get.defaultDialog(
                        title: 'Help & Support',
                        titleStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                        ),
                        middleText:
                            'Call us at:\n01868569162\n\nor Email:\nsupport@messfinder.com',
                        textConfirm: 'Okay',
                        confirmTextColor: Colors.white,
                        buttonColor: primaryColor,
                        onConfirm: () => Get.back(),
                        radius: 16.r,
                        contentPadding: EdgeInsets.all(20.w),
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: ElevatedButton.icon(
                        onPressed: () => _showLogoutDialog(),
                        icon: Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                          size: 22.r,
                        ),
                        label: Text(
                          'Sign Out',
                          style: GoogleFonts.poppins(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24.r),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16.r,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    Get.defaultDialog(
      title: 'Sign Out',
      titleStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.bold,
        fontSize: 18.sp,
      ),
      middleText: 'Are you sure you want to sign out?',
      middleTextStyle: GoogleFonts.poppins(fontSize: 14.sp),
      textConfirm: 'Sign Out',
      textCancel: 'Cancel',
      cancelTextColor: const Color(0xFFEF4444),
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFFEF4444),
      radius: 16.r,
      contentPadding: EdgeInsets.all(20.w),
      onConfirm: () {
        Get.find<AuthController>().logout();
      },
    );
  }
}
