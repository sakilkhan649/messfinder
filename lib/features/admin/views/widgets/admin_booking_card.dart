import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../bachelor/models/booking_model.dart';
import '../utils/admin_colors.dart';

class AdminBookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback? onDelete;

  const AdminBookingCard({
    super.key,
    required this.booking,
    required this.onApprove,
    required this.onReject,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final String name = booking.bachelorName?.isNotEmpty == true
        ? booking.bachelorName!
        : 'Bachelor Lead';
    final String phone = booking.bachelorPhone?.isNotEmpty == true
        ? booking.bachelorPhone!
        : (booking.senderNumber.isNotEmpty ? booking.senderNumber : 'N/A');

    final cardContent = Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AdminColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.035),
            blurRadius: 10.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header: Name & Role Badge ───
          Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: const Color(0xFFF3E8FF),
                child: Icon(Icons.school_rounded, color: const Color(0xFF9333EA), size: 18.r),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.accentDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Bachelor Inquiry Lead',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5.sp,
                        color: AdminColors.accentMid,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Connected',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Divider(color: const Color(0xFFF1F5F9), height: 1),
          ),

          // ─── Phone & Direct Call ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.phone_rounded, size: 14.r, color: AdminColors.accentMid),
                  SizedBox(width: 6.w),
                  Text(
                    phone,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                      color: AdminColors.accentDark,
                    ),
                  ),
                ],
              ),
              if (phone != 'N/A')
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse('tel:$phone');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(7.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Icon(
                      Icons.phone_rounded,
                      size: 14.r,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    if (onDelete != null) {
      return Dismissible(
        key: Key('booking_${booking.bookingId}'),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          return await Get.defaultDialog<bool>(
            title: 'Delete Lead Record',
            titleStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 16.sp,
              color: AdminColors.accentDark,
            ),
            content: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              child: Text(
                'Are you sure you want to permanently delete this lead record?\nThis action cannot be undone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5.sp,
                  color: AdminColors.accentMid,
                ),
              ),
            ),
            textConfirm: 'Delete',
            textCancel: 'Cancel',
            confirmTextColor: Colors.white,
            buttonColor: AdminColors.statusRejected,
            cancelTextColor: AdminColors.accentMid,
            onConfirm: () => Get.back(result: true),
            onCancel: () {},
          ) ?? false;
        },
        onDismissed: (direction) => onDelete!(),
        background: _buildSwipeBackground(Alignment.centerLeft, true),
        secondaryBackground: _buildSwipeBackground(Alignment.centerRight, false),
        child: cardContent,
      );
    }

    return cardContent;
  }

  Widget _buildSwipeBackground(Alignment alignment, bool isLeft) {
    return Container(
      alignment: alignment,
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
        color: AdminColors.statusRejected,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisAlignment:
            isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: isLeft
            ? [
                Icon(Icons.delete_forever_rounded, color: Colors.white, size: 24.r),
                SizedBox(width: 8.w),
                Text(
                  'Delete Record',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ]
            : [
                Text(
                  'Delete Record',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(Icons.delete_forever_rounded, color: Colors.white, size: 24.r),
              ],
      ),
    );
  }
}
