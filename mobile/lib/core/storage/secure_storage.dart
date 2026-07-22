import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage.g.dart';

@Riverpod(keepAlive: true)
SecureStorageService secureStorage(Ref ref) => SecureStorageService();

const _kAccessToken  = 'access_token';
const _kRefreshToken = 'refresh_token';

class SecureStorageService {
  final FlutterSecureStorage _s = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _s.write(key: _kAccessToken, value: accessToken),
      _s.write(key: _kRefreshToken, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken()  => _s.read(key: _kAccessToken);
  Future<String?> getRefreshToken() => _s.read(key: _kRefreshToken);

  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ── Verrouillage biométrique (F-03) — préférence persistée ──────────
  Future<void> setBiometricEnabled(bool enabled) =>
      _s.write(key: 'biometric_enabled', value: enabled ? '1' : '0');

  Future<bool> isBiometricEnabled() async =>
      (await _s.read(key: 'biometric_enabled')) == '1';

  /// Ne supprime PAS la préférence biométrique au logout (réglage appareil).
  Future<void> clearAll() async {
    final bio = await _s.read(key: 'biometric_enabled');
    await _s.deleteAll();
    if (bio != null) await _s.write(key: 'biometric_enabled', value: bio);
  }
}

/// Rafraîchissement de session partagé par TOUTES les couches réseau.
///
/// Garantit qu'un seul POST /auth/refresh est en vol à la fois (mutex via
/// future partagé) : les intercepteurs concurrents attendent le même résultat
/// au lieu de déclencher des refresh parallèles.
class TokenRefresher {
  TokenRefresher._();

  static Future<bool>? _inFlight;

  /// Déclenché quand le refresh token est lui-même expiré : l'AuthNotifier
  /// s'y branche pour passer l'état à « déconnecté » et rediriger vers /auth.
  static void Function()? onSessionExpired;

  /// Tente de renouveler les tokens. Retourne true si la session est valide.
  static Future<bool> refresh(SecureStorageService storage, String baseUrl) {
    return _inFlight ??= _doRefresh(storage, baseUrl).whenComplete(() {
      _inFlight = null;
    });
  }

  static Future<bool> _doRefresh(
      SecureStorageService storage, String baseUrl) async {
    final refreshToken = await storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _expireSession(storage);
      return false;
    }
    try {
      // Dio dédié, sans intercepteur, pour éviter toute boucle de refresh.
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final response = await dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final data = response.data as Map<String, dynamic>;
      await storage.saveTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );
      return true;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        // Refresh token expiré/révoqué → session terminée.
        await _expireSession(storage);
      }
      // Erreur réseau transitoire : on ne déconnecte pas l'utilisateur.
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _expireSession(SecureStorageService storage) async {
    await storage.clearAll();
    onSessionExpired?.call();
  }
}
