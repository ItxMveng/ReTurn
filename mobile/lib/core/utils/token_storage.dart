import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);

Future<void> saveTokens({
  required String accessToken,
  required String refreshToken,
}) async {
  await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
  await _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
}

Future<String?> getAccessToken() =>
    _storage.read(key: AppConstants.accessTokenKey);

Future<String?> getRefreshToken() =>
    _storage.read(key: AppConstants.refreshTokenKey);

Future<void> clearTokens() async {
  await _storage.delete(key: AppConstants.accessTokenKey);
  await _storage.delete(key: AppConstants.refreshTokenKey);
}
