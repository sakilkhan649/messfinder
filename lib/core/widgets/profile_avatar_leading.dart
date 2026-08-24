import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
          child: Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            clipBehavior: Clip.antiAlias,
            child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: user.photoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: SizedBox(
                        width: 20.r,
                        height: 20.r,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20.r,
                    ),
                  )
                : Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20.r,
                  ),
          ),
        ),
      );
    });
  }
}
