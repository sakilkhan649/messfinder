import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mess_finder/core/theme/app_theme.dart';
import 'package:mess_finder/features/chat/controllers/chat_controller.dart';
import 'package:mess_finder/features/chat/models/message_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatScreen extends StatelessWidget {
  final String chatRoomId;
  final String targetUserId;
  final String targetUserName;
  final String? targetUserPhoto;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.targetUserId,
    required this.targetUserName,
    this.targetUserPhoto,
  });

  ChatScreenController get _screenController => Get.find<ChatScreenController>(tag: chatRoomId);
  ChatController get _chatController => Get.find<ChatController>();
  TextEditingController get _messageController => _screenController.messageController;

  void _sendMessage() {
    _screenController.sendMessage(targetUserId);
  }


  @override
  Widget build(BuildContext context) {
    Get.put(ChatScreenController(chatRoomId), tag: chatRoomId);
    final Color rolePrimaryColor = const Color(0xFF059669);
    final LinearGradient rolePrimaryGradient = const LinearGradient(
      colors: [Color(0xFF059669), Color(0xFF047857)],
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
                backgroundImage: targetUserPhoto != null
                    ? NetworkImage(targetUserPhoto!)
                    : null,
                child: targetUserPhoto == null
                    ? Icon(
                        Icons.person_rounded,
                        size: 20.r,
                        color: Colors.white,
                      )
                    : null,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      targetUserName,
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
                stream: _chatController.getMessages(chatRoomId),
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
                            'Say hi to $targetUserName!',
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: isMe
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: 12.h,
                                    right: 8.w,
                                    left: 16.w,
                                  ),
                                  child: Tooltip(
                                    message: targetUserName,
                                    triggerMode: TooltipTriggerMode.tap,
                                    child: CircleAvatar(
                                      radius: 12.r,
                                      backgroundColor: Colors.grey.shade300,
                                      backgroundImage:
                                          targetUserPhoto != null
                                          ? NetworkImage(
                                              targetUserPhoto!,
                                            )
                                          : null,
                                      child: targetUserPhoto == null
                                          ? Icon(
                                              Icons.person_rounded,
                                              size: 14.r,
                                              color: Colors.grey.shade600,
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              Flexible(
                                child: Container(
                                  margin: EdgeInsets.only(
                                    bottom: 12.h,
                                    left: isMe ? 64.w : 0,
                                    right: isMe ? 16.w : 64.w,
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
                                      bottomLeft: Radius.circular(
                                        isMe ? 16.r : 4.r,
                                      ),
                                      bottomRight: Radius.circular(
                                        isMe ? 4.r : 16.r,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isMe
                                            ? rolePrimaryColor.withValues(
                                                alpha: 0.2,
                                              )
                                            : Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
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
                                              color: isMe
                                                  ? Colors.white70
                                                  : Colors.grey,
                                            ),
                                            SizedBox(width: 8.w),
                                            Flexible(
                                              child: Text(
                                                'This message was deleted',
                                                style: GoogleFonts.poppins(
                                                  color: isMe
                                                      ? Colors.white70
                                                      : Colors.grey,
                                                  fontSize: 14.sp,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (message.imageUrl != null)
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  bottom: 8.h,
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        12.r,
                                                      ),
                                                  child: CachedNetworkImage(
                                                    imageUrl: message.imageUrl!,
                                                    width: 200.w,
                                                    fit: BoxFit.cover,
                                                    placeholder:
                                                        (
                                                          context,
                                                          url,
                                                        ) => Container(
                                                          width: 200.w,
                                                          height: 150.h,
                                                          color: Colors.grey
                                                              .withValues(
                                                                alpha: 0.2,
                                                              ),
                                                          child: const Center(
                                                            child:
                                                                CircularProgressIndicator(),
                                                          ),
                                                        ),
                                                    errorWidget:
                                                        (context, url, error) =>
                                                            const Icon(
                                                              Icons.error,
                                                            ),
                                                  ),
                                                ),
                                              ),
                                            if (message.text.isNotEmpty)
                                              Text(
                                                message.text,
                                                style: GoogleFonts.poppins(
                                                  color: isMe
                                                      ? Colors.white
                                                      : AppTheme.textPrimary,
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  _formatTime(
                                                    message.createdAt ??
                                                        DateTime.now(),
                                                  ),
                                                  style: GoogleFonts.poppins(
                                                    color: isMe
                                                        ? Colors.white70
                                                        : Colors.grey.shade500,
                                                    fontSize: 10.sp,
                                                  ),
                                                ),
                                                if (message.isEdited)
                                                  Padding(
                                                    padding: EdgeInsets.only(
                                                      left: 4.w,
                                                    ),
                                                    child: Text(
                                                      '(edited)',
                                                      style:
                                                          GoogleFonts.poppins(
                                                            color: isMe
                                                                ? Colors.white70
                                                                : Colors.grey,
                                                            fontSize: 10.sp,
                                                          ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              // Removed isMe avatar block
                            ],
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
            Obx(
              () => IconButton(
                onPressed: _chatController.isSending.value
                    ? null
                    : () => _chatController.sendImageMessage(
                        chatRoomId,
                        targetUserId,
                      ),
                icon: Icon(
                  Icons.image_rounded,
                  color: _chatController.isSending.value
                      ? Colors.grey
                      : rolePrimaryColor,
                  size: 24.r,
                ),
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
                child: Obx(
                  () => _chatController.isSending.value
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
                        ),
                ),
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
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
              ),
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
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
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
            child: Text('Save', style: GoogleFonts.poppins(color: Colors.blue)),
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
          'This message will be deleted for everyone in this chat.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              _chatController.deleteMessage(chatRoomId, message.id);
              Get.back();
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    int hour = time.hour;
    int minute = time.minute;
    String period = hour >= 12 ? 'PM' : 'AM';
    if (hour == 0) hour = 12;
    if (hour > 12) hour -= 12;
    String minuteStr = minute < 10 ? '0$minute' : '$minute';
    return '$hour:$minuteStr $period';
  }
}

class ChatScreenController extends GetxController {
  final String chatRoomId;
  late final ChatController chatController;
  final TextEditingController messageController = TextEditingController();

  ChatScreenController(this.chatRoomId) {
    chatController = Get.find<ChatController>();
  }

  @override
  void onInit() {
    super.onInit();
    chatController.markMessagesAsRead(chatRoomId);
  }

  void sendMessage(String targetUserId) {
    final text = messageController.text;
    if (text.trim().isNotEmpty) {
      chatController.sendMessage(chatRoomId, text, targetUserId);
      messageController.clear();
    }
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }
}
