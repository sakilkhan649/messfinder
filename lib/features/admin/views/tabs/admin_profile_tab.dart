import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mess_finder/core/utils/image_helper.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../utils/admin_colors.dart';
import '../admin_edit_profile_screen.dart';

class AdminProfileTab extends StatelessWidget {
  const AdminProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Obx(() {
        final user = authController.currentUser.value;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            SizedBox(height: 20.h),
            // Profile Avatar
            Container(
              height: 100.w,
              width: 100.w,
              decoration: BoxDecoration(
                color: AdminColors.accentDark.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AdminColors.accentDark, width: 2),
              ),
              child: ClipOval(
                child: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                    ? AppImageHelper.buildImage(
                        user.photoUrl!,
                        width: 100.w,
                        height: 100.w,
                        fit: BoxFit.cover,
                      )
                    : Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 50.w,
                        color: AdminColors.accentDark,
                      ),
              ),
            ),
            SizedBox(height: 16.h),

            // User Info
            Text(
              user.name,
              style: GoogleFonts.poppins(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: AdminColors.accentDark,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              user.phone.isNotEmpty ? user.phone : 'No Phone Number',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: AdminColors.accentMid,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AdminColors.statusApproved.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                user.role.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: AdminColors.statusApproved,
                ),
              ),
            ),

            SizedBox(height: 40.h),

            // Edit Profile Button
            _buildActionButton(
              icon: Icons.edit_rounded,
              title: 'Edit Profile',
              subtitle: 'Update your name and phone number',
              color: AdminColors.accentDark,
              onTap: () => Get.to(() => AdminEditProfileScreen(user: user)),
            ),
            SizedBox(height: 16.h),

            // Delete Account Button
            _buildActionButton(
              icon: Icons.delete_forever_rounded,
              title: 'Delete Account',
              subtitle: 'Permanently remove your account',
              color: AdminColors.statusRejected,
              onTap: () => _showDeleteConfirmation(authController),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AdminColors.border),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24.w),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AdminColors.accentDark,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: AdminColors.accentMid,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AdminColors.accentLight,
              size: 16.w,
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(AuthController authController) {
    Get.defaultDialog(
      title: 'Delete Account',
      titleStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.bold,
        fontSize: 18.sp,
      ),
      middleText:
          'Are you sure you want to delete your account? This action is permanent and cannot be reversed.',
      middleTextStyle: GoogleFonts.poppins(fontSize: 13.5.sp),
      textCancel: 'Cancel',
      textConfirm: 'Delete',
      confirmTextColor: Colors.white,
      buttonColor: AdminColors.statusRejected,
      onConfirm: () {
        Get.back();
        authController.deleteMyAccount();
      },
    );
  }
}
