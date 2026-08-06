import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/config/app_config.dart';
import '../../../core/firebase/firebase_init.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/repositories/auth_repository.dart';
import '../../../shared/widgets/guided_tour.dart';
import 'auth_state.dart';

part 'auth_notifier.g.dart';

// ─── Provider OTP (Firebase Phone Auth — vrais SMS) ───────────────────────────
@riverpod
class OtpNotifier extends _$OtpNotifier {
  String? _verificationId;

  @override
  OtpState build() => const OtpState.idle();

  /// Normalise au format E.164 attendu par Firebase. Un numéro local
  /// camerounais (sans « + ») se voit préfixer l'indicatif +237.
  String _normalize(String phone) {
    final p = phone.trim().replaceAll(RegExp(r'\s'), '');
    if (p.startsWith('+')) return p;
    if (p.startsWith('237')) return '+$p';
    return '+237$p';
  }

  /// Demande à Firebase d'envoyer un vrai SMS au numéro.
  Future<void> requestOtp(String phoneNumber) async {
    state = const OtpState.sending();
    if (!await ensureFirebaseReady()) {
      state = const OtpState.error(
        'Service d\'authentification indisponible. Réessayez dans un instant.',
      );
      return;
    }
    final phone = _normalize(phoneNumber);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        // Android peut récupérer le code automatiquement → connexion directe.
        verificationCompleted: (credential) async {
          try {
            await _signIn(credential);
          } catch (_) {/* l'utilisateur saisira le code manuellement */}
        },
        verificationFailed: (e) {
          state = OtpState.error(
            e.message ?? 'Échec de l\'envoi du SMS. Vérifiez le numéro.',
          );
        },
        codeSent: (verificationId, _) {
          _verificationId = verificationId;
          state = OtpState.sent(phone);
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      state = OtpState.error(e.toString());
    }
  }

  /// Vérifie le code SMS saisi par l'utilisateur. Retourne true si succès.
  Future<bool> verifyOtp({
    required String phoneNumber,
    required String otpCode,
  }) async {
    final vid = _verificationId;
    if (vid == null) {
      state = const OtpState.error('Session expirée. Renvoyez le code.');
      return false;
    }
    state = const OtpState.verifying();
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: vid,
        smsCode: otpCode.trim(),
      );
      await _signIn(credential);
      state = const OtpState.verified();
      return true;
    } catch (_) {
      state = const OtpState.error('Code invalide ou expiré.');
      return false;
    }
  }

  /// Connexion Firebase → échange l'idToken contre une session backend.
  Future<void> _signIn(PhoneAuthCredential credential) async {
    final userCred =
        await FirebaseAuth.instance.signInWithCredential(credential);
    final idToken = await userCred.user?.getIdToken();
    if (idToken == null) throw Exception('Token Firebase introuvable');
    await ref.read(authRepositoryProvider).loginWithFirebase(idToken);
    await ref.read(authNotifierProvider.notifier).checkAuth();
  }
}

// ─── Provider AUTH (état de session utilisateur) ──────────────────────────────
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    // Session expirée (refresh token invalide) → état déconnecté ; le router
    // redirige alors automatiquement vers /auth/phone.
    TokenRefresher.onSessionExpired = () {
      try {
        state = const AuthState.unauthenticated();
      } catch (_) {/* notifier disposé : rien à faire */}
    };
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
      if (!await ensureFirebaseReady()) {
        state = const AuthState.error(
          'Service Google indisponible. Réessayez dans un instant.',
        );
        return;
      }
      final googleUser = await GoogleSignIn(
        serverClientId: AppConfig.googleServerClientId.isEmpty
            ? null
            : AppConfig.googleServerClientId,
      ).signIn();
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

  /// Connexion par email + mot de passe (Firebase — gratuit, aucun SMS).
  Future<void> signInWithEmail(String email, String password) async {
    state = const AuthState.loading();
    try {
      if (!await ensureFirebaseReady()) {
        state = const AuthState.error(
            'Service d\'authentification indisponible. Réessayez.');
        return;
      }
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      await _finishFirebaseLogin(cred);
    } on FirebaseAuthException catch (e) {
      state = AuthState.error(_mapAuthError(e));
    } catch (_) {
      state = const AuthState.error('Échec de la connexion. Réessayez.');
    }
  }

  /// Création de compte par email + mot de passe (Firebase).
  Future<void> signUpWithEmail(String email, String password) async {
    state = const AuthState.loading();
    try {
      if (!await ensureFirebaseReady()) {
        state = const AuthState.error(
            'Service d\'authentification indisponible. Réessayez.');
        return;
      }
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      await _finishFirebaseLogin(cred);
    } on FirebaseAuthException catch (e) {
      state = AuthState.error(_mapAuthError(e));
    } catch (_) {
      state = const AuthState.error('Création du compte impossible. Réessayez.');
    }
  }

  /// Envoi d'un email de réinitialisation de mot de passe.
  /// Retourne `null` si succès, sinon un message d'erreur.
  Future<String?> sendPasswordReset(String email) async {
    try {
      if (!await ensureFirebaseReady()) {
        return 'Service indisponible. Réessayez.';
      }
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (_) {
      return 'Envoi impossible. Réessayez.';
    }
  }

  Future<void> _finishFirebaseLogin(UserCredential cred) async {
    final idToken = await cred.user?.getIdToken();
    if (idToken == null) throw Exception('Token Firebase introuvable');
    await ref.read(authRepositoryProvider).loginWithFirebase(idToken);
    await checkAuth();
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Adresse email invalide.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cet email.';
      case 'weak-password':
        return 'Mot de passe trop faible (6 caractères minimum).';
      case 'network-request-failed':
        return 'Connexion réseau impossible. Vérifiez votre connexion.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      default:
        return e.message ?? 'Échec de l\'authentification.';
    }
  }

  Future<void> logout() async {
    await resetTourFlag(); // prochain login → tour visible
    await ref.read(authRepositoryProvider).logout();
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    state = const AuthState.unauthenticated();
  }

  /// RGPD (F-04) : supprime aussi l'utilisateur Firebase puis déconnecte.
  /// Le compte applicatif (Postgres) est supprimé en amont via l'API profil.
  Future<void> deleteFirebaseAccountAndLogout() async {
    try {
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (_) {
      // Peut nécessiter une reconnexion récente — non bloquant.
    }
    await logout();
  }
}
