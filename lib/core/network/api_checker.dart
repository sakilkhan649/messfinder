import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';

class ApiChecker {
  static void checkApi(dynamic response) {
    String errorMessage = 'কিছু একটা সমস্যা হয়েছে, আবার চেষ্টা করুন!';

    if (response is String) {
      errorMessage = response;
    } else if (response != null && response.toString().isNotEmpty) {
      errorMessage = response.toString();
    }

    Get.snackbar(
      'সতর্কবার্তা',
      errorMessage,
      backgroundColor: AppTheme.errorColor,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }

  static void showSuccess(String message, {String title = 'সফল!'}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: AppTheme.statusApproved,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }

  static void showError(String message, {String title = 'ত্রুটি!'}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: AppTheme.errorColor,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }
}
