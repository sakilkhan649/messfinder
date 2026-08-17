import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/network/api_checker.dart';
import '../repositories/auth_repo.dart';
import '../views/login_screen.dart';

class ForgotPasswordController extends GetxController {
  final AuthRepository _authRepo = AuthRepository();

  final RxInt currentStep = 0.obs; // 0: Email, 1: OTP, 2: New Password
  final RxBool isLoading = false.obs;

  late TextEditingController emailController;
  late TextEditingController otpController;
  late TextEditingController newPasswordController;
  late TextEditingController confirmPasswordController;

  final RxBool obscureNewPassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;

  // Resend OTP Countdown
  final RxInt countdownSeconds = 60.obs;
  final RxBool canResend = false.obs;
  Timer? _countdownTimer;

  @override
  void onInit() {
    super.onInit();
    emailController = TextEditingController();
    otpController = TextEditingController();
    newPasswordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    emailController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    countdownSeconds.value = 60;
    canResend.value = false;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdownSeconds.value > 0) {
        countdownSeconds.value--;
      } else {
        canResend.value = true;
        timer.cancel();
      }
    });
  }

  // Step 1: Send OTP to Email
  Future<void> sendOtp() async {
    final email = emailController.text.trim();
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      ApiChecker.showError('Please enter a valid email address');
      return;
    }

    isLoading.value = true;
    try {
      await _authRepo.sendResetOtp(email);
      ApiChecker.showSuccess('OTP code sent to $email');
      currentStep.value = 1;
      _startCountdown();
    } catch (e) {
      ApiChecker.checkApi(e);
    } finally {
      isLoading.value = false;
    }
  }

  // Resend OTP
  Future<void> resendOtp() async {
    if (!canResend.value || isLoading.value) return;

    final email = emailController.text.trim();
    isLoading.value = true;
    try {
      await _authRepo.sendResetOtp(email);
      ApiChecker.showSuccess('A new OTP has been sent to your email');
      _startCountdown();
    } catch (e) {
      ApiChecker.checkApi(e);
    } finally {
      isLoading.value = false;
    }
  }

  // Step 2: Verify OTP
  Future<void> verifyOtp() async {
    final email = emailController.text.trim();
    final otp = otpController.text.trim();

    if (otp.isEmpty || otp.length < 6) {
      ApiChecker.showError('Please enter the 6-digit OTP');
      return;
    }

    isLoading.value = true;
    try {
      await _authRepo.verifyResetOtp(email: email, otp: otp);
      ApiChecker.showSuccess('OTP verified successfully!');
      currentStep.value = 2;
    } catch (e) {
      ApiChecker.checkApi(e);
    } finally {
      isLoading.value = false;
    }
  }

  // Step 3: Reset Password
  Future<void> submitNewPassword() async {
    final email = emailController.text.trim();
    final otp = otpController.text.trim();
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (newPassword.isEmpty) {
      ApiChecker.showError('Please enter a new password');
      return;
    }
    if (newPassword.length < 6) {
      ApiChecker.showError('Password must be at least 6 characters long');
      return;
    }
    if (newPassword != confirmPassword) {
      ApiChecker.showError('Passwords do not match');
      return;
    }

    isLoading.value = true;
    try {
      await _authRepo.resetPasswordWithOtp(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      ApiChecker.showSuccess('Password reset successfully! Please log in.');
      Get.offAll(() => const LoginScreen(), transition: Transition.fadeIn);
    } catch (e) {
      ApiChecker.checkApi(e);
    } finally {
      isLoading.value = false;
    }
  }
}
