import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../bachelor/models/booking_model.dart';
import '../../../landlord/models/post_model.dart';
import '../../controllers/admin_controller.dart';
import '../../models/admin_nav_item_model.dart';
import '../utils/admin_colors.dart';
import '../widgets/admin_booking_card.dart';
import '../widgets/admin_post_card.dart';
import '../widgets/admin_search_bar.dart';

/// ===================================================================
/// [VIEW LAYER - MVC PATTERN]
///
/// ===================================================================
class AdminRequestsTab extends StatelessWidget {
  final AdminController controller;

  const AdminRequestsTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PostModel>>(
      stream: controller.allPostsStream,
      builder: (context, postSnapshot) {
        return StreamBuilder<List<BookingModel>>(
          stream: controller.allBookingsStream,
          builder: (context, bookingSnapshot) {
            if (postSnapshot.connectionState == ConnectionState.waiting ||
                bookingSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AdminColors.accentDark),
              );
            }

            final allPosts = postSnapshot.data ?? [];
            final allBookings = bookingSnapshot.data ?? [];

            final pendingPosts = allPosts
                .where((p) => p.paymentStatus.trim().toLowerCase() == 'pending')
                .toList();
            final approvedPosts = allPosts
                .where(
                  (p) =>
                      p.paymentStatus.trim().toLowerCase() == 'approved' ||
                      p.isPublished == true,
                )
                .toList();
            final rejectedPosts = allPosts
                .where(
                  (p) => p.paymentStatus.trim().toLowerCase() == 'rejected',
                )
                .toList();

            final pendingBookings = allBookings
                .where((b) => b.paymentStatus.trim().toLowerCase() == 'pending')
                .toList();
            final approvedBookings = allBookings
                .where(
                  (b) =>
                      b.paymentStatus.trim().toLowerCase() == 'approved' ||
                      b.isUnlocked == true,
                )
                .toList();
            final rejectedBookings = allBookings
                .where(
                  (b) => b.paymentStatus.trim().toLowerCase() == 'rejected',
                )
                .toList();

            return Column(
              children: [
                _buildCategorySelector(),
                Expanded(
                  child: Obx(() {
                    final catIndex = controller.selectedCategoryIndex.value;
                    if (catIndex == 1) {
                      return _buildPostsSection(
                        pendingPosts,
                        approvedPosts,
                        rejectedPosts,
                      );
                    }
                    // default catIndex == 0: Bachelor Bookings
                    return _buildBookingsSection(
                      pendingBookings,
                      approvedBookings,
                      rejectedBookings,
                    );
                  }),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCategorySelector() {
    return Obx(() {
      final currentCat = controller.selectedCategoryIndex.value;
      return Container(
        margin: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 8.h),
        padding: EdgeInsets.all(5.r),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0), // Modern slate segmented background
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: AdminCategoryModel.categories.map((cat) {
            final isSelected = currentCat == cat.index;
            return Expanded(
              child: GestureDetector(
                onTap: () => controller.setCategory(cat.index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AdminColors.accentDark
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AdminColors.accentDark.withValues(
                                alpha: 0.22,
                              ),
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
                        cat.icon,
                        size: 16.r,
                        color: isSelected
                            ? Colors.white
                            : AdminColors.accentMid,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        cat.title,
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AdminColors.accentMid,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  Widget _buildTabBar(int pendingCount, int approvedCount, int rejectedCount) {
    return Obx(() {
      final selectedTab = controller.selectedTabIndex.value;
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2F7),
          borderRadius: BorderRadius.circular(14.r),
        ),
        padding: EdgeInsets.all(4.r),
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton(
                0,
                'Pending ($pendingCount)',
                selectedTab == 0,
                AdminColors.statusPending,
              ),
            ),
            Expanded(
              child: _buildTabButton(
                1,
                'Approved ($approvedCount)',
                selectedTab == 1,
                AdminColors.statusApproved,
              ),
            ),
            Expanded(
              child: _buildTabButton(
                2,
                'Rejected ($rejectedCount)',
                selectedTab == 2,
                AdminColors.statusRejected,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTabButton(
    int index,
    String title,
    bool isSelected,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => controller.setTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4.r,
                    offset: Offset(0, 2.h),
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? color : AdminColors.accentLight,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildBookingsSection(
    List<BookingModel> pending,
    List<BookingModel> approved,
    List<BookingModel> rejected,
  ) {
    return Column(
      children: [
        AdminSearchBar(
          hintText: 'Search by Name, TrxID or Sender...',
          onChanged: (val) => controller.updateSearch(val),
        ),
        _buildTabBar(pending.length, approved.length, rejected.length),
        Expanded(
          child: Obx(() {
            final tabIndex = controller.selectedTabIndex.value;
            final query = controller.searchQuery.value.trim().toLowerCase();
            List<BookingModel> list = (tabIndex == 0)
                ? pending
                : (tabIndex == 1 ? approved : rejected);

            if (query.isNotEmpty) {
              list = list.where((b) {
                final name = b.bachelorName ?? '';
                final phone = b.bachelorPhone ?? '';
                return name.toLowerCase().contains(query) ||
                    phone.toLowerCase().contains(query) ||
                    b.trxId.toLowerCase().contains(query) ||
                    b.senderNumber.toLowerCase().contains(query);
              }).toList();
            }

            if (list.isEmpty) {
              return _buildEmptyState('No Bachelor bookings found');
            }

            return ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              itemCount: list.length,
              separatorBuilder: (c, i) => SizedBox(height: 14.h),
              itemBuilder: (c, i) => AdminBookingCard(
                booking: list[i],
                onApprove: () => controller.approveBooking(list[i]),
                onReject: () => controller.rejectBooking(list[i]),
                onDelete: () => controller.deleteBooking(list[i]),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPostsSection(
    List<PostModel> pending,
    List<PostModel> approved,
    List<PostModel> rejected,
  ) {
    return Column(
      children: [
        AdminSearchBar(
          hintText: 'Search by Title, Phone or TrxID...',
          onChanged: (val) => controller.updateSearch(val),
        ),
        _buildTabBar(pending.length, approved.length, rejected.length),
        Expanded(
          child: Obx(() {
            final tabIndex = controller.selectedTabIndex.value;
            final query = controller.searchQuery.value.trim().toLowerCase();
            List<PostModel> list = (tabIndex == 0)
                ? pending
                : (tabIndex == 1 ? approved : rejected);

            if (query.isNotEmpty) {
              list = list.where((p) {
                final phone = p.ownerPhone ?? '';
                final trx = p.paymentTrxId ?? '';
                final sender = p.senderNumber ?? '';
                return p.title.toLowerCase().contains(query) ||
                    phone.toLowerCase().contains(query) ||
                    trx.toLowerCase().contains(query) ||
                    sender.toLowerCase().contains(query);
              }).toList();
            }

            if (list.isEmpty) {
              return _buildEmptyState('No Mess listing posts found');
            }

            return ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              itemCount: list.length,
              separatorBuilder: (c, i) => SizedBox(height: 14.h),
              itemBuilder: (c, i) => AdminPostCard(
                post: list[i],
                onApprove: () => controller.approvePost(list[i]),
                onReject: () => controller.rejectPost(list[i]),
                onDelete: () => controller.deletePost(list[i]),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
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
