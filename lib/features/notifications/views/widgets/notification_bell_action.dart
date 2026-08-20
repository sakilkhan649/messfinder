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
    return IconButton(
      onPressed: () => Get.to(() => const NotificationsScreen(),
          transition: Transition.rightToLeft),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications,
            color: color ?? Colors.white,
            size: 26.r, // Smaller icon size
          ),
          if (count > 0)
            Positioned(
              right: -3.w,
              top: -3.h,
              child: Container(
                padding: EdgeInsets.all(2.r),
                constraints: BoxConstraints(
                  minWidth: 14.r,
                  minHeight: 14.r,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE50000), // vivid red
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  count > 9 ? '9+' : '$count',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8.sp,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
