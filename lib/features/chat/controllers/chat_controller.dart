import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mess_finder/core/utils/app_logger.dart';
import 'package:mess_finder/core/services/socket_service.dart';
import 'package:mess_finder/core/services/api_service.dart';
import 'package:mess_finder/core/services/notification_service.dart';
import 'package:mess_finder/core/services/media_upload_service.dart';

import 'package:mess_finder/features/auth/controllers/auth_controller.dart';
import 'package:mess_finder/features/chat/models/chat_room_model.dart';
import 'package:mess_finder/features/chat/models/message_model.dart';
import 'package:mess_finder/features/notifications/models/app_notification_model.dart';

class ChatController extends GetxController {
  final ApiService _apiService = ApiService();
  String get currentUserId {
    if (Get.isRegistered<AuthController>()) {
      return Get.find<AuthController>().currentUser.value?.uid ?? '';
    }
    return '';
  }

  // ── Reactive State ────────────────────────────────────────────────────
  final RxList<ChatRoomModel> chatRooms = <ChatRoomModel>[].obs;
  final RxList<MessageModel> currentMessages = <MessageModel>[].obs;
  final RxBool isLoadingRooms = true.obs;
  final RxBool isLoadingMessages = false.obs;
  final RxBool isSending = false.obs;

  // ── Typing & Online Presence ──────────────────────────────────────────
  /// chatId -> userId who is typing
  final RxMap<String, String> typingUsers = <String, String>{}.obs;

  /// Set of userIds who are currently online
  final RxSet<String> onlineUsers = <String>{}.obs;

  /// chatId -> last seen messageId (from peer)
  final RxMap<String, String> seenMessageIds = <String, String>{}.obs;

  /// The message currently being replied to
  final Rx<MessageModel?> replyMessage = Rx<MessageModel?>(null);

  Timer? _typingDebounceTimer;
  bool _isCurrentlyTyping = false;

  // ── Pagination & Search for Chat Rooms ───────────────────────────────
  int _roomPage = 1;
  final int _roomLimit = 20;
  final RxBool hasMoreRooms = true.obs;
  final RxBool isFetchingMoreRooms = false.obs;

  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final ScrollController chatListScrollController = ScrollController();

  // ── Pagination for Chat Messages ──────────────────────────────────────
  int _messageOffset = 0;
  final int _messageLimit = 50;
  final RxBool hasMoreMessages = true.obs;
  final RxBool isFetchingMoreMessages = false.obs;
  final ScrollController messageScrollController = ScrollController();

  String? _currentActiveChatId;
  String? get currentActiveChatId => _currentActiveChatId;

  @override
  void onInit() {
    super.onInit();
    _initSocket();
    fetchChatRooms();
    chatListScrollController.addListener(_onChatListScroll);
    messageScrollController.addListener(_onMessageScroll);
  }

  @override
  void onClose() {
    if (Get.isRegistered<SocketService>()) {
      Get.find<SocketService>().disconnect();
    }
    _typingDebounceTimer?.cancel();
    searchController.dispose();
    chatListScrollController.dispose();
    messageScrollController.dispose();
    super.onClose();
  }

  void _onChatListScroll() {
    if (chatListScrollController.position.pixels >=
            chatListScrollController.position.maxScrollExtent - 200 &&
        !isFetchingMoreRooms.value &&
        hasMoreRooms.value) {
      fetchChatRooms(isLoadMore: true);
    }
  }

  void _onMessageScroll() {
    if (messageScrollController.position.pixels >=
            messageScrollController.position.maxScrollExtent - 200 &&
        !isFetchingMoreMessages.value &&
        hasMoreMessages.value &&
        _currentActiveChatId != null) {
      loadMoreMessages(_currentActiveChatId!);
    }
  }

  void _scrollToBottom() {
    if (messageScrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (messageScrollController.hasClients) {
          messageScrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  // ── Socket Initialization ─────────────────────────────────────────────
  void _initSocket() {
    if (!Get.isRegistered<SocketService>()) return;

    final socketService = Get.find<SocketService>();

    // Initial setup if we enter a chat right away
    if (_currentActiveChatId != null) {
      socketService.emit('join_chat', _currentActiveChatId);
    }
    _requestOnlineUsers();

    // ── Incoming Message ──────────────────────────────────────────────
    socketService.on('receive_message', (data) {
      if (data == null) return;
      final map = Map<String, dynamic>.from(data);
      final msg = MessageModel.fromMap(map);
      final chatId = (map['chat_id'] ?? map['chatId'])?.toString();
      if (chatId == _currentActiveChatId) {
        if (!currentMessages.any((m) => m.id.isNotEmpty && m.id == msg.id)) {
          // Remove optimistic duplicate if exists, matching text and media
          currentMessages.removeWhere(
            (m) =>
                m.id.startsWith('temp_') &&
                m.senderId == msg.senderId &&
                m.text == msg.text &&
                m.imageUrl == msg.imageUrl &&
                m.videoUrl == msg.videoUrl,
          );
          currentMessages.insert(0, msg);
          
          if (messageScrollController.hasClients && messageScrollController.offset < 200) {
            _scrollToBottom();
          }

          // Auto-mark as seen since we're actively in this chat
          if (msg.senderId != currentUserId) {
            _emitMarkSeen(chatId!, msg.id);
          }
        }
      }
      fetchChatRooms();
    });

    // ── Reaction ─────────────────────────────────────────────────────
    socketService.on('message_reacted', (data) {
      if (data == null) return;
      final messageId = data['messageId']?.toString();
      final reactions = data['reactions'] != null
          ? Map<String, String>.from(data['reactions'])
          : <String, String>{};
      final index = currentMessages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        currentMessages[index] = currentMessages[index].copyWith(
          reactions: reactions,
        );
        currentMessages.refresh();
      }
    });

    // ── Edit ─────────────────────────────────────────────────────────
    socketService.on('message_edited', (data) {
      if (data == null) return;
      final messageId = data['messageId']?.toString();
      final text = data['text']?.toString() ?? '';
      final index = currentMessages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        currentMessages[index] = currentMessages[index].copyWith(
          text: text,
          isEdited: true,
        );
        currentMessages.refresh();
      }
    });

    // ── Delete ────────────────────────────────────────────────────────
    socketService.on('message_deleted', (data) {
      if (data == null) return;
      final messageId = data['messageId']?.toString();
      final index = currentMessages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        currentMessages[index] = currentMessages[index].copyWith(
          text: '',
          isDeleted: true,
          imageUrl: null,
          videoUrl: null,
          stickerUrl: null,
        );
        currentMessages.refresh();
      }
    });

    // ── Typing Indicators ─────────────────────────────────────────────
    socketService.on('user_typing', (data) {
      if (data == null) return;
      final chatId = data['chatId']?.toString() ?? '';
      final userId = data['userId']?.toString() ?? '';
      if (userId != currentUserId && chatId.isNotEmpty) {
        typingUsers[chatId] = userId;
      }
    });

    socketService.on('user_stop_typing', (data) {
      if (data == null) return;
      final chatId = data['chatId']?.toString() ?? '';
      typingUsers.remove(chatId);
    });

    // ── Message Seen ─────────────────────────────────────────────────
    socketService.on('message_seen', (data) {
      if (data == null) return;
      final chatId = data['chatId']?.toString() ?? '';
      final lastMessageId = data['lastMessageId']?.toString() ?? '';
      if (chatId.isNotEmpty && lastMessageId.isNotEmpty) {
        seenMessageIds[chatId] = lastMessageId;
      }
    });

    // ── Online Presence ───────────────────────────────────────────────
    socketService.on('user_online', (data) {
      if (data == null) return;
      final userId = data['userId']?.toString() ?? '';
      if (userId.isNotEmpty) onlineUsers.add(userId);
    });

    socketService.on('user_offline', (data) {
      if (data == null) return;
      final userId = data['userId']?.toString() ?? '';
      onlineUsers.remove(userId);
    });

    socketService.on('online_users_list', (data) {
      if (data == null) return;
      final uids = List<String>.from(data as List);
      onlineUsers.addAll(uids);
    });

    // SocketService handles disconnect logging.
  }

  // ── Public Helpers ────────────────────────────────────────────────────
  bool isUserOnline(String userId) => onlineUsers.contains(userId);

  bool isTypingInChat(String chatId) => typingUsers.containsKey(chatId);

  // ── Typing Emit (with debounce) ───────────────────────────────────────
  void onUserTyping(String chatId) {
    if (!_isCurrentlyTyping) {
      _isCurrentlyTyping = true;
      if (Get.isRegistered<SocketService>()) {
        Get.find<SocketService>().emit('typing_start', {
          'chatId': chatId,
          'userId': currentUserId,
        });
      }
    }
    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = Timer(const Duration(seconds: 2), () {
      _isCurrentlyTyping = false;
      if (Get.isRegistered<SocketService>()) {
        Get.find<SocketService>().emit('typing_stop', {
          'chatId': chatId,
          'userId': currentUserId,
        });
      }
    });
  }

  void stopTyping(String chatId) {
    _typingDebounceTimer?.cancel();
    if (_isCurrentlyTyping) {
      _isCurrentlyTyping = false;
      if (Get.isRegistered<SocketService>()) {
        Get.find<SocketService>().emit('typing_stop', {
          'chatId': chatId,
          'userId': currentUserId,
        });
      }
    }
  }

  // ── Mark Seen ─────────────────────────────────────────────────────────
  void _emitMarkSeen(String chatId, String lastMessageId) {
    if (Get.isRegistered<SocketService>()) {
      Get.find<SocketService>().emit('mark_seen', {
        'chatId': chatId,
        'lastMessageId': lastMessageId,
        'seenByUid': currentUserId,
      });
    }
  }

  void markChatAsSeen(String chatId) {
    if (currentMessages.isEmpty) return;
    final lastMsg = currentMessages.first;
    if (lastMsg.senderId != currentUserId) {
      _emitMarkSeen(chatId, lastMsg.id);
    }
  }

  void _requestOnlineUsers() {
    final uids = chatRooms.map((r) => r.otherUserUid).toList();
    if (uids.isNotEmpty) {
      if (Get.isRegistered<SocketService>()) {
        Get.find<SocketService>().emit('get_online_users', uids);
      }
    }
  }

  // ── Chat Room & Join/Leave ────────────────────────────────────────────
  void joinChat(String chatId) {
    _currentActiveChatId = chatId;
    if (Get.isRegistered<SocketService>()) {
      Get.find<SocketService>().emit('join_chat', chatId);
    }
  }

  void leaveChat(String chatId) {
    stopTyping(chatId);
    _currentActiveChatId = null;
  }

  bool _isFetchingRooms = false;

  Future<void> fetchChatRooms({
    bool isRefresh = false,
    bool isLoadMore = false,
  }) async {
    if (_isFetchingRooms) return;

    if (isRefresh) {
      _roomPage = 1;
      hasMoreRooms.value = true;
    }

    if (isLoadMore) {
      isFetchingMoreRooms.value = true;
    } else {
      if (!isRefresh) isLoadingRooms.value = true;
    }

    _isFetchingRooms = true;

    if (!isLoadMore && _roomPage == 1) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cached = prefs.getString('cached_chat_rooms');
        if (cached != null && chatRooms.isEmpty) {
          final List<dynamic> decoded = jsonDecode(cached);
          chatRooms.assignAll(
            decoded.map((e) => ChatRoomModel.fromMap(e)).toList(),
          );
          isLoadingRooms.value = false;
        }
      } catch (e) {
        AppLogger.e('Cache error chat rooms: $e', e, null, 'CHAT_CTRL');
      }
    }

    try {
      final response = await _apiService.dio.get(
        '/chats',
        queryParameters: {'page': _roomPage, 'limit': _roomLimit},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final newRooms = data.map((e) => ChatRoomModel.fromMap(e)).toList();

        if (isRefresh || (!isLoadMore && _roomPage == 1)) {
          chatRooms.assignAll(newRooms);
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('cached_chat_rooms', jsonEncode(data));
          } catch (_) {}
        } else {
          for (var room in newRooms) {
            if (!chatRooms.any((c) => c.id == room.id)) {
              chatRooms.add(room);
            }
          }
        }

        if (newRooms.length < _roomLimit) {
          hasMoreRooms.value = false;
        } else {
          _roomPage++;
        }

        _requestOnlineUsers();
      }
    } catch (e) {
      AppLogger.e('Failed to fetch chat rooms: $e', e, null, 'CHAT_CTRL');
    } finally {
      isLoadingRooms.value = false;
      isFetchingMoreRooms.value = false;
      _isFetchingRooms = false;
    }
  }

  Future<void> fetchMessages(String chatId) async {
    isLoadingMessages.value = true;
    hasMoreMessages.value = true;
    _messageOffset = 0;
    currentMessages.clear();
    seenMessageIds.remove(chatId);

    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_messages_$chatId');
      if (cached != null) {
        final List<dynamic> decoded = jsonDecode(cached);
        final msgs = decoded.map((e) => MessageModel.fromMap(e)).toList();
        currentMessages.assignAll(msgs.reversed.toList());
        isLoadingMessages.value = false;
      }
    } catch (e) {
      AppLogger.e('Cache error messages: $e', e, null, 'CHAT_CTRL');
    }

    try {
      final response = await _apiService.dio.get(
        '/chats/$chatId/messages',
        queryParameters: {'limit': _messageLimit, 'offset': _messageOffset},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final msgs = data.map((e) => MessageModel.fromMap(e)).toList();
        currentMessages.assignAll(msgs.reversed.toList());

        if (msgs.length < _messageLimit) {
          hasMoreMessages.value = false;
        } else {
          _messageOffset += _messageLimit;
        }

        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cached_messages_$chatId', jsonEncode(data));
        } catch (_) {}
      }
    } catch (e) {
      AppLogger.e('Failed to fetch messages: $e', e, null, 'CHAT_CTRL');
    } finally {
      isLoadingMessages.value = false;
      markChatAsSeen(chatId);
    }
  }

  Future<void> fetchNewMessagesSilently(String chatId) async {
    try {
      final response = await _apiService.dio.get(
        '/chats/$chatId/messages',
        queryParameters: {'limit': 15, 'offset': 0},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final msgs = data
            .map((e) => MessageModel.fromMap(e))
            .toList()
            .reversed
            .toList();

        bool addedNew = false;
        for (var msg in msgs) {
          if (!currentMessages.any((m) => m.id.isNotEmpty && m.id == msg.id)) {
            // Remove optimistic duplicate if exists, matching text and media
            currentMessages.removeWhere(
              (m) =>
                  m.id.startsWith('temp_') &&
                  m.senderId == msg.senderId &&
                  m.text == msg.text &&
                  m.imageUrl == msg.imageUrl &&
                  m.videoUrl == msg.videoUrl,
            );
            currentMessages.insert(0, msg);
            addedNew = true;
          }
        }

        if (addedNew) {
          markChatAsSeen(chatId);
          fetchChatRooms(); // Update recent chat list preview
        }
      }
    } catch (e) {
      AppLogger.e(
        'Failed to silently fetch messages: $e',
        e,
        null,
        'CHAT_CTRL',
      );
    }
  }

  Future<void> loadMoreMessages(String chatId) async {
    if (isFetchingMoreMessages.value || !hasMoreMessages.value) return;
    isFetchingMoreMessages.value = true;

    try {
      final response = await _apiService.dio.get(
        '/chats/$chatId/messages',
        queryParameters: {'limit': _messageLimit, 'offset': _messageOffset},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final msgs = data.map((e) => MessageModel.fromMap(e)).toList();

        if (msgs.length < _messageLimit) {
          hasMoreMessages.value = false;
        } else {
          _messageOffset += _messageLimit;
        }
        currentMessages.addAll(msgs.reversed.toList());
      }
    } catch (e) {
      AppLogger.e('Failed to load more messages: $e', e, null, 'CHAT_CTRL');
    } finally {
      isFetchingMoreMessages.value = false;
    }
  }

  Future<String> createOrGetChatRoom(
    String targetUserId,
    String targetUserName,
    String? targetUserPhoto,
  ) async {
    try {
      final response = await _apiService.dio.post(
        '/chats',
        data: {'targetUserId': targetUserId},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final chatId = response.data['chatId'];
        fetchChatRooms();
        return chatId;
      }
      throw 'Failed to create chat room';
    } catch (e) {
      AppLogger.e('Create chat room error: $e', e, null, 'CHAT_CTRL');
      throw 'Cannot start chat';
    }
  }

  Future<void> sendMessage(
    String chatRoomId,
    String text,
    String targetUserId, {
    String? imageUrl,
    String? videoUrl,
  }) async {
    if (text.trim().isEmpty &&
        (imageUrl == null || imageUrl.isEmpty) &&
        (videoUrl == null || videoUrl.isEmpty)) {
      return;
    }

    stopTyping(chatRoomId);

    final replyId = replyMessage.value?.id;
    final replyText = replyMessage.value?.text;
    final replySender = replyMessage.value?.senderId;

    // Optimistic UI
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMsg = MessageModel(
      id: tempId,
      senderId: currentUserId,
      text: text.trim(),
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      createdAt: DateTime.now(),
      isRead: false,
      replyToMessageId: replyId,
      replyToMessageText: replyText,
      replyToMessageSender: replySender,
    );

    // Always insert optimistic UI, even for media, since the URL is already uploaded
    currentMessages.insert(0, optimisticMsg);
    
    _scrollToBottom();

    // Clear reply state
    replyMessage.value = null;

    try {
      isSending.value = true;

      if (Get.isRegistered<SocketService>()) {
        Get.find<SocketService>().emit('send_message', {
          'chatId': chatRoomId,
          'senderUid': currentUserId,
          'targetUid': targetUserId,
          'text': text.trim(),
          'imageUrl': ?imageUrl,
          'videoUrl': ?videoUrl,
          'replyToMessageId': ?replyId,
          'replyToMessageText': ?replyText,
          'replyToMessageSender': ?replySender,
        });
      }

      try {
        final currentUserName =
            Get.find<AuthController>().currentUser.value?.name ?? 'Someone';
        final String messagePreview;
        if (videoUrl != null) {
          messagePreview = text.isNotEmpty
              ? '🎥 ${text.trim()}'
              : '🎥 Sent a video';
        } else if (imageUrl != null) {
          messagePreview = text.isNotEmpty
              ? '📷 ${text.trim()}'
              : '📷 Sent an image';
        } else {
          messagePreview = text.trim();
        }
        NotificationService()
            .sendAndStore(
              receiverUid: targetUserId,
              title: 'New Message from $currentUserName',
              body: messagePreview,
              type: NotificationType.general,
              senderUid: currentUserId,
              relatedId: chatRoomId,
              extraData: {'type': 'chat', 'chatRoomId': chatRoomId},
            )
            .catchError((e) {
              debugPrint('Notification error: $e');
            });
      } catch (e) {
        // ignore notification errors
      }
    } finally {
      isSending.value = false;
    }
  }

  bool _isPickingMedia = false;

  Future<void> sendImageMessage(String chatRoomId, String targetUserId) async {
    if (_isPickingMedia) return;
    _isPickingMedia = true;

    try {
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
                            width: images.length == 1
                                ? Get.width - 32
                                : Get.width * 0.7,
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
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => Get.back(
                          result: {'send': true, 'text': textCtrl.text},
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: const BoxDecoration(
                            color: Color(0xFF059669),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                          ),
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
          final imageUrl = await MediaUploadService().uploadImage(image.path);
          if (imageUrl != null) {
            await sendMessage(
              chatRoomId,
              result['text'] ?? '',
              targetUserId,
              imageUrl: imageUrl,
            );
          }
        }
        isSending.value = false;
      }
    } catch (e) {
      AppLogger.e('Error picking images: $e', e, null, 'CHAT_CTRL');
    } finally {
      _isPickingMedia = false;
    }
  }

  Future<void> sendVideoMessage(String chatRoomId, String targetUserId) async {
    if (_isPickingMedia) return;
    _isPickingMedia = true;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
      if (video == null) return;

      isSending.value = true;
      try {
        final videoUrl = await MediaUploadService().uploadVideo(video.path);
        if (videoUrl != null) {
          await sendMessage(chatRoomId, '', targetUserId, videoUrl: videoUrl);
        } else {
          Get.snackbar(
            'Upload Failed',
            'Could not upload video. Please try again.',
          );
        }
      } catch (e) {
        AppLogger.e('Error uploading video: $e', e, null, 'CHAT_CTRL');
        Get.snackbar('Error', 'An error occurred while sending video.');
      } finally {
        isSending.value = false;
      }
    } catch (e) {
      AppLogger.e('Error picking video: $e', e, null, 'CHAT_CTRL');
    } finally {
      _isPickingMedia = false;
    }
  }

  Future<void> toggleReaction(
    String chatRoomId,
    String messageId,
    String emoji,
  ) async {
    try {
      final index = currentMessages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final old = currentMessages[index];
        final reactions = Map<String, String>.from(old.reactions ?? {});
        if (reactions[currentUserId] == emoji) {
          reactions.remove(currentUserId);
        } else {
          reactions[currentUserId] = emoji;
        }
        currentMessages[index] = old.copyWith(reactions: reactions);
      }

      if (Get.isRegistered<SocketService>()) {
        Get.find<SocketService>().emit('react_message', {
          'chatId': chatRoomId,
          'messageId': messageId,
          'emoji': emoji,
          'uid': currentUserId,
        });
      }

      try {
        await _apiService.dio.put(
          '/chats/$chatRoomId/messages/$messageId/react',
          data: {'emoji': emoji},
        );
      } catch (e) {
        debugPrint('REST react error: $e');
      }
    } catch (e) {
      AppLogger.e('Error toggling reaction: $e', e, null, 'CHAT_CTRL');
    }
  }

  Future<void> editMessage(
    String chatRoomId,
    String messageId,
    String newText,
  ) async {
    if (newText.trim().isEmpty) return;
    try {
      final index = currentMessages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final old = currentMessages[index];
        currentMessages[index] = old.copyWith(
          text: newText.trim(),
          isEdited: true,
        );
      }

      if (Get.isRegistered<SocketService>()) {
        Get.find<SocketService>().emit('edit_message', {
          'chatId': chatRoomId,
          'messageId': messageId,
          'text': newText.trim(),
          'senderUid': currentUserId,
        });
      }

      try {
        await _apiService.dio.put(
          '/chats/$chatRoomId/messages/$messageId',
          data: {'text': newText.trim()},
        );
      } catch (e) {
        debugPrint('REST edit error: $e');
      }
    } catch (e) {
      AppLogger.e('Error editing message: $e', e, null, 'CHAT_CTRL');
    }
  }

  Future<void> deleteMessage(String chatRoomId, String messageId) async {
    try {
      final index = currentMessages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final old = currentMessages[index];
        currentMessages[index] = MessageModel(
          id: old.id,
          senderId: old.senderId,
          text: '',
          isDeleted: true,
          createdAt: old.createdAt,
          isRead: old.isRead,
          isEdited: old.isEdited,
          reactions: old.reactions,
        );
        currentMessages.refresh();
      }

      if (Get.isRegistered<SocketService>()) {
        Get.find<SocketService>().emit('delete_message', {
          'chatId': chatRoomId,
          'messageId': messageId,
          'senderUid': currentUserId,
        });
      }

      try {
        await _apiService.dio.delete('/chats/$chatRoomId/messages/$messageId');
      } catch (e) {
        debugPrint('REST delete error: $e');
      }
    } catch (e) {
      AppLogger.e('Error deleting message: $e', e, null, 'CHAT_CTRL');
    }
  }

  Future<void> markMessagesAsRead(String chatRoomId) async {
    markChatAsSeen(chatRoomId);
  }
}
