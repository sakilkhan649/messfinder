import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../admin/views/utils/admin_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/notification_controller.dart';
import '../models/app_notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<NotificationController>();
    final authCtrl = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;
    final isAdmin = authCtrl?.currentUser.value?.isAdmin == true;

    final Color primaryColor = isAdmin
        ? AdminColors.accentDark
        : const Color(0xFF059669);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18.sp,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        actions: [
          Obx(() {
            if (ctrl.notifications.isEmpty) return const SizedBox.shrink();
            return PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              onSelected: (value) async {
                if (value == 'mark_read') {
                  await ctrl.markAllRead();
                } else if (value == 'clear_all') {
                  Get.defaultDialog(
                    title: 'Clear Notifications',
                    titleStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                      color: const Color(0xFF1E293B),
                    ),
                    middleText: 'Are you sure you want to delete all notifications from the server?',
                    middleTextStyle: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      color: Colors.grey.shade700,
                    ),
                    textConfirm: 'Delete All',
                    textCancel: 'Cancel',
                    confirmTextColor: Colors.white,
                    buttonColor: Colors.red,
                    cancelTextColor: Colors.grey.shade700,
                    onConfirm: () async {
                      Get.back();
                      await ctrl.deleteAllNotifications();
                    },
                  );
                }
              },
              itemBuilder: (context) => [
                if (ctrl.unreadCount.value > 0)
                  PopupMenuItem(
                    value: 'mark_read',
                    child: Row(
                      children: [
                        Icon(Icons.done_all_rounded, size: 18.r, color: primaryColor),
                        SizedBox(width: 10.w),
                        Text(
                          'Mark all as read',
                          style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_rounded, size: 18.r, color: Colors.red),
                      SizedBox(width: 10.w),
                      Text(
                        'Clear all notifications',
                        style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
      body: Obx(() {
        final list = ctrl.notifications;
        if (list.isEmpty) {
          return _buildEmpty();
        }
        return ListView.separated(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          itemCount: list.length,
          separatorBuilder: (context, index) => SizedBox(height: 8.h),
          itemBuilder: (context, i) {
            return Dismissible(
              key: Key(list[i].id),
              direction: DismissDirection.horizontal,
              onDismissed: (direction) {
                ctrl.deleteNotification(list[i].id);
              },
              background: Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(left: 20.w),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(Icons.delete_outline_rounded, color: Colors.red, size: 24.r),
              ),
              secondaryBackground: Container(
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 20.w),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(Icons.delete_outline_rounded, color: Colors.red, size: 24.r),
              ),
              child: _NotificationTile(
                notification: list[i],
                onTap: () {
                  ctrl.markRead(list[i].id);
                  _showNotificationDetail(context, list[i]);
                },
              ),
            )
            .animate()
            .fadeIn(duration: 300.ms, delay: (i * 50).ms)
            .slideY(
              begin: 0.1,
              end: 0,
              duration: 300.ms,
              delay: (i * 50).ms,
            );
          },
        );
      }),
    );
  }

  void _showNotificationDetail(BuildContext context, AppNotificationModel item) {
    final icon = _getNotificationIcon(item.type);
    final color = _getNotificationColor(item.type);

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24.r),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        _formatNotificationTime(item.createdAt),
                        style: GoogleFonts.poppins(
                          fontSize: 11.5.sp,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            const Divider(),
            SizedBox(height: 12.h),
            Text(
              item.body,
              style: GoogleFonts.poppins(
                fontSize: 13.5.sp,
                color: const Color(0xFF334155),
                height: 1.5,
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 48.r,
              color: const Color(0xFF059669),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'No Notifications',
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'You\'re all caught up!\nNew notifications will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final icon = _getIcon(notification.type);
    final color = _getColor(notification.type);
    final timeAgo = _formatTime(notification.createdAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: notification.isRead
                ? Colors.grey.shade200
                : color.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: [
            if (!notification.isRead)
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 8.r,
                offset: Offset(0, 2.h),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20.r),
            ),
            SizedBox(width: 12.w),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5.sp,
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8.r,
                          height: 8.r,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    notification.body,
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    timeAgo,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5.sp,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(NotificationType type) => _getNotificationIcon(type);
  Color _getColor(NotificationType type) => _getNotificationColor(type);
  String _formatTime(DateTime dt) => _formatNotificationTime(dt);
}

IconData _getNotificationIcon(NotificationType type) {
  switch (type) {
    case NotificationType.newPost:
      return Icons.home_work_rounded;
    case NotificationType.bookingRequest:
      return Icons.person_add_rounded;
    case NotificationType.bookingApproved:
      return Icons.check_circle_rounded;
    case NotificationType.bookingRejected:
      return Icons.cancel_rounded;
    case NotificationType.paymentVerified:
      return Icons.payment_rounded;
    case NotificationType.adminBroadcast:
      return Icons.campaign_rounded;
    default:
      return Icons.notifications_rounded;
  }
}

Color _getNotificationColor(NotificationType type) {
  switch (type) {
    case NotificationType.newPost:
      return const Color(0xFF059669);
    case NotificationType.bookingRequest:
      return const Color(0xFF3B82F6);
    case NotificationType.bookingApproved:
      return const Color(0xFF10B981);
    case NotificationType.bookingRejected:
      return const Color(0xFFEF4444);
    case NotificationType.paymentVerified:
      return const Color(0xFFF59E0B);
    case NotificationType.adminBroadcast:
      return const Color(0xFF8B5CF6);
    default:
      return const Color(0xFF64748B);
  }
}

String _formatNotificationTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.day}/${dt.month}/${dt.year}';
}
