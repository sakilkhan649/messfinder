import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/otp_verification_controller.dart';

class OtpVerificationScreen extends StatelessWidget {
  final String phone;
  const OtpVerificationScreen({super.key, required this.phone});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OtpVerificationController(phone: phone));
    final authController = controller.authController;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 22.r),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              Text(
                'Verify Phone',
                style: GoogleFonts.poppins(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Enter the 6-digit verification code sent to $phone.',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 40.h),
              Text(
                'Verification Code',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: controller.otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '000000',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 24.sp,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 8,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                ),
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                height: 54.h,
                child: Obx(() {
                  return ElevatedButton(
                    onPressed: authController.isLoading.value ? null : controller.verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      elevation: 0,
                    ),
                    child: authController.isLoading.value
                        ? SizedBox(
                            height: 24.r,
                            width: 24.r,
                            child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Verify & Continue',
                            style: GoogleFonts.poppins(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  );
                }),
              ),
              SizedBox(height: 24.h),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive code? ",
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: controller.resendOtp,
                      child: Obx(() => Text(
                        controller.canResend.value ? "Resend OTP" : "Resend in ${controller.start.value}s",
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: controller.canResend.value ? AppTheme.primaryColor : Colors.grey,
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
}
