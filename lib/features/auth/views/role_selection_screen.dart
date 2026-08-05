import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/app_constants.dart';
import '../controllers/auth_controller.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 20.h,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Glowing App Emblem (Centered anchor with luxury shadow)
                      Container(
                        width: 58.r,
                        height: 58.r,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF064E3B), // Deep Forest Emerald
                              Color(0xFF10B981), // Vibrant Emerald Green
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.35),
                              blurRadius: 20.r,
                              offset: Offset(0, 8.h),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.home_work_rounded,
                          size: 30.r,
                          color: Colors.white,
                        ),
                      ),

                      SizedBox(height: 14.h),

                      // Sleek Emerald Sparkle Pill Badge (Perfectly centered)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF059669,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(30.r),
                          border: Border.all(
                            color: const Color(
                              0xFF059669,
                            ).withValues(alpha: 0.35),
                            width: 1.w,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 14.r,
                              color: const Color(0xFF059669),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'MESSFINDER BANGLADESH',
                              style: GoogleFonts.poppins(
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: const Color(0xFF065F46),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Bold Premium Typography Header (Perfect letter-spacing & line-height)
                      Text(
                        'Choose Your Role',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.8,
                          height: 1.15,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Tap your role below',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5.sp,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      SizedBox(height: 28.h),

                      // COMPACT HERO CARD 1: LANDLORD
                      _CompactRoleCard(
                        title: 'Landlord',
                        roleBadge: 'OWNER',
                        subtitle: 'Room / House Owner',
                        buttonText: 'Continue',
                        mainIcon: Icons.home_work_rounded,
                        watermarkIcon: Icons.apartment_rounded,
                        gradientColors: const [
                          Color(0xFF064E3B), // Deep Forest Emerald
                          Color(0xFF059669), // Vibrant Emerald
                        ],
                        badgeColor: const Color(0xFF10B981),
                        arrowButtonColor: Colors.white,
                        arrowIconColor: const Color(0xFF064E3B),
                        onTap: () {
                          authController.setRole(AppConstants.roleLandlord);
                        },
                      ),

                      SizedBox(height: 16.h),

                      // COMPACT HERO CARD 2: BACHELOR
                      _CompactRoleCard(
                        title: 'Bachelor',
                        roleBadge: 'SEEKER',
                        subtitle: 'Room & Mess Seeker',
                        buttonText: 'Continue',
                        mainIcon: Icons.person_search_rounded,
                        watermarkIcon: Icons.travel_explore_rounded,
                        gradientColors: const [
                          Color(0xFF1E1B4B), // Deep Indigo
                          Color(0xFF312E81), // Royal Sapphire Violet
                        ],
                        badgeColor: const Color(0xFFF59E0B), // Warm Amber Gold
                        arrowButtonColor: const Color(0xFFF59E0B),
                        arrowIconColor: const Color(0xFF1E1B4B),
                        onTap: () {
                          authController.setRole(AppConstants.roleBachelor);
                        },
                      ),

                      SizedBox(height: 32.h),

                      // Sleek Futuristic Admin Portal Button
                      GestureDetector(
                        onTap: () {
                          authController.setRole(AppConstants.roleAdmin);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 18.w,
                            vertical: 9.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30.r),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF0F172A,
                                ).withValues(alpha: 0.04),
                                blurRadius: 10.r,
                                offset: Offset(0, 3.h),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.admin_panel_settings_rounded,
                                size: 16.r,
                                color: const Color(0xFF64748B),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Admin Portal',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 11.r,
                                color: const Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Minimalist Trust Slogan
                      Text(
                        'Safe, Verified & Easy Room Booking',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CompactRoleCard extends StatefulWidget {
  final String title;
  final String roleBadge;
  final String subtitle;
  final String buttonText;
  final IconData mainIcon;
  final IconData watermarkIcon;
  final List<Color> gradientColors;
  final Color badgeColor;
  final Color arrowButtonColor;
  final Color arrowIconColor;
  final VoidCallback onTap;

  const _CompactRoleCard({
    required this.title,
    required this.roleBadge,
    required this.subtitle,
    required this.buttonText,
    required this.mainIcon,
    required this.watermarkIcon,
    required this.gradientColors,
    required this.badgeColor,
    required this.arrowButtonColor,
    required this.arrowIconColor,
    required this.onTap,
  });

  @override
  State<_CompactRoleCard> createState() => _CompactRoleCardState();
}

class _CompactRoleCardState extends State<_CompactRoleCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.965 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22.r),
            boxShadow: [
              BoxShadow(
                color: widget.gradientColors.first.withValues(alpha: 0.28),
                blurRadius: 18.r,
                offset: Offset(0, 8.h),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1.5.w,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22.r),
            child: Stack(
              children: [
                // Artistic Compact Watermark Icon in background
                Positioned(
                  right: -10.w,
                  bottom: -10.h,
                  child: Icon(
                    widget.watermarkIcon,
                    size: 95.r,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),

                // Compact Card Content (Perfectly aligned horizontally & vertically)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 18.w,
                    vertical: 16.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Aligned center vertically
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(12.r),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Icon(
                              widget.mainIcon,
                              size: 26.r,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 21.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                Text(
                                  widget.subtitle,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.sp,
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: widget.badgeColor.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: widget.badgeColor.withValues(alpha: 0.6),
                                width: 1.w,
                              ),
                            ),
                            child: Text(
                              widget.roleBadge,
                              style: GoogleFonts.poppins(
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16.h),

                      // Bottom Action Bar: Vertically centered baseline
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            widget.buttonText,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Container(
                            width: 38.r,
                            height: 38.r,
                            decoration: BoxDecoration(
                              color: widget.arrowButtonColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.20),
                                  blurRadius: 8.r,
                                  offset: Offset(0, 3.h),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 18.r,
                              color: widget.arrowIconColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
