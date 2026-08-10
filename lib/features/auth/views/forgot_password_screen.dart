import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/forgot_password_controller.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ForgotPasswordController());
    final authController = controller.authController;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              Center(
                child: Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_reset_rounded,
                    size: 56.r,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              SizedBox(height: 28.h),
              Text(
                'Forgot your password?',
                style: GoogleFonts.poppins(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Enter your registered email address below. We will send you a link to reset your password.',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 32.h),

              // Email input
              Text(
                'Email Address',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: controller.emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'example@email.com',
                  prefixIcon: Icon(Icons.email_outlined,
                      color: AppTheme.textSecondary, size: 20.r),
                ),
              ),
              SizedBox(height: 36.h),

              // Send Reset Link Button
              SizedBox(
                width: double.infinity,
                child: Obx(() {
                  return ElevatedButton(
                    onPressed: authController.isLoading.value
                        ? null
                        : controller.resetPassword,
                    child: authController.isLoading.value
                        ? SizedBox(
                            height: 20.r,
                            width: 20.r,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Send Reset Link'),
                  );
                }),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }
}
