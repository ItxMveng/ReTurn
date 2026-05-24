import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage.g.dart';

@Riverpod(keepAlive: true)
SecureStorageService secureStorage(Ref ref) => SecureStorageService();

const _kAccessToken  = 'access_token';
const _kRefreshToken = 'refresh_token';

class SecureStorageService {
  final FlutterSecureStorage _s = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _s.write(key: _kAccessToken, value: accessToken),
      _s.write(key: _kRefreshToken, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken()  => _s.read(key: _kAccessToken);
  Future<String?> getRefreshToken() => _s.read(key: _kRefreshToken);

  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearAll() => _s.deleteAll();
}
