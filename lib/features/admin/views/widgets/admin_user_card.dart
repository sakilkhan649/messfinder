import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/models/user_model.dart';
import '../utils/admin_colors.dart';

/// ===================================================================
/// [VIEW WIDGET - MVC PATTERN]
/// AdminUserCard: ফায়ারবেসে নিবন্ধিত প্রতিটি ইউজারের আসল নাম (Real Name),
/// ফোন নম্বর এবং TrxID প্রদর্শনকারী আনুপাতিক ও সুন্দর কার্ড।
/// 
/// কার্ডের ওপর থেকে ডিলিট আইকন সরানো হয়েছে; ইউজার Left-Right Swipe
/// (Dismissible) করেই কার্ড ডিলিট করতে পারবে।
/// ===================================================================
class AdminUserCard extends StatelessWidget {
  final UserModel user;
  final String? resolvedPhone;
  final String? resolvedTrxId;
  final VoidCallback onDelete;

  const AdminUserCard({
    super.key,
    required this.user,
    this.resolvedPhone,
    this.resolvedTrxId,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isLandlord =
        user.role.trim().toLowerCase() == 'landlord';

    final phoneText = (resolvedPhone != null && resolvedPhone!.isNotEmpty)
        ? resolvedPhone!
        : (user.phone.isNotEmpty ? user.phone : 'No phone number');

    final trxIdText = (resolvedTrxId != null && resolvedTrxId!.isNotEmpty)
        ? resolvedTrxId!
        : (user.trxId != null && user.trxId!.isNotEmpty
            ? user.trxId!
            : 'Not submitted');

    return Dismissible(
      key: Key('${user.uid}_${user.role}'),
      direction: DismissDirection.horizontal, // Left & Right swipe to delete
      confirmDismiss: (direction) async {
        return await Get.defaultDialog<bool>(
          title: 'Delete User Account',
          titleStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 17.sp,
            color: AdminColors.accentDark,
          ),
          content: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            child: Text(
              'Are you sure you want to permanently delete "${user.name.isNotEmpty ? user.name : "this user"}"?\nThis action cannot be undone.',
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
          onConfirm: () {
            Get.back(result: true);
          },
          onCancel: () {},
        ) ?? false;
      },
      onDismissed: (direction) {
        onDelete();
      },
      background: _buildSwipeBackground(Alignment.centerLeft, true),
      secondaryBackground: _buildSwipeBackground(Alignment.centerRight, false),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 23.r,
              backgroundColor: isLandlord
                  ? const Color(0xFFE0F2FE)
                  : const Color(0xFFF3E8FF),
              child: Icon(
                isLandlord
                    ? Icons.real_estate_agent_rounded
                    : Icons.school_rounded,
                color: isLandlord
                    ? const Color(0xFF0284C7)
                    : const Color(0xFF9333EA),
                size: 21.r,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ─── Real Name & Role Badge ───
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.name.isNotEmpty ? user.name : 'Unknown User',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: AdminColors.accentDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      _buildRoleBadge(user.role),
                    ],
                  ),
                  SizedBox(height: 5.h),

                  // ─── Phone Number ───
                  Row(
                    children: [
                      Icon(
                        Icons.phone_rounded,
                        size: 13.r,
                        color: AdminColors.accentMid,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          phoneText,
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
                  SizedBox(height: 5.h),

                  // ─── TrxID Info ───
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 13.r,
                        color: trxIdText == 'Not submitted'
                            ? AdminColors.accentLight
                            : const Color(0xFF0D9488),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'TrxID: ',
                        style: GoogleFonts.poppins(
                          fontSize: 11.8.sp,
                          fontWeight: FontWeight.w500,
                          color: AdminColors.accentMid,
                        ),
                      ),
                      Text(
                        trxIdText,
                        style: GoogleFonts.poppins(
                          fontSize: 11.8.sp,
                          fontWeight: FontWeight.w700,
                          color: trxIdText == 'Not submitted'
                              ? AdminColors.accentLight
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      if (trxIdText != 'Not submitted') ...[
                        SizedBox(width: 6.w),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: trxIdText));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('TrxID copied: $trxIdText'),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Icon(
                            Icons.copy_rounded,
                            size: 14.r,
                            color: const Color(0xFF0D9488),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
                  'Delete Account',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ]
            : [
                Text(
                  'Delete Account',
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

  Widget _buildRoleBadge(String role) {
    final isLandlord = role.trim().toLowerCase() == 'landlord';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: isLandlord
            ? const Color(0xFF0284C7).withValues(alpha: 0.1)
            : const Color(0xFF9333EA).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        role.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: isLandlord
              ? const Color(0xFF0284C7)
              : const Color(0xFF9333EA),
        ),
      ),
    );
  }
}
