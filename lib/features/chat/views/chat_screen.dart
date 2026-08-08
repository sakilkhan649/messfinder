import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mess_finder/core/theme/app_theme.dart';
import 'package:mess_finder/features/auth/controllers/auth_controller.dart';
import 'package:mess_finder/features/chat/controllers/chat_controller.dart';
import 'package:mess_finder/features/chat/models/message_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String targetUserId;
  final String targetUserName;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.targetUserId,
    required this.targetUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatController _chatController = Get.find<ChatController>();
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Mark messages as read when opening the chat
    _chatController.markMessagesAsRead(widget.chatRoomId);
  }

  void _sendMessage() {
    final text = _messageController.text;
    if (text.trim().isNotEmpty) {
      _chatController.sendMessage(widget.chatRoomId, text, widget.targetUserId);
      _messageController.clear();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLandlord = _authController.currentUser.value?.isLandlord ?? false;
      final Color rolePrimaryColor = isLandlord
          ? const Color(0xFF059669) // Emerald for Landlord
          : const Color(0xFF059669); // Deep Indigo for Bachelor
      final LinearGradient rolePrimaryGradient = LinearGradient(
        colors: isLandlord
            ? [const Color(0xFF059669), const Color(0xFF10B981)]
            : [const Color(0xFF059669), const Color(0xFF047857)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: rolePrimaryColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          titleSpacing: 0,
          title: Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Icon(
                  Icons.person_rounded,
                  size: 20.r,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.targetUserName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                    Text(
                      'Online', // Placeholder for status
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: _chatController.getMessages(widget.chatRoomId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: rolePrimaryColor),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: GoogleFonts.poppins(),
                      ),
                    );
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(24.r),
                            decoration: BoxDecoration(
                              color: rolePrimaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.waving_hand_rounded,
                              size: 48.r,
                              color: rolePrimaryColor,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Say hi to ${widget.targetUserName}!',
                            style: GoogleFonts.poppins(
                              color: AppTheme.textSecondary,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe =
                          message.senderId == _chatController.currentUserId;

                      return GestureDetector(
                        onLongPress: isMe && !message.isDeleted
                            ? () => _showMessageOptions(context, message)
                            : null,
                        child: Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: EdgeInsets.only(
                              bottom: 12.h,
                              left: isMe ? 64.w : 0,
                              right: isMe ? 0 : 64.w,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: isMe ? rolePrimaryGradient : null,
                              color: isMe ? null : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16.r),
                                topRight: Radius.circular(16.r),
                                bottomLeft: Radius.circular(isMe ? 16.r : 4.r),
                                bottomRight: Radius.circular(isMe ? 4.r : 16.r),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isMe
                                      ? rolePrimaryColor.withValues(alpha: 0.2)
                                      : Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ],
                            ),
                            child: message.isDeleted
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.block_rounded,
                                        size: 16.r,
                                        color: isMe ? Colors.white70 : Colors.grey,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'This message was deleted',
                                        style: GoogleFonts.poppins(
                                          color: isMe ? Colors.white70 : Colors.grey,
                                          fontSize: 14.sp,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (message.imageUrl != null)
                                        Padding(
                                          padding: EdgeInsets.only(bottom: 8.h),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12.r),
                                            child: CachedNetworkImage(
                                              imageUrl: message.imageUrl!,
                                              width: 200.w,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Container(
                                                width: 200.w,
                                                height: 150.h,
                                                color: Colors.grey.withValues(alpha: 0.2),
                                                child: const Center(child: CircularProgressIndicator()),
                                              ),
                                              errorWidget: (context, url, error) => const Icon(Icons.error),
                                            ),
                                          ),
                                        ),
                                      if (message.text.isNotEmpty)
                                        Text(
                                          message.text,
                                          style: GoogleFonts.poppins(
                                            color: isMe ? Colors.white : AppTheme.textPrimary,
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      if (message.isEdited)
                                        Padding(
                                          padding: EdgeInsets.only(top: 4.h),
                                          child: Text(
                                            '(edited)',
                                            style: GoogleFonts.poppins(
                                              color: isMe ? Colors.white70 : Colors.grey,
                                              fontSize: 10.sp,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            _buildMessageInput(rolePrimaryColor, rolePrimaryGradient),
          ],
        ),
      );
    });
  }

  Widget _buildMessageInput(
    Color rolePrimaryColor,
    LinearGradient rolePrimaryGradient,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20.r,
            offset: Offset(0, -4.h),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: () => _chatController.sendImageMessage(widget.chatRoomId, widget.targetUserId),
              icon: Icon(
                Icons.image_rounded,
                color: rolePrimaryColor,
                size: 24.r,
              ),
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            SizedBox(width: 12.w),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  gradient: rolePrimaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: rolePrimaryColor.withValues(alpha: 0.3),
                      blurRadius: 8.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Obx(() => _chatController.isSending.value
                    ? SizedBox(
                        height: 20.r,
                        width: 20.r,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20.r,
                      )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context, MessageModel message) {
    if (message.text.isEmpty && message.imageUrl != null) {
      // Cannot edit a photo-only message for now, maybe just delete
      _showDeleteDialog(context, message);
      return;
    }

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: Colors.blue),
              title: Text('Edit Message', style: GoogleFonts.poppins()),
              onTap: () {
                Get.back();
                _showEditDialog(context, message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: Text('Delete Message', style: GoogleFonts.poppins()),
              onTap: () {
                Get.back();
                _showDeleteDialog(context, message);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, MessageModel message) {
    final editController = TextEditingController(text: message.text);
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Edit Message', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (editController.text.trim().isNotEmpty) {
                _chatController.editMessage(widget.chatRoomId, message.id, editController.text);
                Get.back();
              }
            },
            child: Text('Save', style: GoogleFonts.poppins(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, MessageModel message) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Delete Message?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('This message will be deleted for everyone in this chat.', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              _chatController.deleteMessage(widget.chatRoomId, message.id);
              Get.back();
            },
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
