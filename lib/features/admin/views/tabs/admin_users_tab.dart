import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/models/user_model.dart';
import '../../../bachelor/models/booking_model.dart';
import '../../../landlord/models/post_model.dart';
import '../../../payment/models/payment_model.dart';
import '../../controllers/admin_controller.dart';
import '../utils/admin_colors.dart';
import '../widgets/admin_search_bar.dart';
import '../widgets/admin_user_card.dart';

/// ===================================================================
/// [VIEW LAYER - MVC PATTERN]
/// AdminUsersTab: অ্যাপে নিবন্ধিত সব ইউজারের (Landlords এবং Bachelors)
/// তালিকা আলাদা ২টি ট্যাবে প্রদর্শন ও ইউজার ডিলিট করার ট্যাব।
/// 
/// কেউ ২টি রোলেই (Landlord ও Bachelor) অ্যাকাউন্ট খুলে থাকলে তাকে
/// ২ ট্যাবেই দেখানো হয় এবং Left-Right Swipe করে ডিলিট করা যায়।
/// ===================================================================
class AdminUsersTab extends StatelessWidget {
  final AdminController controller;

  const AdminUsersTab({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: controller.allUsersStream,
      builder: (context, userSnapshot) {
        return StreamBuilder<List<PostModel>>(
          stream: controller.allPostsStream,
          builder: (context, postSnapshot) {
            return StreamBuilder<List<BookingModel>>(
              stream: controller.allBookingsStream,
              builder: (context, bookingSnapshot) {
                return StreamBuilder<List<PaymentModel>>(
                  stream: controller.allPaymentsStream,
                  builder: (context, paymentSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AdminColors.accentDark,
                        ),
                      );
                    }

                    final allUsers = userSnapshot.data ?? [];
                    final allPosts = postSnapshot.data ?? [];
                    final allBookings = bookingSnapshot.data ?? [];
                    final allPayments = paymentSnapshot.data ?? [];

                    // বাড়িওয়ালা (Landlord) এবং ব্যাচেলর (Bachelor) আলাদা করা
                    // (কেউ ২টি রোলেই অ্যাকাউন্ট খুলে থাকলে উভয় ট্যাবেই দেখাবে)
                    final landlordUsers = allUsers
                        .where((u) => controller.isLandlordUser(
                              u,
                              allPosts,
                              allPayments,
                            ))
                        .toList();
                    final bachelorUsers = allUsers
                        .where((u) => controller.isBachelorUser(
                              u,
                              allBookings,
                              allPayments,
                              allPosts,
                            ))
                        .toList();

                    return Column(
                      children: [
                        AdminSearchBar(
                          hintText: 'Search by Name, Phone, TrxID, or UID...',
                          onChanged: (val) => controller.updateSearch(val),
                        ),
                        _buildUserRoleTabs(
                          landlordCount: landlordUsers.length,
                          bachelorCount: bachelorUsers.length,
                        ),
                        Expanded(
                          child: Obx(() {
                            final tabIndex =
                                controller.selectedUserRoleIndex.value;
                            final query = controller.searchQuery.value
                                .trim()
                                .toLowerCase();

                            List<UserModel> list = (tabIndex == 0)
                                ? landlordUsers
                                : bachelorUsers;

                            if (query.isNotEmpty) {
                              list = list.where((u) {
                                final contactInfo =
                                    controller.getUserContactInfo(
                                  u,
                                  allPosts,
                                  allBookings,
                                  allPayments,
                                );
                                final phone = contactInfo['phone'] ?? '';
                                final trxId = contactInfo['trxId'] ?? '';
                                return u.name.toLowerCase().contains(query) ||
                                    phone.toLowerCase().contains(query) ||
                                    trxId.toLowerCase().contains(query) ||
                                    u.uid.toLowerCase().contains(query);
                              }).toList();
                            }

                            if (list.isEmpty) {
                              return _buildEmptyState(
                                tabIndex == 0
                                    ? 'No Landlord accounts found'
                                    : 'No Bachelor accounts found',
                              );
                            }

                            return ListView.separated(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20.w, vertical: 12.h),
                              itemCount: list.length,
                              separatorBuilder: (c, i) => SizedBox(height: 12.h),
                              itemBuilder: (c, i) {
                                final user = list[i];
                                final contactInfo =
                                    controller.getUserContactInfo(
                                  user,
                                  allPosts,
                                  allBookings,
                                  allPayments,
                                );
                                return AdminUserCard(
                                  user: user,
                                  resolvedPhone: contactInfo['phone'],
                                  resolvedTrxId: contactInfo['trxId'],
                                  onDelete: () =>
                                      controller.confirmDeleteUser(user),
                                );
                              },
                            );
                          }),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // ─── বাড়িওয়ালা (Landlord) vs ব্যাচেলর (Bachelor) Full-Width Segmented Tab ───
  Widget _buildUserRoleTabs({
    required int landlordCount,
    required int bachelorCount,
  }) {
    return Obx(() {
      final selectedTab = controller.selectedUserRoleIndex.value;
      return Container(
        margin: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 8.h),
        padding: EdgeInsets.all(5.r),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildRoleTabButton(
                index: 0,
                title: 'Landlords ($landlordCount)',
                icon: Icons.real_estate_agent_rounded,
                isSelected: selectedTab == 0,
              ),
            ),
            Expanded(
              child: _buildRoleTabButton(
                index: 1,
                title: 'Bachelors ($bachelorCount)',
                icon: Icons.school_rounded,
                isSelected: selectedTab == 1,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRoleTabButton({
    required int index,
    required String title,
    required IconData icon,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => controller.setUserRoleTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? AdminColors.accentDark : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AdminColors.accentDark.withValues(alpha: 0.22),
                    blurRadius: 10.r,
                    offset: Offset(0, 4.h),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16.r,
              color: isSelected ? Colors.white : AdminColors.accentMid,
            ),
            SizedBox(width: 8.w),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AdminColors.accentMid,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 50.r,
            color: AdminColors.accentLight.withValues(alpha: 0.4),
          ),
          SizedBox(height: 12.h),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AdminColors.accentLight,
            ),
          ),
        ],
      ),
    );
  }
}
