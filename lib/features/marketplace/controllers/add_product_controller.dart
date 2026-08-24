import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/location_data.dart';
import '../models/product_model.dart';
import 'marketplace_controller.dart';

class AddProductController extends GetxController {
  final MarketplaceController marketplaceController = Get.find<MarketplaceController>();

  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();

  final selectedCategory = 'Others'.obs;
  final selectedCondition = 'used'.obs;
  final selectedDivision = 'Dhaka'.obs;
  final selectedDistrict = 'Dhaka'.obs;

  final existingImages = <String>[].obs;
  final localImages = <File>[].obs;

  final existingVideoUrl = ''.obs;
  final pickedLocalVideo = ''.obs;

  ProductModel? editProduct;
  bool get isEditMode => editProduct != null;
  bool isInitialized = false;

  void initForProduct(ProductModel? product) {
    if (isInitialized) return;
    isInitialized = true;
    
    editProduct = product;
    if (isEditMode) {
      titleController.text = product!.title;
      descriptionController.text = product.description;
      priceController.text = product.price.toStringAsFixed(0);
      selectedCategory.value = product.category;
      selectedCondition.value = product.condition;
      selectedDivision.value = product.division;
      selectedDistrict.value = product.district;
      existingImages.assignAll(product.images);
      if (product.videoUrl != null && product.videoUrl!.isNotEmpty) {
        existingVideoUrl.value = product.videoUrl!;
      }
    } else {
      if (LocationData.divisions.isNotEmpty) {
        selectedDivision.value = LocationData.divisions.first;
        final districts = LocationData.getDistricts(selectedDivision.value);
        if (districts.isNotEmpty) selectedDistrict.value = districts.first;
      }
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    super.onClose();
  }

  Future<void> pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> media = await picker.pickMultipleMedia(imageQuality: 80);
    if (media.isNotEmpty) {
      localImages.addAll(media.map((e) => File(e.path)));
    }
  }

  void removeExistingImage(int index) {
    existingImages.removeAt(index);
  }

  void removeLocalImage(int index) {
    localImages.removeAt(index);
  }

  Future<void> pickVideoFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      pickedLocalVideo.value = video.path;
    }
  }

  void removeLocalVideo() {
    pickedLocalVideo.value = '';
  }

  void removeExistingVideo() {
    existingVideoUrl.value = '';
  }

  void setDivision(String div) {
    selectedDivision.value = div;
    final districts = LocationData.getDistricts(div);
    if (districts.isNotEmpty) {
      selectedDistrict.value = districts.first;
    }
  }

  String convertBanglaToEnglish(String input) {
    const bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    String result = input;
    for (int i = 0; i < bangla.length; i++) {
      result = result.replaceAll(bangla[i], english[i]);
    }
    return result;
  }

  Future<void> submit() async {
    if (formKey.currentState!.validate()) {
      if (!isEditMode && localImages.isEmpty) {
        Get.snackbar('Error', 'Please select at least one image',
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      String priceText = priceController.text.replaceAll(',', '');
      priceText = convertBanglaToEnglish(priceText);
      double price = double.tryParse(priceText) ?? 0.0;

      bool success = false;
      if (isEditMode) {
        success = await marketplaceController.updateProduct(
          productId: editProduct!.productId!,
          title: titleController.text,
          description: descriptionController.text,
          price: price,
          condition: selectedCondition.value,
          category: selectedCategory.value,
          existingImages: existingImages,
          newLocalImages: localImages,
          newVideoPath: pickedLocalVideo.value.isNotEmpty ? pickedLocalVideo.value : existingVideoUrl.value,
          division: selectedDivision.value,
          district: selectedDistrict.value,
          status: editProduct!.status,
        );
      } else {
        success = await marketplaceController.addProduct(
          title: titleController.text,
          description: descriptionController.text,
          price: price,
          condition: selectedCondition.value,
          category: selectedCategory.value,
          localImages: localImages,
          videoPath: pickedLocalVideo.value.isNotEmpty ? pickedLocalVideo.value : null,
          division: selectedDivision.value,
          district: selectedDistrict.value,
        );
      }

      if (success) {
        Get.back();
        Get.snackbar(
          'Success', 
          isEditMode ? 'Product updated successfully' : 'Product added successfully',
          backgroundColor: const Color(0xFF059669), 
          colorText: Colors.white
        );
      }
    }
  }
}
