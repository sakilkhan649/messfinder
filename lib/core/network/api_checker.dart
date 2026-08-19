import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ApiChecker {
  static void checkApi(dynamic response) {
    String errorMessage = 'Something went wrong, please try again!';

    if (response is String) {
      errorMessage = response;
    } else if (response != null && response.toString().isNotEmpty) {
      errorMessage = response.toString();
    }

    Get.snackbar(
      'Warning',
      errorMessage,
      backgroundColor: AppTheme.errorColor,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: EdgeInsets.all(16.r),
      duration: const Duration(seconds: 3),
    );
  }

  static void showSuccess(String message, {String title = 'Success!'}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: AppTheme.statusApproved,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: EdgeInsets.all(16.r),
      duration: const Duration(seconds: 3),
    );
  }

  static void showError(String message, {String title = 'Error!'}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: AppTheme.errorColor,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: EdgeInsets.all(16.r),
      duration: const Duration(seconds: 3),
    );
  }
}
