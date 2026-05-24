import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// Correspond à UserRead du backend
@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String id,
    @JsonKey(name: 'phone_number') String? phoneNumber,
    String? email,
    @JsonKey(name: 'display_name') String? displayName,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'is_active', defaultValue: true) required bool isActive,
    @JsonKey(name: 'is_verified', defaultValue: false) required bool isVerified,
    @JsonKey(name: 'reputation_score', defaultValue: 0.0) required double reputationScore,
    @JsonKey(name: 'total_restitutions', defaultValue: 0) required int totalRestitutions,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
