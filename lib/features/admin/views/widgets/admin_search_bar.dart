import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/admin_colors.dart';

/// ===================================================================
/// [VIEW WIDGET - MVC PATTERN]
/// AdminSearchBar: অ্যাডমিন প্যানেলের যেকোনো তালিকার (Requests / Users)
/// জন্য পুনরায় ব্যবহারযোগ্য সার্চ বার।
/// ===================================================================
class AdminSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String hintText;

  const AdminSearchBar({
    super.key,
    required this.onChanged,
    this.hintText = 'Search by Name, Phone, or TrxID...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: TextField(
        onChanged: onChanged,
        style: GoogleFonts.poppins(fontSize: 13.5.sp),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            fontSize: 13.sp,
            color: AdminColors.accentLight,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AdminColors.accentLight,
            size: 20.r,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: const BorderSide(color: AdminColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: const BorderSide(color: AdminColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: const BorderSide(
              color: AdminColors.borderFocused,
              width: 1.5,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 14.h),
        ),
      ),
    );
  }
}
