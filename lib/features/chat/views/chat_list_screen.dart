import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mess_finder/core/theme/app_theme.dart';
import 'package:mess_finder/features/chat/controllers/chat_controller.dart';
import 'package:mess_finder/features/chat/views/chat_screen.dart';
import 'package:mess_finder/features/notifications/views/widgets/notification_bell_action.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatelessWidget {
  ChatListScreen({super.key});

  final ChatController _chatController = Get.find<ChatController>();

  @override
  Widget build(BuildContext context) {
    final Color rolePrimaryColor = const Color(0xFF059669);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: rolePrimaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Messages',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
        ),
        actions: const [
          NotificationBellAction(),
        ],
      ),
      body: Obx(() {
        if (_chatController.isLoadingRooms.value) {
          return Center(
            child: CircularProgressIndicator(color: rolePrimaryColor),
          );
        }

        final chats = _chatController.chatRooms;

        if (chats.isEmpty) {
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
                    Icons.chat_bubble_outline_rounded,
                    size: 48.r,
                    color: rolePrimaryColor,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'No conversations yet',
                  style: GoogleFonts.poppins(
                    color: AppTheme.textSecondary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Your chats will appear here.',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade500,
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: rolePrimaryColor,
          onRefresh: () async {
            await _chatController.fetchChatRooms();
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];

              final otherUserId = chat.otherUserUid;
              final otherUserName = chat.otherUserName;
              final otherUserPhoto = chat.otherUserPhoto;
              final unreadCount = chat.unreadCounts[_chatController.currentUserId] ?? 0;
              final lastMsg = chat.lastMessage;
              // Assuming if lastMsg contains "You: " it's ours, otherwise it's just the message.
              // For a better implementation, we'd need lastSenderId from backend.

              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16.r),
                    onTap: () {
                      Get.to(
                        () => ChatScreen(
                          chatRoomId: chat.id,
                          targetUserId: otherUserId,
                          targetUserName: otherUserName,
                          targetUserPhoto: otherUserPhoto,
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.all(12.r),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: rolePrimaryColor.withValues(alpha: 0.2),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 28.r,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: otherUserPhoto.isNotEmpty
                                  ? NetworkImage(otherUserPhoto)
                                  : null,
                              child: otherUserPhoto.isEmpty
                                  ? Icon(
                                      Icons.person,
                                      size: 32.r,
                                      color: Colors.grey.shade400,
                                    )
                                  : null,
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        otherUserName,
                                        style: GoogleFonts.poppins(
                                          fontWeight: unreadCount > 0
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          fontSize: 16.sp,
                                          color: AppTheme.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (chat.lastMessageTime != null)
                                      Text(
                                        _formatTime(chat.lastMessageTime!),
                                        style: GoogleFonts.poppins(
                                          fontSize: 12.sp,
                                          color: unreadCount > 0
                                              ? rolePrimaryColor
                                              : Colors.grey.shade500,
                                          fontWeight: unreadCount > 0
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 4.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        lastMsg.isEmpty ? 'Say hi! 👋' : lastMsg,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14.sp,
                                          color: unreadCount > 0
                                              ? AppTheme.textPrimary
                                              : Colors.grey.shade600,
                                          fontWeight: unreadCount > 0
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (unreadCount > 0)
                                      Container(
                                        margin: EdgeInsets.only(left: 8.w),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.w,
                                          vertical: 4.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: rolePrimaryColor,
                                          borderRadius: BorderRadius.circular(12.r),
                                        ),
                                        child: Text(
                                          unreadCount.toString(),
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
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
            },
          ),
        );
      }),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return DateFormat('h:mm a').format(time);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d').format(time);
    }
  }
}
