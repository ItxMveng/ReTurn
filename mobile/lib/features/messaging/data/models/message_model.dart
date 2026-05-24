import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_model.freezed.dart';
part 'message_model.g.dart';

@freezed
class MessageModel with _$MessageModel {
  const factory MessageModel({
    required String id,
    @JsonKey(name: 'conversation_id') required String conversationId,
    @JsonKey(name: 'sender_id') required String senderId,
    required String content,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'is_read') @Default(false) bool isRead,
  }) = _MessageModel;

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);
}

@freezed
class ConversationModel with _$ConversationModel {
  const factory ConversationModel({
    required String id,
    @JsonKey(name: 'match_id') required String matchId,
    @JsonKey(name: 'other_user_name') String? otherUserName,
    @JsonKey(name: 'last_message') String? lastMessage,
    @JsonKey(name: 'unread_count') @Default(0) int unreadCount,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _ConversationModel;

  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      _$ConversationModelFromJson(json);
}
