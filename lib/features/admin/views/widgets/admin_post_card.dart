import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../landlord/models/post_model.dart';
import '../utils/admin_colors.dart';

class AdminPostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback? onDelete;

  const AdminPostCard({
    super.key,
    required this.post,
    required this.onApprove,
    required this.onReject,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final String ownerPhone = post.ownerPhone ?? '';
    final String address = post.address.isNotEmpty
        ? post.address
        : '${post.district}, ${post.division}';

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
          // ─── Header: Post Title & Rent Badge ───
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  post.title.isNotEmpty ? post.title : 'Mess Room Listing',
                  style: GoogleFonts.poppins(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.accentDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  '৳${post.rent.toInt()}/mo',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // ─── Location ───
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14.r,
                color: const Color(0xFF0284C7),
              ),
              SizedBox(width: 5.w),
              Expanded(
                child: Text(
                  address,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: AdminColors.accentMid,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Divider(color: const Color(0xFFF1F5F9), height: 1),
          ),

          // ─── Landlord Info & Actions ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Landlord contact
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.person_pin_circle_rounded,
                      size: 16.r,
                      color: AdminColors.accentMid,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        ownerPhone.isNotEmpty ? ownerPhone : 'Owner: N/A',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AdminColors.accentDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Chip
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: post.isAvailable
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: post.isAvailable
                        ? const Color(0xFF10B981).withValues(alpha: 0.3)
                        : AdminColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5.r,
                      height: 5.r,
                      decoration: BoxDecoration(
                        color: post.isAvailable
                            ? const Color(0xFF10B981)
                            : const Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      post.isAvailable ? 'Available' : 'Booked',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w600,
                        color: post.isAvailable
                            ? const Color(0xFF059669)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              if (ownerPhone.isNotEmpty) ...[
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse('tel:$ownerPhone');
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
            ],
          ),
        ],
      ),
    );

    if (onDelete != null) {
      return Dismissible(
        key: Key('post_${post.postId}'),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          return await Get.defaultDialog<bool>(
            title: 'Delete Listing',
            titleStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 16.sp,
              color: AdminColors.accentDark,
            ),
            content: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              child: Text(
                'Are you sure you want to permanently delete "${post.title}"?\nThis action cannot be undone.',
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
                  'Delete Listing',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ]
            : [
                Text(
                  'Delete Listing',
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
