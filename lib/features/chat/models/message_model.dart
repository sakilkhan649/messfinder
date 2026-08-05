import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime? createdAt;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.createdAt,
    this.isRead = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String docId) {
    return MessageModel(
      id: docId,
      senderId: map['senderId']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      createdAt: map['createdAt'] != null && map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }
}
