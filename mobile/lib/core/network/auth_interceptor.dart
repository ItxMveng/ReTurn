import 'package:dio/dio.dart';
import '../utils/token_storage.dart';

// Singleton lock to prevent parallel refresh storms
bool _isRefreshing = false;
final List<void Function(String)> _pendingRetries = [];

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final Future<void> Function() onLogout;

  AuthInterceptor(this._dio, {required this.onLogout});

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

    // Don't retry the refresh endpoint itself
    if (err.requestOptions.path.contains('/auth/refresh')) {
      await _handleLogout();
      handler.next(err);
      return;
    }

    if (_isRefreshing) {
      // Queue this request until refresh is done
      final completer = _QueuedRequest();
      _pendingRetries.add((newToken) {
        completer.resolve(newToken);
      });
      final newToken = await completer.future;
      if (newToken != null) {
        handler.resolve(await _retry(err.requestOptions, newToken));
      } else {
        handler.next(err);
      }
      return;
    }

    _isRefreshing = true;
    try {
      final refreshTok = await getRefreshToken();
      if (refreshTok == null) {
        await _handleLogout();
        handler.next(err);
        return;
      }

      final response = await _dio.post(
        '/api/v1/auth/refresh',
        data: {'refresh_token': refreshTok},
        options: Options(headers: {}), // no auth header for this call
      );

      final newAccess = response.data['access_token'] as String;
      final newRefresh = response.data['refresh_token'] as String;
      await saveTokens(accessToken: newAccess, refreshToken: newRefresh);

      // Resolve pending requests
      for (final retry in _pendingRetries) {
        retry(newAccess);
      }
      _pendingRetries.clear();

      handler.resolve(await _retry(err.requestOptions, newAccess));
    } catch (_) {
      _pendingRetries.clear();
      await _handleLogout();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<Response<dynamic>> _retry(
      RequestOptions options, String token) async {
    final opts = Options(
      method: options.method,
      headers: {...options.headers, 'Authorization': 'Bearer $token'},
    );
    return _dio.request<dynamic>(
      options.path,
      data: options.data,
      queryParameters: options.queryParameters,
      options: opts,
    );
  }

  Future<void> _handleLogout() async {
    await clearTokens();
    await onLogout();
  }
}

// Simple async completer wrapper for queuing
class _QueuedRequest {
  String? _token;
  bool _completed = false;
  final _callbacks = <void Function(String?)>[];

  Future<String?> get future async {
    if (_completed) return _token;
    // Poll — in practice completes almost immediately
    while (!_completed) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    return _token;
  }

  void resolve(String token) {
    _token = token;
    _completed = true;
    for (final cb in _callbacks) { cb(token); }
  }
}
