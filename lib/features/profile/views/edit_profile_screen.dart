import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_helper.dart';
import '../controllers/edit_profile_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';

class EditProfileScreen extends StatelessWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF059669);

    return GetBuilder<EditProfileController>(
      init: EditProfileController(user: user),
      builder: (controller) {
        return Scaffold(
          backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18.sp,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Clean Avatar Selector
                GestureDetector(
                  onTap: controller.pickImageFromGallery,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 110.r,
                        height: 110.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF1F5F9),
                        ),
                        child: Obx(() => ClipOval(
                          child: controller.selectedImageFile.value != null
                              ? Image.file(
                                  controller.selectedImageFile.value!,
                                  fit: BoxFit.cover,
                                )
                              : (user.photoUrl != null &&
                                      user.photoUrl!.isNotEmpty)
                                  ? AppImageHelper.buildImage(
                                      user.photoUrl!,
                                      fit: BoxFit.cover,
                                    )
                                  : Icon(
                                      Icons.person_rounded,
                                      size: 55.r,
                                      color: Colors.grey.shade400,
                                    ),
                        )),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3.w),
                          ),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            size: 16.r,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Change Profile Picture',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                
                SizedBox(height: 40.h),

                // Form Fields
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Full Name'),
                    SizedBox(height: 8.h),
                    _buildTextField(
                      controller: controller.nameController,
                      hint: 'Enter your full name',
                      icon: Icons.person_outline_rounded,
                      primaryColor: primaryColor,
                      validatorMsg: 'Please enter your name',
                    ),
                    SizedBox(height: 24.h),

                    _buildLabel('Phone Number'),
                    SizedBox(height: 8.h),
                    _buildTextField(
                      controller: controller.phoneController,
                      hint: 'e.g. 01700112233',
                      icon: Icons.phone_outlined,
                      primaryColor: primaryColor,
                      keyboardType: TextInputType.phone,
                      validatorMsg: 'Please enter phone number',
                    ),
                    SizedBox(height: 24.h),

                    _buildLabel('Email Address'),
                    SizedBox(height: 8.h),
                    _buildTextField(
                      controller: controller.emailController,
                      hint: 'e.g. example@email.com',
                      icon: Icons.email_outlined,
                      primaryColor: primaryColor,
                      keyboardType: TextInputType.emailAddress,
                      validatorMsg: 'Please enter your email',
                    ),
                  ],
                ),
                
                SizedBox(height: 48.h),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: Obx(() {
                    final authCtrl = Get.find<AuthController>();
                    final isLoading = authCtrl.isLoading.value;
                    
                    return ElevatedButton(
                      onPressed: isLoading ? null : controller.submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? SizedBox(
                              height: 24.r,
                              width: 24.r,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Save Changes',
                              style: GoogleFonts.poppins(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color primaryColor,
    required String validatorMsg,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 22.r),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (v) => v == null || v.trim().isEmpty ? validatorMsg : null,
    );
  }
}
