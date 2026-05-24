class Conversation {
  final String roomId;
  final String otherUserName;
  final String? lastMessage;
  final DateTime? lastAt;
  final int unread;

  const Conversation({
    required this.roomId,
    required this.otherUserName,
    this.lastMessage,
    this.lastAt,
    this.unread = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        roomId: j['room_id'] as String,
        otherUserName: j['other_user_name'] as String,
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

  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.isMe,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j, String myId) =>
      ChatMessage(
        id: j['id'] as String,
        roomId: j['room_id'] as String,
        senderId: j['sender_id'] as String,
        content: j['content'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
        isMe: j['sender_id'] == myId,
      );
}
