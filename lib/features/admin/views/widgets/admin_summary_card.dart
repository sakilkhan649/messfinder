import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// ===================================================================
/// [VIEW WIDGET - MVC PATTERN]
/// ===================================================================
class AdminSummaryCard extends StatelessWidget {
  final String label;
  final String count;
  final Color color;
  final IconData icon;

  const AdminSummaryCard({
    super.key,
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 8.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(7.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18.r),
          ),
          SizedBox(height: 8.h),
          Text(
            count,
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
