import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mess_finder/core/theme/app_theme.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callerName;
  final String? callerPhoto;
  final bool isVideo;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const IncomingCallScreen({
    super.key,
    required this.callerName,
    this.callerPhoto,
    required this.isVideo,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background (Caller Photo blurred or dark gradient)
          if (widget.callerPhoto != null && widget.callerPhoto!.isNotEmpty)
            Image.network(
              widget.callerPhoto!,
              fit: BoxFit.cover,
            )
          else
            Container(color: const Color(0xFF091F26)),
            
          // Blur overlay to make text readable
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              color: const Color(0xFF06141A).withValues(alpha: 0.85),
            ),
          ),
          
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top section (Title)
                Padding(
                  padding: EdgeInsets.only(top: 40.h),
                  child: Column(
                    children: [
                      Text(
                        widget.isVideo ? 'INCOMING VIDEO CALL' : 'INCOMING AUDIO CALL',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14.sp,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        widget.callerName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Center section (Pulsating Avatar)
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer ripple
                            Container(
                              width: (180.r * _pulseAnimation.value),
                              height: (180.r * _pulseAnimation.value),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              ),
                            ),
                            // Inner ripple
                            Container(
                              width: (150.r * _pulseAnimation.value),
                              height: (150.r * _pulseAnimation.value),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                              ),
                            ),
                            // Avatar border
                            Container(
                              padding: EdgeInsets.all(4.r),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppTheme.primaryGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.5),
                                    blurRadius: 20.r,
                                    spreadRadius: 2.r,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 60.r,
                                backgroundColor: const Color(0xFF1E293B),
                                backgroundImage: (widget.callerPhoto != null &&
                                        widget.callerPhoto!.isNotEmpty)
                                    ? NetworkImage(widget.callerPhoto!)
                                    : null,
                                child: (widget.callerPhoto == null ||
                                        widget.callerPhoto!.isEmpty)
                                    ? Icon(Icons.person_rounded,
                                        size: 60.r, color: Colors.white70)
                                    : null,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                // Bottom section (Action Buttons)
                Padding(
                  padding: EdgeInsets.only(bottom: 60.h, left: 40.w, right: 40.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Decline Button
                      GestureDetector(
                        onTap: widget.onDecline,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72.r,
                              height: 72.r,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFDC2626).withValues(alpha: 0.5),
                                    blurRadius: 16.r,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.call_end_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'Decline',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Accept Button
                      GestureDetector(
                        onTap: widget.onAccept,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72.r,
                              height: 72.r,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.5),
                                    blurRadius: 16.r,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                widget.isVideo
                                    ? Icons.videocam_rounded
                                    : Icons.call_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'Accept',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
