import 'package:freezed_annotation/freezed_annotation.dart';
import '../data/models/user_model.dart';

part 'auth_state.freezed.dart';

/// États possibles du flux d’authentification
@freezed
class AuthState with _$AuthState {
  /// Initial — pas encore vérifié
  const factory AuthState.initial() = AuthInitial;

  /// Vérification de l’état de connexion en cours
  const factory AuthState.checking() = AuthChecking;

  /// Utilisateur connecté
  const factory AuthState.authenticated(UserModel user) = AuthAuthenticated;

  /// Utilisateur non connecté
  const factory AuthState.unauthenticated() = AuthUnauthenticated;

  /// Opération en cours (login/logout)
  const factory AuthState.loading() = AuthLoading;

  /// Erreur survenue
  const factory AuthState.error(String message) = AuthError;
}

/// États spécifiques au flux OTP
@freezed
class OtpState with _$OtpState {
  const factory OtpState.idle() = OtpIdle;
  const factory OtpState.sending() = OtpSending;
  const factory OtpState.sent(String phoneNumber) = OtpSent;
  const factory OtpState.verifying() = OtpVerifying;
  const factory OtpState.verified() = OtpVerified;
  const factory OtpState.error(String message) = OtpError;
}
