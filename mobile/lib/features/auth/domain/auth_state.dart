import 'package:freezed_annotation/freezed_annotation.dart';
import '../data/models/user_model.dart';

part 'auth_state.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.otpSent({required String phoneNumber}) = _OtpSent;
  const factory AuthState.authenticated({required UserModel user}) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.error({required String message}) = _Error;
}
