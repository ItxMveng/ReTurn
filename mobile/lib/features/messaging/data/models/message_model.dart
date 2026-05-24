import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_model.freezed.dart';
part 'message_model.g.dart';

@freezed
class MessageModel with _$MessageModel {
  const factory MessageModel({
    required String id,
    @JsonKey(name: 'match_id')  required String matchId,
    @JsonKey(name: 'sender_id') required String senderId,
    @JsonKey(name: 'content')   required String content,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'is_read', defaultValue: false) required bool isRead,
  }) = _MessageModel;

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);
}
