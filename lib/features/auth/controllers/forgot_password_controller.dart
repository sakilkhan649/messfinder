import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';

class ForgotPasswordController extends GetxController {
  final AuthController authController = Get.find<AuthController>();
  late TextEditingController emailController;

  @override
  void onInit() {
    super.onInit();
    emailController = TextEditingController();
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }

  void resetPassword() {
    authController.resetPassword(emailController.text);
  }
}
