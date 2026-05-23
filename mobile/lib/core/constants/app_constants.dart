class AppConstants {
  AppConstants._();

  static const String appName = 'ReTurn';

  // Priority order for API base URL resolution:
  //   1. Build-time --dart-define=API_BASE_URL=https://api.myserver.com   (production)
  //   2. Build-time --dart-define=API_BASE_URL=http://192.168.x.x:8000    (dev, physical device)
  //   3. Hard-coded default below                                           (Android emulator)
  //
  // To find your PC IP on Windows : ipconfig → IPv4 Address
  // Example dev build on physical device:
  //   flutter run --dart-define=API_BASE_URL=http://192.168.1.X:8000
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000', // Android emulator → host localhost
  );

  // Clés flutter_secure_storage
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';

  // OTP
  static const int otpResendDelaySeconds = 60;
  static const int otpCodeLength = 6;

  // Biométrie - Clés flutter_secure_storage
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String pinCodeKey = 'pin_code';
  static const String biometricTimeoutKey = 'biometric_timeout';
  
  // Biométrie - Configuration
  static const Duration defaultBiometricTimeout = Duration(minutes: 5);
  static const int pinCodeLength = 6;
}
