import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../utils/token_storage.dart';

/// Single Dio instance shared by all repositories.
/// Handles:
///   - Attaching Bearer token to every request
///   - 401 → automatic token refresh → retry original request
///   - Refresh failure → logout + clear tokens
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 30),
  ));

  dio.interceptors.add(_AppInterceptor(
    dio: dio,
    onForceLogout: () async {},
  ));

  // Dispose Dio when provider is destroyed (e.g. full app restart)
  ref.onDispose(dio.close);

  return dio;
});

class _AppInterceptor extends Interceptor {
  _AppInterceptor({required this.dio, required this.onForceLogout});

  final Dio dio;
  final Future<void> Function() onForceLogout;

  bool _isRefreshing = false;
  final List<({RequestOptions opts, ErrorInterceptorHandler handler})> _queue =
      [];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await getAccessToken();
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

    if (_isRefreshing) {
      _queue.add((opts: err.requestOptions, handler: handler));
      return;
    }

    _isRefreshing = true;
    try {
      final refreshTok = await getRefreshToken();
      if (refreshTok == null) {
        await _forceLogout(handler, err);
        return;
      }

      final refreshRes = await dio.post(
        '/api/v1/auth/refresh',
        data: {'refresh_token': refreshTok},
        options: Options(
          headers: <String, dynamic>{},
          extra: {'skipAuthRetry': true},
        ),
      );

      final newAccess = refreshRes.data['access_token'] as String;
      final newRefresh = refreshRes.data['refresh_token'] as String;
      await saveTokens(accessToken: newAccess, refreshToken: newRefresh);

      // Retry original request
      handler.resolve(await _retry(err.requestOptions, newAccess));

      // Drain queued requests
      final pending = List.of(_queue);
      _queue.clear();
      for (final item in pending) {
        item.handler.resolve(await _retry(item.opts, newAccess));
      }
    } catch (_) {
      final pending = List.of(_queue);
      _queue.clear();
      for (final item in pending) {
        item.handler.next(err);
      }
      await _forceLogout(handler, err);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<Response<dynamic>> _retry(
      RequestOptions options, String newToken) async {
    return dio.fetch(options
      ..headers['Authorization'] = 'Bearer $newToken');
  }

  Future<void> _forceLogout(
      ErrorInterceptorHandler handler, DioException err) async {
    await clearTokens();
    await onForceLogout();
    handler.next(err);
  }
}
