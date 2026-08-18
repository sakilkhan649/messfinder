import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mess_finder/core/utils/image_helper.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../utils/admin_colors.dart';
import '../admin_edit_profile_screen.dart';
import '../widgets/admin_broadcast_dialog.dart';

class AdminProfileTab extends StatelessWidget {
  const AdminProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Obx(() {
        final user = authController.currentUser.value;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            SizedBox(height: 10.h),
            // Profile Avatar
            Container(
              height: 84.r,
              width: 84.r,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF97316).withValues(alpha: 0.1),
                    blurRadius: 12.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: ClipOval(
                child: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                    ? AppImageHelper.buildImage(
                        user.photoUrl!,
                        width: 84.r,
                        height: 84.r,
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 42.r,
                          color: const Color(0xFFEA580C),
                        ),
                      ),
              ),
            ),
            SizedBox(height: 12.h),

            // User Info
            Text(
              user.name.isNotEmpty ? user.name : 'System Administrator',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AdminColors.accentDark,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              user.email.isNotEmpty ? user.email : (user.phone.isNotEmpty ? user.phone : 'admin@messfinder.com'),
              style: GoogleFonts.poppins(
                fontSize: 12.5.sp,
                color: AdminColors.accentMid,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.3)),
              ),
              child: Text(
                'SYSTEM ADMIN',
                style: GoogleFonts.poppins(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFEA580C),
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // ── System Health Diagnostics ──
            _buildSystemHealthCard(),

            SizedBox(height: 16.h),

            // Broadcast Announcement Action
            _buildActionButton(
              icon: Icons.campaign_rounded,
              title: 'Broadcast Announcement',
              subtitle: 'Send global notification to users',
              color: const Color(0xFF0284C7),
              onTap: () => AdminBroadcastDialog.show(context),
            ),
            SizedBox(height: 10.h),

            // Edit Profile Button
            _buildActionButton(
              icon: Icons.edit_rounded,
              title: 'Edit Profile',
              subtitle: 'Update your display name and contact',
              color: AdminColors.accentDark,
              onTap: () => Get.to(() => AdminEditProfileScreen(user: user)),
            ),
            SizedBox(height: 10.h),

            // Logout Button
            _buildActionButton(
              icon: Icons.logout_rounded,
              title: 'Log Out',
              subtitle: 'Sign out from admin portal',
              color: const Color(0xFF64748B),
              onTap: () => authController.logout(),
            ),
            SizedBox(height: 10.h),

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

  Widget _buildSystemHealthCard() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AdminColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dns_rounded, color: const Color(0xFF059669), size: 18.r),
              SizedBox(width: 8.w),
              Text(
                'System Status & Engine',
                style: GoogleFonts.poppins(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.accentDark,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5.r,
                      height: 5.r,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'ONLINE',
                      style: GoogleFonts.poppins(
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Divider(color: const Color(0xFFF1F5F9), height: 1.h),
          SizedBox(height: 10.h),
          _buildHealthRow(Icons.storage_rounded, 'Database', 'PostgreSQL (Active)'),
          SizedBox(height: 8.h),
          _buildHealthRow(Icons.router_rounded, 'API Server', 'Port 5000 (Live)'),
          SizedBox(height: 8.h),
          _buildHealthRow(Icons.chat_bubble_outline_rounded, 'Live Chat & Call', 'Socket.IO Engine'),
          SizedBox(height: 8.h),
          _buildHealthRow(Icons.card_membership_rounded, 'Platform Plan', '100% Free Tier'),
        ],
      ),
    );
  }

  Widget _buildHealthRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14.r, color: AdminColors.accentMid),
        SizedBox(width: 8.w),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            color: AdminColors.accentMid,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            color: AdminColors.accentDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AdminColors.border),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.025),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(9.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20.r),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w600,
                      color: AdminColors.accentDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11.sp,
                      color: AdminColors.accentMid,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AdminColors.accentLight,
              size: 13.r,
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
