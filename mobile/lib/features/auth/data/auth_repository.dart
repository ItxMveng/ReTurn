import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api/api_client.dart';
import '../../../core/network/network_info.dart';
import '../../../core/errors/app_exceptions.dart';

/// Modèle de réponse login/register
class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String phone;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.phone,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> j) => AuthTokens(
        accessToken: j['access_token'] as String,
        refreshToken: j['refresh_token'] as String,
        userId: j['user_id'] as String,
        phone: j['phone'] as String,
      );
}

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  final NetworkInfo _net;

  const AuthRepository(
      {required Dio dio,
      required FlutterSecureStorage storage,
      required NetworkInfo net})
      : _dio = dio,
        _storage = storage,
        _net = net;

  Future<AuthTokens> register({
    required String phone,
    required String fullName,
    required String password,
  }) =>
      _net.request(() async {
        final res = await _dio.post('/auth/register', data: {
          'phone': phone,
          'full_name': fullName,
          'password': password,
        });
        final tokens = AuthTokens.fromJson(res.data as Map<String, dynamic>);
        await _persist(tokens);
        return tokens;
      });

  Future<AuthTokens> login({
    required String phone,
    required String password,
  }) =>
      _net.request(() async {
        final res = await _dio.post('/auth/login', data: {
          'phone': phone,
          'password': password,
        });
        final tokens = AuthTokens.fromJson(res.data as Map<String, dynamic>);
        await _persist(tokens);
        return tokens;
      });

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
    await _storage.deleteAll();
  }

  Future<AuthTokens?> restoreSession() async {
    final access = await _storage.read(key: 'access_token');
    final refresh = await _storage.read(key: 'refresh_token');
    final userId = await _storage.read(key: 'user_id');
    final phone = await _storage.read(key: 'phone');
    if (access == null || userId == null || phone == null) return null;
    return AuthTokens(
      accessToken: access,
      refreshToken: refresh ?? '',
      userId: userId,
      phone: phone,
    );
  }

  Future<void> _persist(AuthTokens t) async {
    await _storage.write(key: 'access_token', value: t.accessToken);
    await _storage.write(key: 'refresh_token', value: t.refreshToken);
    await _storage.write(key: 'user_id', value: t.userId);
    await _storage.write(key: 'phone', value: t.phone);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.read(dioProvider),
    storage: const FlutterSecureStorage(),
    net: ref.read(networkInfoProvider),
  );
});
