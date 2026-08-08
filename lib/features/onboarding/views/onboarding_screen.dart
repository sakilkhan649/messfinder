import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Put controller so it's initialized when screen loads
    final controller = Get.put(OnboardingController());
    final Color primaryColor = const Color(0xFF059669);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: controller.skipOnboarding,
                child: Text(
                  'Skip',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ).animate().fade(delay: 300.ms),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                onPageChanged: controller.onPageChanged,
                itemCount: controller.pages.length,
                itemBuilder: (context, index) {
                  final page = controller.pages[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated Image
                        Image.asset(
                              page.imagePath,
                              height: 250.h,
                              fit: BoxFit.contain,
                            )
                            .animate(target: 1)
                            .scale(duration: 500.ms, curve: Curves.easeOutBack),

                        SizedBox(height: 60.h),

                        // Title
                        Text(
                              page.title,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            )
                            .animate()
                            .slideY(begin: 0.5, end: 0, duration: 400.ms)
                            .fade(),

                        SizedBox(height: 20.h),

                        // Description
                        Text(
                              page.description,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF64748B),
                                height: 1.5,
                              ),
                            )
                            .animate()
                            .slideY(
                              begin: 0.5,
                              end: 0,
                              duration: 400.ms,
                              delay: 100.ms,
                            )
                            .fade(),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom section
            Padding(
              padding: EdgeInsets.all(40.w),
              child: Obx(() {
                final isLastPage =
                    controller.currentPage.value == controller.pages.length - 1;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Dot indicators
                    Row(
                      children: List.generate(
                        controller.pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: EdgeInsets.only(right: 8.w),
                          height: 8.h,
                          width: controller.currentPage.value == index
                              ? 24.w
                              : 8.w,
                          decoration: BoxDecoration(
                            color: controller.currentPage.value == index
                                ? primaryColor
                                : primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ),
                    ),

                    // Next / Get Started button
                    InkWell(
                      onTap: isLastPage
                          ? controller.completeOnboarding
                          : controller.nextPage,
                      borderRadius: BorderRadius.circular(30.r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: EdgeInsets.symmetric(
                          horizontal: isLastPage ? 24.w : 20.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(30.r),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isLastPage ? 'Get Started' : 'Next',
                              style: GoogleFonts.poppins(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            if (!isLastPage) ...[
                              SizedBox(width: 8.w),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
