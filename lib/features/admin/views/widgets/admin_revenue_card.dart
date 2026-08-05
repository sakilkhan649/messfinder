import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/app_constants.dart';
import '../utils/admin_colors.dart';

/// ===================================================================
/// [VIEW WIDGET - MVC PATTERN]
/// AdminRevenueCard: অ্যাডমিনের মোট আয় ও আয়ের উৎসগুলোর (Bookings, Postings)
/// সারসংক্ষেপ প্রদর্শনকারী হিরো কার্ড (Hero Card)।
/// 
/// পারফেক্ট অ্যালাইনমেন্ট ও হরাইজন্টাল/ভার্টিক্যাল ডিভাইডার দিয়ে সাজানো হয়েছে।
/// ===================================================================
class AdminRevenueCard extends StatelessWidget {
  final int totalRevenue;
  final int postRev;
  final int bookingRev;

  const AdminRevenueCard({
    super.key,
    required this.totalRevenue,
    required this.postRev,
    required this.bookingRev,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        gradient: AdminColors.heroGradient,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.28),
            blurRadius: 16.r,
            offset: Offset(0, 7.h),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ওয়াটারমার্ক আইকন (Background shield icon)
          Positioned(
            right: -10.w,
            top: -10.h,
            child: Icon(
              Icons.shield_rounded,
              size: 100.r,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Header Row ─────────────────────────────
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(7.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 18.r,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Total Revenue Earned',
                    style: GoogleFonts.poppins(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),

              // ── Total Amount ───────────────────────────────
              Text(
                '৳$totalRevenue',
                style: GoogleFonts.poppins(
                  fontSize: 36.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                  height: 1.1,
                ),
              ),

              // ── Horizontal Divider ─────────────────────────
              Divider(
                color: Colors.white.withValues(alpha: 0.15),
                height: 32.h,
                thickness: 1,
              ),

              // ── Bottom Columns with Vertical Divider ───────
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildRevenueRowItem(
                        'Bookings (৳${AppConstants.bachelorFee})',
                        '৳$bookingRev',
                        Icons.school_rounded,
                        const Color(0xFFA78BFA), // Violet accent
                      ),
                    ),
                    VerticalDivider(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 32.w,
                      thickness: 1,
                    ),
                    Expanded(
                      child: _buildRevenueRowItem(
                        'Postings (৳${AppConstants.landlordFee})',
                        '৳$postRev',
                        Icons.home_work_rounded,
                        const Color(0xFF38BDF8), // Light blue accent
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueRowItem(
    String label,
    String amount,
    IconData icon,
    Color iconColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Icon(icon, size: 15.r, color: iconColor),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.white.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        Text(
          amount,
          style: GoogleFonts.poppins(
            fontSize: 19.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
