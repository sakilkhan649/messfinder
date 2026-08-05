import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:mess_finder/core/utils/api_constants.dart';
import 'package:mess_finder/features/chat/models/chat_room_model.dart';
import 'package:mess_finder/features/chat/models/message_model.dart';

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
          if (currentUserPhoto != null) uid1: currentUserPhoto,
          if (finalTargetPhoto != null) uid2: finalTargetPhoto,
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

  Future<void> sendMessage(String chatRoomId, String text, String targetUserId) async {
    if (text.trim().isEmpty) return;

    final messageRef = _firestore
        .collection(ApiConstants.chatsCollection)
        .doc(chatRoomId)
        .collection(ApiConstants.messagesCollection)
        .doc();

    final message = MessageModel(
      id: messageRef.id,
      senderId: currentUserId,
      text: text.trim(),
    );

    // Run transaction or batch to update message and last message info in chat room
    final batch = _firestore.batch();
    
    batch.set(messageRef, message.toMap());
    
    final chatRoomRef = _firestore.collection(ApiConstants.chatsCollection).doc(chatRoomId);
    batch.update(chatRoomRef, {
      'lastMessage': text.trim(),
      'lastSenderId': currentUserId,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCounts.$targetUserId': FieldValue.increment(1),
    });

    await batch.commit();
  }

  Future<void> markMessagesAsRead(String chatRoomId) async {
    final chatRoomRef = _firestore.collection(ApiConstants.chatsCollection).doc(chatRoomId);
    await chatRoomRef.update({
      'unreadCounts.$currentUserId': 0,
    });
  }
}
