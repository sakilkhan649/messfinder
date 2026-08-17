import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:image_picker/image_picker.dart';

import 'package:mess_finder/core/utils/app_logger.dart';
import 'package:mess_finder/core/services/api_service.dart';
import 'package:mess_finder/core/services/notification_service.dart';
import 'package:mess_finder/core/utils/imgbb_service.dart';

import 'package:mess_finder/features/auth/controllers/auth_controller.dart';
import 'package:mess_finder/features/chat/models/chat_room_model.dart';
import 'package:mess_finder/features/chat/models/message_model.dart';
import 'package:mess_finder/features/notifications/models/app_notification_model.dart';

class ChatController extends GetxController {
  final ApiService _apiService = ApiService();
  IO.Socket? _socket;

  String get currentUserId {
    if (Get.isRegistered<AuthController>()) {
      return Get.find<AuthController>().currentUser.value?.uid ?? '';
    }
    return '';
  }

  // Reactive state
  final RxList<ChatRoomModel> chatRooms = <ChatRoomModel>[].obs;
  final RxList<MessageModel> currentMessages = <MessageModel>[].obs;
  final RxBool isLoadingRooms = true.obs;
  final RxBool isLoadingMessages = false.obs;
  final RxBool isSending = false.obs;

  String? _currentActiveChatId;

  @override
  void onInit() {
    super.onInit();
    _initSocket();
    fetchChatRooms();
  }

  @override
  void onClose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.onClose();
  }

  void _initSocket() {
    // ApiService.baseUrl = 'http://10.0.2.2:5000/api'
    // Socket.io needs the base server URL (without /api)
    final socketUrl = ApiService.baseUrl.replaceAll('/api', '');
    AppLogger.i('Connecting Socket.io to: $socketUrl', tag: 'CHAT_CTRL');

    _socket = IO.io(socketUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build());

    _socket?.connect();

    _socket?.onConnect((_) {
      AppLogger.s('Socket.IO connected', tag: 'CHAT_CTRL');
    });

    _socket?.on('receive_message', (data) {
      final msg = MessageModel.fromMap(data);
      // If we are currently in this chat room, add message to list
      if (data['chat_id'] == _currentActiveChatId) {
        // Only add if not already in list to avoid duplicates
        if (!currentMessages.any((m) => m.id == msg.id)) {
          currentMessages.insert(0, msg);
        }
      }
      // Refresh chat rooms list to update last message
      fetchChatRooms();
    });

    _socket?.onDisconnect((_) {
      AppLogger.w('Socket.IO disconnected', tag: 'CHAT_CTRL');
    });
  }

  void joinChat(String chatId) {
    _currentActiveChatId = chatId;
    _socket?.emit('join_chat', chatId);
  }

  void leaveChat() {
    _currentActiveChatId = null;
  }

  Future<void> fetchChatRooms() async {
    try {
      final response = await _apiService.dio.get('/chats');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        chatRooms.assignAll(data.map((e) => ChatRoomModel.fromMap(e)).toList());
      }
    } catch (e) {
      AppLogger.e('Failed to fetch chat rooms: $e', e, null, 'CHAT_CTRL');
    } finally {
      isLoadingRooms.value = false;
    }
  }

  Future<void> fetchMessages(String chatId) async {
    isLoadingMessages.value = true;
    currentMessages.clear();
    try {
      final response = await _apiService.dio.get('/chats/$chatId/messages');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final msgs = data.map((e) => MessageModel.fromMap(e)).toList();
        // Backend returns oldest first, but chat UI needs newest first
        currentMessages.assignAll(msgs.reversed.toList());
      }
    } catch (e) {
      AppLogger.e('Failed to fetch messages: $e', e, null, 'CHAT_CTRL');
    } finally {
      isLoadingMessages.value = false;
    }
  }

  Future<String> createOrGetChatRoom(String targetUserId, String targetUserName, String? targetUserPhoto) async {
    try {
      final response = await _apiService.dio.post('/chats', data: {
        'targetUserId': targetUserId,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        final chatId = response.data['chatId'];
        // Refresh chat rooms so the new one appears
        fetchChatRooms();
        return chatId;
      }
      throw 'Failed to create chat room';
    } catch (e) {
      AppLogger.e('Create chat room error: $e', e, null, 'CHAT_CTRL');
      throw 'Cannot start chat';
    }
  }

  Future<void> sendMessage(String chatRoomId, String text, String targetUserId, {String? imageUrl, String? videoUrl}) async {
    if (text.trim().isEmpty && imageUrl == null && videoUrl == null) return;

    try {
      isSending.value = true;
      
      // Emit via socket
      _socket?.emit('send_message', {
        'chatId': chatRoomId,
        'senderUid': currentUserId,
        'text': text.trim(),
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
      });

      // Send Push Notification
      try {
        final currentUserName = Get.find<AuthController>().currentUser.value?.name ?? 'Someone';
        final String messagePreview;
        if (videoUrl != null) {
          messagePreview = text.isNotEmpty ? '🎥 ${text.trim()}' : '🎥 Sent a video';
        } else if (imageUrl != null) {
          messagePreview = text.isNotEmpty ? '📷 ${text.trim()}' : '📷 Sent an image';
        } else {
          messagePreview = text.trim();
        }
        NotificationService().sendAndStore(
          receiverUid: targetUserId,
          title: 'New Message from $currentUserName',
          body: messagePreview,
          type: NotificationType.general,
          senderUid: currentUserId,
          relatedId: chatRoomId,
          extraData: {'type': 'chat', 'chatRoomId': chatRoomId},
        ).catchError((e) {
          debugPrint('Notification error: $e');
        });
      } catch (e) {
        // ignore notification errors
      }
    } finally {
      isSending.value = false;
    }
  }

  Future<void> sendImageMessage(String chatRoomId, String targetUserId) async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(imageQuality: 70);
    if (images.isEmpty) return;
    
    final TextEditingController textCtrl = TextEditingController();

    final result = await Get.bottomSheet<Map<String, dynamic>>(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(
                height: 250,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(images[index].path),
                          fit: BoxFit.cover,
                          width: images.length == 1 ? Get.width - 32 : Get.width * 0.7,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: textCtrl,
                        maxLines: 4,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: 'Add a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => Get.back(result: {'send': true, 'text': textCtrl.text}),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E88E5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );

    if (result != null && result['send'] == true) {
      isSending.value = true;
      for (var image in images) {
        final imageUrl = await ImgbbService().uploadImage(image.path);
        if (imageUrl != null) {
          await sendMessage(chatRoomId, result['text'] ?? '', targetUserId, imageUrl: imageUrl);
        }
      }
      isSending.value = false;
    }
  }

  Future<void> sendVideoMessage(String chatRoomId, String targetUserId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;
    
    isSending.value = true;
    try {
      final videoUrl = await ImgbbService().uploadVideo(video.path);
      if (videoUrl != null) {
        await sendMessage(chatRoomId, '', targetUserId, videoUrl: videoUrl);
      } else {
        Get.snackbar('Upload Failed', 'Could not upload video. Please try again.');
      }
    } catch (e) {
      AppLogger.e('Error uploading video: $e', e, null, 'CHAT_CTRL');
      Get.snackbar('Error', 'An error occurred while sending video.');
    } finally {
      isSending.value = false;
    }
  }

  Future<void> toggleReaction(String chatRoomId, String messageId, String emoji) async {
    // Reactions are not currently implemented in the REST backend.
  }

  Future<void> editMessage(String chatRoomId, String messageId, String newText) async {
    // Message editing is not currently implemented in the REST backend.
  }

  Future<void> deleteMessage(String chatRoomId, String messageId) async {
    // Message deletion is not currently implemented in the REST backend.
  }

  Future<void> markMessagesAsRead(String chatRoomId) async {
    // Mark as read is not currently implemented in the REST backend.
  }
}
