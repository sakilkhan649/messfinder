import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user_model.dart';
import 'bottom_nav_painter.dart';
import 'package:get/get.dart';

import '../controllers/user_home_controller.dart';

class UserHomeScreen extends StatelessWidget {
  final UserModel user;

  const UserHomeScreen({super.key, required this.user});

  static const Color _primaryEmerald = Color(0xFF059669);

  @override
  Widget build(BuildContext context) {
    final UserHomeController controller = Get.find<UserHomeController>();
    controller.initScreensIfNeeded(user);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. The Main Content
          Obx(() => IndexedStack(index: controller.currentIndex.value, children: controller.screens!)),

          // 2. The Custom Bottom Navbar & FAB with absolute positioning
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Obx(() => AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              offset: controller.isBottomNavVisible.value ? Offset.zero : const Offset(0, 1.8),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  // Navbar Background, Shadow, Border, and Icons
                  Padding(
                    padding: EdgeInsets.only(top: 30.h),
                    child: CustomPaint(
                      painter: BottomNavBorderPainter(
                        fabSize: 60.r,
                        notchMargin: 10.r,
                        borderColor: Colors.grey.shade400,
                        shadowColor: Colors.black.withValues(alpha: 0.15),
                      ),
                      child: Container(
                        height: 70.h, // Responsive height
                        padding: EdgeInsets.only(bottom: 8.h), // Responsive padding
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildNavItem(
                                    controller: controller,
                                    index: 0,
                                    icon: Icons.home_outlined,
                                    activeIcon: Icons.home_rounded,
                                    label: 'Home',
                                    activeColor: _primaryEmerald,
                                  ),
                                  _buildNavItem(
                                    controller: controller,
                                    index: 1,
                                    icon: Icons.location_on_outlined,
                                    activeIcon: Icons.location_on_rounded,
                                    label: 'Locations',
                                    activeColor: _primaryEmerald,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 75.w), // Notch gap
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildNavItem(
                                    controller: controller,
                                    index: 3,
                                    icon: Icons.storefront_outlined,
                                    activeIcon: Icons.storefront_rounded,
                                    label: 'Markets',
                                    activeColor: _primaryEmerald,
                                  ),
                                  _buildNavItem(
                                    controller: controller,
                                    index: 4,
                                    icon: Icons.chat_bubble_outline_rounded,
                                    activeIcon: Icons.chat_bubble_rounded,
                                    label: 'Chats',
                                    activeColor: _primaryEmerald,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // The Floating Action Button (placed perfectly inside the notch)
                  Positioned(
                    top: 0,
                    child: Material(
                      type: MaterialType.circle,
                      color: _primaryEmerald,
                      elevation: 4,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => controller.onTabSelected(2),
                        child: SizedBox(
                          height: 60.r,
                          width: 60.r,
                          child: Icon(Icons.add, color: Colors.white, size: 30.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required UserHomeController controller,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color activeColor,
  }) {
    return InkWell(
      onTap: () => controller.onTabSelected(index),
      borderRadius: BorderRadius.circular(12.r),
      splashColor: activeColor.withValues(alpha: 0.1),
      highlightColor: activeColor.withValues(alpha: 0.05),
      child: Obx(() {
        final isSelected = controller.currentIndex.value == index;
        return Container(
          width: 65.w,
          color: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 24.r, // Responsive icon size
                color: isSelected ? activeColor : Colors.black54,
              ),
              SizedBox(height: 4.h),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.poppins(
                  fontSize: 11.sp, // Responsive text size
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? activeColor : Colors.black54,
                ),
                child: Text(label),
              ),
            ],
          ),
        );
      }),
    );
  }
}
