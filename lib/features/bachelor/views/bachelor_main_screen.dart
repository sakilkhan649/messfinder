import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user_model.dart';
import 'bachelor_home_screen.dart';
import 'mess_map_screen.dart';
import '../../chat/views/chat_list_screen.dart';
import '../../marketplace/views/marketplace_screen.dart';
import 'package:get/get.dart';
import '../controllers/bachelor_main_controller.dart';

class BachelorMainScreen extends StatelessWidget {
  final UserModel user;

  const BachelorMainScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BachelorMainController>();
    const primaryColor = Color(0xFF059669);

    final List<Widget> screens = [
      BachelorHomeScreen(user: user),
      const MessMapScreen(),
      ChatListScreen(),
      const MarketplaceScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main content
          Obx(() => IndexedStack(index: controller.currentIndex.value, children: screens)),

          // Floating bottom navbar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Obx(() => AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              offset: controller.isBottomNavVisible.value ? Offset.zero : const Offset(0, 1),
              child: Padding(
                padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 20.h),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Navbar bar
                    Container(
                      height: 70.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(35.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.20),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 8), // Shadow underneath
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(35.r),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left side
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildNavItem(
                                  index: 0,
                                  icon: Icons.home_outlined,
                                  activeIcon: Icons.home_rounded,
                                  label: 'Home',
                                  activeColor: primaryColor,
                                  controller: controller,
                                ),
                                _buildNavItem(
                                  index: 1,
                                  icon: Icons.location_on_outlined,
                                  activeIcon: Icons.location_on_rounded,
                                  label: 'Map',
                                  activeColor: primaryColor,
                                  controller: controller,
                                ),
                              ],
                            ),
                          ),
                          // Center space for FAB
                          SizedBox(width: 72.w),
                          // Right side
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildNavItem(
                                  index: 2,
                                  icon: Icons.chat_bubble_outline_rounded,
                                  activeIcon: Icons.chat_bubble_rounded,
                                  label: 'Chats',
                                  activeColor: primaryColor,
                                  controller: controller,
                                ),
                                _buildNavItem(
                                  index: 3,
                                  icon: Icons.storefront_outlined,
                                  activeIcon: Icons.storefront_rounded,
                                  label: 'Market',
                                  activeColor: primaryColor,
                                  controller: controller,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                    // Center FAB
                    Positioned(
                      top: -20.h,
                      child: FloatingActionButton(
                        onPressed: () {
                          Get.snackbar(
                            'Action',
                            'Center button tapped',
                            snackPosition: SnackPosition.TOP,
                          );
                        },
                        backgroundColor: primaryColor,
                        elevation: 6,
                        shape: const CircleBorder(),
                        child: Icon(
                          Icons.eco_outlined,
                          color: Colors.white,
                          size: 28.r,
                        ),
                      ),
                    ),
                  ],
                  ), // Ends Stack
                ), // Ends Padding
              ))), // Ends AnimatedSlide, Obx, Positioned
          ], // Ends Stack children
        ), // Ends Stack
      ); // Ends Scaffold
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color activeColor,
    required BachelorMainController controller,
  }) {
    final isSelected = controller.currentIndex.value == index;

    return GestureDetector(
      onTap: () => controller.setIndex(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 55.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 28.r,
              color: isSelected ? activeColor : Colors.grey.shade400,
            ),
            SizedBox(height: 6.h),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: isSelected ? 1.0 : 0.0,
              child: Container(
                height: 5.r,
                width: 5.r,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
