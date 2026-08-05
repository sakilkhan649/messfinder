import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user_model.dart';
import '../../profile/views/profile_screen.dart';
import 'landlord_home_screen.dart';
import 'tenant_leads_screen.dart';
import '../../chat/views/chat_list_screen.dart';

class LandlordMainScreen extends StatefulWidget {
  final UserModel user;

  const LandlordMainScreen({super.key, required this.user});

  @override
  State<LandlordMainScreen> createState() => _LandlordMainScreenState();
}

class _LandlordMainScreenState extends State<LandlordMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    const emeraldTheme = Color(0xFF059669);

    final List<Widget> screens = [
      LandlordHomeScreen(user: widget.user),
      const TenantLeadsScreen(),
      ChatListScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
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
                  icon: Icons.home_work_rounded,
                  label: 'Rooms',
                  activeColor: emeraldTheme,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.people_alt_rounded,
                  label: 'Requests',
                  activeColor: emeraldTheme,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.chat_rounded,
                  label: 'Chats',
                  activeColor: emeraldTheme,
                ),
              ],
            ),
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
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.w500,
                  color:
                      isSelected ? activeColor : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
