import 'package:flutter/material.dart';
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
    final UserHomeController controller = Get.put(UserHomeController());
    controller.initScreensIfNeeded(user);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. The Main Content
          NotificationListener<UserScrollNotification>(
            onNotification: controller.handleScrollNotification,
            child: Obx(() => IndexedStack(index: controller.currentIndex.value, children: controller.screens!)),
          ),

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
                    padding: const EdgeInsets.only(top: 36),
                    child: CustomPaint(
                      painter: BottomNavBorderPainter(
                        borderColor: Colors.grey.shade400,
                        shadowColor: Colors.black.withValues(alpha: 0.15),
                      ),
                      child: Container(
                        height: 85, // Slightly taller to give breathing room
                        padding: const EdgeInsets.only(bottom: 15), // Pushes icons up away from the gesture bar
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
                                    activeColor: _primaryEmerald,
                                  ),
                                  _buildNavItem(
                                    controller: controller,
                                    index: 1,
                                    icon: Icons.location_on_outlined,
                                    activeIcon: Icons.location_on_rounded,
                                    activeColor: _primaryEmerald,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 75), // Notch gap
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildNavItem(
                                    controller: controller,
                                    index: 3,
                                    icon: Icons.storefront_outlined,
                                    activeIcon: Icons.storefront_rounded,
                                    activeColor: _primaryEmerald,
                                  ),
                                  _buildNavItem(
                                    controller: controller,
                                    index: 4,
                                    icon: Icons.chat_bubble_outline_rounded,
                                    activeIcon: Icons.chat_bubble_rounded,
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
                        child: const SizedBox(
                          height: 72,
                          width: 72,
                          child: Icon(Icons.add, color: Colors.white, size: 36),
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
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: () => controller.onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: Obx(() {
        final isSelected = controller.currentIndex.value == index;
        return SizedBox(
          width: 55,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 28,
                color: isSelected ? activeColor : Colors.black87,
              ),
              const SizedBox(height: 6),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: isSelected ? 1.0 : 0.0,
                child: Container(
                  height: 3,
                  width: 16,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
