import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/models/user_model.dart';
import '../../controllers/admin_controller.dart';
import '../utils/admin_colors.dart';
import '../widgets/admin_search_bar.dart';
import '../widgets/admin_user_card.dart';

class AdminUsersTab extends StatelessWidget {
  final AdminController controller;

  const AdminUsersTab({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.allUsers.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(
            color: AdminColors.accentDark,
          ),
        );
      }

      final allUsers = controller.allUsers;
      final regularUsers = allUsers.where((u) => !controller.isAdminUser(u)).toList();
      final adminUsers = allUsers.where((u) => controller.isAdminUser(u)).toList();

      return RefreshIndicator(
        color: AdminColors.accentDark,
        onRefresh: () => controller.fetchDashboardData(showLoader: false),
        child: Column(
          children: [
            AdminSearchBar(
              hintText: 'Search by Name, Phone, Email, or UID...',
              onChanged: (val) => controller.updateSearch(val),
            ),
            _buildUserRoleTabs(
              allCount: allUsers.length,
              usersCount: regularUsers.length,
              adminCount: adminUsers.length,
            ),
            Expanded(
              child: Obx(() {
                final tabIndex = controller.selectedUserRoleIndex.value;
                final query = controller.searchQuery.value.trim().toLowerCase();

                List<UserModel> list;
                if (tabIndex == 1) {
                  list = regularUsers;
                } else if (tabIndex == 2) {
                  list = adminUsers;
                } else {
                  list = allUsers;
                }

                if (query.isNotEmpty) {
                  list = list.where((u) {
                    final phone = u.phone;
                    final email = u.email;
                    return u.name.toLowerCase().contains(query) ||
                        phone.toLowerCase().contains(query) ||
                        email.toLowerCase().contains(query) ||
                        u.uid.toLowerCase().contains(query);
                  }).toList();
                }

                if (list.isEmpty) {
                  String emptyLabel = 'No accounts found';
                  if (tabIndex == 1) emptyLabel = 'No User accounts found';
                  if (tabIndex == 2) emptyLabel = 'No Admin accounts found';
                  return _buildEmptyState(emptyLabel);
                }

                return ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  itemCount: list.length,
                  separatorBuilder: (c, i) => SizedBox(height: 12.h),
                  itemBuilder: (c, i) {
                    final user = list[i];
                    return AdminUserCard(
                      user: user,
                      resolvedPhone: user.phone,
                      onDelete: () => controller.confirmDeleteUser(user),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildUserRoleTabs({
    required int allCount,
    required int usersCount,
    required int adminCount,
  }) {
    return Obx(() {
      final selectedTab = controller.selectedUserRoleIndex.value;
      final tabs = [
        {'title': 'All Users ($allCount)', 'icon': Icons.groups_rounded},
        {'title': 'General Users ($usersCount)', 'icon': Icons.person_rounded},
        {'title': 'Admins ($adminCount)', 'icon': Icons.admin_panel_settings_rounded},
      ];

      return Container(
        height: 38.h,
        margin: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 8.h),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: tabs.length,
          separatorBuilder: (c, i) => SizedBox(width: 8.w),
          itemBuilder: (context, index) {
            final isSelected = selectedTab == index;
            final tab = tabs[index];
            return GestureDetector(
              onTap: () => controller.setUserRoleTab(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isSelected ? AdminColors.accentDark : Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: isSelected ? AdminColors.accentDark : AdminColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 14.r,
                      color: isSelected ? Colors.white : AdminColors.accentMid,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      tab['title'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AdminColors.accentMid,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 44.r,
            color: AdminColors.accentLight.withValues(alpha: 0.4),
          ),
          SizedBox(height: 10.h),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w500,
              color: AdminColors.accentLight,
            ),
          ),
        ],
      ),
    );
  }
}
