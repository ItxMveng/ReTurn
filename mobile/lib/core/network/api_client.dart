import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:docretour/core/constants/app_constants.dart';
import 'package:docretour/core/network/auth_interceptor.dart';

// Single Dio instance shared across all repositories
Dio? _client;

Dio buildApiClient({required Future<void> Function() onLogout}) {
  if (_client != null) return _client!;

  final dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 30),
  ));

  dio.interceptors.add(AuthInterceptor(dio, onLogout: onLogout));

  _client = dio;
  return dio;
}

void invalidateApiClient() => _client = null;

// Riverpod provider — requires the logout callback injected by authProvider
final apiClientProvider = Provider<Dio>((ref) {
  throw UnimplementedError(
    'apiClientProvider must be overridden with buildApiClient()',
  );
});
