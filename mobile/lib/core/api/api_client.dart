import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../storage/secure_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));
  // IMPORTANT : on réutilise le MÊME SecureStorageService que l'auth.
  // Un FlutterSecureStorage() avec des options par défaut utiliserait un
  // backend Android différent (sans encryptedSharedPreferences) et ne pourrait
  // PAS relire le token écrit par l'auth → 401 sur toutes les requêtes.
  dio.interceptors.add(AuthInterceptor(dio, ref.read(secureStorageProvider)));
  return dio;
});

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final SecureStorageService _storage;

  AuthInterceptor(this._dio, this._storage);

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final isRefreshCall = err.requestOptions.path.contains('/auth/refresh');
    if (err.response?.statusCode == 401 && !isRefreshCall) {
      // Refresh mutualisé (un seul en vol pour toute l'app).
      final refreshed =
          await TokenRefresher.refresh(_storage, _dio.options.baseUrl);
      if (refreshed) {
        try {
          final newAccess = await _storage.getAccessToken();
          err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
          final retryResp = await _dio.fetch(err.requestOptions);
          return handler.resolve(retryResp);
        } catch (_) {/* la requête rejouée a échoué : on propage l'erreur */}
      }
    }
    return handler.next(err);
  }
}
