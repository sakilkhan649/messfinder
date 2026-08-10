import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_constants.dart';
import '../controllers/auth_controller.dart';
import '../controllers/login_controller.dart';
import 'forgot_password_screen.dart';
import 'phone_login_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _showAdminLoginDialog(AuthController authController) {
    final adminEmailCtrl = TextEditingController();
    final adminPassCtrl = TextEditingController();
    final obscure = true.obs;
    const adminColor = Color(0xFF0F172A);

    Get.bottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      Container(
        padding: EdgeInsets.only(
          left: 24.w,
          right: 24.w,
          top: 24.h,
          bottom: MediaQuery.of(Get.context!).viewInsets.bottom + 24.h,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30.r,
              offset: Offset(0, -6.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),

            // Icon
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: adminColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.admin_panel_settings_rounded,
                color: adminColor,
                size: 30.r,
              ),
            ),
            SizedBox(height: 12.h),

            Text(
              'Admin Access',
              style: GoogleFonts.poppins(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: adminColor,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Enter admin credentials to continue',
              style: GoogleFonts.poppins(
                fontSize: 12.5.sp,
                color: Colors.grey.shade500,
              ),
            ),
            SizedBox(height: 24.h),

            // Email field
            TextField(
              controller: adminEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Admin Email',
                labelStyle: GoogleFonts.poppins(fontSize: 13.sp),
                prefixIcon: Icon(Icons.email_outlined, size: 20.r),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: adminColor, width: 1.5),
                ),
              ),
            ),
            SizedBox(height: 14.h),

            // Password field
            Obx(() => TextField(
              controller: adminPassCtrl,
              obscureText: obscure.value,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: GoogleFonts.poppins(fontSize: 13.sp),
                prefixIcon: Icon(Icons.lock_outline_rounded, size: 20.r),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscure.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 19.r,
                    color: Colors.grey,
                  ),
                  onPressed: () => obscure.toggle(),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: adminColor, width: 1.5),
                ),
              ),
            )),
            SizedBox(height: 24.h),

            // Login button
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: () {
                  final email = adminEmailCtrl.text.trim();
                  final pass = adminPassCtrl.text.trim();
                  if (email.isEmpty || pass.isEmpty) return;
                  // Set role to admin so AuthController navigates correctly
                  authController.selectedRole.value = AppConstants.roleAdmin;
                  Get.back(); // close dialog
                  authController.login(email, pass);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: adminColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Sign in as Admin',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());
    final authController = controller.authController;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 20.h,
                  ),
                  child: Obx(() {
                    final obscurePassword = authController.obscureLoginPassword.value;
                    final List<Color> gradientColors = const [Color(0xFF064E3B), Color(0xFF10B981)];
                    final Color accentColor = const Color(0xFF059669);
                    final IconData roleIcon = Icons.home_work_rounded;
                    const String badgeText = 'LOGIN';

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 32.h),

                        // Glowing Role Emblem (৩ বার tap = Admin Portal)
                        GestureDetector(
                          onTap: () => controller.handleLogoTap(() => _showAdminLoginDialog(authController)),
                          child: Container(
                            width: 60.r,
                            height: 60.r,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: gradientColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.35),
                                  blurRadius: 20.r,
                                  offset: Offset(0, 8.h),
                                ),
                              ],
                            ),
                            child: Icon(
                              roleIcon,
                              size: 30.r,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        SizedBox(height: 14.h),

                        // Sleek Role Pill Badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 5.h,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(30.r),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.35),
                              width: 1.w,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_user_rounded,
                                size: 13.r,
                                color: accentColor,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'MESSFINDER $badgeText',
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 16.h),

                        // Bold Simple Header
                        Text(
                          'Welcome Back',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.6,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Sign in to continue',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        SizedBox(height: 28.h),

                        // Email Input Field
                        _buildInputField(
                          label: 'Email Address',
                          hintText: 'example@email.com',
                          controller: controller.emailController,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        SizedBox(height: 16.h),

                        // Password Input Field
                        _buildInputField(
                          label: 'Password',
                          hintText: '••••••••',
                          controller: controller.passwordController,
                          icon: Icons.lock_outline_rounded,
                          obscureText: obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 19.r,
                              color: AppTheme.textSecondary,
                            ),
                            onPressed: () {
                              authController.toggleLoginPasswordVisibility();
                            },
                          ),
                        ),

                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Get.to(
                                () => const ForgotPasswordScreen(),
                                transition: Transition.rightToLeft,
                              );
                            },
                            child: Text(
                              'Forgot Password?',
                              style: GoogleFonts.poppins(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 16.h),

                        // Glowing Action Sign In Button
                        GestureDetector(
                          onTap: authController.isLoading.value
                              ? null
                              : () {
                                  controller.login();
                                },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: gradientColors,
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: [
                                BoxShadow(
                                  color: gradientColors.first
                                      .withValues(alpha: 0.28),
                                  blurRadius: 16.r,
                                  offset: Offset(0, 6.h),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (authController.isLoading.value)
                                  SizedBox(
                                    height: 18.r,
                                    width: 18.r,
                                    child: const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                else ...[
                                  Text(
                                    'Sign In',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.5.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18.r,
                                    color: Colors.white,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 16.h),
                        
                        // Continue with Phone Button
                        GestureDetector(
                          onTap: () {
                            Get.to(() => const PhoneLoginScreen(), transition: Transition.rightToLeft);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.phone_android_rounded, color: accentColor, size: 18.r),
                                SizedBox(width: 8.w),
                                Text(
                                  'Continue with Phone',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.5.sp,
                                    fontWeight: FontWeight.w600,
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // Create Account Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'New user? ',
                              style: GoogleFonts.poppins(
                                fontSize: 13.sp,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                authController
                                    .obscureSignupPassword.value = true;
                                Get.to(
                                  () => const SignupScreen(),
                                  transition: Transition.rightToLeft,
                                );
                              },
                              child: Text(
                                'Create Account',
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: accentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20.r),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
