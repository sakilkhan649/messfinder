import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user_model.dart';
import '../../bachelor/views/bachelor_home_screen.dart';
import '../../bachelor/views/mess_map_screen.dart';
import '../../chat/views/chat_list_screen.dart';
import '../../profile/views/profile_screen.dart';
import '../../landlord/views/add_post_screen.dart';

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
      const AddPostScreen(),
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
          ? SizedBox(
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
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(useMaterial3: false),
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          offset: _isBottomNavVisible ? Offset.zero : const Offset(0, 1),
          child: BottomAppBar(
            color: Colors.white,
            elevation: 24, // High elevation for prominent shadow
            shadowColor: Colors.black, // Pure black shadow
            surfaceTintColor: Colors.transparent,
            notchMargin: 10,
            shape: const CircularNotchedRectangle(),
            padding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              child: SizedBox(
                height: 70,
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
                    const SizedBox(
                      width: 75,
                    ), // Wider center space for the large 72x72 FAB
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
          ),
        ),
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
