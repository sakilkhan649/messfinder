import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_helper.dart';
import '../../../core/utils/location_data.dart';
import '../controllers/add_post_controller.dart';
import '../controllers/post_controller.dart';
import '../models/post_model.dart';
import 'map_location_picker_screen.dart';

class AddPostScreen extends StatelessWidget {
  final PostModel? existingPost;
  final bool showBackButton;
  final VoidCallback? onPostAdded;

  const AddPostScreen({
    super.key, 
    this.existingPost,
    this.showBackButton = true,
    this.onPostAdded,
  });

  InputDecoration _buildInputDecoration({
    required String hintText,
    IconData? prefixIcon,
    String? prefixText,
  }) {
    const emeraldTheme = Color(0xFF059669);
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(
        fontSize: 13.sp,
        color: const Color(0xFF94A3B8),
      ),
      prefixText: prefixText,
      prefixStyle: GoogleFonts.poppins(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: emeraldTheme, size: 20.r)
          : null,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(color: emeraldTheme, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(color: AppTheme.errorColor),
      ),
    );
  }

    @override
  Widget build(BuildContext context) {
    final tag = existingPost?.postId ?? 'new';
    final controller = Get.put(
      AddPostController(
        existingPost: existingPost,
        onPostAdded: onPostAdded,
      ),
      tag: tag,
    );
    const emeraldTheme = Color(0xFF059669);
    const darkEmerald = Color(0xFF064E3B);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: darkEmerald,
        elevation: 0,
        title: Text(
          controller.isEditing ? 'Edit Room Listing' : 'Add New Room',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
        automaticallyImplyLeading: false,
        leading: showBackButton 
            ? IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                ),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Clean Info banner
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: emeraldTheme.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: emeraldTheme.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: emeraldTheme.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.verified_user_rounded,
                          color: emeraldTheme,
                          size: 20.r,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          controller.isEditing
                              ? 'Update your room listing details below.'
                              : 'Fill in accurate room details & upload real photos to attract verified bachelors.',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5.sp,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                // Section 1: Basic Information
                _buildSectionHeader(
                  Icons.home_work_rounded,
                  'Basic Information',
                ),
                SizedBox(height: 12.h),

                Text(
                  'Room Title',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: controller.titleController,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  decoration: _buildInputDecoration(
                    hintText: 'e.g. Spacious Single Room in Mirpur 10',
                    prefixIcon: Icons.title_rounded,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter room title' : null,
                ),
                SizedBox(height: 18.h),

                // Rent & Seats Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Rent',
                            style: GoogleFonts.poppins(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          TextFormField(
                            controller: controller.rentController,
                            keyboardType: TextInputType.number,
                            decoration: _buildInputDecoration(
                              hintText: '4500',
                              prefixText: 'Tk. ',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Enter rent'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Seats',
                            style: GoogleFonts.poppins(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          TextFormField(
                            controller: controller.seatDescController,
                            keyboardType: TextInputType.number,
                            decoration: _buildInputDecoration(
                              hintText: 'e.g. 2',
                              prefixIcon: Icons.single_bed_rounded,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Enter seat count'
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                // Section 2: Preferences & Location
                _buildSectionHeader(
                  Icons.people_alt_rounded,
                  'Preferences & Location',
                ),
                SizedBox(height: 12.h),

                Text(
                  'Preferred Tenant Gender',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    _buildGenderRadio('male', 'Male Only', controller),
                    SizedBox(width: 10.w),
                    _buildGenderRadio('female', 'Female Only', controller),
                    SizedBox(width: 10.w),
                    _buildGenderRadio('both', 'Any Bachelor', controller),
                  ],
                ),
                SizedBox(height: 18.h),

                Text(
                  'Preferred Tenant Type',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    _buildTenantRadio('Student', 'Student', controller),
                    SizedBox(width: 8.w),
                    _buildTenantRadio('Job', 'Job', controller),
                    SizedBox(width: 8.w),
                    _buildTenantRadio(
                      'Student / Job holder',
                      'Student / Job holder', controller
                    ),
                  ],
                ),
                SizedBox(height: 18.h),

                Text(
                  'Division',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Obx(() => DropdownButtonFormField<String>(
                      value: controller.selectedDivision.value,
                      decoration: _buildInputDecoration(hintText: 'Select Division', prefixIcon: Icons.map_rounded),
                      items: LocationData.divisions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: GoogleFonts.poppins(fontSize: 14.sp)),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          controller.selectedDivision.value = newValue;
                          controller.selectedDistrict.value = LocationData.getDistricts(newValue).first;
                        }
                      },
                    )),
                SizedBox(height: 18.h),

                Text(
                  'District',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Obx(() => DropdownButtonFormField<String>(
                      value: controller.selectedDistrict.value,
                      decoration: _buildInputDecoration(hintText: 'Select District', prefixIcon: Icons.location_city_rounded),
                      items: LocationData.getDistricts(controller.selectedDivision.value).map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: GoogleFonts.poppins(fontSize: 14.sp)),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          controller.selectedDistrict.value = newValue;
                        }
                      },
                    )),
                SizedBox(height: 18.h),

                Text(
                  'Full Address (Area/Road)',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: controller.addressController,
                  keyboardType: TextInputType.streetAddress,
                  textCapitalization: TextCapitalization.words,
                  maxLines: 2,
                  decoration: _buildInputDecoration(
                    hintText:
                        'e.g. House 12, Road 4, Section 10, Mirpur, Dhaka',
                    prefixIcon: Icons.location_on_rounded,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter address' : null,
                ),
                SizedBox(height: 12.h),
                ElevatedButton.icon(
                  onPressed: () async {
                    final LatLng? picked = await Get.to(() => MapLocationPickerScreen(initialLocation: controller.selectedLocation.value));
                    if (picked != null) {
                      controller.selectedLocation.value = picked;
                      Get.snackbar(
                        'Location Selected',
                        'Map location has been updated successfully.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: const Color(0xFF059669),
                        colorText: Colors.white,
                      );
                    }
                  },
                  icon: Icon(Icons.map_outlined, color: const Color(0xFF059669), size: 20.r),
                  label: Text('Select Location on Map', style: GoogleFonts.poppins(color: const Color(0xFF059669))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFF059669)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                  ),
                ),
                SizedBox(height: 18.h),

                Text(
                  'Contact Phone Number',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: controller.phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _buildInputDecoration(
                    hintText: 'e.g. 01712345678',
                    prefixIcon: Icons.phone_rounded,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Enter phone number'
                      : null,
                ),
                SizedBox(height: 24.h),

                // Section 3: Facilities
                _buildSectionHeader(
                  Icons.check_circle_outline_rounded,
                  'Included Facilities',
                ),
                SizedBox(height: 12.h),

                Obx(() => Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: controller.allFacilities.map((facility) {
                    final isSelected = controller.selectedFacilities.contains(facility);
                    return FilterChip(
                      label: Text(
                        facility,
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: emeraldTheme,
                      backgroundColor: const Color(0xFFF1F5F9),
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                        side: BorderSide(
                          color: isSelected
                              ? emeraldTheme
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          controller.selectedFacilities.add(facility);
                        } else {
                          controller.selectedFacilities.remove(facility);
                        }
                      },
                    );
                  }).toList(),
                )),
                SizedBox(height: 24.h),

                // Section 4: Photo Selection (Gallery Only, No Demo Pictures)
                _buildSectionHeader(
                  Icons.photo_camera_rounded,
                  'Real Room Photos',
                ),
                SizedBox(height: 12.h),

                GestureDetector(
                  onTap: controller.pickImagesFromGallery,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    decoration: BoxDecoration(
                      color: emeraldTheme.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: emeraldTheme.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: emeraldTheme.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_photo_alternate_rounded,
                            color: emeraldTheme,
                            size: 32.r,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          'Tap to Upload Real Room Photos',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: emeraldTheme,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Select genuine photos from gallery (No demo pictures)',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5.sp,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 14.h),

                // Display selected local images or existing images
                Obx(() {
                  if (controller.pickedLocalImages.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Selected Photos (${controller.pickedLocalImages.length})',
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => controller.pickedLocalImages.clear(),
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
                      itemCount: controller.pickedLocalImages.length,
                      itemBuilder: (context, index) {
                        final file = controller.pickedLocalImages[index];
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
                                child: AppImageHelper.buildImage(file.path),
                              ),
                            ),
                            Positioned(
                              top: 6.h,
                              right: 18.w,
                              child: GestureDetector(
                                onTap: () {
                                  controller.pickedLocalImages.removeAt(index);
                                },
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
                    ]);
                  } else if (controller.isEditing && existingPost!.images.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  Text(
                    'Existing Room Photos',
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    height: 105.h,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: existingPost!.images.length,
                      itemBuilder: (context, index) {
                        final img = existingPost!.images[index];
                        return Container(
                          width: 120.w,
                          margin: EdgeInsets.only(right: 12.w),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10.r),
                            child: AppImageHelper.buildImage(img),
                          ),
                        );
                      },
                    ),
                  )]);
                  }
                  return const SizedBox.shrink();
                }),
                SizedBox(height: 32.h),

                // Submit Button
                Obx(() {
                  final postController = Get.find<PostController>();
                  return SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: postController.isLoading.value ? null : controller.submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: emeraldTheme,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: 4,
                      ),
                      child: postController.isLoading.value
                          ? SizedBox(
                              height: 24.h,
                              width: 24.h,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              controller.isEditing
                                  ? 'Update Room Listing'
                                  : 'Publish Room Listing',
                              style: GoogleFonts.poppins(
                                fontSize: 15.5.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  );
                }),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    const emeraldTheme = Color(0xFF059669);
    return Row(
      children: [
        Icon(icon, color: emeraldTheme, size: 20.r),
        SizedBox(width: 8.w),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderRadio(String value, String label, AddPostController controller) {
    const emeraldTheme = Color(0xFF059669);
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.bachelorType.value = value,
        child: Obx(() {
          final selected = controller.bachelorType.value == value;
          return Container(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              color: selected ? emeraldTheme : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: selected ? emeraldTheme : const Color(0xFFE2E8F0),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTenantRadio(String value, String label, AddPostController controller) {
    const emeraldTheme = Color(0xFF059669);
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.preferredTenant.value = value,
        child: Obx(() {
          final selected = controller.preferredTenant.value == value;
          return Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
            decoration: BoxDecoration(
              color: selected ? emeraldTheme : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: selected ? emeraldTheme : const Color(0xFFE2E8F0),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          );
        }),
      ),
    );
  }
}
