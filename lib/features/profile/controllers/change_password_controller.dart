import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/network/api_checker.dart';
import '../../auth/repositories/auth_repo.dart';

class ChangePasswordController extends GetxController {
  final AuthRepository _authRepo = AuthRepository();

  final formKey = GlobalKey<FormState>();

  late final TextEditingController currentPasswordController;
  late final TextEditingController newPasswordController;
  late final TextEditingController confirmPasswordController;

  final RxBool obscureCurrentPassword = true.obs;
  final RxBool obscureNewPassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;

  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    currentPasswordController = TextEditingController();
    newPasswordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  Future<void> changePassword() async {
    final currentPass = currentPasswordController.text;
    final newPass = newPasswordController.text;
    final confirmPass = confirmPasswordController.text;

    if (currentPass.isEmpty) {
      ApiChecker.showError('Please enter your current password');
      return;
    }
    if (newPass.isEmpty) {
      ApiChecker.showError('Please enter a new password');
      return;
    }
    if (newPass.length < 6) {
      ApiChecker.showError('New password must be at least 6 characters long');
      return;
    }
    if (newPass == currentPass) {
      ApiChecker.showError('New password must be different from current password');
      return;
    }
    if (newPass != confirmPass) {
      ApiChecker.showError('New passwords do not match');
      return;
    }

    isLoading.value = true;
    try {
      await _authRepo.changePassword(
        oldPassword: currentPass,
        newPassword: newPass,
      );
      Get.back();
      ApiChecker.showSuccess('Password updated successfully!');
    } catch (e) {
      ApiChecker.checkApi(e);
    } finally {
      isLoading.value = false;
    }
  }
}
