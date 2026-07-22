import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../config/app_config.dart';
import '../storage/secure_storage.dart';

part 'api_client.g.dart';

@riverpod
ApiClient apiClient(Ref ref) {
  return ApiClient(
    baseUrl: AppConfig.apiBaseUrl,
    storage: ref.watch(secureStorageProvider),
  );
}

class ApiClient {
  ApiClient({
    required String baseUrl,
    required SecureStorageService storage,
  }) : _storage = storage {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));
    _dio.interceptors.addAll([
      _AuthInterceptor(_storage, _dio),
      LogInterceptor(requestBody: AppConfig.isDebug, responseBody: AppConfig.isDebug),
    ]);
  }

  late final Dio _dio;
  final SecureStorageService _storage;

  Future<T> get<T>(String path, {required T Function(dynamic) fromJson, Map<String, dynamic>? query}) async {
    final r = await _dio.get(path, queryParameters: query);
    return fromJson(r.data);
  }

  Future<T> post<T>(String path, {required T Function(dynamic) fromJson, Map<String, dynamic>? body}) async {
    final r = await _dio.post(path, data: body);
    return fromJson(r.data);
  }

  Future<T> put<T>(String path, {required T Function(dynamic) fromJson, Map<String, dynamic>? body}) async {
    final r = await _dio.put(path, data: body);
    return fromJson(r.data);
  }

  Future<T> patch<T>(String path, {required T Function(dynamic) fromJson, Map<String, dynamic>? body}) async {
    final r = await _dio.patch(path, data: body);
    return fromJson(r.data);
  }

  Future<void> delete(String path) async {
    await _dio.delete(path);
  }
}

/// Intercepteur JWT : injecte l'access token et gère le refresh auto
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._storage, this._dio);
  final SecureStorageService _storage;
  final Dio _dio;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final isRefreshCall = err.requestOptions.path.contains('/auth/refresh');
    if (err.response?.statusCode == 401 && !isRefreshCall) {
      // Refresh mutualisé (mutex partagé entre toutes les couches réseau).
      final refreshed =
          await TokenRefresher.refresh(_storage, _dio.options.baseUrl);
      if (refreshed) {
        final opts = err.requestOptions;
        final newToken = await _storage.getAccessToken();
        opts.headers['Authorization'] = 'Bearer $newToken';
        try {
          final response = await _dio.fetch(opts);
          handler.resolve(response);
          return;
        } catch (_) {/* la requête rejouée a échoué : on propage l'erreur */}
      }
    }
    handler.next(err);
  }
}
