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
class UserHomeScreen extends StatefulWidget {
  final UserModel user;

  const UserHomeScreen({super.key, required this.user});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;
  bool _isBottomNavVisible = true;

  @override
  Widget build(BuildContext context) {
    const primaryEmerald = Color(0xFF059669);

    final List<Widget> screens = [
      BachelorHomeScreen(user: widget.user),
      const MessMapScreen(),
      AddPostScreen(
        showBackButton: false,
        onPostAdded: () {
          setState(() {
            _currentIndex = 0;
          });
        },
      ),
      ChatListScreen(),
      ProfileScreen(user: widget.user),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      extendBody: true,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. The Main Content
          NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.direction == ScrollDirection.forward) {
                if (!_isBottomNavVisible) setState(() => _isBottomNavVisible = true);
              } else if (notification.direction == ScrollDirection.reverse) {
                if (_isBottomNavVisible) setState(() => _isBottomNavVisible = false);
              }
              return false;
            },
            child: IndexedStack(index: _currentIndex, children: screens),
          ),

          // 2. The Custom Bottom Navbar & FAB with absolute positioning
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              offset: _isBottomNavVisible ? Offset.zero : const Offset(0, 1.8),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  // Navbar Background, Shadow, Border, and Icons
                  CustomPaint(
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
                                  icon: Icons.home_outlined,
                                  activeIcon: Icons.home_rounded,
                                  activeColor: primaryEmerald,
                                ),
                                _buildNavItem(
                                  index: 1,
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
                                  icon: Icons.chat_bubble_outline_rounded,
                                  activeIcon: Icons.chat_bubble_rounded,
                                  activeColor: primaryEmerald,
                                ),
                                _buildNavItem(
                                  index: 4,
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

                  // The Floating Action Button (placed perfectly inside the notch)
                  Positioned(
                    top: -36, // Half of 72px FAB size
                    child: SizedBox(
                      height: 72,
                      width: 72,
                      child: FittedBox(
                        child: FloatingActionButton(
                          onPressed: () => setState(() => _currentIndex = 2),
                          backgroundColor: primaryEmerald,
                          elevation: 4,
                          shape: const CircleBorder(),
                          child: const Icon(Icons.add, color: Colors.white, size: 36),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required Color activeColor,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
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
      ),
    );
  }
}
