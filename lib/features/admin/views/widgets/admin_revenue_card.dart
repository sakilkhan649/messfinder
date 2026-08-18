import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// ===================================================================
/// [VIEW WIDGET - MVC PATTERN]
/// 
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
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.18),
            blurRadius: 16.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Header Row ─────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: Colors.white,
                      size: 16.r,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Control Center',
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.r,
                      height: 6.r,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      '100% Free Plan',
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF34D399),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // ── Title & Subtitle ───────────────────────────
          Text(
            'Community Management',
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'Direct access to mess listings, tenant leads, and member directory.',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: const Color(0xFF94A3B8),
              height: 1.35,
            ),
          ),

          SizedBox(height: 16.h),
          Divider(
            color: Colors.white.withValues(alpha: 0.1),
            height: 1.h,
          ),
          SizedBox(height: 14.h),

          // ── Bottom Highlights ──
          Row(
            children: [
              Expanded(
                child: _buildBadgeItem(
                  'Instant Publish',
                  'No Posting Fee',
                  Icons.verified_rounded,
                  const Color(0xFF38BDF8),
                ),
              ),
              Container(
                width: 1.w,
                height: 28.h,
                color: Colors.white.withValues(alpha: 0.1),
                margin: EdgeInsets.symmetric(horizontal: 10.w),
              ),
              Expanded(
                child: _buildBadgeItem(
                  'Free Inquiries',
                  'Direct Calls & Chat',
                  Icons.connect_without_contact_rounded,
                  const Color(0xFFA78BFA),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16.r, color: iconColor),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 10.5.sp,
                  color: const Color(0xFF94A3B8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
