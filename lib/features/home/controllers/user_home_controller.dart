import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/models/user_model.dart';
import '../../bachelor/views/bachelor_home_screen.dart';
import '../../bachelor/views/mess_map_screen.dart';
import '../../chat/views/chat_list_screen.dart';
import '../../landlord/views/add_post_screen.dart';
import '../../marketplace/views/marketplace_screen.dart';

class UserHomeController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final RxBool isBottomNavVisible = true.obs;

  List<Widget>? screens;

  void initScreensIfNeeded(UserModel user) {
    screens ??= [
      BachelorHomeScreen(user: user),
      const MessMapScreen(),
      AddPostScreen(
        showBackButton: false,
        customTag: 'new_home',
        onPostAdded: () {
          currentIndex.value = 0;
          isBottomNavVisible.value = true;
        },
      ),
      const MarketplaceScreen(),
      ChatListScreen(),
    ];
  }

  void onTabSelected(int index) {
    currentIndex.value = index;
    isBottomNavVisible.value = true;
  }

  bool handleScrollNotification(UserScrollNotification notification) {
    if (currentIndex.value == 0 || currentIndex.value == 3) {
      if (notification.direction == ScrollDirection.forward) {
        if (!isBottomNavVisible.value) isBottomNavVisible.value = true;
      } else if (notification.direction == ScrollDirection.reverse) {
        if (isBottomNavVisible.value) isBottomNavVisible.value = false;
      }
    } else {
      if (!isBottomNavVisible.value) isBottomNavVisible.value = true;
    }
    return false;
  }
}
