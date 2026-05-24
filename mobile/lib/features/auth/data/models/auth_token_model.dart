import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_token_model.freezed.dart';
part 'auth_token_model.g.dart';

/// Correspond à la réponse TokenResponse du backend
@freezed
class AuthTokenModel with _$AuthTokenModel {
  const factory AuthTokenModel({
    @JsonKey(name: 'access_token')  required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
    @JsonKey(name: 'token_type', defaultValue: 'bearer') required String tokenType,
    @JsonKey(name: 'is_new_user', defaultValue: false) required bool isNewUser,
  }) = _AuthTokenModel;

  factory AuthTokenModel.fromJson(Map<String, dynamic> json) =>
      _$AuthTokenModelFromJson(json);
}
