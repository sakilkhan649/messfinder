import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user_model.dart';
import 'landlord_home_screen.dart';
import '../../chat/views/chat_list_screen.dart';
import 'package:get/get.dart';
import '../../profile/views/profile_screen.dart';
import 'add_post_screen.dart';

class LandlordMainScreen extends StatelessWidget {
  final UserModel user;

  const LandlordMainScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final RxInt currentIndex = 0.obs;
    const emeraldTheme = Color(0xFF059669);

    final List<Widget> screens = [
      MyPostsScreen(user: user),
      ChatListScreen(),
      ProfileScreen(user: user),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Obx(() => IndexedStack(index: currentIndex.value, children: screens)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const AddPostScreen()),
        backgroundColor: emeraldTheme,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 20,
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
        padding: EdgeInsets.zero,
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
                      currentIndex: currentIndex,
                      icon: Icons.home_work_outlined,
                      activeIcon: Icons.home_work_rounded,
                      label: 'Rooms',
                      activeColor: emeraldTheme,
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
                      index: 1,
                      currentIndex: currentIndex,
                      icon: Icons.chat_bubble_outline_rounded,
                      activeIcon: Icons.chat_bubble_rounded,
                      label: 'Chats',
                      activeColor: emeraldTheme,
                    ),
                    _buildNavItem(
                      index: 2,
                      currentIndex: currentIndex,
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: 'Profile',
                      activeColor: emeraldTheme,
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

  Widget _buildNavItem({
    required int index,
    required RxInt currentIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color activeColor,
  }) {
    return Obx(() {
      final isSelected = currentIndex.value == index;

      return GestureDetector(
        onTap: () => currentIndex.value = index,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Icon(
              isSelected ? activeIcon : icon,
              size: 26.r,
              color: isSelected ? activeColor : Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? activeColor : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
    });
  }
}
