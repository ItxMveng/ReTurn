class Conversation {
  final String roomId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String? lastMessage;
  final DateTime? lastAt;
  final int unread;

  const Conversation({
    required this.roomId,
    required this.otherUserName,
    this.otherUserAvatar,
    this.lastMessage,
    this.lastAt,
    this.unread = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        roomId: j['room_id'] as String,
        otherUserName: j['other_user_name'] as String,
        otherUserAvatar: j['other_user_avatar'] as String?,
        lastMessage: j['last_message'] as String?,
        lastAt: j['last_at'] != null
            ? DateTime.parse(j['last_at'] as String)
            : null,
        unread: (j['unread'] as int?) ?? 0,
      );
}

class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool isMe;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.isMe,
    this.isRead = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j, String myId) =>
      ChatMessage(
        id: j['id'] as String,
        // Le backend renvoie `match_id` (un match = une room de chat).
        roomId: (j['room_id'] ?? j['match_id']) as String,
        senderId: j['sender_id'] as String,
        content: j['content'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
        isMe: j['sender_id'] == myId,
        isRead: j['is_read'] as bool? ?? false,
      );
}
