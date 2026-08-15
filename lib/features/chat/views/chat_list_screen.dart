import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mess_finder/core/theme/app_theme.dart';
import 'package:mess_finder/features/chat/controllers/chat_controller.dart';
import 'package:mess_finder/features/chat/models/chat_room_model.dart';
import 'package:mess_finder/features/chat/views/chat_screen.dart';
import 'package:mess_finder/features/notifications/views/widgets/notification_bell_action.dart';

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
        body: StreamBuilder<List<ChatRoomModel>>(
          stream: _chatController.getChatRooms(),
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
            final validChats = snapshot.hasData 
                ? snapshot.data!.where((chat) {
                    final otherUserId = chat.participants.firstWhere(
                      (id) => id != _chatController.currentUserId,
                      orElse: () => '',
                    );
                    return otherUserId.isNotEmpty;
                  }).toList()
                : [];

            if (validChats.isEmpty) {
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

            final chats = validChats;

            return RefreshIndicator(
              color: rolePrimaryColor,
              onRefresh: () async {
                await Future.delayed(const Duration(seconds: 1));
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                itemCount: chats.length,
                itemBuilder: (context, index) {
                  final chat = chats[index];

                  final otherUserId = chat.participants.firstWhere(
                    (id) => id != _chatController.currentUserId,
                    orElse: () => '',
                  );

                  final otherUserName =
                      chat.participantNames[otherUserId] ?? 'Unknown';
                  final otherUserPhoto = chat.participantPhotos[otherUserId];

                  final unreadCount =
                      chat.unreadCounts[_chatController.currentUserId] ?? 0;

                  final isMeLastSender = chat.lastSenderId == _chatController.currentUserId;
                  final prefix = isMeLastSender ? 'You: ' : '';
                  // otherUserId.isEmpty is already filtered out

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(otherUserId)
                        .get(const GetOptions(source: Source.serverAndCache)),
                    builder: (context, userSnap) {
                      String finalOtherUserName = otherUserName;
                      String? finalOtherUserPhoto = otherUserPhoto;

                      if (userSnap.hasData && userSnap.data != null && userSnap.data!.exists) {
                        final data = userSnap.data!.data() as Map<String, dynamic>?;
                        if (data != null) {
                          finalOtherUserName = data['name']?.toString() ?? otherUserName;
                          finalOtherUserPhoto = data['photoUrl']?.toString() ?? otherUserPhoto;
                          
                          // Auto-heal the stale chat room cache in the background
                          if (finalOtherUserName != otherUserName || finalOtherUserPhoto != otherUserPhoto) {
                            FirebaseFirestore.instance
                                .collection('chats')
                                .doc(chat.id)
                                .update({
                              'participantNames.$otherUserId': finalOtherUserName,
                              'participantPhotos.$otherUserId': finalOtherUserPhoto,
                            }).catchError((_) {});
                          }
                        }
                      }

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
                                  targetUserName: finalOtherUserName,
                                  targetUserPhoto: finalOtherUserPhoto,
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
                                        color: rolePrimaryColor.withValues(
                                          alpha: 0.2,
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 26.r,
                                      backgroundColor: rolePrimaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      backgroundImage:
                                          finalOtherUserPhoto != null &&
                                              finalOtherUserPhoto.isNotEmpty
                                          ? NetworkImage(finalOtherUserPhoto)
                                          : null,
                                      child:
                                          finalOtherUserPhoto == null ||
                                              finalOtherUserPhoto.isEmpty
                                          ? Icon(
                                              Icons.person_rounded,
                                              size: 28.r,
                                              color: rolePrimaryColor,
                                            )
                                          : null,
                                    ),
                                  ),
                                  SizedBox(width: 16.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          finalOtherUserName,
                                          style: GoogleFonts.poppins(
                                            fontWeight: unreadCount > 0
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            fontSize: 15.sp,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          chat.lastMessage.isEmpty
                                              ? 'Say hi!'
                                              : '$prefix${chat.lastMessage}',
                                          style: GoogleFonts.poppins(
                                            color: unreadCount > 0
                                                ? AppTheme.textPrimary
                                                : AppTheme.textSecondary,
                                            fontWeight: unreadCount > 0
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                            fontSize: 13.sp,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (unreadCount > 0) ...[
                                    SizedBox(width: 8.w),
                                    Container(
                                      padding: EdgeInsets.all(8.r),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.errorColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        unreadCount.toString(),
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      );
  }
}
