import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/admin_controller.dart';
import '../models/admin_nav_item_model.dart';
import 'utils/admin_colors.dart';
import 'tabs/admin_overview_tab.dart';
import 'tabs/admin_requests_tab.dart';
import 'tabs/admin_users_tab.dart';
import 'tabs/admin_profile_tab.dart';

/// ===================================================================
/// [VIEW LAYER - MAIN SCAFFOLD (MVC PATTERN)]
/// 
/// ===================================================================
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late AdminController _adminController;

  @override
  void initState() {
    super.initState();
    _adminController = Get.find<AdminController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.pageBg,
      appBar: _buildAppBar(),
      body: Obx(() {
        final currentNav = _adminController.currentNavIndex.value;
        return IndexedStack(
          index: currentNav,
          children: [
            AdminOverviewTab(controller: _adminController),
            AdminRequestsTab(controller: _adminController),
            AdminUsersTab(controller: _adminController),
            AdminProfileTab(),
          ],
        );
      }),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AdminColors.accentDark,
      elevation: 0,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.admin_panel_settings_rounded,
            color: Colors.white,
            size: 24.r,
          ),
          SizedBox(width: 8.w),
          Text(
            'Admin Portal',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => _confirmLogout(),
          icon: Icon(Icons.logout_rounded, color: Colors.white, size: 22.r),
          tooltip: 'Logout',
        ),
        SizedBox(width: 6.w),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Obx(() {
      final currentNav = _adminController.currentNavIndex.value;
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.08),
              blurRadius: 16.r,
              offset: Offset(0, -4.h),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentNav,
          onTap: (index) => _adminController.changeNavIndex(index),
          backgroundColor: Colors.white,
          selectedItemColor: AdminColors.accentDark,
          unselectedItemColor: AdminColors.accentLight,
          selectedLabelStyle: GoogleFonts.poppins(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
          ),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: AdminNavItemModel.navItems.map((item) {
            final isSelected = currentNav == item.index;
            return BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 3.h),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: 22.r,
                ),
              ),
              label: item.label,
            );
          }).toList(),
        ),
      );
    });
  }

  void _confirmLogout() {
    Get.defaultDialog(
      title: 'Sign Out',
      titleStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.bold,
        fontSize: 18.sp,
      ),
      middleText: 'Are you sure you want to sign out from Admin Portal?',
      middleTextStyle: GoogleFonts.poppins(fontSize: 13.5.sp),
      textCancel: 'Cancel',
      textConfirm: 'Sign Out',
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFFE53935), // Red button
      onConfirm: () {
        Get.back();
        if (Get.isRegistered<AuthController>()) {
          Get.find<AuthController>().logout();
        }
      },
    );
  }
}
