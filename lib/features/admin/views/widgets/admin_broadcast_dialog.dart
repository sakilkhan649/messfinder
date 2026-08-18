import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/admin_controller.dart';
import '../utils/admin_colors.dart';

class AdminBroadcastDialog extends StatefulWidget {
  const AdminBroadcastDialog({super.key});

  static void show(BuildContext context) {
    Get.dialog(
      const AdminBroadcastDialog(),
      barrierDismissible: true,
    );
  }

  @override
  State<AdminBroadcastDialog> createState() => _AdminBroadcastDialogState();
}

class _AdminBroadcastDialogState extends State<AdminBroadcastDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = 'all';

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminController = Get.find<AdminController>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(22.r),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: AdminColors.accentDark.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.campaign_rounded,
                      color: AdminColors.accentDark,
                      size: 22.r,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Broadcast Announcement',
                          style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: AdminColors.accentDark,
                          ),
                        ),
                        Text(
                          'Send in-app notification to users',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5.sp,
                            color: AdminColors.accentLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.h),

              // ── Target Audience ──
              Text(
                'Target Audience',
                style: GoogleFonts.poppins(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: AdminColors.accentDark,
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  _buildAudienceChip('all', 'All Users', Icons.groups_rounded),
                  SizedBox(width: 8.w),
                  _buildAudienceChip('landlord', 'Landlords', Icons.real_estate_agent_rounded),
                  SizedBox(width: 8.w),
                  _buildAudienceChip('bachelor', 'Bachelors', Icons.person_rounded),
                ],
              ),
              SizedBox(height: 16.h),

              // ── Title Field ──
              Text(
                'Announcement Title',
                style: GoogleFonts.poppins(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: AdminColors.accentDark,
                ),
              ),
              SizedBox(height: 6.h),
              TextFormField(
                controller: _titleController,
                style: GoogleFonts.poppins(fontSize: 13.5.sp),
                decoration: InputDecoration(
                  hintText: 'e.g. New Feature Released! 🎉',
                  hintStyle: GoogleFonts.poppins(color: AdminColors.accentLight, fontSize: 12.5.sp),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
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
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
              ),
              SizedBox(height: 14.h),

              // ── Message Body Field ──
              Text(
                'Message Content',
                style: GoogleFonts.poppins(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: AdminColors.accentDark,
                ),
              ),
              SizedBox(height: 6.h),
              TextFormField(
                controller: _bodyController,
                maxLines: 4,
                style: GoogleFonts.poppins(fontSize: 13.sp),
                decoration: InputDecoration(
                  hintText: 'Write your announcement message here...',
                  hintStyle: GoogleFonts.poppins(color: AdminColors.accentLight, fontSize: 12.5.sp),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
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
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Message is required' : null,
              ),
              SizedBox(height: 22.h),

              // ── Action Buttons ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        side: BorderSide(color: AdminColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w600,
                          color: AdminColors.accentMid,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Obx(
                      () => ElevatedButton(
                        onPressed: adminController.isLoading.value
                            ? null
                            : () => _handleSend(adminController),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.accentDark,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          elevation: 0,
                        ),
                        child: adminController.isLoading.value
                            ? SizedBox(
                                height: 18.r,
                                width: 18.r,
                                child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Send Now',
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSend(AdminController adminController) async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final role = _selectedRole;

    final navigator = Navigator.of(context, rootNavigator: true);
    final success = await adminController.sendBroadcastAnnouncement(
      title: title,
      body: body,
      targetRole: role,
    );
    if (success && mounted) {
      navigator.pop();
    }
  }

  Widget _buildAudienceChip(String roleKey, String label, IconData icon) {
    final isSelected = _selectedRole == roleKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = roleKey),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected ? AdminColors.accentDark : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isSelected ? AdminColors.accentDark : AdminColors.border,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14.r,
                color: isSelected ? Colors.white : AdminColors.accentMid,
              ),
              SizedBox(height: 2.h),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10.5.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AdminColors.accentMid,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
