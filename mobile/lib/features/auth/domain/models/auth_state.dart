import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.codeSent({
    required String verificationId,
    required String phoneNumber,
    int? resendToken,
  }) = _CodeSent;
  const factory AuthState.verified({required String uid}) = _Verified;
  const factory AuthState.authenticated({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) = _Authenticated;
  const factory AuthState.error({
    required String message,
    required AuthErrorType type,
  }) = _Error;
}

enum AuthErrorType {
  invalidPhone,
  invalidCode,
  tooManyRequests,
  networkError,
  serverError,
  unknown,
}
