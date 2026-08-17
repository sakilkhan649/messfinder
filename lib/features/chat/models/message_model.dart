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
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['message_id']?.toString() ?? '',
      senderId: map['sender_uid']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      imageUrl: map['image_url']?.toString(),
      videoUrl: map['video_url']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      isRead: map['is_read'] ?? false,
      isEdited: map['is_edited'] ?? false,
      isDeleted: map['is_deleted'] ?? false,
      reactions: map['reactions'] != null ? Map<String, String>.from(map['reactions']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender_uid': senderId,
      'text': text,
      if (imageUrl != null) 'image_url': imageUrl,
      if (videoUrl != null) 'video_url': videoUrl,
      'is_read': isRead,
    };
  }
}
