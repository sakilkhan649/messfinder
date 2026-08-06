import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_constants.dart';
import '../../../core/utils/image_helper.dart';
import '../controllers/post_controller.dart';
import '../models/post_model.dart';

class AddPostScreen extends StatefulWidget {
  final PostModel? existingPost;
  const AddPostScreen({super.key, this.existingPost});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _rentController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _seatDescController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _pickedLocalImages = [];

  String _bachelorType = 'male'; // 'male', 'female', 'both'
  String _preferredTenant = 'Student / Job holder'; // 'Student', 'Job', 'Student / Job holder'
  final List<String> _selectedFacilities = ['WiFi', '24/7 Water'];

  final List<String> _allFacilities = AppConstants.availableFacilities;

  @override
  void initState() {
    super.initState();
    if (widget.existingPost != null) {
      final p = widget.existingPost!;
      _titleController.text = p.title;
      _rentController.text = p.rent.toInt().toString();
      _addressController.text = p.address;
      _seatDescController.text = p.seatDescription ?? p.seatCount.toString();
      _phoneController.text = p.ownerPhone ?? '';
      _bachelorType = p.bachelorType;
      _preferredTenant = p.preferredTenant;
      _selectedFacilities.clear();
      _selectedFacilities.addAll(p.facilities);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _rentController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _seatDescController.dispose();
    super.dispose();
  }

  bool get isEditing => widget.existingPost != null;

  int _parseSeatCount(String desc) {
    if (desc.isEmpty) return 1;
    final RegExp regExp = RegExp(r'\d+');
    final matches = regExp.allMatches(desc);
    if (matches.isNotEmpty) {
      return int.tryParse(matches.last.group(0)!) ?? 1;
    }
    return 1;
  }

  Future<void> _pickImagesFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
      );
      if (images.isNotEmpty) {
        setState(() {
          _pickedLocalImages.addAll(images);
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick images from gallery.',
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (!isEditing && _pickedLocalImages.isEmpty) {
        Get.snackbar(
          'Photo Required',
          'Please select at least 1 real photo of your room from gallery.',
          backgroundColor: AppTheme.errorColor,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      _publishPostData();
    }
  }

  void _publishPostData({String? trxId, String? senderNumber}) {
    final postCtrl = Get.find<PostController>();
    final List<String> imagesToUse = _pickedLocalImages.isNotEmpty
        ? _pickedLocalImages.map((e) => e.path).toList()
        : (widget.existingPost?.images ?? []);

    final parsedSeats = _parseSeatCount(_seatDescController.text);

    if (isEditing) {
      final updatedPost = widget.existingPost!.copyWith(
        title: _titleController.text.trim(),
        rent: double.tryParse(_rentController.text.trim()) ?? 4500,
        address: _addressController.text.trim(),
        seatCount: parsedSeats,
        seatDescription: _seatDescController.text.trim(),
        ownerPhone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : widget.existingPost!.ownerPhone,
        bachelorType: _bachelorType,
        preferredTenant: _preferredTenant,
        facilities: _selectedFacilities,
        images: imagesToUse,
      );
      Get.back();
      postCtrl.updateMessPost(updatedPost);
    } else {
      Get.back();
      postCtrl.addMessPost(
        title: _titleController.text.trim(),
        rent: double.tryParse(_rentController.text.trim()) ?? 4500,
        address: _addressController.text.trim(),
        seatCount: parsedSeats,
        seatDescription: _seatDescController.text.trim(),
        ownerPhone: _phoneController.text.trim(),
        bachelorType: _bachelorType,
        preferredTenant: _preferredTenant,
        facilities: _selectedFacilities,
        images: imagesToUse,
        senderNumber: senderNumber,
        trxId: trxId,
      );
    }
  }

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
          ? Icon(
              prefixIcon,
              color: emeraldTheme,
              size: 20.r,
            )
          : null,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 16.h,
      ),
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
    const emeraldTheme = Color(0xFF059669);
    const darkEmerald = Color(0xFF064E3B);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: darkEmerald,
        elevation: 0,
        title: Text(
          isEditing ? 'Edit Room Listing' : 'Add New Room',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Form(
            key: _formKey,
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
                        child: Icon(Icons.verified_user_rounded,
                            color: emeraldTheme, size: 20.r),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          isEditing
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
                    Icons.home_work_rounded, 'Basic Information'),
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
                  controller: _titleController,
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
                            controller: _rentController,
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
                            controller: _seatDescController,
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
                _buildSectionHeader(Icons.people_alt_rounded, 'Preferences & Location'),
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
                    _buildGenderRadio('male', 'Male Only'),
                    SizedBox(width: 10.w),
                    _buildGenderRadio('female', 'Female Only'),
                    SizedBox(width: 10.w),
                    _buildGenderRadio('both', 'Any Bachelor'),
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
                    _buildTenantRadio('Student', 'Student'),
                    SizedBox(width: 8.w),
                    _buildTenantRadio('Job', 'Job'),
                    SizedBox(width: 8.w),
                    _buildTenantRadio(
                        'Student / Job holder', 'Student / Job holder'),
                  ],
                ),
                SizedBox(height: 18.h),

                Text(
                  'Full Address',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  controller: _addressController,
                  keyboardType: TextInputType.streetAddress,
                  textCapitalization: TextCapitalization.words,
                  maxLines: 2,
                  decoration: _buildInputDecoration(
                    hintText: 'e.g. House 12, Road 4, Section 10, Mirpur, Dhaka',
                    prefixIcon: Icons.location_on_rounded,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter address' : null,
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
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _buildInputDecoration(
                    hintText: 'e.g. 01712345678',
                    prefixIcon: Icons.phone_rounded,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter phone number' : null,
                ),
                SizedBox(height: 24.h),

                // Section 3: Facilities
                _buildSectionHeader(Icons.check_circle_outline_rounded,
                    'Included Facilities'),
                SizedBox(height: 12.h),

                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: _allFacilities.map((facility) {
                    final isSelected = _selectedFacilities.contains(facility);
                    return FilterChip(
                      label: Text(
                        facility,
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color:
                              isSelected ? Colors.white : AppTheme.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
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
                        setState(() {
                          if (selected) {
                            _selectedFacilities.add(facility);
                          } else {
                            _selectedFacilities.remove(facility);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 24.h),

                // Section 4: Photo Selection (Gallery Only, No Demo Pictures)
                _buildSectionHeader(
                    Icons.photo_camera_rounded, 'Real Room Photos'),
                SizedBox(height: 12.h),

                GestureDetector(
                  onTap: _pickImagesFromGallery,
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
                if (_pickedLocalImages.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Selected Photos (${_pickedLocalImages.length})',
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _pickedLocalImages.clear()),
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
                      itemCount: _pickedLocalImages.length,
                      itemBuilder: (context, index) {
                        final file = _pickedLocalImages[index];
                        return Stack(
                          children: [
                            Container(
                              width: 120.w,
                              margin: EdgeInsets.only(right: 12.w),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                    color: emeraldTheme, width: 1.5),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10.r),
                                child:
                                    AppImageHelper.buildImage(file.path),
                              ),
                            ),
                            Positioned(
                              top: 6.h,
                              right: 18.w,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _pickedLocalImages.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.all(5.r),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.errorColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.close_rounded,
                                      size: 14.r, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ] else if (isEditing &&
                    widget.existingPost!.images.isNotEmpty) ...[
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
                      itemCount: widget.existingPost!.images.length,
                      itemBuilder: (context, index) {
                        final img = widget.existingPost!.images[index];
                        return Container(
                          width: 120.w,
                          margin: EdgeInsets.only(right: 12.w),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                                color: const Color(0xFFE2E8F0), width: 1.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10.r),
                            child: AppImageHelper.buildImage(img),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                SizedBox(height: 32.h),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: emeraldTheme,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      isEditing
                          ? 'Update Room Listing'
                          : 'Publish Room Listing (Tk.${AppConstants.landlordFee})',
                      style: GoogleFonts.poppins(
                        fontSize: 15.5.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
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

  Widget _buildGenderRadio(String value, String label) {
    const emeraldTheme = Color(0xFF059669);
    final selected = _bachelorType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _bachelorType = value),
        child: Container(
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
        ),
      ),
    );
  }

  Widget _buildTenantRadio(String value, String label) {
    const emeraldTheme = Color(0xFF059669);
    final selected = _preferredTenant == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _preferredTenant = value),
        child: Container(
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
        ),
      ),
    );
  }
}
