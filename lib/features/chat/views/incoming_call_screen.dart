import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mess_finder/core/theme/app_theme.dart';
import 'package:get/get.dart';

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
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showQuickReplySheet() {
    final defaultMessages = [
      "I'll call you right back.",
      "Can't talk right now.",
      "In a meeting.",
      "Call me later?"
    ];

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Reply',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 16.h),
            ...defaultMessages.map((msg) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(msg, style: GoogleFonts.poppins(fontSize: 15.sp)),
                  trailing: const Icon(Icons.send_rounded, color: AppTheme.primaryColor),
                  onTap: () {
                    Get.back();
                    widget.onDecline();
                    // In a real scenario, call chatController.sendMessage(msg) here
                    Get.snackbar('Sent', 'Message sent to ${widget.callerName}');
                  },
                )),
            SizedBox(height: 16.h),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background (Caller Photo blurred or dark gradient)
          if (widget.callerPhoto != null && widget.callerPhoto!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: widget.callerPhoto!,
              fit: BoxFit.cover,
            )
          else
            Container(color: const Color(0xFF091F26)),
            
          // Blur overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
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
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                              color: Colors.white,
                              size: 16.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              widget.isVideo ? 'VIDEO CALL' : 'AUDIO CALL',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12.sp,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
                                border: Border.all(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                  width: 2,
                                ),
                                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                              ),
                            ),
                            // Inner ripple
                            Container(
                              width: (150.r * _pulseAnimation.value),
                              height: (150.r * _pulseAnimation.value),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryColor.withValues(alpha: 0.15),
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
                                    color: AppTheme.primaryColor.withValues(alpha: 0.4),
                                    blurRadius: 24.r,
                                    spreadRadius: 4.r,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 60.r,
                                backgroundColor: const Color(0xFF1E293B),
                                backgroundImage: (widget.callerPhoto != null &&
                                        widget.callerPhoto!.isNotEmpty)
                                    ? CachedNetworkImageProvider(widget.callerPhoto!)
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

                // Quick Message button
                GestureDetector(
                  onTap: _showQuickReplySheet,
                  child: Container(
                    margin: EdgeInsets.only(bottom: 24.h),
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.message_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8.w),
                        Text(
                          'Message',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom section (Swipe Action Buttons)
                Padding(
                  padding: EdgeInsets.only(bottom: 50.h, left: 40.w, right: 40.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Swipe to Decline
                      _SwipeAction(
                        isAccept: false,
                        icon: Icons.call_end_rounded,
                        color: const Color(0xFFEF4444), // Red-500
                        onSwipe: widget.onDecline,
                      ),

                      // Swipe to Accept
                      _SwipeAction(
                        isAccept: true,
                        icon: widget.isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                        color: const Color(0xFF10B981), // Emerald-500
                        onSwipe: widget.onAccept,
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

class _SwipeAction extends StatefulWidget {
  final bool isAccept;
  final IconData icon;
  final Color color;
  final VoidCallback onSwipe;

  const _SwipeAction({
    required this.isAccept,
    required this.icon,
    required this.color,
    required this.onSwipe,
  });

  @override
  State<_SwipeAction> createState() => _SwipeActionState();
}

class _SwipeActionState extends State<_SwipeAction> with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  final double _maxDrag = 80.0;
  late AnimationController _springCtrl;

  @override
  void initState() {
    super.initState();
    _springCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 0,
      upperBound: _maxDrag,
    );
    _springCtrl.addListener(() {
      setState(() {
        _dragOffset = _springCtrl.value;
      });
    });
  }

  @override
  void dispose() {
    _springCtrl.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      // Swipe up (negative delta Y)
      _dragOffset -= details.delta.dy;
      _dragOffset = _dragOffset.clamp(0.0, _maxDrag);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragOffset > _maxDrag * 0.7) {
      widget.onSwipe();
    } else {
      _springCtrl.value = _dragOffset;
      _springCtrl.animateTo(0, curve: Curves.easeOutBack);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Arrow hints
        Opacity(
          opacity: (1 - (_dragOffset / _maxDrag)).clamp(0.0, 1.0),
          child: Column(
            children: [
              Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white54, size: 24.sp),
              Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white30, size: 24.sp),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onVerticalDragUpdate: _onPanUpdate,
          onVerticalDragEnd: _onPanEnd,
          onTap: widget.onSwipe, // Fallback for simple tap
          child: Transform.translate(
            offset: Offset(0, -_dragOffset),
            child: Container(
              width: 72.r,
              height: 72.r,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.5),
                    blurRadius: 16.r,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                color: Colors.white,
                size: 32.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
