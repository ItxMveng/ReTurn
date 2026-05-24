import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/storage/hive_storage.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import 'auth_state.dart';

part 'auth_notifier.g.dart';

/// Notifier principal — gère l’état global de session
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    _checkInitialAuth();
    return const AuthState.initial();
  }

  /// Vérifie si un token valide existe au démarrage
  Future<void> _checkInitialAuth() async {
    state = const AuthState.checking();
    try {
      final repo = ref.read(authRepositoryProvider);
      final isAuth = await repo.isAuthenticated();
      if (!isAuth) {
        state = const AuthState.unauthenticated();
        return;
      }
      // Token présent : on récupère le profil
      final user = await repo.getMe();
      // Cache le profil offline
      ref.read(hiveStorageProvider).cacheProfile(user.toJson());
      state = AuthState.authenticated(user);
    } catch (_) {
      // En cas d’erreur réseau, tenter de lire le cache
      final cached = ref.read(hiveStorageProvider).getCachedProfile();
      if (cached != null) {
        try {
          state = AuthState.authenticated(UserModel.fromJson(cached));
          return;
        } catch (_) {}
      }
      state = const AuthState.unauthenticated();
    }
  }

  /// Appelé après un OTP vérifié avec succès
  Future<void> onOtpVerified() async {
    state = const AuthState.loading();
    try {
      final user = await ref.read(authRepositoryProvider).getMe();
      ref.read(hiveStorageProvider).cacheProfile(user.toJson());
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(friendlyError(e));
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    state = const AuthState.loading();
    try {
      await ref.read(authRepositoryProvider).logout();
      await ref.read(hiveStorageProvider).clearAll();
      state = const AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(friendlyError(e));
    }
  }

  /// Expose l’utilisateur courant (ou null)
  UserModel? get currentUser => state.whenOrNull(authenticated: (u) => u);
}

/// Notifier dédié au flux OTP (requête + vérification)
@riverpod
class OtpNotifier extends _$OtpNotifier {
  @override
  OtpState build() => const OtpState.idle();

  /// Demande l’envoi de l’OTP
  Future<void> requestOtp(String phoneNumber) async {
    state = const OtpState.sending();
    try {
      await ref.read(authRepositoryProvider).requestOtp(phoneNumber);
      state = OtpState.sent(phoneNumber);
    } catch (e) {
      state = OtpState.error(friendlyError(e));
    }
  }

  /// Vérifie le code OTP saisi
  Future<bool> verifyOtp({
    required String phoneNumber,
    required String otpCode,
  }) async {
    state = const OtpState.verifying();
    try {
      await ref.read(authRepositoryProvider).verifyOtp(
        phoneNumber: phoneNumber,
        otpCode: otpCode,
      );
      state = const OtpState.verified();
      // Met à jour la session globale
      await ref.read(authNotifierProvider.notifier).onOtpVerified();
      return true;
    } catch (e) {
      state = OtpState.error(friendlyError(e));
      return false;
    }
  }

  void reset() => state = const OtpState.idle();
}
