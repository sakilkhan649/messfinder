import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mess_finder/core/theme/app_theme.dart';
import 'package:mess_finder/features/chat/controllers/call_controller.dart';
import 'package:mess_finder/features/chat/controllers/call_ui_controller.dart';

class CallScreen extends StatelessWidget {
  const CallScreen({super.key});

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor().toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  @override
  Widget build(BuildContext context) {
    final callCtrl = CallController.to;
    final uiCtrl = Get.put(CallUIController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (uiCtrl.pipPosition.value == null) {
        final size = MediaQuery.of(context).size;
        uiCtrl.pipPosition.value = Offset(size.width - 110.w, 80.h);
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          callCtrl.endCall();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: GestureDetector(
          onTap: uiCtrl.toggleControls,
          behavior: HitTestBehavior.opaque,
          child: Obx(() {
            final isVideo = callCtrl.isVideoCall.value;
            final isConnected = callCtrl.callState.value == CallState.connected;
            final remoteUid = callCtrl.remoteUid.value;

            return SafeArea(
              top: false,
              bottom: false,
              child: Stack(
                children: [
                  // ── 1. Background (Remote Video, Local Video, or Audio) ──
                  if (isVideo && callCtrl.engine != null && callCtrl.isEngineReady.value)
                    if (isConnected && remoteUid != 0)
                      if (callCtrl.isRemoteVideoDisabled.value)
                        Positioned.fill(
                          child: _buildCallerInfoOverlay(callCtrl, isConnected, true),
                        )
                      else
                        Positioned.fill(
                          child: AgoraVideoView(
                            controller: VideoViewController.remote(
                              rtcEngine: callCtrl.engine!,
                              canvas: VideoCanvas(
                                uid: remoteUid,
                                renderMode: RenderModeType.renderModeHidden, // Fills screen
                              ),
                              connection: RtcConnection(channelId: callCtrl.currentChannel),
                            ),
                          ),
                        )
                    else
                      Positioned.fill(
                        child: Container(
                          color: Colors.black, // fallback
                          child: AgoraVideoView(
                            controller: VideoViewController(
                              rtcEngine: callCtrl.engine!,
                              canvas: const VideoCanvas(
                                uid: 0,
                                renderMode: RenderModeType.renderModeHidden, // Fills screen
                              ),
                            ),
                          ),
                        ),
                      )
                  else
                    _buildAudioBackground(callCtrl, isConnected),

                  // ── 2. Caller Info Overlay (For Audio, or Ringing Video) ──
                  if (!isConnected || !isVideo)
                    Positioned.fill(
                      child: _buildCallerInfoOverlay(callCtrl, isConnected, isVideo),
                    ),

                  // ── 3. Top Minimal Bar ─────────────────────────────────
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    top: uiCtrl.showControls.value ? 50.h : -100.h,
                    left: 20.w,
                    right: isVideo ? 120.w : 20.w,
                    child: _buildTopBar(callCtrl),
                  ),

                  // ── 4. Local Camera PiP (Video Calls only, Connected) ──
                  if (isVideo && isConnected && callCtrl.engine != null && callCtrl.isEngineReady.value && !callCtrl.isVideoDisabled.value && uiCtrl.pipPosition.value != null)
                    Positioned(
                      left: uiCtrl.pipPosition.value!.dx,
                      top: uiCtrl.pipPosition.value!.dy,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          uiCtrl.updatePipPosition(details.delta);
                        },
                        child: _buildPipCamera(callCtrl),
                      ),
                    ),

                  // ── 5. Bottom Controls Bar ────────────────────────────
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    bottom: uiCtrl.showControls.value ? 40.h : -120.h,
                    left: 20.w,
                    right: 20.w,
                    child: _buildControls(callCtrl),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Clean Lightweight Audio Background ─────────────────────────────────
  Widget _buildAudioBackground(CallController callCtrl, bool isConnected) {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F172A), // Slate 900
              Color(0xFF1E293B), // Slate 800
              Color(0xFF0F172A), // Slate 900
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }

  // ── Caller Info Overlay (Avatar & Name) ────────────────────────────────
  Widget _buildCallerInfoOverlay(CallController callCtrl, bool isConnected, bool isVideo) {
    final statusText = isConnected
        ? _formatDuration(callCtrl.callDuration.value)
        : callCtrl.callStatusText.value;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Avatar with subtle double ring
        Container(
          width: 150.r,
          height: 150.r,
          padding: EdgeInsets.all(4.r),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isVideo ? Colors.white.withValues(alpha: 0.3) : AppTheme.primaryColor.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: isVideo ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
              )
            ] : null,
          ),
          child: ClipOval(
            child: callCtrl.peerUserPhoto != null && callCtrl.peerUserPhoto!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: callCtrl.peerUserPhoto!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: SizedBox(
                        width: 24.r,
                        height: 24.r,
                        child: const CircularProgressIndicator(color: Colors.white70, strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.person_rounded,
                      size: 68.r,
                      color: Colors.white70,
                    ),
                  )
                : Icon(Icons.person_rounded, size: 68.r, color: Colors.white70),
          ),
        ),
        SizedBox(height: 24.h),

        // Caller Name
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            callCtrl.peerUserName,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24.sp,
              shadows: isVideo ? [
                Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 10)
              ] : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(height: 8.h),

        // Status Badge
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: isVideo ? Colors.black.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7.r,
                height: 7.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected
                      ? const Color(0xFF10B981)
                      : (callCtrl.callStatusText.value == 'User is Offline'
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFF59E0B)),
                ),
              ),
              SizedBox(width: 7.w),
              Text(
                statusText,
                style: GoogleFonts.poppins(
                  color: isConnected ? const Color(0xFF34D399) : Colors.white70,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Top Minimal Bar ───────────────────────────────────────────────────
  Widget _buildTopBar(CallController callCtrl) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => callCtrl.endCall(),
          child: Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 16),
          ),
        ),
        SizedBox(width: 12.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                callCtrl.isVideoCall.value
                    ? Icons.videocam_rounded
                    : Icons.phone_rounded,
                color: const Color(0xFF34D399),
                size: 14.sp,
              ),
              SizedBox(width: 6.w),
              Text(
                callCtrl.isVideoCall.value ? 'Video Call' : 'Audio Call',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Network indicator
        Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.signal_cellular_4_bar_rounded, color: Colors.green, size: 16),
        ),
      ],
    );
  }

  // ── PiP Camera Card (Video Calls) ──────────────────────────────────────
  Widget _buildPipCamera(CallController callCtrl) {
    return Container(
      width: 95.w,
      height: 135.h,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppTheme.primaryColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10.r,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Stack(
          children: [
            Positioned.fill(
              child: AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: callCtrl.engine!,
                  canvas: const VideoCanvas(
                    uid: 0,
                    renderMode: RenderModeType.renderModeHidden, // Fills PiP card
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 4.h,
              right: 4.w,
              child: GestureDetector(
                onTap: callCtrl.switchCamera,
                child: Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.flip_camera_ios_rounded,
                      color: Colors.white, size: 14.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Clean Bottom Controls Dock ─────────────────────────────────────────
  Widget _buildControls(CallController callCtrl) {
    final isVideo = callCtrl.isVideoCall.value;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. Mute
          _buildActionButton(
            icon: callCtrl.isMuted.value
                ? Icons.mic_off_rounded
                : Icons.mic_rounded,
            label: callCtrl.isMuted.value ? 'Unmute' : 'Mute',
            isActive: callCtrl.isMuted.value,
            activeColor: const Color(0xFFEF4444),
            onTap: callCtrl.toggleMute,
          ),

          // 2. Speaker (Audio) or Camera On/Off (Video)
          if (isVideo)
            _buildActionButton(
              icon: callCtrl.isVideoDisabled.value
                  ? Icons.videocam_off_rounded
                  : Icons.videocam_rounded,
              label: callCtrl.isVideoDisabled.value ? 'Cam Off' : 'Cam On',
              isActive: !callCtrl.isVideoDisabled.value,
              activeColor: AppTheme.primaryColor,
              onTap: callCtrl.toggleVideo,
            )
          else
            _buildActionButton(
              icon: callCtrl.isSpeakerOn.value
                  ? Icons.volume_up_rounded
                  : Icons.volume_down_rounded,
              label: 'Speaker',
              isActive: callCtrl.isSpeakerOn.value,
              activeColor: AppTheme.primaryColor,
              onTap: callCtrl.toggleSpeaker,
            ),

          // 3. Switch to Audio/Video
          if (isVideo)
            _buildActionButton(
              icon: Icons.phone_rounded,
              label: 'Audio Only',
              isActive: false,
              onTap: () {
                callCtrl.isVideoCall.value = false;
                callCtrl.toggleVideo(); // Disables video when switching to audio
              },
            )
          else
            _buildActionButton(
              icon: Icons.videocam_rounded,
              label: 'Video',
              isActive: false,
              onTap: () {
                callCtrl.isVideoCall.value = true;
                callCtrl.toggleVideo(); // Enables video
              },
            ),

          // 4. End Call Button
          GestureDetector(
            onTap: () => callCtrl.endCall(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52.r,
                  height: 52.r,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x55EF4444),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.call_end_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  'End',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isActive,
    Color? activeColor,
    required VoidCallback onTap,
  }) {
    final bg = isActive
        ? (activeColor ?? AppTheme.primaryColor)
        : Colors.white.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48.r,
            height: 48.r,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22.sp),
          ),
          SizedBox(height: 5.h),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
