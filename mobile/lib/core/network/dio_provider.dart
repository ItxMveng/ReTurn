import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/secure_storage.dart';

/// Single Dio instance shared by all repositories.
/// Handles:
///   - Attaching Bearer token to every request
///   - 401 → automatic token refresh (mutex partagé) → retry original request
///   - Refresh failure → session expirée gérée par TokenRefresher
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 30),
  ));

  dio.interceptors.add(_AppInterceptor(
    dio: dio,
    storage: ref.read(secureStorageProvider),
  ));

  // Dispose Dio when provider is destroyed (e.g. full app restart)
  ref.onDispose(dio.close);

  return dio;
});

class _AppInterceptor extends Interceptor {
  _AppInterceptor({required this.dio, required this.storage});

  final Dio dio;
  final SecureStorageService storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }
    // Don't refresh on the refresh endpoint itself
    if (err.requestOptions.path.contains('/auth/refresh') ||
        err.requestOptions.path.contains('/auth/verify-firebase-token')) {
      handler.next(err);
      return;
    }

    // Refresh mutualisé : les appels concurrents attendent le même future.
    final refreshed =
        await TokenRefresher.refresh(storage, dio.options.baseUrl);
    if (refreshed) {
      try {
        final newToken = await storage.getAccessToken();
        handler.resolve(await dio.fetch(
          err.requestOptions..headers['Authorization'] = 'Bearer $newToken',
        ));
        return;
      } catch (_) {/* la requête rejouée a échoué : on propage l'erreur */}
    }
    handler.next(err);
  }
}
