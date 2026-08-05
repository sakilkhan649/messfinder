import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/api_checker.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../landlord/models/post_model.dart';
import '../utils/admin_colors.dart';

/// ===================================================================
/// [VIEW WIDGET - MVC PATTERN]
/// AdminPostCard: মেস লিস্টিং পোস্ট ও পেমেন্টের বিস্তারিত দেখানোর কার্ড।
/// Approve এবং Reject করার বাটন এই কার্ড থেকে Controller-এর কলব্যাক চালায়।
/// 
/// Approved বা Rejected কার্ডগুলো Left-Right Swipe (Dismissible) করে
/// ফায়ারবেস থেকে স্থায়ীভাবে ডিলিট করা যায়।
/// ===================================================================
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
    final bool isApproved =
        post.paymentStatus.trim().toLowerCase() == 'approved' ||
            post.isPublished == true;
    final bool isPending =
        post.paymentStatus.trim().toLowerCase() == 'pending';

    final String ownerPhone = post.ownerPhone ?? 'N/A';
    final String trxId = post.paymentTrxId ?? 'N/A';
    final String senderNumber = post.senderNumber ?? 'N/A';

    final cardContent = Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isApproved
              ? AdminColors.statusApproved.withValues(alpha: 0.35)
              : AdminColors.border,
        ),
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
          // ─── Header: Post Title & Amount Badge ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  post.title,
                  style: GoogleFonts.poppins(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AdminColors.accentDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8.w),
              _buildFeeBadge('৳${AppConstants.landlordFee}'),
            ],
          ),
          SizedBox(height: 3.h),

          // ─── Subtitle: Role & Phone ───
          Text(
            'Landlord • $ownerPhone',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: AdminColors.accentLight,
              fontWeight: FontWeight.w500,
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Divider(color: AdminColors.border, height: 1),
          ),

          // ─── Payment Info: Sender & Method ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Sender: ${senderNumber.isNotEmpty ? senderNumber : "N/A"}',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.accentMid,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildMethodBadge('BKASH'),
            ],
          ),
          SizedBox(height: 10.h),

          // ─── TrxID Box with Copy Button ───
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'TrxID: ${trxId.isNotEmpty ? trxId : "N/A"}',
                    style: GoogleFonts.poppins(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.accentDark,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: trxId));
                    ApiChecker.showSuccess(
                      'TrxID copied to clipboard!',
                      title: 'Copied',
                    );
                  },
                  child: Icon(
                    Icons.copy_rounded,
                    size: 16.r,
                    color: AdminColors.accentMid,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),

          // ─── Action Buttons / Status Badge ───
          if (isPending)
            Row(
              children: [
                Expanded(
                  child: _buildActionBtn(
                    label: 'REJECT',
                    color: AdminColors.statusRejected,
                    isOutlined: true,
                    onTap: onReject,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildActionBtn(
                    label: 'APPROVE',
                    color: AdminColors.statusApproved,
                    isOutlined: false,
                    onTap: onApprove,
                  ),
                ),
              ],
            )
          else
            _buildStatusBadge(isApproved),
        ],
      ),
    );

    if (onDelete != null) {
      return Dismissible(
        key: Key('post_${post.postId}'),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          return await Get.defaultDialog<bool>(
            title: 'Delete Post Record',
            titleStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 17.sp,
              color: AdminColors.accentDark,
            ),
            content: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              child: Text(
                'Are you sure you want to permanently delete "${post.title}"?\nThis action cannot be undone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
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
                Icon(Icons.delete_forever_rounded,
                    color: Colors.white, size: 26.r),
                SizedBox(width: 8.w),
                Text(
                  'Delete Record',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ]
            : [
                Text(
                  'Delete Record',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(Icons.delete_forever_rounded,
                    color: Colors.white, size: 26.r),
              ],
      ),
    );
  }

  Widget _buildFeeBadge(String fee) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AdminColors.accentDark,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        fee,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13.sp,
        ),
      ),
    );
  }

  Widget _buildMethodBadge(String method) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        method,
        style: GoogleFonts.poppins(
          color: AdminColors.accentDark,
          fontWeight: FontWeight.w700,
          fontSize: 11.sp,
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required String label,
    required Color color,
    required bool isOutlined,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(12.r),
          border: isOutlined ? Border.all(color: color, width: 1.5) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isOutlined ? color : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isApproved) {
    final color =
        isApproved ? AdminColors.statusApproved : AdminColors.statusRejected;
    final text = isApproved ? 'APPROVED' : 'REJECTED';
    final icon =
        isApproved ? Icons.check_circle_rounded : Icons.cancel_rounded;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16.r),
          SizedBox(width: 6.w),
          Text(
            text,
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}
