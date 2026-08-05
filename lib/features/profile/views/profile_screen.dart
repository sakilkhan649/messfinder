import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_helper.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';
import '../../auth/views/role_selection_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  final UserModel user;

  const ProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final UserModel activeUser = Get.isRegistered<AuthController>()
          ? (Get.find<AuthController>().currentUser.value ?? user)
          : user;

      final isLandlord = activeUser.isLandlord;
      final Color primaryColor = isLandlord
          ? const Color(0xFF7C3AED) // Royal Purple for Landlord
          : const Color(0xFF0EA5E9); // Vibrant Sky Blue for Bachelor
      final Color accentColor = isLandlord
          ? const Color(0xFF9F67FA)
          : const Color(0xFF059669); // Emerald accent

      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: CustomScrollView(
          slivers: [
            // Ultra-Premium Header
            SliverAppBar(
              expandedHeight: 285.h,
              pinned: true,
              backgroundColor: primaryColor,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  onPressed: () {
                    Get.to(() => EditProfileScreen(user: activeUser));
                  },
                  icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  tooltip: 'প্রোফাইল সম্পাদনা (Edit Profile)',
                ),
                IconButton(
                  onPressed: () => _showLogoutDialog(),
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  tooltip: 'লগআউট',
                ),
                SizedBox(width: 8.w),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor,
                        accentColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(20.r),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 10.h),
                          // Avatar with Glow Border
                          Container(
                            width: 84.r,
                            height: 84.r,
                            padding: EdgeInsets.all(4.r),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.6),
                                width: 3.r,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 15.r,
                                  offset: Offset(0, 6.h),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: (activeUser.photoUrl != null &&
                                      activeUser.photoUrl!.isNotEmpty)
                                  ? AppImageHelper.buildImage(
                                      activeUser.photoUrl!,
                                      fit: BoxFit.cover,
                                      width: 76.r,
                                      height: 76.r,
                                    )
                                  : Container(
                                      color: Colors.white,
                                      child: Icon(
                                        isLandlord
                                            ? Icons.home_work_rounded
                                            : Icons.person_rounded,
                                        size: 40.r,
                                        color: primaryColor,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: 12.h),

                          // Name
                          Text(
                            activeUser.name,
                            style: GoogleFonts.poppins(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),

                          // Phone
                          if (activeUser.phone.isNotEmpty)
                            Text(
                              activeUser.phone,
                              style: GoogleFonts.poppins(
                                fontSize: 13.sp,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          SizedBox(height: 8.h),

                          // Verified Approved Capsule
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 14.w, vertical: 5.h),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8.r,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
                                      size: 16.r,
                                      color: AppTheme.statusApproved,
                                    ),
                                    SizedBox(width: 5.w),
                                    Text(
                                      isLandlord
                                          ? 'বাড়িওয়ালা (Approved ✓)'
                                          : 'ব্যাচেলর (Approved ✓)',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),

                          // Edit Profile Capsule Button
                          GestureDetector(
                            onTap: () {
                              Get.to(() => EditProfileScreen(user: activeUser));
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 14.w, vertical: 5.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit_rounded,
                                      size: 14.r, color: Colors.white),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'প্রোফাইল সম্পাদনা করুন',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Content Below Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.shield_rounded,
                            title: 'ভেরিফায়েড',
                            subtitle: '১০০% বিশ্বস্ত',
                            color: primaryColor,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildStatCard(
                            icon: isLandlord
                                ? Icons.real_estate_agent_rounded
                                : Icons.favorite_rounded,
                            title: isLandlord ? 'মালিকানা' : 'সদস্যপদ',
                            subtitle: 'সক্রিয় অ্যাকাউন্ট',
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    Text(
                      'অ্যাকাউন্ট ও সেটিংস',
                      style: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Menu Items
                    _buildMenuItem(
                      icon: Icons.edit_note_rounded,
                      title: 'প্রোফাইল সম্পাদনা করুন (Edit Profile)',
                      subtitle: 'নাম, মোবাইল নম্বর ও ব্যক্তিগত তথ্য আপডেট করুন',
                      color: primaryColor,
                      onTap: () {
                        Get.to(() => EditProfileScreen(user: activeUser));
                      },
                    ),

                    _buildMenuItem(
                      icon: Icons.payment_rounded,
                      title: 'আমার পেমেন্ট স্ট্যাটাস',
                      subtitle: 'আপনার পেমেন্ট ভেরিফাই হয়েছে (Approved)',
                      color: primaryColor,
                      onTap: () => Get.snackbar(
                        'পেমেন্ট স্ট্যাটাস',
                        'আপনার পেমেন্ট ভেরিফাই ও অনুমোদিত আছে ✓',
                        backgroundColor: AppTheme.statusApproved,
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                      ),
                    ),

                    _buildMenuItem(
                      icon: Icons.swap_horiz_rounded,
                      title: 'রোল পরিবর্তন করুন',
                      subtitle: 'বাড়িওয়ালা বা ব্যাচেলর রোলে পরিবর্তন করুন',
                      color: const Color(0xFFF59E0B),
                      onTap: () {
                        Get.to(() => const RoleSelectionScreen(),
                            transition: Transition.fadeIn);
                      },
                    ),

                    _buildMenuItem(
                      icon: Icons.notifications_active_rounded,
                      title: 'নোটিফিকেশন সেটিংস',
                      subtitle: 'নতুন মেস বা বুকিংয়ের আপডেট নিয়ন্ত্রণ করুন',
                      color: primaryColor,
                      onTap: () => Get.snackbar(
                        'নোটিফিকেশন',
                        'নোটিফিকেশন সবসময় সক্রিয় আছে ✓',
                        backgroundColor: primaryColor,
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                      ),
                    ),

                    _buildMenuItem(
                      icon: Icons.security_rounded,
                      title: 'নিরাপত্তা ও প্রাইভেসি',
                      subtitle: 'পাসওয়ার্ড এবং অ্যাকাউন্টের নিরাপত্তা',
                      color: primaryColor,
                      onTap: () => Get.snackbar(
                        'নিরাপত্তা',
                        'আপনার অ্যাকাউন্ট ফায়ারবেস দ্বারা সুরক্ষিত ✓',
                        backgroundColor: primaryColor,
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                      ),
                    ),

                    _buildMenuItem(
                      icon: Icons.help_outline_rounded,
                      title: 'সাহায্য ও সাপোর্ট',
                      subtitle: 'যেকোনো প্রয়োজনে আমাদের সাথে যোগাযোগ করুন',
                      color: primaryColor,
                      onTap: () => Get.defaultDialog(
                        title: 'হেল্পলাইন সাপোর্ট',
                        middleText:
                            'যেকোনো প্রয়োজনে কল করুন:\n01868569162\nঅথবা ইমেইল করুন:\nsupport@messfinder.com',
                        textConfirm: 'ঠিক আছে',
                        confirmTextColor: Colors.white,
                        buttonColor: primaryColor,
                        onConfirm: () => Get.back(),
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: OutlinedButton.icon(
                        onPressed: () => _showLogoutDialog(),
                        icon: const Icon(Icons.logout_rounded,
                            color: AppTheme.errorColor),
                        label: Text(
                          'অ্যাকাউন্ট থেকে লগআউট করুন',
                          style: GoogleFonts.poppins(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.errorColor,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppTheme.errorColor, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 30.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: color, size: 22.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          leading: Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: color, size: 22.r),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 11.sp,
              color: AppTheme.textSecondary,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16.r,
            color: Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    Get.defaultDialog(
      title: 'লগআউট',
      middleText: 'আপনি কি নিশ্চিতভাবে লগআউট করতে চান?',
      textConfirm: 'হ্যাঁ, লগআউট',
      textCancel: 'না',
      confirmTextColor: Colors.white,
      buttonColor: AppTheme.errorColor,
      onConfirm: () {
        Get.find<AuthController>().logout();
      },
    );
  }
}
