import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:mess_finder/core/utils/api_constants.dart';
import 'package:mess_finder/features/chat/models/chat_room_model.dart';
import 'package:mess_finder/features/chat/models/message_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mess_finder/core/utils/imgbb_service.dart';
import 'package:mess_finder/core/services/notification_service.dart';
import 'package:mess_finder/features/auth/controllers/auth_controller.dart';
import 'package:mess_finder/features/notifications/models/app_notification_model.dart';

class ChatController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  // Creates or gets an existing chat room between current user and target user
  Future<String> createOrGetChatRoom(String targetUserId, String targetUserName, String? targetUserPhoto) async {
    final uid1 = currentUserId;
    final uid2 = targetUserId;
    
    // Create a unique chat room ID
    final chatRoomId = uid1.compareTo(uid2) > 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';

    final docRef = _firestore.collection(ApiConstants.chatsCollection).doc(chatRoomId);
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      // Fetch current user details
      final currentUserDoc = await _firestore.collection(ApiConstants.usersCollection).doc(uid1).get();
      final currentUserName = currentUserDoc.data()?['name']?.toString() ?? 'Unknown User';
      final currentUserPhoto = currentUserDoc.data()?['photoUrl']?.toString();

      // Fetch target user details if not provided
      String finalTargetName = targetUserName;
      String? finalTargetPhoto = targetUserPhoto;
      
      if (finalTargetName.isEmpty || finalTargetName == 'Loading...') {
        final targetUserDoc = await _firestore.collection(ApiConstants.usersCollection).doc(uid2).get();
        finalTargetName = targetUserDoc.data()?['name']?.toString() ?? 'Unknown User';
        finalTargetPhoto = targetUserDoc.data()?['photoUrl']?.toString();
      }

      final chatRoom = ChatRoomModel(
        id: chatRoomId,
        participants: [uid1, uid2],
        participantNames: {
          uid1: currentUserName,
          uid2: finalTargetName,
        },
        participantPhotos: {
          uid1: currentUserPhoto ?? '',
          uid2: finalTargetPhoto ?? '',
        },
        lastMessage: '',
        lastSenderId: '',
        unreadCounts: {uid1: 0, uid2: 0},
      );

      await docRef.set(chatRoom.toMap());
    }

    return chatRoomId;
  }

  // Stream for Chat Rooms list
  Stream<List<ChatRoomModel>> getChatRooms() {
    return _firestore
        .collection(ApiConstants.chatsCollection)
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      final rooms = snapshot.docs.map((doc) => ChatRoomModel.fromMap(doc.data(), doc.id)).toList();
      // Sort locally to avoid requiring a composite index in Firestore
      rooms.sort((a, b) {
        final timeA = a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final timeB = b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return timeB.compareTo(timeA); // descending order
      });
      return rooms;
    });
  }

  // Stream for Messages in a specific chat room
  Stream<List<MessageModel>> getMessages(String chatRoomId) {
    return _firestore
        .collection(ApiConstants.chatsCollection)
        .doc(chatRoomId)
        .collection(ApiConstants.messagesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MessageModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  final RxBool isSending = false.obs;

  Future<void> sendMessage(String chatRoomId, String text, String targetUserId, {String? imageUrl, String? videoUrl}) async {
    if (text.trim().isEmpty && imageUrl == null && videoUrl == null) return;

    try {
      isSending.value = true;
      final messageRef = _firestore
          .collection(ApiConstants.chatsCollection)
          .doc(chatRoomId)
          .collection(ApiConstants.messagesCollection)
          .doc();

      final message = MessageModel(
        id: messageRef.id,
        senderId: currentUserId,
        text: text.trim(),
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        // Omit createdAt to use FieldValue.serverTimestamp() in toMap()
      );

      // Run in batch to ensure both updates happen together
      final batch = _firestore.batch();
      
      batch.set(messageRef, message.toMap());
      
      final chatRef = _firestore.collection(ApiConstants.chatsCollection).doc(chatRoomId);
      final String lastMsgText;
      if (videoUrl != null) {
        lastMsgText = text.isNotEmpty ? '🎥 ${text.trim()}' : '🎥 Video';
      } else if (imageUrl != null) {
        lastMsgText = text.isNotEmpty ? '📷 ${text.trim()}' : '📷 Image';
      } else {
        lastMsgText = text;
      }

      batch.update(chatRef, {
        'lastMessage': lastMsgText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': currentUserId,
        'unreadCounts.$targetUserId': FieldValue.increment(1),
      });

      await batch.commit();
      
      // Send Push Notification (Fire and forget so it doesn't block UI)
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

    // Show Messenger-style preview dialog/bottom sheet
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
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFF059669),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
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
    );

    if (result == null || result['send'] != true) return;

    Get.snackbar(
      'Uploading...',
      'Please wait while your ${images.length > 1 ? 'images are' : 'image is'} being uploaded.',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
    
    isSending.value = true;
    try {
      final imgbbService = ImgbbService();
      
      for (int i = 0; i < images.length; i++) {
        final imageUrl = await imgbbService.uploadImage(images[i].path);
        
        if (imageUrl != null) {
          // Send text only with the first image
          final text = i == 0 ? result['text'] as String : '';
          await sendMessage(chatRoomId, text, targetUserId, imageUrl: imageUrl);
        } else {
          Get.snackbar('Error', 'Failed to upload image ${i + 1}');
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to send images: $e');
    } finally {
      isSending.value = false;
    }
  }

  Future<void> sendVideoMessage(String chatRoomId, String targetUserId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    if (video == null) return;
    
    Get.snackbar(
      'Uploading...',
      'Please wait while your video is being uploaded.',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
    
    isSending.value = true;
    try {
      final imgbbService = Get.put(ImgbbService());
      final videoUrl = await imgbbService.uploadVideo(video.path);
      
      if (videoUrl != null) {
        await sendMessage(chatRoomId, '', targetUserId, videoUrl: videoUrl);
      } else {
        Get.snackbar('Error', 'Failed to upload video');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to send video: $e');
    } finally {
      isSending.value = false;
    }
  }

  Future<void> editMessage(String chatRoomId, String messageId, String newText) async {
    if (newText.trim().isEmpty) return;
    try {
      await _firestore
          .collection(ApiConstants.chatsCollection)
          .doc(chatRoomId)
          .collection(ApiConstants.messagesCollection)
          .doc(messageId)
          .update({
        'text': newText.trim(),
        'isEdited': true,
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to edit message');
    }
  }

  Future<void> deleteMessage(String chatRoomId, String messageId) async {
    try {
      await _firestore
          .collection(ApiConstants.chatsCollection)
          .doc(chatRoomId)
          .collection(ApiConstants.messagesCollection)
          .doc(messageId)
          .update({
        'isDeleted': true,
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete message');
    }
  }

  Future<void> toggleReaction(String chatRoomId, String messageId, String emoji) async {
    try {
      final docRef = _firestore
          .collection(ApiConstants.chatsCollection)
          .doc(chatRoomId)
          .collection(ApiConstants.messagesCollection)
          .doc(messageId);

      final docSnap = await docRef.get();
      if (!docSnap.exists) return;
      
      final data = docSnap.data();
      Map<String, dynamic> reactions = data?['reactions'] != null 
          ? Map<String, dynamic>.from(data!['reactions']) 
          : {};

      if (reactions[currentUserId] == emoji) {
        // If the same emoji is clicked, remove the reaction
        reactions.remove(currentUserId);
      } else {
        // Add or update the reaction
        reactions[currentUserId] = emoji;
      }

      await docRef.update({
        'reactions': reactions.isEmpty ? FieldValue.delete() : reactions,
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to update reaction');
    }
  }

  Future<void> sendSticker(String chatRoomId, String targetUserId, String stickerUrl) async {
    try {
      isSending.value = true;
      final messageRef = _firestore
          .collection(ApiConstants.chatsCollection)
          .doc(chatRoomId)
          .collection(ApiConstants.messagesCollection)
          .doc();

      final message = MessageModel(
        id: messageRef.id,
        senderId: currentUserId,
        text: '',
        stickerUrl: stickerUrl,
      );

      final batch = _firestore.batch();
      batch.set(messageRef, message.toMap());
      
      final chatRef = _firestore.collection(ApiConstants.chatsCollection).doc(chatRoomId);
      
      batch.update(chatRef, {
        'lastMessage': 'Sent a sticker',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': currentUserId,
        'unreadCounts.$targetUserId': FieldValue.increment(1),
      });

      await batch.commit();
      
      // Send Push Notification
      try {
        final currentUserName = Get.find<AuthController>().currentUser.value?.name ?? 'Someone';
        await NotificationService().sendAndStore(
          receiverUid: targetUserId,
          title: 'New Message from $currentUserName',
          body: 'Sent a sticker',
          type: NotificationType.general,
          senderUid: currentUserId,
          relatedId: chatRoomId,
          extraData: {'type': 'chat', 'chatRoomId': chatRoomId},
        );
      } catch (e) {
        // ignore notification errors
      }
    } finally {
      isSending.value = false;
    }
  }

  Future<void> markMessagesAsRead(String chatRoomId) async {
    final chatRoomRef = _firestore.collection(ApiConstants.chatsCollection).doc(chatRoomId);
    await chatRoomRef.update({
      'unreadCounts.$currentUserId': 0,
    });
  }
}
