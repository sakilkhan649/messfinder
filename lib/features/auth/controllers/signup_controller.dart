import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';

class SignupController extends GetxController {
  final AuthController authController = Get.find<AuthController>();
  
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController passwordController;

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController();
    phoneController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void signUp() {
    authController.signUp(
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );
  }
}
