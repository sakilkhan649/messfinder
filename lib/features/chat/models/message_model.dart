class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final String? imageUrl;
  final String? videoUrl;
  final DateTime? createdAt;
  final bool isRead;
  final bool isEdited;
  final bool isDeleted;
  final String? stickerUrl;
  final Map<String, String>? reactions;
  final String? replyToMessageId;
  final String? replyToMessageText;
  final String? replyToMessageSender;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.imageUrl,
    this.videoUrl,
    this.createdAt,
    this.isRead = false,
    this.isEdited = false,
    this.isDeleted = false,
    this.stickerUrl,
    this.reactions,
    this.replyToMessageId,
    this.replyToMessageText,
    this.replyToMessageSender,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is String && val.isNotEmpty) {
        try { return DateTime.parse(val); } catch (_) { return null; }
      }
      return null;
    }

    return MessageModel(
      id: (map['message_id'] ?? map['id'] ?? map['_id'])?.toString() ?? '',
      senderId: (map['sender_uid'] ?? map['senderId'] ?? map['sender_id'])?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      imageUrl: (map['image_url'] ?? map['imageUrl'])?.toString(),
      videoUrl: (map['video_url'] ?? map['videoUrl'])?.toString(),
      createdAt: parseDate(map['created_at'] ?? map['createdAt']),
      isRead: map['is_read'] ?? map['isRead'] ?? false,
      isEdited: map['is_edited'] ?? map['isEdited'] ?? false,
      isDeleted: map['is_deleted'] ?? map['isDeleted'] ?? false,
      stickerUrl: (map['sticker_url'] ?? map['stickerUrl'])?.toString(),
      reactions: map['reactions'] != null ? Map<String, String>.from(map['reactions']) : null,
      replyToMessageId: (map['reply_to_message_id'] ?? map['replyToMessageId'])?.toString(),
      replyToMessageText: (map['reply_to_message_text'] ?? map['replyToMessageText'])?.toString(),
      replyToMessageSender: (map['reply_to_message_sender'] ?? map['replyToMessageSender'])?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender_uid': senderId,
      'text': text,
      if (imageUrl != null) 'image_url': imageUrl,
      if (videoUrl != null) 'video_url': videoUrl,
      'is_read': isRead,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (replyToMessageText != null) 'replyToMessageText': replyToMessageText,
      if (replyToMessageSender != null) 'replyToMessageSender': replyToMessageSender,
    };
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? text,
    String? imageUrl,
    String? videoUrl,
    DateTime? createdAt,
    bool? isRead,
    bool? isEdited,
    bool? isDeleted,
    String? stickerUrl,
    Map<String, String>? reactions,
    String? replyToMessageId,
    String? replyToMessageText,
    String? replyToMessageSender,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      stickerUrl: stickerUrl ?? this.stickerUrl,
      reactions: reactions ?? this.reactions,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToMessageText: replyToMessageText ?? this.replyToMessageText,
      replyToMessageSender: replyToMessageSender ?? this.replyToMessageSender,
    );
  }
}
