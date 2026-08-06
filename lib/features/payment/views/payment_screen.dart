import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_checker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_constants.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';
import '../controllers/payment_controller.dart';

class PaymentScreen extends StatefulWidget {
  final UserModel user;

  const PaymentScreen({super.key, required this.user});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _senderNumberController = TextEditingController();
  final TextEditingController _trxIdController = TextEditingController();
  late PaymentController _paymentController;

  @override
  void initState() {
    super.initState();
    _paymentController = Get.find<PaymentController>();
  }

  @override
  void dispose() {
    _senderNumberController.dispose();
    _trxIdController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String number) {
    Clipboard.setData(ClipboardData(text: number));
    ApiChecker.showSuccess('Number copied to clipboard: $number', title: 'Copied');
  }

  String _getAdminNumber() {
    final method = _paymentController.selectedMethod.value;
    if (method == 'rocket') {
      return '018685691625';
    }
    return '01868569162';
  }

  @override
  Widget build(BuildContext context) {
    // widget.user.role is correctly set by auth flow before navigation
    final isLandlord = widget.user.isLandlord;
    final int fee = isLandlord
        ? AppConstants.landlordFee
        : AppConstants.bachelorFee;
    final String roleTitle =
        isLandlord ? 'Landlord' : 'Bachelor';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Payment & Verification'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => Get.find<AuthController>().logout(),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log Out',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Amount Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.25),
                      blurRadius: 15.r,
                      offset: Offset(0, 6.h),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Registration Fee ($roleTitle)',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Tk.$fee.00',
                      style: GoogleFonts.poppins(
                        fontSize: 36.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Pay the one-time registration fee',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // Payment Methods Tabs
              Text(
                'Select Payment Method',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),
              Obx(() {
                return Row(
                  children: [
                    _buildMethodTab('bkash', 'bKash', const Color(0xFFE2136E)),
                    SizedBox(width: 10.w),
                    _buildMethodTab('nagad', 'Nagad', const Color(0xFFED1C24)),
                    SizedBox(width: 10.w),
                    _buildMethodTab('rocket', 'Rocket', const Color(0xFF8C3494)),
                  ],
                );
              }),
              SizedBox(height: 20.h),

              // Send Money Number Card
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Send Money to the Personal number below:',
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Obx(() {
                      final adminNum = _getAdminNumber();
                      final methodLabel = _paymentController
                                  .selectedMethod.value ==
                              'rocket'
                          ? 'Rocket Personal'
                          : (_paymentController.selectedMethod.value == 'nagad'
                              ? 'Nagad Personal'
                              : 'bKash Personal');

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  adminNum,
                                  style: GoogleFonts.poppins(
                                    fontSize: 19.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  '($methodLabel)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.sp,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _copyToClipboard(adminNum),
                            icon: Icon(
                              Icons.copy_rounded,
                              size: 24.r,
                              color: AppTheme.primaryColor,
                            ),
                            tooltip: 'Copy number',
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // Step 1: Sender Mobile Number
              Text(
                '1. Sender Mobile Number',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _senderNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'e.g. 01XXXXXXXXX',
                  prefixIcon: Icon(Icons.phone_android_rounded,
                      color: AppTheme.textSecondary, size: 20.r),
                ),
              ),
              SizedBox(height: 16.h),

              // Step 2: Transaction ID (TrxID)
              Text(
                '2. Transaction ID (TrxID)',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _trxIdController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'e.g. 8N7A6D5S',
                  prefixIcon: Icon(Icons.receipt_long_rounded,
                      color: AppTheme.textSecondary, size: 20.r),
                ),
              ),
              SizedBox(height: 32.h),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: Obx(() {
                  return ElevatedButton(
                    onPressed: _paymentController.isLoading.value
                        ? null
                        : () {
                            _paymentController.submitTrxId(
                              trxId: _trxIdController.text,
                              senderNumber: _senderNumberController.text,
                              user: widget.user,
                            );
                          },
                    child: _paymentController.isLoading.value
                        ? SizedBox(
                            height: 20.r,
                            width: 20.r,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Verify Payment (Submit TrxID)'),
                  );
                }),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodTab(String key, String title, Color color) {
    final isSelected = _paymentController.selectedMethod.value == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => _paymentController.selectMethod(key),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2.w : 1.w,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? color : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
