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

class AdminEditProfileScreen extends StatefulWidget {
  final UserModel user;

  const AdminEditProfileScreen({super.key, required this.user});

  @override
  State<AdminEditProfileScreen> createState() => _AdminEditProfileScreenState();
}

class _AdminEditProfileScreenState extends State<AdminEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  final ImagePicker _picker = ImagePicker();
  File? _selectedImageFile;

  final authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
        });
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

  void _submitUpdate() {
    if (_formKey.currentState!.validate()) {
      authController.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        photoUrl: _selectedImageFile?.path ?? widget.user.photoUrl,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          key: _formKey,
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
                onTap: _pickImageFromGallery,
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
                          child: _selectedImageFile != null
                              ? Image.file(
                                  _selectedImageFile!,
                                  fit: BoxFit.cover,
                                  width: 100.r,
                                  height: 100.r,
                                )
                              : (widget.user.photoUrl != null &&
                                    widget.user.photoUrl!.isNotEmpty)
                              ? AppImageHelper.buildImage(
                                  widget.user.photoUrl!,
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
                                ),
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
                controller: _nameController,
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
                controller: _phoneController,
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
                        : _submitUpdate,
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
