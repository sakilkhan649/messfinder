import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_assets.dart';
import '../controllers/splash_controller.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure SplashController is instantiated
    Get.find<SplashController>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 126.r,
                height: 126.r,
                padding: EdgeInsets.all(18.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 2.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 28.r,
                      spreadRadius: 2.r,
                      offset: Offset(0, 8.h),
                    ),
                    BoxShadow(
                      color: const Color(0xFF047857).withValues(alpha: 0.3),
                      blurRadius: 20.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    AppAssets.appLogo,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'MessFinder',
                style: GoogleFonts.poppins(
                  fontSize: 34.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'FIND YOUR PERFECT MESS',
                style: GoogleFonts.poppins(
                  fontSize: 8.sp,
                  color: Colors.white.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.5,
                ),
              ),
              SizedBox(height: 48.h),
              SizedBox(
                width: 28.r,
                height: 28.r,
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
