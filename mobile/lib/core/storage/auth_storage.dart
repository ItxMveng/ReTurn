import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authStorageProvider = Provider<AuthStorage>((ref) => AuthStorage());

class AuthStorage {
  static const _st = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveTokens(
      {required String access, required String refresh}) async {
    await _st.write(key: 'access_token', value: access);
    await _st.write(key: 'refresh_token', value: refresh);
  }

  Future<String?> get accessToken => _st.read(key: 'access_token');
  Future<String?> get refreshToken => _st.read(key: 'refresh_token');

  Future<bool> get isLoggedIn async {
    final t = await _st.read(key: 'access_token');
    return t != null && t.isNotEmpty;
  }

  Future<void> clear() => _st.deleteAll();
}
