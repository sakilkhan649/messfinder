class ChatRoomModel {
  final String id;
  final String otherUserUid;
  final String otherUserName;
  final String otherUserPhoto;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final List<String> participants;
  final Map<String, int> unreadCounts;

  ChatRoomModel({
    required this.id,
    required this.otherUserUid,
    required this.otherUserName,
    required this.otherUserPhoto,
    required this.lastMessage,
    this.lastMessageTime,
    this.participants = const [],
    this.unreadCounts = const {},
  });

  factory ChatRoomModel.fromMap(Map<String, dynamic> map) {
    String photoUrl = map['other_user_image']?.toString() ?? 
        map['other_user_photo']?.toString() ?? 
        map['profile_image']?.toString() ?? 
        map['photoUrl']?.toString() ?? '';
        
    if (photoUrl.startsWith('http://') && !photoUrl.contains('localhost')) {
      photoUrl = photoUrl.replaceFirst('http://', 'https://');
    }
    
    return ChatRoomModel(
      id: map['chat_id']?.toString() ?? '',
      otherUserUid: map['other_user_uid']?.toString() ?? '',
      otherUserName: map['other_user_name']?.toString() ?? 'Unknown',
      otherUserPhoto: photoUrl,
      lastMessage: map['last_message']?.toString() ?? '',
      lastMessageTime: map['last_message_time'] != null
          ? DateTime.parse(map['last_message_time'])
          : null,
      participants: [map['other_user_uid']?.toString() ?? ''],
      unreadCounts: const {},
    );
  }
}
