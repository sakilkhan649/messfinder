import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_constants.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';

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
          : const Color(0xFF1E1B4B); // Deep Indigo for Bachelor

      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: primaryColor,
          elevation: 0,
          title: Text(
            'Profile',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 18.sp,
              color: Colors.white,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Profile Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 20.w),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24.r),
                    bottomRight: Radius.circular(24.r),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50.r,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      backgroundImage:
                          activeUser.photoUrl != null &&
                              activeUser.photoUrl!.isNotEmpty
                          ? NetworkImage(activeUser.photoUrl!)
                          : null,
                      child:
                          activeUser.photoUrl == null ||
                              activeUser.photoUrl!.isEmpty
                          ? Icon(
                              Icons.person_rounded,
                              size: 50.r,
                              color: Colors.white,
                            )
                          : null,
                    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack).fade(duration: 400.ms),
                    SizedBox(height: 16.h),
                    Text(
                      activeUser.name,
                      style: GoogleFonts.poppins(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    if (activeUser.phone.isNotEmpty)
                      Text(
                        activeUser.phone,
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Text(
                        isLandlord ? 'Verified Landlord' : 'Verified Bachelor',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Menu Items
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Settings',
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _buildMenuItem(
                      icon: Icons.edit_rounded,
                      title: 'Edit Profile',
                      onTap: () =>
                          Get.to(() => EditProfileScreen(user: activeUser)),
                      index: 0,
                    ),
                    _buildMenuItem(
                      icon: isLandlord ? Icons.person_search_rounded : Icons.home_work_rounded,
                      title: isLandlord ? 'Switch to Bachelor' : 'Switch to Landlord',
                      onTap: () {
                        final authCtrl = Get.find<AuthController>();
                        if (isLandlord) {
                          authCtrl.switchRole(AppConstants.roleBachelor);
                        } else {
                          authCtrl.switchRole(AppConstants.roleLandlord);
                        }
                      },
                      index: 1,
                    ),
                    _buildMenuItem(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
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
                      ),
                      index: 2,
                    ),

                    SizedBox(height: 32.h),

                    // Logout
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton.icon(
                        onPressed: () => _showLogoutDialog(primaryColor),
                        icon: Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                          size: 20.r,
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
                          backgroundColor: Colors.red.shade600,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    int index = 0,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          leading: Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: const Color(0xFF475569), size: 20.r),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14.r,
            color: Colors.grey.shade400,
          ),
        ),
      ),
    ).animate().fade(duration: 300.ms, delay: (index * 100).ms).slideX(begin: -0.1, end: 0, duration: 300.ms, delay: (index * 100).ms, curve: Curves.easeOutQuad);
  }

  void _showLogoutDialog(Color primaryColor) {
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
      cancelTextColor: Colors.red.shade600,
      confirmTextColor: Colors.white,
      buttonColor: Colors.red.shade600,
      radius: 12.r,
      onConfirm: () {
        Get.find<AuthController>().logout();
      },
    );
  }
}
