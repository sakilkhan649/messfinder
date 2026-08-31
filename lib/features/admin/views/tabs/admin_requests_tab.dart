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

class AdminRequestsTab extends StatelessWidget {
  final AdminController controller;

  const AdminRequestsTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.allPosts.isEmpty && controller.allBookings.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: AdminColors.accentDark),
        );
      }

      final allPosts = controller.allPosts;
      final allBookings = controller.allBookings;

      return RefreshIndicator(
        color: AdminColors.accentDark,
        onRefresh: () => controller.fetchDashboardData(showLoader: false),
        child: Column(
          children: [
            _buildCategorySelector(),
            Expanded(
              child: Obx(() {
                final catIndex = controller.selectedCategoryIndex.value;
                if (catIndex == 0) {
                  return _buildPostsSection(allPosts);
                }
                return _buildBookingsSection(allBookings);
              }),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCategorySelector() {
    return Obx(() {
      final currentCat = controller.selectedCategoryIndex.value;
      return Container(
        margin: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 8.h),
        padding: EdgeInsets.all(4.r),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          children: AdminCategoryModel.categories.map((cat) {
            final isSelected = currentCat == cat.index;
            return Expanded(
              child: GestureDetector(
                onTap: () => controller.setCategory(cat.index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  decoration: BoxDecoration(
                    color: isSelected ? AdminColors.accentDark : Colors.transparent,
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AdminColors.accentDark.withValues(alpha: 0.2),
                              blurRadius: 8.r,
                              offset: Offset(0, 3.h),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        cat.icon,
                        size: 15.r,
                        color: isSelected ? Colors.white : AdminColors.accentMid,
                      ),
                      SizedBox(width: 7.w),
                      Text(
                        cat.title,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5.sp,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? Colors.white : AdminColors.accentMid,
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

  Widget _buildPostsSection(List<PostModel> posts) {
    final availableCount = posts.where((p) => p.isAvailable).length;
    final bookedCount = posts.where((p) => !p.isAvailable).length;

    return Column(
      children: [
        AdminSearchBar(
          hintText: 'Search by Title, Area, or Phone...',
          onChanged: (val) => controller.updateSearch(val),
        ),
        // Filter Pills
        Obx(() {
          final tabIndex = controller.selectedTabIndex.value;
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
            child: Row(
              children: [
                _buildFilterPill(0, 'All (${posts.length})', tabIndex == 0),
                SizedBox(width: 8.w),
                _buildFilterPill(1, 'Available ($availableCount)', tabIndex == 1),
                SizedBox(width: 8.w),
                _buildFilterPill(2, 'Booked ($bookedCount)', tabIndex == 2),
              ],
            ),
          );
        }),
        Expanded(
          child: Obx(() {
            final tabIndex = controller.selectedTabIndex.value;
            final query = controller.searchQuery.value.trim().toLowerCase();

            List<PostModel> list = posts;
            if (tabIndex == 1) {
              list = posts.where((p) => p.isAvailable).toList();
            } else if (tabIndex == 2) {
              list = posts.where((p) => !p.isAvailable).toList();
            }

            if (query.isNotEmpty) {
              list = list.where((p) {
                final phone = p.ownerPhone ?? '';
                final address = p.address;
                return p.title.toLowerCase().contains(query) ||
                    phone.toLowerCase().contains(query) ||
                    address.toLowerCase().contains(query) ||
                    p.district.toLowerCase().contains(query);
              }).toList();
            }

            if (list.isEmpty) {
              return _buildEmptyState('No Mess listings found');
            }

            return ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              itemCount: list.length,
              separatorBuilder: (c, i) => SizedBox(height: 12.h),
              itemBuilder: (c, i) => AdminPostCard(
                key: ValueKey(list[i].postId),
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

  Widget _buildBookingsSection(List<BookingModel> bookings) {
    return Column(
      children: [
        AdminSearchBar(
          hintText: 'Search by Name or Phone...',
          onChanged: (val) => controller.updateSearch(val),
        ),
        Expanded(
          child: Obx(() {
            final query = controller.searchQuery.value.trim().toLowerCase();
            List<BookingModel> list = bookings;

            if (query.isNotEmpty) {
              list = list.where((b) {
                final name = b.bachelorName ?? '';
                final phone = b.bachelorPhone ?? '';
                return name.toLowerCase().contains(query) ||
                    phone.toLowerCase().contains(query);
              }).toList();
            }

            if (list.isEmpty) {
              return _buildEmptyState('No Bachelor inquiry leads found');
            }

            return ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              itemCount: list.length,
              separatorBuilder: (c, i) => SizedBox(height: 12.h),
              itemBuilder: (c, i) => AdminBookingCard(
                key: ValueKey(list[i].bookingId),
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

  Widget _buildFilterPill(int index, String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected ? AdminColors.accentDark : Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isSelected ? AdminColors.accentDark : AdminColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.5.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AdminColors.accentMid,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
            Icons.inbox_outlined,
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
