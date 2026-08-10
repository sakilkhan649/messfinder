import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';
import '../views/otp_verification_screen.dart';
import '../../../core/theme/app_theme.dart';

class PhoneLoginController extends GetxController {
  final AuthController authController = Get.find<AuthController>();
  late TextEditingController phoneController;

  @override
  void onInit() {
    super.onInit();
    phoneController = TextEditingController();
  }

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }

  void sendOtp() {
    final phone = phoneController.text.trim();
    if (phone.isNotEmpty) {
      authController.verifyPhoneNumber(phone);
      Get.to(() => OtpVerificationScreen(phone: phone), transition: Transition.rightToLeft);
    } else {
      Get.snackbar(
        'Error',
        'Please enter a valid phone number',
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
      );
    }
  }
}
