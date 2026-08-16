import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final String? imageUrl;
  final DateTime? createdAt;
  final bool isRead;
  final bool isEdited;
  final bool isDeleted;
  final Map<String, String>? reactions;
  final String? stickerUrl;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.imageUrl,
    this.createdAt,
    this.isRead = false,
    this.isEdited = false,
    this.isDeleted = false,
    this.reactions,
    this.stickerUrl,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String docId) {
    return MessageModel(
      id: docId,
      senderId: map['senderId']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString(),
      createdAt: map['createdAt'] != null && map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      isRead: map['isRead'] ?? false,
      isEdited: map['isEdited'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      reactions: map['reactions'] != null ? Map<String, String>.from(map['reactions']) : null,
      stickerUrl: map['stickerUrl']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'isRead': isRead,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      if (reactions != null) 'reactions': reactions,
      if (stickerUrl != null) 'stickerUrl': stickerUrl,
    };
  }
}
