import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/network/api_checker.dart';
import '../../../core/utils/api_constants.dart';
import '../../../core/utils/app_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';
import '../models/payment_model.dart';
import '../repositories/payment_repo.dart';
import '../views/payment_pending_screen.dart';

class PaymentController extends GetxController {
  final PaymentRepository _paymentRepo = PaymentRepository();

  final RxBool isLoading = false.obs;
  final RxString selectedMethod = 'bkash'.obs;
  final Rx<PaymentModel?> myLatestPayment = Rx<PaymentModel?>(null);

  final senderNumberController = TextEditingController();
  final trxIdController = TextEditingController();

  @override
  void onClose() {
    senderNumberController.dispose();
    trxIdController.dispose();
    super.onClose();
  }

  void selectMethod(String method) {
    selectedMethod.value = method;
    AppLogger.i('Selected payment method: $method', tag: 'PAYMENT_CONTROLLER');
  }

  Future<void> submitTrxId({
    required String trxId,
    required String senderNumber,
    required UserModel user,
  }) async {
    if (trxId.trim().isEmpty || senderNumber.trim().isEmpty) {
      ApiChecker.checkApi('Please enter both Transaction ID (TrxID) and Sender Mobile Number.');
      return;
    }
    if (trxId.trim().length < 6) {
      ApiChecker.checkApi('Please enter a valid Transaction ID (at least 6 characters).');
      return;
    }

    isLoading.value = true;
    AppLogger.i(
        'Submitting TrxID -> TrxID: $trxId | Sender: $senderNumber',
        tag: 'PAYMENT_CONTROLLER');

    try {
      final docId = 'PAY_${DateTime.now().millisecondsSinceEpoch}';
      final isLandlordUser = user.isLandlord ||
          Get.find<AuthController>().selectedRole.value ==
              AppConstants.roleLandlord;
      final newPayment = PaymentModel(
        paymentId: docId,
        userUid: user.uid,
        userName: user.name,
        userPhone: user.phone,
        role: isLandlordUser
            ? AppConstants.roleLandlord
            : AppConstants.roleBachelor,
        amount: isLandlordUser
            ? AppConstants.landlordFee
            : AppConstants.bachelorFee,
        trxId: trxId.trim(),
        senderNumber: senderNumber.trim(),
        paymentMethod: selectedMethod.value,
        status: 'pending',
        date: DateTime.now(),
      );

      await _paymentRepo.submitPayment(newPayment);
      myLatestPayment.value = newPayment;

      try {
        await FirebaseFirestore.instance
            .collection(ApiConstants.usersCollection)
            .doc(user.uid)
            .set({
          'trxId': trxId.trim(),
          if (user.phone.isEmpty && senderNumber.trim().isNotEmpty)
            'phone': senderNumber.trim(),
        }, SetOptions(merge: true));
      } catch (_) {}

      AppLogger.s('TrxID submitted successfully, awaiting admin verification',
          tag: 'PAYMENT_CONTROLLER');
      ApiChecker.showSuccess(
        'Your Transaction ID has been sent to our admin team! Once verified, your account will be activated.',
        title: 'Verification Pending ⏳',
      );

      // Navigate to PaymentPendingScreen for professional admin verification flow
      Get.off(() => PaymentPendingScreen(user: user));
    } catch (e, stack) {
      AppLogger.e(
          'Failed to submit TrxID: $e', e, stack, 'PAYMENT_CONTROLLER');
      ApiChecker.checkApi(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkMyStatus(UserModel user,
      {bool showPendingMessage = false}) async {
    isLoading.value = true;
    AppLogger.i('Checking payment status for user: ${user.uid}',
        tag: 'PAYMENT_CONTROLLER');
    try {
      final payment = await _paymentRepo.getMyPaymentStatus(user.uid);
      myLatestPayment.value = payment;
      if (payment != null && payment.isApproved) {
        AppLogger.s('User payment status is Approved!', tag: 'PAYMENT_CONTROLLER');
        if (Get.isRegistered<AuthController>()) {
          final approvedUser = user.copyWith(isPaid: true);
          Get.find<AuthController>().currentUser.value = approvedUser;
          ApiChecker.showSuccess(
            'Congratulations! 🎉 Your payment has been approved by admin! All features are now unlocked.',
            title: 'Account Activated',
          );
          Get.find<AuthController>().handleNavigation(approvedUser);
        }
      } else if (payment != null && payment.isRejected) {
        AppLogger.w('User payment status is Rejected!', tag: 'PAYMENT_CONTROLLER');
        ApiChecker.checkApi(
            'The Transaction ID was rejected. Please verify and submit a valid TrxID.');
      } else if (payment != null && payment.isPending) {
        AppLogger.i('User payment status is still Pending', tag: 'PAYMENT_CONTROLLER');
        if (showPendingMessage) {
          Get.snackbar(
            'Pending Verification',
            'Your payment is currently being verified. Please check back shortly.',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } catch (e, stack) {
      AppLogger.e('Failed to check payment status: $e', e, stack,
          'PAYMENT_CONTROLLER');
      ApiChecker.checkApi(e);
    } finally {
      isLoading.value = false;
    }
  }
}
