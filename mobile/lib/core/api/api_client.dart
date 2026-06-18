import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _baseUrl = String.fromEnvironment('API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1');

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));
  dio.interceptors.add(AuthInterceptor(dio));
  return dio;
});

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  static const _storage = FlutterSecureStorage();

  AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        final refreshToken = await _storage.read(key: 'refresh_token');
        if (refreshToken == null) return handler.next(err);
        final response = await _dio.post('/auth/refresh',
            data: {'refresh_token': refreshToken});
        final newAccess = response.data['access_token'] as String;
        final newRefresh = response.data['refresh_token'] as String;
        await _storage.write(key: 'access_token', value: newAccess);
        await _storage.write(key: 'refresh_token', value: newRefresh);
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
        final retryResp = await _dio.fetch(err.requestOptions);
        return handler.resolve(retryResp);
      } catch (_) {
        await _storage.deleteAll();
      }
    }
    return handler.next(err);
  }
}
