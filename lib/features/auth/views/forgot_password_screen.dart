import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/forgot_password_controller.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = AppTheme.primaryColor;

    return GetBuilder<ForgotPasswordController>(
      init: ForgotPasswordController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Obx(() {
          switch (controller.currentStep.value) {
            case 1:
              return Text(
                'Verify OTP',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18.sp),
              );
            case 2:
              return Text(
                'New Password',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18.sp),
              );
            default:
              return Text(
                'Reset Password',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18.sp),
              );
          }
        }),
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
              onPressed: () {
                if (controller.currentStep.value > 0) {
                  controller.currentStep.value--;
                } else {
                  Get.back();
                }
              },
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Obx(() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12.h),
                // ── Card Container ───────────────────────────────────────────
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
                    children: [
                      // Animated Header Icon
                      _buildHeaderIcon(controller.currentStep.value, primaryColor),
                      SizedBox(height: 24.h),

                      // Step 0: Email Input
                      if (controller.currentStep.value == 0)
                        _buildEmailStep(controller, primaryColor)
                      // Step 1: Pinput OTP Input
                      else if (controller.currentStep.value == 1)
                        _buildOtpStep(controller, primaryColor)
                      // Step 2: New Password
                      else
                        _buildNewPasswordStep(controller, primaryColor),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
      },
    );
  }

  // ── Header Icon ───────────────────────────────────────────────────────────
  Widget _buildHeaderIcon(int step, Color primaryColor) {
    IconData icon;
    if (step == 0) {
      icon = Icons.lock_reset_rounded;
    } else if (step == 1) {
      icon = Icons.mark_email_read_outlined;
    } else {
      icon = Icons.vpn_key_rounded;
    }

    return Container(
      width: 72.r,
      height: 72.r,
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(icon, size: 36.r, color: primaryColor),
      ),
    );
  }

  // ── Step 0: Email Input ───────────────────────────────────────────────────
  Widget _buildEmailStep(ForgotPasswordController controller, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Forgot Password?',
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Center(
          child: Text(
            'No worries! Enter your registered email and we’ll send a 6-digit OTP code to verify your account.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ),
        SizedBox(height: 28.h),

        Text(
          'Email Address',
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller.emailController,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.poppins(fontSize: 14.sp, color: const Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: 'e.g. name@example.com',
            hintStyle: GoogleFonts.poppins(fontSize: 13.5.sp, color: const Color(0xFF94A3B8)),
            prefixIcon: Icon(Icons.mail_outline_rounded, color: const Color(0xFF64748B), size: 20.r),
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
        ),
        SizedBox(height: 28.h),

        SizedBox(
          width: double.infinity,
          height: 52.h,
          child: ElevatedButton(
            onPressed: controller.isLoading.value ? null : controller.sendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              elevation: 0,
            ),
            child: controller.isLoading.value
                ? SizedBox(
                    height: 22.r,
                    width: 22.r,
                    child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    'Send OTP Code',
                    style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  // ── Step 1: Pinput OTP Input ──────────────────────────────────────────────
  Widget _buildOtpStep(ForgotPasswordController controller, Color primaryColor) {
    // Premium Pinput Theme Configuration
    final defaultPinTheme = PinTheme(
      width: 48.w,
      height: 56.h,
      textStyle: GoogleFonts.poppins(
        fontSize: 20.sp,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF0F172A),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: primaryColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: primaryColor, width: 1.5),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Verification Code',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'We have sent a 6-digit OTP to:',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 13.sp, color: const Color(0xFF64748B)),
        ),
        SizedBox(height: 4.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            controller.emailController.text.trim(),
            style: GoogleFonts.poppins(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
        ),
        SizedBox(height: 28.h),

        // ── Pinput Widget ───────────────────────────────────────────────────
        Pinput(
          controller: controller.otpController,
          length: 6,
          defaultPinTheme: defaultPinTheme,
          focusedPinTheme: focusedPinTheme,
          submittedPinTheme: submittedPinTheme,
          pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
          showCursor: true,
          cursor: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                margin: EdgeInsets.only(bottom: 10.h),
                width: 18.w,
                height: 2.h,
                color: primaryColor,
              ),
            ],
          ),
          onCompleted: (pin) {
            controller.verifyOtp();
          },
        ),
        SizedBox(height: 24.h),

        // ── Resend Countdown Badge ──────────────────────────────────────────
        Obx(() {
          if (!controller.canResend.value) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(30.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, size: 16.r, color: const Color(0xFF64748B)),
                  SizedBox(width: 6.w),
                  Text(
                    'Resend code in ${controller.countdownSeconds.value}s',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return TextButton.icon(
              onPressed: controller.isLoading.value ? null : controller.resendOtp,
              icon: Icon(Icons.refresh_rounded, size: 18.r, color: primaryColor),
              label: Text(
                'Resend OTP Code',
                style: GoogleFonts.poppins(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            );
          }
        }),
        SizedBox(height: 28.h),

        // Verify Button
        SizedBox(
          width: double.infinity,
          height: 52.h,
          child: ElevatedButton(
            onPressed: controller.isLoading.value ? null : controller.verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              elevation: 0,
            ),
            child: controller.isLoading.value
                ? SizedBox(
                    height: 22.r,
                    width: 22.r,
                    child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    'Verify Code',
                    style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  // ── Step 2: New Password View ─────────────────────────────────────────────
  Widget _buildNewPasswordStep(ForgotPasswordController controller, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Create New Password',
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Center(
          child: Text(
            'Your new password must be at least 6 characters long and different from previous passwords.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ),
        SizedBox(height: 28.h),

        // New Password Field
        Text(
          'New Password',
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        SizedBox(height: 8.h),
        Obx(() => TextField(
              controller: controller.newPasswordController,
              obscureText: controller.obscureNewPassword.value,
              style: GoogleFonts.poppins(fontSize: 14.sp, color: const Color(0xFF0F172A)),
              decoration: InputDecoration(
                hintText: 'Enter new password',
                hintStyle: GoogleFonts.poppins(fontSize: 13.5.sp, color: const Color(0xFF94A3B8)),
                prefixIcon: Icon(Icons.lock_outline_rounded, color: const Color(0xFF64748B), size: 20.r),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.obscureNewPassword.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF64748B),
                    size: 20.r,
                  ),
                  onPressed: () => controller.obscureNewPassword.toggle(),
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
        SizedBox(height: 18.h),

        // Confirm Password Field
        Text(
          'Confirm Password',
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        SizedBox(height: 8.h),
        Obx(() => TextField(
              controller: controller.confirmPasswordController,
              obscureText: controller.obscureConfirmPassword.value,
              style: GoogleFonts.poppins(fontSize: 14.sp, color: const Color(0xFF0F172A)),
              decoration: InputDecoration(
                hintText: 'Re-enter new password',
                hintStyle: GoogleFonts.poppins(fontSize: 13.5.sp, color: const Color(0xFF94A3B8)),
                prefixIcon: Icon(Icons.lock_reset_rounded, color: const Color(0xFF64748B), size: 20.r),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.obscureConfirmPassword.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF64748B),
                    size: 20.r,
                  ),
                  onPressed: () => controller.obscureConfirmPassword.toggle(),
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
        SizedBox(height: 28.h),

        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 52.h,
          child: ElevatedButton(
            onPressed: controller.isLoading.value ? null : controller.submitNewPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
              elevation: 0,
            ),
            child: controller.isLoading.value
                ? SizedBox(
                    height: 22.r,
                    width: 22.r,
                    child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    'Reset Password & Login',
                    style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }
}
