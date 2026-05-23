class ChatMessage {
  final String id;
  final String matchId;
  final String senderId;
  final String content;
  final String messageType;
  final bool isRead;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.content,
    required this.messageType,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        matchId: json['match_id'] as String,
        senderId: json['sender_id'] as String,
        content: json['content'] as String,
        messageType: json['message_type'] as String? ?? 'text',
        isRead: json['is_read'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  bool get isSystem => messageType == 'system';
  bool get isLocation => messageType == 'location';
}
