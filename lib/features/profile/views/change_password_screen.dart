import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/change_password_controller.dart';

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChangePasswordController());
    final Color primaryColor = AppTheme.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Change Password',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18.sp,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.all(8.r),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1E293B)),
              onPressed: () => Get.back(),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Column(
            children: [
              SizedBox(height: 12.h),

              // Main Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF64748B).withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Header
                    Center(
                      child: Container(
                        width: 72.r,
                        height: 72.r,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.lock_reset_rounded,
                            size: 36.r,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),

                    Center(
                      child: Text(
                        'Update Security',
                        style: GoogleFonts.poppins(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Center(
                      child: Text(
                        'Ensure your account is using a long, random password to stay secure.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          color: const Color(0xFF64748B),
                          height: 1.5,
                        ),
                      ),
                    ),
                    SizedBox(height: 28.h),

                    // Current Password
                    _buildPasswordField(
                      label: 'Current Password',
                      hintText: 'Enter current password',
                      controller: controller.currentPasswordController,
                      isObscure: controller.obscureCurrentPassword,
                      primaryColor: primaryColor,
                      prefixIcon: Icons.lock_outline_rounded,
                    ),
                    SizedBox(height: 18.h),

                    // New Password
                    _buildPasswordField(
                      label: 'New Password',
                      hintText: 'Enter new password (min. 6 chars)',
                      controller: controller.newPasswordController,
                      isObscure: controller.obscureNewPassword,
                      primaryColor: primaryColor,
                      prefixIcon: Icons.vpn_key_rounded,
                    ),
                    SizedBox(height: 18.h),

                    // Confirm Password
                    _buildPasswordField(
                      label: 'Confirm New Password',
                      hintText: 'Re-enter new password',
                      controller: controller.confirmPasswordController,
                      isObscure: controller.obscureConfirmPassword,
                      primaryColor: primaryColor,
                      prefixIcon: Icons.check_circle_outline_rounded,
                    ),
                    SizedBox(height: 32.h),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: Obx(() => ElevatedButton(
                            onPressed: controller.isLoading.value
                                ? null
                                : controller.changePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              elevation: 0,
                            ),
                            child: controller.isLoading.value
                                ? SizedBox(
                                    height: 22.r,
                                    width: 22.r,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    'Update Password',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          )),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required RxBool isObscure,
    required Color primaryColor,
    required IconData prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        SizedBox(height: 8.h),
        Obx(() => TextField(
              controller: controller,
              obscureText: isObscure.value,
              style: GoogleFonts.poppins(fontSize: 14.sp, color: const Color(0xFF0F172A)),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.poppins(fontSize: 13.5.sp, color: const Color(0xFF94A3B8)),
                prefixIcon: Icon(prefixIcon, color: const Color(0xFF64748B), size: 20.r),
                suffixIcon: IconButton(
                  icon: Icon(
                    isObscure.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF64748B),
                    size: 20.r,
                  ),
                  onPressed: () => isObscure.toggle(),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide(color: primaryColor, width: 1.8),
                ),
              ),
            )),
      ],
    );
  }
}
