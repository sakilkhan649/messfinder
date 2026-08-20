import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../features/profile/views/profile_screen.dart';

class ProfileAvatarLeading extends StatelessWidget {
  const ProfileAvatarLeading({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the AuthController to access the current user
    final authController = Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
    
    return Obx(() {
      final user = authController?.currentUser.value;
      if (user == null) {
        return const SizedBox.shrink(); // Hide if no user is found
      }
      
      return GestureDetector(
        onTap: () {
          Get.to(() => ProfileScreen(user: user));
        },
        child: Padding(
          padding: EdgeInsets.only(left: 16.w),
          child: CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                ? NetworkImage(user.photoUrl!)
                : null,
            child: user.photoUrl == null || user.photoUrl!.isEmpty
                ? Icon(Icons.person, color: Colors.white, size: 20.r)
                : null,
          ),
        ),
      );
    });
  }
}
