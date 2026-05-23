import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

import 'package:docretour/core/constants/app_constants.dart';
import 'package:docretour/features/auth/domain/models/auth_state.dart';

final _log = Logger();

class AuthRepository {
  AuthRepository()
      : _auth = FirebaseAuth.instance,
        _googleSignIn = GoogleSignIn(
          serverClientId:
              '774092129161-ed0d2cs235cccvbsu506ikdiehktpko7.apps.googleusercontent.com',
        ),
        // IMPORTANT : en test sur téléphone physique, utiliser l'IP locale
        // de la machine (ipconfig → IPv4) au lieu de 10.0.2.2 (émulateur).
        // Lancer avec : flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000
        _dio = Dio(BaseOptions(
          baseUrl: AppConstants.apiBaseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
        )),
        _storage = const FlutterSecureStorage();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final Dio _dio;
  final FlutterSecureStorage _storage;

  // --- Formatage numéro camerounais vers E.164 ---
  static String formatPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('237')) return '+$digits';
    if (digits.startsWith('6') && digits.length == 9) return '+237$digits';
    if (digits.startsWith('06') || digits.startsWith('07')) {
      return '+237${digits.substring(1)}';
    }
    if (digits.length == 9) return '+237$digits';
    return '+$digits';
  }

  // --- Connexion Google ---
  Future<AuthState> signInWithGoogle() async {
    try {
      _log.d('Connexion Google démarrée');
      // Forcer le sélecteur de compte à chaque fois
      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // L'utilisateur a annulé
        return const AuthState.initial();
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      return _exchangeFirebaseToken(result);
    } on FirebaseAuthException catch (e) {
      return _mapFirebaseError(e);
    } catch (e) {
      _log.w('Erreur connexion Google: $e');
      return const AuthState.error(
        message: 'Connexion Google annulée ou échouée. Réessayez.',
        type: AuthErrorType.unknown,
      );
    }
  }

  // --- Envoyer le code SMS via Firebase ---
  Future<AuthState> sendOtp(
    String rawPhone, {
    int? resendToken,
    required void Function(AuthState) onStateChange,
  }) async {
    final phone = formatPhone(rawPhone);
    _log.d('Envoi OTP vers $phone');

    final completer = Completer<AuthState>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      forceResendingToken: resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        _log.d('Auto-vérification Firebase déclenchée');
        try {
          final result = await _auth.signInWithCredential(credential);
          final state = await _exchangeFirebaseToken(result);
          onStateChange(state);
          if (!completer.isCompleted) completer.complete(state);
        } catch (e) {
          final state = _mapException(e);
          onStateChange(state);
          if (!completer.isCompleted) completer.complete(state);
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        _log.w('Échec vérification Firebase: ${e.code}');
        final state = _mapFirebaseError(e);
        onStateChange(state);
        if (!completer.isCompleted) completer.complete(state);
      },
      codeSent: (String verificationId, int? token) {
        _log.d('Code SMS envoyé (verificationId reçu)');
        final state = AuthState.codeSent(
          verificationId: verificationId,
          phoneNumber: phone,
          resendToken: token,
        );
        onStateChange(state);
        if (!completer.isCompleted) completer.complete(state);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _log.d('Timeout auto-récupération SMS');
      },
    );

    return completer.future;
  }

  // --- Vérifier le code saisi par l'utilisateur ---
  Future<AuthState> verifySmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final result = await _auth.signInWithCredential(credential);
    return _exchangeFirebaseToken(result);
  }

  // --- Échange token Firebase → tokens backend ---
  Future<AuthState> _exchangeFirebaseToken(UserCredential result) async {
    try {
      final idToken = await result.user?.getIdToken();
      if (idToken == null) {
        return const AuthState.error(
          message: 'Impossible d\'obtenir le token Firebase.',
          type: AuthErrorType.unknown,
        );
      }

      final response = await _dio.post(
        '/api/v1/auth/verify-firebase-token',
        data: {'firebase_token': idToken},
      );

      final data = response.data as Map<String, dynamic>;
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;
      final userId = data['user_id'] as String;

      await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
      await _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
      await _storage.write(key: AppConstants.userIdKey, value: userId);

      return AuthState.authenticated(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userId,
      );
    } on FirebaseAuthException catch (e) {
      return _mapFirebaseError(e);
    } on DioException catch (e) {
      _log.w('Erreur réseau backend: ${e.type} — ${e.message}');
      // Backend injoignable : utiliser le token Firebase directement
      // L'échange sera retentée au prochain appel API via l'intercepteur
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        final firebaseToken = await result.user?.getIdToken() ?? '';
        final uid = result.user?.uid ?? '';
        if (uid.isNotEmpty) {
          await _storage.write(key: AppConstants.accessTokenKey, value: firebaseToken);
          await _storage.write(key: AppConstants.refreshTokenKey, value: firebaseToken);
          await _storage.write(key: AppConstants.userIdKey, value: uid);
          _log.w('Backend injoignable — session Firebase locale créée (uid: $uid)');
          return AuthState.authenticated(
            accessToken: firebaseToken,
            refreshToken: firebaseToken,
            userId: uid,
          );
        }
      }
      final msg = _networkErrorMessage(e);
      return AuthState.error(message: msg, type: AuthErrorType.networkError);
    }
  }

  // --- Restaurer la session depuis le stockage ---
  Future<AuthState?> tryRestoreSession() async {
    final accessToken = await _storage.read(key: AppConstants.accessTokenKey);
    final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
    final userId = await _storage.read(key: AppConstants.userIdKey);
    if (accessToken == null || refreshToken == null || userId == null) return null;

    // 1. Try current access token
    try {
      await _dio.get(
        '/api/v1/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      return AuthState.authenticated(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userId,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode != 401) {
        // Network error — keep session, retry later
        return AuthState.authenticated(
          accessToken: accessToken,
          refreshToken: refreshToken,
          userId: userId,
        );
      }
      // 2. Access token expired — try refresh
      try {
        final refreshResp = await _dio.post(
          '/api/v1/auth/refresh',
          data: {'refresh_token': refreshToken},
        );
        final newAccess = refreshResp.data['access_token'] as String;
        final newRefresh = refreshResp.data['refresh_token'] as String;
        final newUserId = refreshResp.data['user_id'] as String? ?? userId;
        await _storage.write(key: AppConstants.accessTokenKey, value: newAccess);
        await _storage.write(key: AppConstants.refreshTokenKey, value: newRefresh);
        await _storage.write(key: AppConstants.userIdKey, value: newUserId);
        return AuthState.authenticated(
          accessToken: newAccess,
          refreshToken: newRefresh,
          userId: newUserId,
        );
      } catch (_) {
        await clearSession();
        return null;
      }
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    await clearSession();
  }

  Future<void> clearSession() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    await _storage.delete(key: AppConstants.userIdKey);
  }

  Future<String?> getStoredToken() =>
      _storage.read(key: AppConstants.accessTokenKey);

  // --- Mapping erreurs Firebase → messages français ---
  AuthState _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return const AuthState.error(
          message: 'Numéro de téléphone invalide. Vérifiez le format (+237XXXXXXXXX).',
          type: AuthErrorType.invalidPhone,
        );
      case 'too-many-requests':
        return const AuthState.error(
          message: 'Trop de tentatives. Veuillez patienter quelques minutes.',
          type: AuthErrorType.tooManyRequests,
        );
      case 'invalid-verification-code':
        return const AuthState.error(
          message: 'Code incorrect. Vérifiez le code reçu par SMS.',
          type: AuthErrorType.invalidCode,
        );
      case 'session-expired':
        return const AuthState.error(
          message: 'Session expirée. Veuillez demander un nouveau code.',
          type: AuthErrorType.invalidCode,
        );
      case 'network-request-failed':
        return const AuthState.error(
          message: 'Erreur réseau. Vérifiez votre connexion internet.',
          type: AuthErrorType.networkError,
        );
      case 'operation-not-allowed':
        return const AuthState.error(
          message:
              'Cette méthode de connexion n\'est pas activée dans Firebase. '
              'Activez-la dans la console Firebase → Authentication → Sign-in method.',
          type: AuthErrorType.serverError,
        );
      case 'account-exists-with-different-credential':
        return const AuthState.error(
          message:
              'Un compte existe déjà avec cette adresse email. '
              'Utilisez la méthode de connexion associée à ce compte.',
          type: AuthErrorType.unknown,
        );
      default:
        _log.w('FirebaseAuthException non mappée: ${e.code}');
        return AuthState.error(
          message: 'Une erreur est survenue (${e.code}). Veuillez réessayer.',
          type: AuthErrorType.unknown,
        );
    }
  }

  AuthState _mapException(Object e) {
    if (e is FirebaseAuthException) return _mapFirebaseError(e);
    if (e is DioException) {
      return AuthState.error(
          message: _networkErrorMessage(e), type: AuthErrorType.networkError);
    }
    return const AuthState.error(
      message: 'Une erreur inattendue est survenue.',
      type: AuthErrorType.unknown,
    );
  }

  String _networkErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Le serveur ne répond pas (timeout). '
            'Vérifiez que le backend est démarré et que l\'URL est correcte : '
            '${AppConstants.apiBaseUrl}';
      case DioExceptionType.connectionError:
        return 'Impossible de joindre le serveur ${AppConstants.apiBaseUrl}. '
            'Vérifiez : 1) le backend est démarré, '
            '2) votre téléphone et le PC sont sur le même Wi-Fi, '
            '3) l\'IP dans API_BASE_URL est correcte (ipconfig sur le PC).';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 500) return 'Erreur serveur interne (500). Consultez les logs du backend.';
        if (code == 404) return 'Endpoint introuvable (404). Vérifiez la version de l\'API.';
        return 'Erreur serveur ($code). Veuillez réessayer.';
      default:
        return 'Erreur réseau (${e.type.name}). Vérifiez votre connexion internet.';
    }
  }
}
