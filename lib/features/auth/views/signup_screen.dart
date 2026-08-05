import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_constants.dart';
import '../controllers/auth_controller.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
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
                    final obscurePassword =
                        authController.obscureSignupPassword.value;

                    // Role Theme Styling
                    final List<Color> gradientColors = isLandlord
                        ? const [Color(0xFF064E3B), Color(0xFF10B981)]
                        : const [Color(0xFF1E1B4B), Color(0xFF312E81)];

                    final Color accentColor = isLandlord
                        ? const Color(0xFF059669)
                        : const Color(0xFFF59E0B);

                    final IconData roleIcon = isLandlord
                        ? Icons.home_work_rounded
                        : Icons.person_search_rounded;

                    final String badgeText =
                        isLandlord ? 'OWNER SIGNUP' : 'SEEKER SIGNUP';

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Top Back Button Row
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

                        SizedBox(height: 12.h),

                        // Glowing Role Emblem
                        Container(
                          width: 56.r,
                          height: 56.r,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradientColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18.r),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.35),
                                blurRadius: 18.r,
                                offset: Offset(0, 6.h),
                              ),
                            ],
                          ),
                          child: Icon(
                            roleIcon,
                            size: 28.r,
                            color: Colors.white,
                          ),
                        ),

                        SizedBox(height: 12.h),

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
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 14.h),

                        // Bold Simple Header
                        Text(
                          'Create Account',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 25.sp,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.6,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          'Join MessFinder today',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // Full Name Field (Styled exactly like ForgotPasswordScreen)
                        _buildInputField(
                          label: 'Full Name',
                          hintText: 'e.g. John Doe',
                          controller: nameController,
                          icon: Icons.person_outline_rounded,
                        ),

                        SizedBox(height: 16.h),

                        // Phone Number Field (Styled exactly like ForgotPasswordScreen)
                        _buildInputField(
                          label: 'Phone Number',
                          hintText: '01XXXXXXXXX',
                          controller: phoneController,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),

                        SizedBox(height: 16.h),

                        // Email Field (Styled exactly like ForgotPasswordScreen)
                        _buildInputField(
                          label: 'Email Address',
                          hintText: 'example@email.com',
                          controller: emailController,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        SizedBox(height: 16.h),

                        // Password Field (Styled exactly like ForgotPasswordScreen with GetX)
                        _buildInputField(
                          label: 'Create Password',
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
                              authController.toggleSignupPasswordVisibility();
                            },
                          ),
                        ),

                        SizedBox(height: 26.h),

                        // Glowing Create Account Button
                        GestureDetector(
                          onTap: authController.isLoading.value
                              ? null
                              : () {
                                  authController.signUp(
                                    name: nameController.text.trim(),
                                    phone: phoneController.text.trim(),
                                    email: emailController.text.trim(),
                                    password: passwordController.text.trim(),
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
                                    'Create Account',
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

                        SizedBox(height: 20.h),

                        // Back to Sign In Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: GoogleFonts.poppins(
                                fontSize: 13.sp,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Get.back(),
                              child: Text(
                                'Sign In',
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
