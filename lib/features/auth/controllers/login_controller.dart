import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';

class LoginController extends GetxController {
  final AuthController authController = Get.find<AuthController>();
  
  late TextEditingController emailController;
  late TextEditingController passwordController;
  
  int tapCount = 0;
  DateTime lastTapTime = DateTime.now();

  @override
  void onInit() {
    super.onInit();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void handleLogoTap(VoidCallback showAdminLoginDialog) {
    final now = DateTime.now();
    if (now.difference(lastTapTime).inMilliseconds > 1000) {
      tapCount = 0;
    }
    lastTapTime = now;
    tapCount++;

    if (tapCount >= 3) {
      tapCount = 0;
      showAdminLoginDialog();
    }
  }

  void login() {
    authController.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );
  }
}
