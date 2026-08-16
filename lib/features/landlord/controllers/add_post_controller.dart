import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/utils/app_constants.dart';
import '../models/post_model.dart';
import 'post_controller.dart';

class AddPostController extends GetxController {
  final PostModel? existingPost;
  final VoidCallback? onPostAdded;

  AddPostController({this.existingPost, this.onPostAdded});

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController rentController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController seatDescController = TextEditingController();

  final RxString selectedDivision = 'Dhaka'.obs;
  final RxString selectedDistrict = 'Dhaka'.obs;

  final ImagePicker _picker = ImagePicker();
  final RxList<XFile> pickedLocalImages = <XFile>[].obs;
  final RxString pickedLocalVideo = ''.obs;

  final RxString bachelorType = 'male'.obs;
  final RxString preferredTenant = 'Student / Job holder'.obs;
  final RxList<String> selectedFacilities = ['WiFi', '24/7 Water'].obs;
  final List<String> allFacilities = AppConstants.availableFacilities;

  final Rx<LatLng> selectedLocation = const LatLng(23.8103, 90.4125).obs;

  bool get isEditing => existingPost != null;

  @override
  void onInit() {
    super.onInit();
    if (existingPost != null) {
      final p = existingPost!;
      titleController.text = p.title;
      rentController.text = p.rent.toInt().toString();
      addressController.text = p.address;
      seatDescController.text = p.seatDescription ?? p.seatCount.toString();
      phoneController.text = p.ownerPhone ?? '';
      bachelorType.value = p.bachelorType;
      preferredTenant.value = p.preferredTenant;
      selectedDivision.value = p.division;
      selectedDistrict.value = p.district;
      selectedFacilities.clear();
      selectedFacilities.addAll(p.facilities);
      selectedLocation.value = LatLng(p.latitude, p.longitude);
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    rentController.dispose();
    addressController.dispose();
    phoneController.dispose();
    seatDescController.dispose();
    super.onClose();
  }

  void clearForm() {
    titleController.clear();
    rentController.clear();
    addressController.clear();
    seatDescController.clear();
    phoneController.clear();
    pickedLocalImages.clear();
    pickedLocalVideo.value = '';
    selectedFacilities.clear();
    selectedFacilities.addAll(['WiFi', '24/7 Water']);
    selectedDivision.value = 'Dhaka';
    selectedDistrict.value = 'Dhaka';
  }

  int _parseSeatCount(String desc) {
    if (desc.isEmpty) return 1;
    // ignore: deprecated_member_use
    final regExp = RegExp(r'\d+');
    final matches = regExp.allMatches(desc);
    if (matches.isNotEmpty) {
      return int.tryParse(matches.last.group(0)!) ?? 1;
    }
    return 1;
  }

  Future<void> pickImagesFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 80);
      if (images.isNotEmpty) {
        pickedLocalImages.addAll(images);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick images from gallery.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> pickVideoFromGallery() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        pickedLocalVideo.value = video.path;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick video from gallery.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void submit() {
    if (formKey.currentState!.validate()) {
      if (!isEditing && pickedLocalImages.isEmpty) {
        Get.snackbar(
          'Photo Required',
          'Please select at least 1 real photo of your room from gallery.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      publishPostData();
    } else {
      Get.snackbar(
        'Incomplete Information',
        'Please fill all required fields properly.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> publishPostData({String? trxId, String? senderNumber}) async {
    final postCtrl = Get.isRegistered<PostController>()
        ? Get.find<PostController>()
        : Get.put(PostController());
    final List<String> imagesToUse = pickedLocalImages.isNotEmpty
        ? pickedLocalImages.map((e) => e.path).toList()
        : (existingPost?.images ?? []);

    final parsedSeats = _parseSeatCount(seatDescController.text);

    if (isEditing) {
      final updatedPost = existingPost!.copyWith(
        title: titleController.text.trim(),
        rent: double.tryParse(rentController.text.trim()) ?? 4500,
        address: addressController.text.trim(),
        seatCount: parsedSeats,
        seatDescription: seatDescController.text.trim(),
        division: selectedDivision.value,
        district: selectedDistrict.value,
        bachelorType: bachelorType.value,
        ownerPhone: phoneController.text.trim().isNotEmpty
            ? phoneController.text.trim()
            : existingPost!.ownerPhone,
        preferredTenant: preferredTenant.value,
        facilities: selectedFacilities,
        images: imagesToUse,
        latitude: selectedLocation.value.latitude,
        longitude: selectedLocation.value.longitude,
      );
      final success = await postCtrl.updateMessPost(updatedPost, newVideoPath: pickedLocalVideo.value);
      if (success) {
        Get.back();
        // Delay slightly so the snackbar doesn't get dismissed by any lingering transitions
        Future.delayed(const Duration(milliseconds: 300), () {
          Get.snackbar(
            'Success!',
            'Room listing updated successfully! 🎉',
            backgroundColor: const Color(0xFF059669), // AppTheme.statusApproved
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          );
        });
      }
    } else {
      final success = await postCtrl.addMessPost(
        title: titleController.text.trim(),
        rent: double.tryParse(rentController.text.trim()) ?? 4500,
        address: addressController.text.trim(),
        seatCount: parsedSeats,
        seatDescription: seatDescController.text.trim(),
        division: selectedDivision.value,
        district: selectedDistrict.value,
        ownerPhone: phoneController.text.trim(),
        bachelorType: bachelorType.value,
        preferredTenant: preferredTenant.value,
        facilities: selectedFacilities,
        images: imagesToUse,
        latitude: selectedLocation.value.latitude,
        longitude: selectedLocation.value.longitude,
        senderNumber: senderNumber,
        trxId: trxId,
        videoPath: pickedLocalVideo.value,
      );
      if (success) {
        if (onPostAdded != null) {
          clearForm();
          onPostAdded!();
        } else {
          Get.back();
        }
        Future.delayed(const Duration(milliseconds: 300), () {
          Get.snackbar(
            'Success!',
            'Room listing published successfully! 🎉',
            backgroundColor: const Color(0xFF059669),
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          );
        });
      }
    }
  }
}
