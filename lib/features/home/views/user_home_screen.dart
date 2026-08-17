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

class UserHomeScreen extends StatefulWidget {
  final UserModel user;

  const UserHomeScreen({super.key, required this.user});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final RxInt _currentIndex = 0.obs;
  final RxBool _isBottomNavVisible = true.obs;
  static const Color _primaryEmerald = Color(0xFF059669);

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      BachelorHomeScreen(user: widget.user),
      const MessMapScreen(),
      AddPostScreen(
        showBackButton: false,
        customTag: 'new_home',
        onPostAdded: () {
          _currentIndex.value = 0;
          _isBottomNavVisible.value = true;
        },
      ),
      ChatListScreen(),
      ProfileScreen(user: widget.user),
    ];
  }

  void _onTabSelected(int index) {
    _currentIndex.value = index;
    _isBottomNavVisible.value = true;
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
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
              // Only allow hiding on Feed screen (index 0)
              if (_currentIndex.value == 0) {
                if (notification.direction == ScrollDirection.forward) {
                  if (!_isBottomNavVisible.value) _isBottomNavVisible.value = true;
                } else if (notification.direction == ScrollDirection.reverse) {
                  if (_isBottomNavVisible.value) _isBottomNavVisible.value = false;
                }
              } else {
                if (!_isBottomNavVisible.value) _isBottomNavVisible.value = true;
              }
              return false;
            },
            child: Obx(() => IndexedStack(index: _currentIndex.value, children: _screens)),
          ),

          // 2. The Custom Bottom Navbar & FAB with absolute positioning
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Obx(() => AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              offset: _isBottomNavVisible.value ? Offset.zero : const Offset(0, 1.8),
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
                                    index: 0,
                                    icon: Icons.home_outlined,
                                    activeIcon: Icons.home_rounded,
                                    activeColor: _primaryEmerald,
                                  ),
                                  _buildNavItem(
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
                                    index: 3,
                                    icon: Icons.chat_bubble_outline_rounded,
                                    activeIcon: Icons.chat_bubble_rounded,
                                    activeColor: _primaryEmerald,
                                  ),
                                  _buildNavItem(
                                    index: 4,
                                    icon: Icons.person_outline_rounded,
                                    activeIcon: Icons.person_rounded,
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
                        onTap: () => _onTabSelected(2),
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
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: () => _onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: Obx(() {
        final isSelected = _currentIndex.value == index;
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
