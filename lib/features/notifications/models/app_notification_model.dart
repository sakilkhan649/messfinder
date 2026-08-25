import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  newPost,
  bookingRequest,
  bookingApproved,
  bookingRejected,
  paymentVerified,
  adminBroadcast,
  call,
  chat,
  general,
}

class AppNotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final String receiverUid;
  final String? senderUid;
  final String? relatedId; // postId, bookingId, etc.
  bool isRead;
  final DateTime createdAt;

  AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.receiverUid,
    this.senderUid,
    this.relatedId,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    return AppNotificationModel(
      id: docId,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'general'),
        orElse: () => NotificationType.general,
      ),
      receiverUid: map['receiverUid'] ?? '',
      senderUid: map['senderUid'],
      relatedId: map['relatedId'],
      isRead: map['isRead'] ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type.name,
      'receiverUid': receiverUid,
      if (senderUid != null) 'senderUid': senderUid,
      if (relatedId != null) 'relatedId': relatedId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
