import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/admin_controller.dart';
import '../../models/admin_stats_model.dart';
import '../utils/admin_colors.dart';
import '../widgets/admin_revenue_card.dart';
import '../widgets/admin_summary_card.dart';
import '../widgets/admin_breakdown_tile.dart';
import '../widgets/admin_broadcast_dialog.dart';

/// ===================================================================
/// [VIEW LAYER - MVC PATTERN]
/// ===================================================================
class AdminOverviewTab extends StatelessWidget {
  final AdminController controller;

  const AdminOverviewTab({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.allPosts.isEmpty && controller.allBookings.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(
            color: AdminColors.accentDark,
          ),
        );
      }

      final posts = controller.allPosts;
      final bookings = controller.allBookings;
      final stats = controller.adminStats.value.totalPending > 0 || controller.adminStats.value.totalApproved > 0
          ? controller.adminStats.value
          : AdminStatsModel.fromData(bookings: bookings, posts: posts);

      return RefreshIndicator(
        color: AdminColors.accentDark,
        onRefresh: () => controller.fetchDashboardData(showLoader: false),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: EdgeInsets.all(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Status Banner ──────────────────────────────
              AdminRevenueCard(
                totalRevenue: stats.totalRevenue,
                postRev: stats.postRevenue,
                bookingRev: stats.bookingRevenue,
              ),
              SizedBox(height: 20.h),

              // ── Quick Admin Actions ────────────────────────────
              _buildSectionTitle('Quick Actions'),
              SizedBox(height: 10.h),
              // Broadcast Banner Card
              GestureDetector(
                onTap: () => AdminBroadcastDialog.show(context),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(Icons.campaign_rounded, color: Colors.white, size: 20.r),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Broadcast Announcement',
                              style: GoogleFonts.poppins(
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF14532D),
                              ),
                            ),
                            Text(
                              'Send instant in-app alerts to all members',
                              style: GoogleFonts.poppins(
                                fontSize: 11.sp,
                                color: const Color(0xFF166534),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14.r, color: const Color(0xFF16A34A)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: _buildActionTile(
                      title: 'Mess Listings',
                      subtitle: '${posts.length} Listed',
                      icon: Icons.home_work_rounded,
                      color: const Color(0xFF0284C7),
                      onTap: () => controller.changeNavIndex(1),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _buildActionTile(
                      title: 'User Directory',
                      subtitle: '${controller.allUsers.length} Members',
                      icon: Icons.people_alt_rounded,
                      color: const Color(0xFF7C3AED),
                      onTap: () => controller.changeNavIndex(2),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 22.h),

              // ── Platform Activity Metrics ──────────────────────
              _buildSectionTitle('Platform Metrics'),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: AdminSummaryCard(
                      label: 'Listings',
                      count: '${posts.length}',
                      color: const Color(0xFF0284C7),
                      icon: Icons.home_rounded,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: AdminSummaryCard(
                      label: 'Users',
                      count: '${controller.allUsers.length}',
                      color: const Color(0xFF059669),
                      icon: Icons.group_rounded,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: AdminSummaryCard(
                      label: 'Inquiries',
                      count: '${bookings.length}',
                      color: const Color(0xFF7C3AED),
                      icon: Icons.connect_without_contact_rounded,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 22.h),

              // ── Category Breakdown ─────────────────────────────
              _buildSectionTitle('Community Breakdown'),
              SizedBox(height: 12.h),
              AdminBreakdownTile(
                title: 'Mess & Room Listings',
                stats:
                    'Active: ${posts.where((p) => p.isAvailable).length}  •  Total: ${posts.length}',
                icon: Icons.home_work_rounded,
                accentColor: const Color(0xFF0284C7),
              ),
              SizedBox(height: 10.h),
              AdminBreakdownTile(
                title: 'Room Inquiries & Connections',
                stats:
                    'Direct Connections: ${bookings.length}  •  Active: ${bookings.where((b) => b.isUnlocked).length}',
                icon: Icons.connect_without_contact_rounded,
                accentColor: const Color(0xFF7C3AED),
              ),
              SizedBox(height: 10.h),
              AdminBreakdownTile(
                title: 'Platform Community',
                stats:
                    'General Users: ${controller.allUsers.where((u) => !controller.isAdminUser(u)).length}  •  Admins: ${controller.allUsers.where((u) => controller.isAdminUser(u)).length}',
                icon: Icons.group_rounded,
                accentColor: const Color(0xFF059669),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AdminColors.border),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
              blurRadius: 8.r,
              offset: Offset(0, 3.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: color, size: 18.r),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.accentDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11.sp,
                      color: AdminColors.accentMid,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 14.sp,
        fontWeight: FontWeight.w700,
        color: AdminColors.accentDark,
      ),
    );
  }
}
