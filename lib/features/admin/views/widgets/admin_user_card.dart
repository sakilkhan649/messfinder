import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/models/user_model.dart';
import '../utils/admin_colors.dart';

/// ===================================================================
/// [VIEW WIDGET - MVC PATTERN]
/// 
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
    final isAdmin = user.role.trim().toLowerCase() == 'admin';

    final phoneText = (resolvedPhone != null && resolvedPhone!.isNotEmpty)
        ? resolvedPhone!
        : (user.phone.isNotEmpty ? user.phone : 'No phone number');

    final emailText = user.email.isNotEmpty ? user.email : 'No email address';

    return Dismissible(
      key: Key('${user.uid}_${user.role}'),
      direction: DismissDirection.horizontal, // Left & Right swipe to delete
      confirmDismiss: (direction) async {
        return await Get.defaultDialog<bool>(
          title: 'Delete User Account',
          titleStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16.sp,
            color: AdminColors.accentDark,
          ),
          content: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            child: Text(
              'Are you sure you want to permanently delete "${user.name.isNotEmpty ? user.name : "this user"}"?\nThis action cannot be undone.',
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
      onDismissed: (direction) {
        onDelete();
      },
      background: _buildSwipeBackground(Alignment.centerLeft, true),
      secondaryBackground: _buildSwipeBackground(Alignment.centerRight, false),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isAdmin
                ? const Color(0xFFF97316).withValues(alpha: 0.3)
                : AdminColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.025),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 20.r,
              backgroundColor: isAdmin
                  ? const Color(0xFFFFF7ED)
                  : const Color(0xFFF1F5F9),
              child: Icon(
                isAdmin
                    ? Icons.admin_panel_settings_rounded
                    : Icons.person_rounded,
                color: isAdmin
                    ? const Color(0xFFEA580C)
                    : const Color(0xFF475569),
                size: 20.r,
              ),
            ),
            SizedBox(width: 12.w),
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
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w700,
                            color: AdminColors.accentDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      _buildRoleBadge(isAdmin),
                    ],
                  ),
                  SizedBox(height: 4.h),

                  // ─── Phone Number ───
                  Row(
                    children: [
                      Icon(
                        Icons.phone_rounded,
                        size: 12.r,
                        color: AdminColors.accentMid,
                      ),
                      SizedBox(width: 5.w),
                      Expanded(
                        child: Text(
                          phoneText,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5.sp,
                            color: AdminColors.accentMid,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),

                  // ─── Email ───
                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 12.r,
                        color: AdminColors.accentLight,
                      ),
                      SizedBox(width: 5.w),
                      Expanded(
                        child: Text(
                          emailText,
                          style: GoogleFonts.poppins(
                            fontSize: 11.sp,
                            color: AdminColors.accentLight,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: AdminColors.statusRejected,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        mainAxisAlignment:
            isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: isLeft
            ? [
                Icon(Icons.delete_forever_rounded,
                    color: Colors.white, size: 22.r),
                SizedBox(width: 6.w),
                Text(
                  'Delete Account',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ]
            : [
                Text(
                  'Delete Account',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 6.w),
                Icon(Icons.delete_forever_rounded,
                    color: Colors.white, size: 22.r),
              ],
      ),
    );
  }

  Widget _buildRoleBadge(bool isAdmin) {
    final Color badgeColor = isAdmin
        ? const Color(0xFFEA580C)
        : const Color(0xFF0284C7);

    final Color bgColor = isAdmin
        ? const Color(0xFFFFF7ED)
        : const Color(0xFFF0F9FF);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.5.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        isAdmin ? 'ADMIN' : 'USER',
        style: GoogleFonts.poppins(
          fontSize: 9.5.sp,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }
}
