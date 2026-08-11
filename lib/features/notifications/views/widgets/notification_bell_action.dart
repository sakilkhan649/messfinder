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
            Icons.notifications,
            color: color ?? Colors.white,
            size: 24.r, // Made a bit smaller
          ),
        ),
        if (count > 0)
          Positioned(
            right: 10.w,
            top: 10.h,
            child: Container(
              padding: EdgeInsets.all(3.r),
              constraints: BoxConstraints(
                minWidth: 16.r,
                minHeight: 16.r,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE50000), // Pure red for the badge
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                count > 9 ? '9+' : '$count',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  height: 1, // To ensure it centers properly
                ),
              ),
            ),
          ),
      ],
    );
  }
}
