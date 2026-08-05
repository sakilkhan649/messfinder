import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_constants.dart';
import '../controllers/auth_controller.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

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
                    final role = authController.selectedRole.value;
                    final isLandlord = role == AppConstants.roleLandlord;
                    final isAdmin = role == AppConstants.roleAdmin;
                    final obscurePassword =
                        authController.obscureLoginPassword.value;

                    // Role Theme Styling
                    final List<Color> gradientColors = isLandlord
                        ? const [Color(0xFF064E3B), Color(0xFF10B981)]
                        : (isAdmin
                            ? const [Color(0xFF0F172A), Color(0xFF334155)]
                            : const [Color(0xFF1E1B4B), Color(0xFF312E81)]);

                    final Color accentColor = isLandlord
                        ? const Color(0xFF059669)
                        : (isAdmin
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFFF59E0B));

                    final IconData roleIcon = isLandlord
                        ? Icons.home_work_rounded
                        : (isAdmin
                            ? Icons.admin_panel_settings_rounded
                            : Icons.person_search_rounded);

                    final String badgeText = isLandlord
                        ? 'OWNER LOGIN'
                        : (isAdmin ? 'ADMIN LOGIN' : 'SEEKER LOGIN');

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Top Navigation / Back Row
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Get.back(),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                    color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 14.r,
                                    color: const Color(0xFF475569),
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'Back',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 16.h),

                        // Glowing Role Emblem
                        Container(
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

                        // Email Input Field (Styled exactly like ForgotPasswordScreen)
                        _buildInputField(
                          label: 'Email Address',
                          hintText: 'example@email.com',
                          controller: emailController,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        SizedBox(height: 16.h),

                        // Password Input Field (Styled exactly like ForgotPasswordScreen with GetX)
                        _buildInputField(
                          label: 'Password',
                          hintText: '••••••••',
                          controller: passwordController,
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
                                  authController.login(
                                    emailController.text.trim(),
                                    passwordController.text.trim(),
                                  );
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

                        SizedBox(height: 24.h),

                        // Create Account Link (Hidden for Admin)
                        if (!isAdmin)
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

  // Exactly matching ForgotPasswordScreen's TextField design
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
