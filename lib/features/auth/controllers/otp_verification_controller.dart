import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';

class OtpVerificationController extends GetxController {
  final String phone;
  final AuthController authController = Get.find<AuthController>();
  
  late TextEditingController otpController;
  
  Timer? _timer;
  final RxInt start = 60.obs;
  final RxBool canResend = false.obs;

  OtpVerificationController({required this.phone});

  @override
  void onInit() {
    super.onInit();
    otpController = TextEditingController();
    startTimer();
  }

  void startTimer() {
    start.value = 60;
    canResend.value = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (start.value == 0) {
        canResend.value = true;
        timer.cancel();
      } else {
        start.value--;
      }
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    otpController.dispose();
    super.onClose();
  }

  void verifyOtp() {
    final otp = otpController.text.trim();
    authController.verifyOTP(otp, phone);
  }

  void resendOtp() {
    if (canResend.value) {
      startTimer();
      authController.verifyPhoneNumber(phone);
    }
  }
}
