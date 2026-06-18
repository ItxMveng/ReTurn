import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/repositories/auth_repository.dart';
import '../../../shared/widgets/guided_tour.dart';
import 'auth_state.dart';

part 'auth_notifier.g.dart';

// ─── Provider OTP (flux envoi/vérification OTP) ───────────────────────────────
@riverpod
class OtpNotifier extends _$OtpNotifier {
  @override
  OtpState build() => const OtpState.idle();

  Future<void> requestOtp(String phoneNumber) async {
    state = const OtpState.sending();
    try {
      await ref.read(authRepositoryProvider).requestOtp(phoneNumber);
      state = OtpState.sent(phoneNumber);
    } catch (e) {
      state = OtpState.error(e.toString());
    }
  }

  /// Retourne true si la vérification a réussi
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
      // Met à jour le AuthNotifier après vérification réussie
      await ref.read(authNotifierProvider.notifier).checkAuth();
      state = const OtpState.verified();
      return true;
    } catch (e) {
      state = OtpState.error(e.toString());
      return false;
    }
  }
}

// ─── Provider AUTH (état de session utilisateur) ──────────────────────────────
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    // Vérifie la session au démarrage
    Future.microtask(checkAuth);
    return const AuthState.initial();
  }

  Future<void> checkAuth() async {
    state = const AuthState.checking();
    final isAuth = await ref.read(authRepositoryProvider).isAuthenticated();
    if (isAuth) {
      try {
        final user = await ref.read(authRepositoryProvider).getMe();
        state = AuthState.authenticated(user);
      } catch (_) {
        state = const AuthState.unauthenticated();
      }
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AuthState.loading();
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        state = const AuthState.unauthenticated();
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCred.user?.getIdToken();
      if (idToken == null) throw Exception('Token Firebase introuvable');

      await ref.read(authRepositoryProvider).loginWithFirebase(idToken);
      await checkAuth();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> logout() async {
    await resetTourFlag(); // prochain login → tour visible
    await ref.read(authRepositoryProvider).logout();
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    state = const AuthState.unauthenticated();
  }
}
