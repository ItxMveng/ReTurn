import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../storage/secure_storage.dart';
import 'interceptors.dart';

part 'api_client.g.dart';

/// Base URL de l'API — à surcharger via .env
const String kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/api/v1',
);

@riverpod
Dio dio(Ref ref) {
  final storage = ref.watch(secureStorageProvider);
  final d = Dio(
    BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ),
  );
  d.interceptors.addAll([
    AuthInterceptor(storage, d),
    LoggingInterceptor(),
    ErrorInterceptor(),
  ]);
  return d;
}

/// Provider haut-niveau pour les appels API
@riverpod
ApiClient apiClient(Ref ref) => ApiClient(ref.watch(dioProvider));

class ApiClient {
  ApiClient(this._dio);
  final Dio _dio;

  Future<T> get<T>(String path, {Map<String, dynamic>? queryParams, required T Function(dynamic) fromJson}) async {
    final res = await _dio.get(path, queryParameters: queryParams);
    return fromJson(res.data);
  }

  Future<T> post<T>(String path, {required Map<String, dynamic> body, required T Function(dynamic) fromJson}) async {
    final res = await _dio.post(path, data: body);
    return fromJson(res.data);
  }

  Future<T> put<T>(String path, {required Map<String, dynamic> body, required T Function(dynamic) fromJson}) async {
    final res = await _dio.put(path, data: body);
    return fromJson(res.data);
  }

  Future<void> delete(String path) async {
    await _dio.delete(path);
  }

  Future<T> patch<T>(String path, {required Map<String, dynamic> body, required T Function(dynamic) fromJson}) async {
    final res = await _dio.patch(path, data: body);
    return fromJson(res.data);
  }
}
