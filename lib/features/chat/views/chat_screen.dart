import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:mess_finder/core/theme/app_theme.dart';
import 'package:mess_finder/features/chat/controllers/chat_controller.dart';
import 'package:mess_finder/features/chat/models/message_model.dart';
import 'package:mess_finder/features/chat/controllers/call_controller.dart';
import 'package:mess_finder/features/chat/views/widgets/video_player_widget.dart';
import 'package:mess_finder/features/chat/views/widgets/media_preview_screen.dart';
import 'package:mess_finder/features/profile/views/public_profile_screen.dart';

class ChatScreen extends StatelessWidget {
  final String chatRoomId;
  final String targetUserId;
  final String targetUserName;
  final String? targetUserPhoto;
  final String? initialMessage;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.targetUserId,
    required this.targetUserName,
    this.targetUserPhoto,
    this.initialMessage,
  });

  String get _sanitizedUserPhoto {
    String photoUrl = targetUserPhoto ?? '';
    if (photoUrl.startsWith('http://') && !photoUrl.contains('localhost') && !photoUrl.contains('10.0.2.2')) {
      return photoUrl.replaceFirst('http://', 'https://');
    }
    return photoUrl;
  }

  ChatScreenController get _screenController =>
      Get.find<ChatScreenController>(tag: chatRoomId);
  ChatController get _chatController => Get.find<ChatController>();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatScreenController>(
      tag: chatRoomId,
      init: ChatScreenController(chatRoomId, initialMessage: initialMessage),
      builder: (_) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
      // ── Clean Emerald AppBar matching App Branding ──────────────────
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        elevation: 0,
        surfaceTintColor: const Color(0xFF059669),
        leading: IconButton(
         icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () {
            Get.to(() => PublicProfileScreen(userId: targetUserId));
          },
          child: Row(
            children: [
              // Avatar with Online Badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 19.r,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: _sanitizedUserPhoto.isNotEmpty
                        ? CachedNetworkImageProvider(_sanitizedUserPhoto)
                        : null,
                    child: _sanitizedUserPhoto.isEmpty
                        ? const Icon(Icons.person,
                            size: 20, color: Colors.white)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10.r,
                      height: 10.r,
                      decoration: BoxDecoration(
                        color: const Color(0xFF34D399),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      targetUserName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.5.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          'Active now',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w500,
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
        actions: [
          IconButton(
            icon: Icon(Icons.phone_rounded, color: Colors.white, size:24.sp),
            tooltip: 'Audio Call',
            onPressed: () {
              CallController.to.makeCall(
                targetUserId: targetUserId,
                targetUserName: targetUserName,
                targetUserPhoto: _sanitizedUserPhoto,
                isVideo: false,
              );
            },
          ),
          SizedBox(width: 30.w),
          IconButton(
            icon: Icon(Icons.videocam_rounded, color: Colors.white, size:24.sp),
            tooltip: 'Video Call',
            onPressed: () {
              CallController.to.makeCall(
                targetUserId: targetUserId,
                targetUserName: targetUserName,
                targetUserPhoto: _sanitizedUserPhoto,
                isVideo: true,
              );
            },
          ),
          SizedBox(width: 8.w),
        ],
      ),

      // ── Chat Body (Flush layout without double SafeArea) ───────────
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (_chatController.isLoadingMessages.value) {
                return const Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.primaryColor),
                );
              }

              final messages = _chatController.currentMessages;

              if (messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(20.r),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                        ),
                        child: Text('👋', style: TextStyle(fontSize: 36.sp)),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Say hi to $targetUserName!',
                        style: GoogleFonts.poppins(
                          color: AppTheme.textPrimary,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Send a message or wave to start the conversation.',
                        style: GoogleFonts.poppins(
                          color: AppTheme.textSecondary,
                          fontSize: 12.5.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: _chatController.messageScrollController,
                reverse: true,
                physics: const BouncingScrollPhysics(),
                padding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                itemCount: messages.length + 2,
                itemBuilder: (context, index) {
                  if (index == messages.length + 1) {
                    return Obx(() {
                      if (_chatController.isFetchingMoreMessages.value) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF059669)),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    });
                  }

                  if (index == messages.length) {
                    return _buildTopProfileHeader(context);
                  }

                  final message = messages[index];
                  final isMe =
                      message.senderId == _chatController.currentUserId;

                  return _buildMessageBubble(context, message, isMe);
                },
              );
            }),
          ),

          // ── Clean Bottom Input Bar ──────────────────────────────────
          _buildBottomInputBar(context),
        ],
      ),
    );
      },
    );
  }

  // ── Messenger-Style Top Profile Header (Under AppBar at top of chat) ───
  Widget _buildTopProfileHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Large Avatar
          GestureDetector(
            onTap: () {
              Get.to(() => PublicProfileScreen(userId: targetUserId));
            },
            child: CircleAvatar(
              radius: 36.r,
              backgroundColor: const Color(0xFFE2E8F0),
              backgroundImage: _sanitizedUserPhoto.isNotEmpty
                      ? CachedNetworkImageProvider(_sanitizedUserPhoto)
                      : null,
              child: _sanitizedUserPhoto.isEmpty
                  ? Icon(Icons.person, size: 38.r, color: const Color(0xFF94A3B8))
                  : null,
            ),
          ),
          SizedBox(height: 10.h),

          // Name
          Text(
            targetUserName,
            style: GoogleFonts.poppins(
              fontSize: 17.5.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),

          // Subtitle
          Text(
            'MessFinder Member',
            style: GoogleFonts.poppins(
              fontSize: 12.5.sp,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 10.h),

          // View Profile Button
          OutlinedButton(
            onPressed: () {
              Get.to(() => PublicProfileScreen(userId: targetUserId));
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF059669),
              side: const BorderSide(color: Color(0xFF059669), width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 6.h),
            ),
            child: Text(
              'View Profile',
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          const Divider(color: Color(0xFFE2E8F0), height: 1),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  // ── Clean Proportional Message Bubble ──────────────────────────────
  Widget _buildMessageBubble(
      BuildContext context, MessageModel message, bool isMe) {
    final hasReactions =
        message.reactions != null && message.reactions!.isNotEmpty;
    final isEmojiOnly = _isEmojiOnly(message.text) &&
        message.imageUrl == null &&
        message.videoUrl == null &&
        !message.isDeleted;

    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.72;

    return Padding(
      padding: EdgeInsets.only(bottom: hasReactions ? 14.h : 6.h),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Receiver Avatar (Left side)
          if (!isMe) ...[
            CircleAvatar(
              radius: 14.r,
              backgroundColor: const Color(0xFFE2E8F0),
              backgroundImage: _sanitizedUserPhoto.isNotEmpty
                  ? CachedNetworkImageProvider(_sanitizedUserPhoto)
                  : null,
              child: _sanitizedUserPhoto.isEmpty
                  ? const Icon(Icons.person, size: 16, color: Color(0xFF94A3B8))
                  : null,
            ),
            SizedBox(width: 8.w),
          ],

          // Message Content
          GestureDetector(
            onLongPressStart: (details) {
              _showMessageOptions(context, message, details.globalPosition);
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Emoji-only Message (Clean & Floating)
                if (isEmojiOnly)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                    child: Text(
                      message.text,
                      style: TextStyle(fontSize: 34.sp),
                    ),
                  )
                // 2. Image Attachment
                else if (message.imageUrl != null)
                  GestureDetector(
                    onTap: () {
                      Get.to(() => MediaPreviewScreen(
                        mediaUrl: message.imageUrl!,
                        isVideo: false,
                      ));
                    },
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 230.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8.r,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CachedNetworkImage(
                              imageUrl: message.imageUrl!,
                              width: 230.w,
                              memCacheWidth: 600,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 160.h,
                                color: const Color(0xFFE2E8F0),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primaryColor,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, err) => Container(
                                height: 140.h,
                                color: const Color(0xFFE2E8F0),
                                child: const Icon(Icons.broken_image,
                                    color: Colors.grey),
                              ),
                            ),
                            // Timestamp Overlay on Image
                            Container(
                              margin: EdgeInsets.all(8.r),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                _formatTime(
                                    message.createdAt ?? DateTime.now()),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                // 3. Video Attachment
                else if (message.videoUrl != null)
                  GestureDetector(
                    onTap: () {
                      Get.to(() => MediaPreviewScreen(
                        mediaUrl: message.videoUrl!,
                        isVideo: true,
                      ));
                    },
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 230.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8.r,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: VideoPlayerWidget(videoUrl: message.videoUrl!),
                      ),
                    ),
                  )
                // 4. Call Log Message Bubble (Audio / Video Call status & duration)
                else if (_isCallMessage(message.text))
                  _buildCallLogBubble(context, message, isMe)
                // 5. Standard Text Bubble (Compact & Inline)
                else
                  Container(
                    constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                    padding:
                        EdgeInsets.symmetric(horizontal: 13.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      // Sent = Vibrant Emerald, Received = Pure White Card
                      gradient: isMe
                          ? const LinearGradient(
                              colors: [Color(0xFF059669), Color(0xFF047857)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isMe ? null : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.r),
                        topRight: Radius.circular(16.r),
                        bottomLeft: Radius.circular(isMe ? 16.r : 4.r),
                        bottomRight: Radius.circular(isMe ? 4.r : 16.r),
                      ),
                      border: isMe
                          ? null
                          : Border.all(
                              color: const Color(0xFFE2E8F0), width: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: isMe
                              ? const Color(0xFF059669).withValues(alpha: 0.18)
                              : Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4.r,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: message.isDeleted
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.block_rounded,
                                  size: 14.r,
                                  color: isMe ? Colors.white70 : Colors.grey),
                              SizedBox(width: 6.w),
                              Text(
                                'This message was removed',
                                style: GoogleFonts.poppins(
                                  color: isMe
                                      ? Colors.white70
                                      : Colors.grey.shade600,
                                  fontSize: 12.5.sp,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          )
                        : Wrap(
                            alignment: WrapAlignment.end,
                            crossAxisAlignment: WrapCrossAlignment.end,
                            spacing: 8.w,
                            runSpacing: 2.h,
                            children: [
                              SelectableText(
                                message.text,
                                style: GoogleFonts.poppins(
                                  color: isMe
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w400,
                                  height: 1.25,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(bottom: 1.h),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatTime(message.createdAt ??
                                          DateTime.now()),
                                      style: GoogleFonts.poppins(
                                        color: isMe
                                            ? Colors.white.withValues(alpha: 0.75)
                                            : AppTheme.textSecondary,
                                        fontSize: 9.5.sp,
                                      ),
                                    ),
                                    if (message.isEdited) ...[
                                      SizedBox(width: 3.w),
                                      Text(
                                        '· edited',
                                        style: GoogleFonts.poppins(
                                          color: isMe
                                              ? Colors.white70
                                              : Colors.grey.shade500,
                                          fontSize: 9.5.sp,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),

                // ── Floating Reaction Badge ──────────────────────────────
                if (hasReactions)
                  Positioned(
                    bottom: -10.h,
                    right: isMe ? 4.w : null,
                    left: isMe ? null : 4.w,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                            color: const Color(0xFFE2E8F0), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4.r,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: message.reactions!.values
                            .toSet()
                            .map((emoji) => Text(emoji,
                                style: TextStyle(fontSize: 12.sp)))
                            .toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Call Log Message Helper & Bubble Builder ───────────────────────────
  bool _isCallMessage(String text) => text.startsWith('[CALL_LOG:');

  Widget _buildCallLogBubble(
      BuildContext context, MessageModel message, bool isMe) {
    final parts = message.text
        .replaceAll('[CALL_LOG:', '')
        .replaceAll(']', '')
        .split(':');
    final callType = parts.isNotEmpty ? parts[0] : 'audio';
    final status = parts.length > 1 ? parts[1] : 'completed';
    final durSeconds = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
    final isVideo = callType == 'video';

    final isMissed = status == 'missed';
    final isDeclined = status == 'declined' || status == 'busy';
    final isCompleted = status == 'completed';

    final String title;
    if (isMissed) {
      title = isMe
          ? 'Unanswered ${isVideo ? "Video" : "Audio"} Call'
          : 'Missed ${isVideo ? "Video" : "Audio"} Call';
    } else if (isDeclined) {
      title = isMe
          ? 'Declined ${isVideo ? "Video" : "Audio"} Call'
          : 'Declined ${isVideo ? "Video" : "Audio"} Call';
    } else if (isCompleted) {
      title = isMe
          ? 'Outgoing ${isVideo ? "Video" : "Audio"} Call'
          : 'Incoming ${isVideo ? "Video" : "Audio"} Call';
    } else {
      title = isMe
          ? 'Outgoing ${isVideo ? "Video" : "Audio"} Call'
          : 'Incoming ${isVideo ? "Video" : "Audio"} Call';
    }

    final String subtitle;
    if (durSeconds > 0) {
      final m = durSeconds ~/ 60;
      final s = durSeconds % 60;
      subtitle = m > 0 ? '$m min $s sec' : '$s sec';
    } else if (isMissed) {
      subtitle = isMe ? 'No answer' : 'Tap to call back';
    } else if (isDeclined) {
      subtitle = 'Call unavailable';
    } else {
      subtitle = 'Call ended';
    }

    final IconData iconData;
    if (isMissed) {
      iconData =
          isVideo ? Icons.videocam_off_rounded : Icons.phone_missed_rounded;
    } else if (isDeclined) {
      iconData =
          isVideo ? Icons.videocam_off_rounded : Icons.phone_disabled_rounded;
    } else {
      iconData = isVideo
          ? Icons.videocam_rounded
          : (isMe
              ? Icons.phone_forwarded_rounded
              : Icons.phone_callback_rounded);
    }

    final Color iconColor;
    if (isMissed) {
      iconColor = const Color(0xFFEF4444);
    } else if (isDeclined) {
      iconColor = const Color(0xFFF59E0B);
    } else {
      iconColor = isMe ? Colors.white : const Color(0xFF059669);
    }

    return GestureDetector(
      onTap: () {
        CallController.to.makeCall(
          targetUserId: targetUserId,
          targetUserName: targetUserName,
          targetUserPhoto: targetUserPhoto,
          isVideo: isVideo,
        );
      },
      child: Container(
        constraints: BoxConstraints(maxWidth: 245.w),
        padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 10.h),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isMe ? null : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: isMe
              ? null
              : Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: isMe
                  ? const Color(0xFF059669).withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 8.r,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.white.withValues(alpha: 0.18)
                    : (isMissed
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFE6F4EA)),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 19.r),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                      color: isMe
                          ? Colors.white
                          : (isMissed
                              ? const Color(0xFFEF4444)
                              : AppTheme.textPrimary),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w400,
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.85)
                              : AppTheme.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatTime(message.createdAt ?? DateTime.now()),
                        style: GoogleFonts.poppins(
                          fontSize: 9.5.sp,
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.75)
                              : const Color(0xFF94A3B8),
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
    );
  }

  // ── Prominent, Clean & Distinct Bottom Input Bar ────────────────────
  Widget _buildBottomInputBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8.r,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        minimum: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.fromLTRB(10.w, 6.h, 10.w, 6.h),
          child: Row(
            children: [
              // Photo / Media Button (Distinct Soft Circle)
              GestureDetector(
                onTap: () => _chatController.sendImageMessage(chatRoomId, targetUserId),
                child: Container(
                  padding: EdgeInsets.all(9.r),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.image_rounded,
                    color: Color(0xFF059669),
                    size: 21,
                  ),
                ),
              ),
              SizedBox(width: 6.w),

              // Video Button (Distinct Soft Circle)
              GestureDetector(
                onTap: () => _chatController.sendVideoMessage(chatRoomId, targetUserId),
                child: Container(
                  padding: EdgeInsets.all(9.r),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.videocam_rounded,
                    color: Color(0xFF059669),
                    size: 21,
                  ),
                ),
              ),
              SizedBox(width: 8.w),

              // Distinct High-Contrast Text Input Pill
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9), // Soft distinct slate background
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: const Color(0xFF94A3B8), // Clear visible border
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _screenController.messageController,
                          cursorColor: const Color(0xFF059669),
                          onChanged: (val) {
                            _screenController.hasText.value =
                                val.trim().isNotEmpty;
                          },
                          onSubmitted: (_) => _sendMessage(),
                          maxLines: 4,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          style: GoogleFonts.poppins(
                            fontSize: 14.5.sp,
                            color: const Color(0xFF0F172A), // Crisp deep slate
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            filled: false,
                            fillColor: Colors.transparent,
                            hintText: 'Type a message...',
                            hintStyle: GoogleFonts.poppins(
                              color: const Color(0xFF475569), // Darker, crystal-clear readable placeholder
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 10.h),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showStickerPicker(context, targetUserId),
                        child: const Icon(
                          Icons.emoji_emotions_outlined,
                          color: Color(0xFF475569), // Crisp dark icon
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),

              // Prominent Circular Send Button OR Quick Thumbs-Up 👍
              Obx(() {
                final hasContent = _screenController.hasText.value;
                final isSending = _chatController.isSending.value;

                if (isSending) {
                  return Container(
                    width: 42.r,
                    height: 42.r,
                    padding: EdgeInsets.all(10.r),
                    child: const CircularProgressIndicator(
                      color: Color(0xFF059669),
                      strokeWidth: 2.5,
                    ),
                  );
                }

                return GestureDetector(
                  onTap: () {
                    if (hasContent) {
                      _sendMessage();
                    } else {
                      _chatController.sendMessage(
                          chatRoomId, '👍', targetUserId);
                    }
                  },
                  child: Container(
                    width: 42.r,
                    height: 42.r,
                    decoration: BoxDecoration(
                      color: hasContent
                          ? const Color(0xFF059669)
                          : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      boxShadow: hasContent
                          ? [
                              BoxShadow(
                                color: const Color(0xFF059669)
                                    .withValues(alpha: 0.35),
                                blurRadius: 6.r,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: hasContent
                          ? const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            )
                          : const Text(
                              '👍',
                              style: TextStyle(fontSize: 22),
                            ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _sendMessage() {
    _screenController.sendMessage(targetUserId);
  }

  // ── Message Options Bottom Sheet ──────────────────────────────────
  void _showMessageOptions(
      BuildContext context, MessageModel message, Offset tapPosition) {
    final isMe = message.senderId == _chatController.currentUserId;
    final canEdit = message.text.isNotEmpty && !message.isDeleted;
    final hasText = message.text.trim().isNotEmpty && !message.isDeleted;

    Get.bottomSheet(
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 36.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),

                // Reaction Emojis (Other user's messages ONLY)
                if (!isMe && !message.isDeleted) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:
                          ['❤️', '😂', '😮', '😢', '😡', '👍', '👎'].map((emoji) {
                        final isSelected = message.reactions?[
                                _chatController.currentUserId] ==
                            emoji;
                        return GestureDetector(
                          onTap: () {
                            Get.back();
                            _chatController.toggleReaction(
                                chatRoomId, message.id, emoji);
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 4.w),
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                      .withValues(alpha: 0.15)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14.r),
                              border: isSelected
                                  ? Border.all(
                                      color: AppTheme.primaryColor,
                                      width: 1.5)
                                  : null,
                            ),
                            child: Text(emoji,
                                style: TextStyle(fontSize: 24.sp)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (hasText || isMe) ...[
                    SizedBox(height: 14.h),
                    const Divider(color: Color(0xFFE2E8F0), height: 1),
                  ],
                ],

                // Copy Message
                if (hasText)
                  ListTile(
                    leading: const Icon(Icons.copy_rounded,
                        color: AppTheme.primaryColor),
                    title: Text('Copy Message',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500, fontSize: 14.sp)),
                    onTap: () {
                      Get.back();
                      Clipboard.setData(ClipboardData(text: message.text));
                      Get.snackbar(
                        'Copied',
                        'Message copied to clipboard',
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 2),
                      );
                    },
                  ),

                // Edit Message (Own only)
                if (isMe && canEdit)
                  ListTile(
                    leading:
                        const Icon(Icons.edit_rounded, color: Colors.blue),
                    title: Text('Edit Message',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500, fontSize: 14.sp)),
                    onTap: () {
                      Get.back();
                      _showEditDialog(context, message);
                    },
                  ),

                // Delete Message (Own only)
                if (isMe && !message.isDeleted)
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red),
                    title: Text('Delete Message',
                        style: GoogleFonts.poppins(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                            fontSize: 14.sp)),
                    onTap: () {
                      Get.back();
                      _showDeleteDialog(context, message);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, MessageModel message) {
    final editController = TextEditingController(text: message.text);
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Edit Message',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (editController.text.trim().isNotEmpty) {
                _chatController.editMessage(
                  chatRoomId,
                  message.id,
                  editController.text,
                );
                Get.back();
              }
            },
            child: Text('Save',
                style: GoogleFonts.poppins(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, MessageModel message) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Delete Message?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This message will be removed for everyone in this chat.',
          style: GoogleFonts.poppins(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              _chatController.deleteMessage(chatRoomId, message.id);
              Get.back();
            },
            child: Text('Delete',
                style: GoogleFonts.poppins(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showStickerPicker(BuildContext context, String targetUserId) {
    final defaultStickers = ['👍', '❤️', '😂', '🔥', '🎉', '💩', '😎', '🙏'];

    Get.bottomSheet(
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Send a Quick Emoji',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 16.sp)),
              SizedBox(height: 16.h),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16.w,
                  mainAxisSpacing: 16.h,
                ),
                itemCount: defaultStickers.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Get.back();
                      _chatController.sendMessage(
                        chatRoomId,
                        defaultStickers[index],
                        targetUserId,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Center(
                        child: Text(
                          defaultStickers[index],
                          style: TextStyle(fontSize: 30.sp),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  bool _isEmojiOnly(String text) {
    final textWithoutSpaces = text.replaceAll(RegExp(r'\s+'), '');
    if (textWithoutSpaces.isEmpty) return false;
    if (textWithoutSpaces.runes.length > 3) return false;
    return !RegExp(r'[\p{L}\p{N}\p{P}]', unicode: true)
        .hasMatch(textWithoutSpaces);
  }
}

// ── Screen Controller ────────────────────────────────────────────────
class ChatScreenController extends GetxController {
  final String chatRoomId;
  final String? initialMessage;
  late final ChatController chatController;
  final TextEditingController messageController = TextEditingController();
  final RxBool hasText = false.obs;

  ChatScreenController(this.chatRoomId, {this.initialMessage}) {
    chatController = Get.find<ChatController>();
    if (initialMessage != null && initialMessage!.trim().isNotEmpty) {
      messageController.text = initialMessage!.trim();
      hasText.value = true;
    }
  }

  @override
  void onInit() {
    super.onInit();
    chatController.joinChat(chatRoomId);
    chatController.fetchMessages(chatRoomId);
    chatController.markMessagesAsRead(chatRoomId);
  }

  void sendMessage(String targetUserId) {
    final text = messageController.text;
    if (text.trim().isNotEmpty) {
      chatController.sendMessage(chatRoomId, text, targetUserId);
      messageController.clear();
      hasText.value = false;
    }
  }

  @override
  void onClose() {
    chatController.leaveChat();
    messageController.dispose();
    super.onClose();
  }
}
