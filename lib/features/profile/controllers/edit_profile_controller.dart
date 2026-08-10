import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';

class EditProfileController extends GetxController {
  final UserModel user;
  
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  
  final ImagePicker _picker = ImagePicker();
  final Rx<File?> selectedImageFile = Rx<File?>(null);

  EditProfileController({required this.user});

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
        'Failed to load image from gallery',
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void submit() {
    if (formKey.currentState!.validate()) {
      final authCtrl = Get.find<AuthController>();
      authCtrl.updateProfile(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        photoUrl: selectedImageFile.value?.path ?? user.photoUrl,
      );
    }
  }
}
