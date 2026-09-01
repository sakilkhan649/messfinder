import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mess_finder/core/theme/app_theme.dart';
import 'package:mess_finder/features/chat/controllers/chat_controller.dart';
import 'package:mess_finder/features/chat/models/chat_room_model.dart';
import 'package:mess_finder/features/chat/views/chat_screen.dart';
import 'package:mess_finder/features/notifications/views/widgets/notification_bell_action.dart';
import 'package:mess_finder/core/widgets/profile_avatar_leading.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatController chatController = Get.find<ChatController>();
    const Color primaryColor = Color(0xFF059669);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // ── App Brand Emerald AppBar ──────────────────────────────────────
      appBar: AppBar(
        toolbarHeight: 40.h,
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: const ProfileAvatarLeading(),
        titleSpacing: 16.w,
        title: Text(
          'Messages',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
        ),
        actions: const [
          NotificationBellAction(color: Colors.white),
          SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.h),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(50.r),
              ),
              child: Obx(() => TextField(
                controller: chatController.searchController,
                onChanged: (val) {
                  chatController.searchQuery.value = val.trim();
                },
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: Colors.white,
                ),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.transparent,
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.white70,
                    size: 20.r,
                  ),
                  hintText: 'Search conversations...',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13.sp,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 12.h,
                  ),
                  suffixIcon: chatController.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded, size: 18.r, color: Colors.white70),
                          onPressed: () {
                            chatController.clearSearch();
                          },
                        )
                      : null,
                ),
              )),
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (chatController.isLoadingRooms.value) {
          return const Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }

        final allChats = chatController.chatRooms;
        final filteredChats = allChats.where((chat) {
          if (chatController.searchQuery.value.isEmpty) return true;
          return chat.otherUserName
                  .toLowerCase()
                  .contains(chatController.searchQuery.value.toLowerCase()) ||
              chat.lastMessage
                  .toLowerCase()
                  .contains(chatController.searchQuery.value.toLowerCase());
        }).toList();

        return RefreshIndicator(
          color: primaryColor,
          onRefresh: () async {
            await chatController.fetchChatRooms(isRefresh: true);
          },
          child: Column(
            children: [
              // ── Search bar moved to AppBar ──

              // ── Chat List ───────────────────────────────────────────
              Expanded(
                child: filteredChats.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(20.r),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 38.r,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                            SizedBox(height: 14.h),
                            Text(
                              chatController.searchQuery.value.isNotEmpty
                                  ? 'No conversations found'
                                  : 'No conversations yet',
                              style: GoogleFonts.poppins(
                                color: AppTheme.textPrimary,
                                fontSize: 15.5.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              chatController.searchQuery.value.isNotEmpty
                                  ? 'Try searching with another keyword.'
                                  : 'Connect with landlords from listings to start chatting.',
                              style: GoogleFonts.poppins(
                                color: AppTheme.textSecondary,
                                fontSize: 12.5.sp,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: chatController.chatListScrollController,
                        physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics()),
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 4.h),
                        itemCount: filteredChats.length + (chatController.isFetchingMoreRooms.value ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == filteredChats.length) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 20.h),
                              child: const Center(
                                child: CircularProgressIndicator(color: primaryColor),
                              ),
                            );
                          }
                          final chat = filteredChats[index];
                          return _buildChatCard(context, chatController, chat);
                        },
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildChatCard(BuildContext context, ChatController chatController, ChatRoomModel chat) {
    final unreadCount =
        chat.unreadCounts[chatController.currentUserId] ?? 0;
    final isUnread = unreadCount > 0;
    final lastMsg = _formatLastMessage(chat.lastMessage);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isUnread
              ? const Color(0xFF059669).withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6.r,
            offset: const Offset(0, 2),
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
                targetUserId: chat.otherUserUid,
                targetUserName: chat.otherUserName,
                targetUserPhoto: chat.otherUserPhoto,
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                // Avatar with Online Badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 25.r,
                      backgroundColor: const Color(0xFFE2E8F0),
                      backgroundImage: chat.otherUserPhoto.isNotEmpty
                          ? CachedNetworkImageProvider(chat.otherUserPhoto)
                          : null,
                      child: chat.otherUserPhoto.isEmpty
                          ? const Icon(Icons.person,
                              size: 26, color: Color(0xFF94A3B8))
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12.r,
                        height: 12.r,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 14.w),

                // Name, Preview & Time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              chat.otherUserName,
                              style: GoogleFonts.poppins(
                                fontWeight: isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: 15.sp,
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
                                fontSize: 11.5.sp,
                                color: isUnread
                                    ? const Color(0xFF059669)
                                    : AppTheme.textSecondary,
                                fontWeight: isUnread
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 3.h),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMsg,
                              style: GoogleFonts.poppins(
                                fontSize: 13.sp,
                                color: isUnread
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary,
                                fontWeight: isUnread
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
                                  horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                unreadCount.toString(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 10.sp,
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
  }

  String _formatLastMessage(String msg) {
    if (msg.isEmpty) return 'Started a conversation';
    if (msg.startsWith('[CALL_LOG:')) {
      final parts = msg.replaceAll('[CALL_LOG:', '').replaceAll(']', '').split(':');
      final callType = parts.isNotEmpty ? parts[0] : 'audio';
      final status = parts.length > 1 ? parts[1] : 'completed';
      final isVideo = callType == 'video';
      if (status == 'missed') {
        return isVideo ? '📹 Missed Video Call' : '📞 Missed Audio Call';
      } else if (status == 'declined' || status == 'busy') {
        return isVideo ? '📹 Declined Video Call' : '📞 Declined Audio Call';
      } else {
        return isVideo ? '📹 Video Call' : '📞 Audio Call';
      }
    }
    return msg;
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
