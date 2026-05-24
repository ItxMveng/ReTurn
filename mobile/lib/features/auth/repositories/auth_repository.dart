import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/auth_storage.dart';
import '../models/auth_models.dart';

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository(
          ref.read(dioProvider),
          ref.read(authStorageProvider),
        ));

class AuthRepository {
  final Dio _dio;
  final AuthStorage _storage;
  AuthRepository(this._dio, this._storage);

  Future<void> login(LoginRequest req) async {
    final res = await _dio.post('/auth/login', data: req.toJson());
    final tokens = AuthTokens.fromJson(res.data as Map<String, dynamic>);
    await _storage.saveTokens(
        access: tokens.accessToken, refresh: tokens.refreshToken);
  }

  Future<void> register(RegisterRequest req) async {
    final res = await _dio.post('/auth/register', data: req.toJson());
    final tokens = AuthTokens.fromJson(res.data as Map<String, dynamic>);
    await _storage.saveTokens(
        access: tokens.accessToken, refresh: tokens.refreshToken);
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
    await _storage.clear();
  }
}
