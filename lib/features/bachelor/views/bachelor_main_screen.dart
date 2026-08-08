import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user_model.dart';
import 'bachelor_home_screen.dart';
import 'mess_map_screen.dart';
import '../../chat/views/chat_list_screen.dart';
import '../../profile/views/profile_screen.dart';
import 'package:get/get.dart';

class BachelorMainScreen extends StatefulWidget {
  final UserModel user;

  const BachelorMainScreen({super.key, required this.user});

  @override
  State<BachelorMainScreen> createState() => _BachelorMainScreenState();
}

class _BachelorMainScreenState extends State<BachelorMainScreen> {
  int _currentIndex = 0;
  bool _isBottomNavVisible = true;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF059669); // Deep Indigo

    final List<Widget> screens = [
      BachelorHomeScreen(user: widget.user),
      const MessMapScreen(),
      ChatListScreen(),
      ProfileScreen(user: widget.user),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      extendBody: true,
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.reverse) {
            if (_isBottomNavVisible) {
              setState(() => _isBottomNavVisible = false);
            }
          } else if (notification.direction == ScrollDirection.forward) {
            if (!_isBottomNavVisible) {
              setState(() => _isBottomNavVisible = true);
            }
          }
          return false;
        },
        child: IndexedStack(index: _currentIndex, children: screens),
      ),
      floatingActionButton: _isBottomNavVisible
          ? FloatingActionButton(
              onPressed: () {
                // TODO: Add action for center button (e.g., Search or Add)
                Get.snackbar('Action', 'Center button tapped',
                    snackPosition: SnackPosition.TOP);
              },
              backgroundColor: primaryColor,
              elevation: 4,
              shape: const CircleBorder(),
              child: Icon(Icons.eco_outlined, color: Colors.white, size: 28.r),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _isBottomNavVisible ? Offset.zero : const Offset(0, 1),
        child: Padding(
          padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 20.h),
          child: BottomAppBar(
            color: Colors.white,
            elevation: 10,
            notchMargin: 12,
            shape: AutomaticNotchedShape(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(35.r),
              ),
              const CircleBorder(),
            ),
            padding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: 70.h,
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
                      ),
                      _buildNavItem(
                        index: 1,
                        icon: Icons.location_on_outlined,
                        activeIcon: Icons.location_on_rounded,
                        label: 'Map',
                        activeColor: primaryColor,
                      ),
                    ],
                  ),
                ),
                // Center space for FAB
                SizedBox(width: 48.w),
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
                      ),
                      _buildNavItem(
                        index: 3,
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        label: 'Profile',
                        activeColor: primaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color activeColor,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
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
