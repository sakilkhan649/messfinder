import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_helper.dart';
import '../../../core/utils/location_data.dart';
import '../controllers/add_product_controller.dart';
import '../models/product_model.dart';

class AddProductScreen extends StatelessWidget {
  final ProductModel? product;
  
  const AddProductScreen({super.key, this.product});

  void _showSelectionBottomSheet({
    required BuildContext context,
    required String title,
    required List<String> items,
    required String? selectedValue,
    required Function(String) onItemSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 16.h),
            Divider(color: Colors.grey.shade200, height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = item == selectedValue;
                  return InkWell(
                    onTap: () {
                      onItemSelected(item);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade100),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item,
                            style: GoogleFonts.poppins(
                              fontSize: 16.sp,
                              color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 20.sp),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomDropdownField({
    required String hint,
    required String? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value ?? hint,
                style: GoogleFonts.poppins(
                  color: value == null ? Colors.grey.shade600 : AppTheme.textPrimary,
                  fontSize: 14.sp,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const emeraldTheme = Color(0xFF059669);
    
    return GetBuilder<AddProductController>(
      init: AddProductController()..initForProduct(product),
      builder: (controller) {
        return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        child: Scaffold(
          appBar: AppBar(
            title: Text(controller.isEditMode ? 'Edit Product' : 'Sell an Item', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.close_rounded,color: Colors.white,size: 25.r),
              onPressed: () => Get.back(),
            ),
          ),
          backgroundColor: AppTheme.backgroundColor,
          body: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              top: 20.h,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
            ),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Title', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              SizedBox(height: 8.h),
              TextFormField(
                controller: controller.titleController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'e.g. Study Table, Office Chair...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                validator: (v) => v!.isEmpty ? 'Enter product title' : null,
              ),
              SizedBox(height: 16.h),

              Text('Price (Tk)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              SizedBox(height: 8.h),
              TextFormField(
                controller: controller.priceController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'e.g. 1500',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                validator: (v) => v!.isEmpty ? 'Enter price' : null,
              ),
              SizedBox(height: 16.h),

              Text('Category', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              SizedBox(height: 8.h),
              Obx(() => _buildCustomDropdownField(
                hint: 'Select Category',
                value: controller.selectedCategory.value,
                onTap: () {
                  _showSelectionBottomSheet(
                    context: context,
                    title: 'Select Category',
                    items: controller.marketplaceController.categories.where((c) => c != 'All').toList(),
                    selectedValue: controller.selectedCategory.value,
                    onItemSelected: (v) => controller.selectedCategory.value = v,
                  );
                },
              )),
              SizedBox(height: 16.h),

              Text('Condition', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              SizedBox(height: 8.h),
              Obx(() => _buildCustomDropdownField(
                hint: 'Select Condition',
                value: controller.selectedCondition.value == 'new' ? 'New' : 'Used',
                onTap: () {
                  _showSelectionBottomSheet(
                    context: context,
                    title: 'Select Condition',
                    items: const ['New', 'Used'],
                    selectedValue: controller.selectedCondition.value == 'new' ? 'New' : 'Used',
                    onItemSelected: (v) => controller.selectedCondition.value = v.toLowerCase(),
                  );
                },
              )),
              SizedBox(height: 16.h),

              Text('Division & District', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: Obx(() => _buildCustomDropdownField(
                      hint: 'Division',
                      value: LocationData.divisions.contains(controller.selectedDivision.value) ? controller.selectedDivision.value : null,
                      onTap: () {
                        _showSelectionBottomSheet(
                          context: context,
                          title: 'Select Division',
                          items: LocationData.divisions,
                          selectedValue: controller.selectedDivision.value,
                          onItemSelected: controller.setDivision,
                        );
                      },
                    )),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Obx(() => _buildCustomDropdownField(
                      hint: 'District',
                      value: LocationData.getDistricts(controller.selectedDivision.value).contains(controller.selectedDistrict.value) ? controller.selectedDistrict.value : null,
                      onTap: () {
                        _showSelectionBottomSheet(
                          context: context,
                          title: 'Select District',
                          items: LocationData.getDistricts(controller.selectedDivision.value),
                          selectedValue: controller.selectedDistrict.value,
                          onItemSelected: (v) => controller.selectedDistrict.value = v,
                        );
                      },
                    )),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              Text('Description', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              SizedBox(height: 8.h),
              TextFormField(
                controller: controller.descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe the item...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
              SizedBox(height: 16.h),

              Text('Product Media (Photos & Video)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              SizedBox(height: 8.h),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20.r),
                      ),
                    ),
                    builder: (context) {
                      return SafeArea(
                        child: Container(
                          padding: EdgeInsets.all(20.w),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Select Media Type',
                                style: GoogleFonts.poppins(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 20.h),
                              ListTile(
                                leading: Icon(
                                  Icons.photo_library,
                                  color: emeraldTheme,
                                ),
                                title: Text(
                                  'Upload Photos',
                                  style: GoogleFonts.poppins(),
                                ),
                                onTap: () {
                                  Get.back();
                                  controller.pickImages();
                                },
                              ),
                              ListTile(
                                leading: Icon(
                                  Icons.video_collection,
                                  color: emeraldTheme,
                                ),
                                title: Text(
                                  'Upload Video',
                                  style: GoogleFonts.poppins(),
                                ),
                                onTap: () {
                                  Get.back();
                                  controller.pickVideoFromGallery();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                child: Container(
                  height: 100.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: emeraldTheme.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: emeraldTheme.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, color: emeraldTheme, size: 32.r),
                      Text('Tap to add photos/videos', style: GoogleFonts.poppins(color: emeraldTheme)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Existing Images
              Obx(() {
                if (controller.existingImages.isNotEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Existing Photos (${controller.existingImages.length})',
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => controller.existingImages.clear(),
                            child: Text(
                              'Clear All',
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.errorColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      SizedBox(
                        height: 105.h,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: controller.existingImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  width: 120.w,
                                  margin: EdgeInsets.only(right: 12.w),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: emeraldTheme,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10.r),
                                    child: AppImageHelper.buildImage(
                                      controller.existingImages[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 6.h,
                                  right: 18.w,
                                  child: GestureDetector(
                                    onTap: () => controller.removeExistingImage(index),
                                    child: Container(
                                      padding: EdgeInsets.all(5.r),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.errorColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 14.r,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),

              // Display selected local video or existing video
              Obx(() {
                if (controller.pickedLocalVideo.value.isNotEmpty) {
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.video_file,
                                color: emeraldTheme,
                                size: 24.r,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Video Selected',
                                style: GoogleFonts.poppins(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => controller.pickedLocalVideo.value = '',
                            child: Text(
                              'Remove',
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.errorColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                    ],
                  );
                } else if (controller.isEditMode && controller.existingVideoUrl.value.isNotEmpty) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: emeraldTheme,
                            size: 20.r,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Existing video attached',
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),


              // Local Images
              Obx(() {
                if (controller.localImages.isNotEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Selected Photos (${controller.localImages.length})',
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => controller.localImages.clear(),
                            child: Text(
                              'Clear All',
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.errorColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      SizedBox(
                        height: 105.h,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: controller.localImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  width: 120.w,
                                  margin: EdgeInsets.only(right: 12.w),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: emeraldTheme,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10.r),
                                    child: Image.file(
                                      controller.localImages[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 6.h,
                                  right: 18.w,
                                  child: GestureDetector(
                                    onTap: () => controller.removeLocalImage(index),
                                    child: Container(
                                      padding: EdgeInsets.all(5.r),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.errorColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 14.r,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
              SizedBox(height: 40.h),

              Obx(() => SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: controller.marketplaceController.isLoading.value ? null : controller.submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: emeraldTheme,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: controller.marketplaceController.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(controller.isEditMode ? 'Update Product' : 'Post Product', 
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                ),
              )),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
      ),
      ),
    );
      },
    );
  }
}
