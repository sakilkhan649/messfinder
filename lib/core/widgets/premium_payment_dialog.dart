import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/payment/controllers/payment_controller.dart';
import '../../features/payment/views/payment_pending_screen.dart';
import '../network/api_checker.dart';
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';

class PremiumPaymentDialog {
  static void show(
    BuildContext context, {
    required bool isLandlord,
    Function(String trxId, String senderNumber)? onPaymentSubmitted,
    VoidCallback? onSuccess,
  }) {
    final auth = Get.find<AuthController>();
    final user = auth.currentUser.value;
    if (user == null) {
      ApiChecker.checkApi('Please log in first');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PremiumPaymentSheet(
        user: user,
        isLandlord: isLandlord,
        onPaymentSubmitted: onPaymentSubmitted,
        onSuccess: onSuccess,
      ),
    );
  }
}

class _PremiumPaymentSheet extends StatelessWidget {
  final UserModel user;
  final bool isLandlord;
  final Function(String trxId, String senderNumber)? onPaymentSubmitted;
  final VoidCallback? onSuccess;

  const _PremiumPaymentSheet({
    required this.user,
    required this.isLandlord,
    this.onPaymentSubmitted,
    this.onSuccess,
  });

  String _getAdminNumber(PaymentController paymentController) {
    final method = paymentController.selectedMethod.value;
    if (method == 'rocket') {
      return '018685691625';
    }
    return '01868569162';
  }

  void _copyNumber(String number) {
    Clipboard.setData(ClipboardData(text: number));
    ApiChecker.showSuccess('Copied number: $number', title: 'Copied');
  }

  @override
  Widget build(BuildContext context) {
    final paymentController = Get.find<PaymentController>();
    final int fee =
        isLandlord ? AppConstants.landlordFee : AppConstants.bachelorFee;

    return GetBuilder<PremiumPaymentController>(
      init: PremiumPaymentController(),
      builder: (screenController) {
        return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30.r,
            offset: Offset(0, -10.h),
          ),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 28.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag indicator
              Center(
                child: Container(
                  width: 48.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // Pending Status Card
              Obx(() {
                final lastPayment = paymentController.myLatestPayment.value;
                if (lastPayment != null && lastPayment.isPending) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 16.h),
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.hourglass_top_rounded,
                            color: Color(0xFFB45309)),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            'Your payment verification is currently under review.',
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              color: const Color(0xFFB45309),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Get.back();
                            Get.to(() =>
                                PaymentPendingScreen(user: user));
                          },
                          child: const Text('View Status'),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 15.r,
                      offset: Offset(0, 8.h),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.workspace_premium_rounded,
                            color: Colors.white,
                            size: 28.r,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            isLandlord
                                ? 'Listing Verification'
                                : 'Unlock Contact Info',
                            style: GoogleFonts.poppins(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      isLandlord
                          ? 'Pay per listing to publish your mess room and connect with verified bachelors.'
                          : 'Pay once per booking to unlock the landlord phone number and call directly.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        color: Colors.white.withValues(alpha: 0.95),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                      child: Text(
                        isLandlord
                            ? 'Only Tk.$fee (per listing)'
                            : 'Only Tk.$fee (per booking)',
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              Text(
                'Select Payment Method',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),
              Obx(() {
                final currentMethod = paymentController.selectedMethod.value;
                return Row(
                  children: [
                    _buildMethodTab('bkash', 'bKash', Icons.account_balance_wallet_rounded, currentMethod, paymentController),
                    SizedBox(width: 10.w),
                    _buildMethodTab('nagad', 'Nagad', Icons.payments_rounded, currentMethod, paymentController),
                    SizedBox(width: 10.w),
                    _buildMethodTab('rocket', 'Rocket', Icons.rocket_launch_rounded, currentMethod, paymentController),
                  ],
                );
              }),
              SizedBox(height: 16.h),

              Obx(() {
                final number = _getAdminNumber(paymentController);
                final method = paymentController.selectedMethod.value;
                final methodName = method == 'bkash'
                    ? 'bKash'
                    : method == 'nagad'
                        ? 'Nagad'
                        : 'Rocket';

                return Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$methodName Personal Number (Send Money)',
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              number,
                              style: GoogleFonts.poppins(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _copyNumber(number),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                          foregroundColor: AppTheme.primaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        icon: Icon(Icons.copy_rounded, size: 16.r),
                        label: Text(
                          'Copy',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              SizedBox(height: 24.h),

              Text(
                'Sender Phone Number',
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: screenController.senderController,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.poppins(fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: 'e.g. 017xxxxxxxx',
                  prefixIcon: const Icon(Icons.phone_android_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                ),
              ),
              SizedBox(height: 16.h),

              Text(
                'Transaction ID (TrxID)',
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: screenController.trxIdController,
                style: GoogleFonts.poppins(fontSize: 14.sp),
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'e.g. 9J7K3X1M',
                  prefixIcon: const Icon(Icons.receipt_long_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                ),
              ),
              SizedBox(height: 28.h),

              Obx(() {
                final isLoading = paymentController.isLoading.value;
                return SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            final sender = screenController.senderController.text.trim();
                            final trxId = screenController.trxIdController.text.trim();
                            if (sender.isEmpty || trxId.isEmpty) {
                              ApiChecker.showError(
                                  'Please enter Sender Number and TrxID');
                              return;
                            }
                            Get.back();
                            if (onPaymentSubmitted != null) {
                              onPaymentSubmitted!(trxId, sender);
                            } else {
                              paymentController.submitTrxId(
                                trxId: trxId,
                                senderNumber: sender,
                                user: user,
                              );
                            }
                            if (onSuccess != null) {
                              onSuccess!();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      elevation: 4,
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 24.r,
                            height: 24.r,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Submit Verification 🚀',
                            style: GoogleFonts.poppins(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
    },
    );
  }

  Widget _buildMethodTab(
      String key, String title, IconData icon, String current, PaymentController paymentController) {
    final isSelected = current == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => paymentController.selectMethod(key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
                size: 22.r,
              ),
              SizedBox(height: 4.h),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class PremiumPaymentController extends GetxController {
  final TextEditingController senderController = TextEditingController();
  final TextEditingController trxIdController = TextEditingController();

  @override
  void onClose() {
    senderController.dispose();
    trxIdController.dispose();
    super.onClose();
  }
}
