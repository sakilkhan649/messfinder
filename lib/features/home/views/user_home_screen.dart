import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user_model.dart';
import '../../bachelor/views/bachelor_home_screen.dart';
import '../../bachelor/views/mess_map_screen.dart';
import '../../chat/views/chat_list_screen.dart';
import '../../profile/views/profile_screen.dart';
import '../../landlord/views/add_post_screen.dart';
import 'bottom_nav_painter.dart';
import 'package:get/get.dart';
class UserHomeScreen extends StatelessWidget {
  final UserModel user;

  const UserHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final RxInt currentIndex = 0.obs;
    final RxBool isBottomNavVisible = true.obs;
    const primaryEmerald = Color(0xFF059669);

    final List<Widget> screens = [
      BachelorHomeScreen(user: user),
      const MessMapScreen(),
      AddPostScreen(
        showBackButton: false,
        onPostAdded: () {
          currentIndex.value = 0;
        },
      ),
      ChatListScreen(),
      ProfileScreen(user: user),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. The Main Content
          NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.direction == ScrollDirection.forward) {
                if (!isBottomNavVisible.value) isBottomNavVisible.value = true;
              } else if (notification.direction == ScrollDirection.reverse) {
                if (isBottomNavVisible.value) isBottomNavVisible.value = false;
              }
              return false;
            },
            child: Obx(() => IndexedStack(index: currentIndex.value, children: screens)),
          ),

          // 2. The Custom Bottom Navbar & FAB with absolute positioning
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Obx(() => AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              offset: isBottomNavVisible.value ? Offset.zero : const Offset(0, 1.8),
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
                        height: 85, // Slightly taller than 70 to give breathing room
                        padding: const EdgeInsets.only(bottom: 15), // Pushes icons up away from the gesture bar
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildNavItem(
                                    index: 0,
                                    currentIndex: currentIndex,
                                    icon: Icons.home_outlined,
                                    activeIcon: Icons.home_rounded,
                                    activeColor: primaryEmerald,
                                  ),
                                  _buildNavItem(
                                    index: 1,
                                    currentIndex: currentIndex,
                                    icon: Icons.location_on_outlined,
                                    activeIcon: Icons.location_on_rounded,
                                    activeColor: primaryEmerald,
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
                                    index: 3,
                                    currentIndex: currentIndex,
                                    icon: Icons.chat_bubble_outline_rounded,
                                    activeIcon: Icons.chat_bubble_rounded,
                                    activeColor: primaryEmerald,
                                  ),
                                  _buildNavItem(
                                    index: 4,
                                    currentIndex: currentIndex,
                                    icon: Icons.person_outline_rounded,
                                    activeIcon: Icons.person_rounded,
                                    activeColor: primaryEmerald,
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
                      color: primaryEmerald,
                      elevation: 4,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => currentIndex.value = 2,
                        child: SizedBox(
                          height: 72,
                          width: 72,
                          child: const Icon(Icons.add, color: Colors.white, size: 36),
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
    required int index,
    required RxInt currentIndex,
    required IconData icon,
    required IconData activeIcon,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: () => currentIndex.value = index,
      behavior: HitTestBehavior.opaque,
      child: Obx(() {
        final isSelected = currentIndex.value == index;
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
