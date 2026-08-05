import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../bachelor/models/booking_model.dart';
import '../../../landlord/models/post_model.dart';
import '../../controllers/admin_controller.dart';
import '../../models/admin_stats_model.dart';
import '../utils/admin_colors.dart';
import '../widgets/admin_revenue_card.dart';
import '../widgets/admin_summary_card.dart';
import '../widgets/admin_breakdown_tile.dart';

/// ===================================================================
/// [VIEW LAYER - MVC PATTERN]
/// AdminOverviewTab: অ্যাডমিনের ওভারভিউ বা সামারি স্ক্রিন।
/// এখানে মোট আয় (Revenue) এবং প্রতিটি ক্যাটাগরির (Bookings, Posts)
/// পরিসংখ্যান কার্ড ও টাইল আকারে প্রদর্শিত হয়।
/// ===================================================================
class AdminOverviewTab extends StatelessWidget {
  final AdminController controller;

  const AdminOverviewTab({
    super.key,
    required this.controller,
  });

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
                child: CircularProgressIndicator(
                  color: AdminColors.accentDark,
                ),
              );
            }

            final posts = postSnapshot.data ?? [];
            final bookings = bookingSnapshot.data ?? [];

            // Model থেকে পরিসংখ্যান (Stats & Revenue) হিসাব করা হচ্ছে
            final stats = AdminStatsModel.fromData(
              bookings: bookings,
              posts: posts,
            );

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.all(20.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero Revenue Card ──────────────────────────────
                  AdminRevenueCard(
                    totalRevenue: stats.totalRevenue,
                    postRev: stats.postRevenue,
                    bookingRev: stats.bookingRevenue,
                  ),
                  SizedBox(height: 24.h),

                  // ── Requests Summary ───────────────────────────────
                  _buildSectionTitle('Requests Summary'),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: AdminSummaryCard(
                          label: 'Pending',
                          count: '${stats.totalPending}',
                          color: AdminColors.statusPending,
                          icon: Icons.hourglass_empty_rounded,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: AdminSummaryCard(
                          label: 'Approved',
                          count: '${stats.totalApproved}',
                          color: AdminColors.statusApproved,
                          icon: Icons.check_circle_outline_rounded,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: AdminSummaryCard(
                          label: 'Rejected',
                          count: '${stats.totalRejected}',
                          color: AdminColors.statusRejected,
                          icon: Icons.cancel_outlined,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // ── Category Breakdown ─────────────────────────────
                  _buildSectionTitle('Category Breakdown'),
                  SizedBox(height: 12.h),
                  AdminBreakdownTile(
                    title: 'Bachelor Bookings',
                    stats:
                        'Pending: ${stats.pendingBookings}  •  Approved: ${stats.approvedBookings}',
                    icon: Icons.school_rounded,
                    accentColor: const Color(0xFF7C3AED),
                  ),
                  SizedBox(height: 12.h),
                  AdminBreakdownTile(
                    title: 'Mess Posts',
                    stats:
                        'Pending: ${stats.pendingPosts}  •  Approved: ${stats.approvedPosts}',
                    icon: Icons.home_work_rounded,
                    accentColor: const Color(0xFF0891B2),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 15.sp,
        fontWeight: FontWeight.w700,
        color: AdminColors.accentDark,
      ),
    );
  }
}
