import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/image_helper.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';
import 'utils/admin_colors.dart';

class AdminEditProfileScreen extends StatelessWidget {
  final UserModel user;

  const AdminEditProfileScreen({super.key, required this.user});

  AdminEditProfileController get controller => Get.find<AdminEditProfileController>(tag: 'admin_edit_profile');


  @override
  Widget build(BuildContext context) {
    Get.put(AdminEditProfileController(user), tag: 'admin_edit_profile');
    final authController = Get.find<AuthController>();
    return Scaffold(
      backgroundColor: AdminColors.pageBg,
      appBar: AppBar(
        backgroundColor: AdminColors.accentDark,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20.r,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Personal Information',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AdminColors.accentDark,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Center(
                child: Text(
                  'Update your profile details below. These changes will reflect across the admin panel.',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    color: AdminColors.accentMid,
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              // Avatar Upload
              GestureDetector(
                onTap: controller.pickImageFromGallery,
                child: Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 110.r,
                        height: 110.r,
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AdminColors.accentDark.withValues(
                              alpha: 0.3,
                            ),
                            width: 3.r,
                          ),
                        ),
                        child: ClipOval(
                          child: Obx(() => controller.selectedImageFile.value != null
                              ? Image.file(
                                  controller.selectedImageFile.value!,
                                  fit: BoxFit.cover,
                                  width: 100.r,
                                  height: 100.r,
                                )
                              : (user.photoUrl != null &&
                                    user.photoUrl!.isNotEmpty)
                              ? AppImageHelper.buildImage(
                                  user.photoUrl!,
                                  fit: BoxFit.cover,
                                  width: 100.r,
                                  height: 100.r,
                                )
                              : Container(
                                  color: AdminColors.accentDark.withValues(
                                    alpha: 0.1,
                                  ),
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 50.r,
                                    color: AdminColors.accentDark,
                                  ),
                                )),
                        ),
                      ),
                      Positioned(
                        bottom: 2.h,
                        right: 2.w,
                        child: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: AdminColors.accentDark,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.w),
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
              ),
              SizedBox(height: 8.h),
              Center(
                child: Text(
                  'Tap to change photo',
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.accentDark,
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              // Name Field
              Text(
                'Full Name',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AdminColors.accentDark,
                ),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: controller.nameController,
                style: GoogleFonts.poppins(fontSize: 14.sp),
                decoration: _inputDecoration(
                  'Enter your name',
                  Icons.person_outline_rounded,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.h),

              // Phone Field
              Text(
                'Phone Number',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AdminColors.accentDark,
                ),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: controller.phoneController,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.poppins(fontSize: 14.sp),
                decoration: _inputDecoration(
                  'Enter your phone number',
                  Icons.phone_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),

              SizedBox(height: 40.h),

              // Save Button
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: authController.isLoading.value
                        ? null
                        : controller.submitUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.accentDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 2,
                    ),
                    child: authController.isLoading.value
                        ? SizedBox(
                            height: 24.r,
                            width: 24.r,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Save Changes',
                            style: GoogleFonts.poppins(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        color: AdminColors.accentLight,
        fontSize: 13.sp,
      ),
      prefixIcon: Icon(icon, color: AdminColors.accentMid, size: 22.w),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AdminColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AdminColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AdminColors.accentDark, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: AdminColors.statusRejected),
      ),
    );
  }
}

class AdminEditProfileController extends GetxController {
  final UserModel user;
  
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  
  final ImagePicker _picker = ImagePicker();
  final Rx<File?> selectedImageFile = Rx<File?>(null);

  AdminEditProfileController(this.user);

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController(text: user.name);
    phoneController = TextEditingController(text: user.phone);
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  Future<void> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        selectedImageFile.value = File(pickedFile.path);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not load image from gallery: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void submitUpdate() {
    if (formKey.currentState!.validate()) {
      final authController = Get.find<AuthController>();
      authController.updateProfile(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        photoUrl: selectedImageFile.value?.path ?? user.photoUrl,
      );
    }
  }
}
