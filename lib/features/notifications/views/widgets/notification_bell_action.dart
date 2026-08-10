import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controllers/notification_controller.dart';
import '../notifications_screen.dart';

class NotificationBellAction extends StatelessWidget {
  final Color? color;

  const NotificationBellAction({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<NotificationController>()) {
      return _buildIcon(0);
    }
    
    return Obx(() {
      final count = Get.find<NotificationController>().unreadCount.value;
      return _buildIcon(count);
    });
  }

  Widget _buildIcon(int count) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () => Get.to(() => const NotificationsScreen(),
              transition: Transition.rightToLeft),
          icon: Icon(
            Icons.notifications, // Changed to standard notifications icon
            color: color ?? Colors.white,
            size: 28.r, // Explicitly set size
          ),
        ),
        if (count > 0)
          Positioned(
            right: 8.w,
            top: 8.h,
            child: Container(
              padding: EdgeInsets.all(4.r),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
