import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user_model.dart';
import '../../notifications/controllers/notification_controller.dart';
import '../../notifications/views/notifications_screen.dart';
import 'bachelor_home_screen.dart';
import 'mess_map_screen.dart';
import '../../chat/views/chat_list_screen.dart';
import '../../profile/views/profile_screen.dart';

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
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _isBottomNavVisible ? Offset.zero : const Offset(0, 1),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 15.r,
                offset: Offset(0, -4.h),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.home_rounded,
                    label: 'Home',
                    activeColor: primaryColor,
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.location_on_rounded,
                    label: 'Map',
                    activeColor: primaryColor,
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.chat_bubble_rounded,
                    label: 'Chats',
                    activeColor: primaryColor,
                  ),
                  // Notification Bell
                  _buildNotificationBell(primaryColor),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    activeColor: primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBell(Color primaryColor) {
    return Expanded(
      child: InkWell(
        onTap: () => Get.to(() => const NotificationsScreen(),
            transition: Transition.rightToLeft),
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() {
                final count = Get.isRegistered<NotificationController>()
                    ? Get.find<NotificationController>().unreadCount.value
                    : 0;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
                      child: Icon(
                        Icons.notifications_rounded,
                        size: 24.r,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (count > 0)
                      Positioned(
                        right: 14.w,
                        top: 2.h,
                        child: Container(
                          padding: EdgeInsets.all(3.r),
                          constraints: BoxConstraints(minWidth: 16.r, minHeight: 16.r),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              count > 9 ? '9+' : '$count',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }),
              SizedBox(height: 4.h),
              Text(
                'Alerts',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required Color activeColor,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Icon(
                  icon,
                  size: 24.r,
                  color: isSelected ? activeColor : Colors.grey.shade500,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? activeColor : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
