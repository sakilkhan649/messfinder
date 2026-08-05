import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_helper.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  final ImagePicker _picker = ImagePicker();
  File? _selectedImageFile;

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
        'ত্রুটি',
        'গ্যালারি থেকে ছবি লোড করা সম্ভব হয়নি: $e',
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final authCtrl = Get.find<AuthController>();
      authCtrl.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        photoUrl: _selectedImageFile?.path ?? widget.user.photoUrl,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandlord = widget.user.isLandlord;
    final Color primaryColor = isLandlord
        ? const Color(0xFF7C3AED) // Royal Purple for Landlord
        : const Color(0xFF0EA5E9); // Vibrant Sky Blue for Bachelor

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'প্রোফাইল সম্পাদনা করুন',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.r),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: 10.h),
                // Avatar with Edit badge (Tappable for Gallery)
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
                              color: primaryColor.withValues(alpha: 0.3),
                              width: 3.r,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 15.r,
                                offset: Offset(0, 6.h),
                              ),
                            ],
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
                                        color: primaryColor.withValues(
                                            alpha: 0.1),
                                        child: Icon(
                                          isLandlord
                                              ? Icons.home_work_rounded
                                              : Icons.person_rounded,
                                          size: 50.r,
                                          color: primaryColor,
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
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2.w),
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
                Text(
                  'গ্যালারি থেকে ছবি দিতে ক্লিক করুন',
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: 12.h),

                // Role badge
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    isLandlord
                        ? 'বাড়িওয়ালা (Approved ✓)'
                        : 'ব্যাচেলর (Approved ✓)',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // Edit Card
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'আপনার নাম *',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'আপনার পুরো নাম লিখুন',
                          prefixIcon: Icon(Icons.person_outline_rounded,
                              color: primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'নাম লিখুন'
                            : null,
                      ),
                      SizedBox(height: 18.h),

                      Text(
                        'মোবাইল নম্বর *',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'যেমন: 01700112233',
                          prefixIcon:
                              Icon(Icons.phone_outlined, color: primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'মোবাইল নম্বর লিখুন'
                            : null,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'এই নম্বরে ব্যাচেলর বা বাড়িওয়ালা আপনার সাথে যোগাযোগ করতে পারবে',
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: Obx(() {
                    final authCtrl = Get.find<AuthController>();
                    if (authCtrl.isLoading.value) {
                      return ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      );
                    }
                    return ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        'পরিবর্তন সংরক্ষণ করুন',
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
