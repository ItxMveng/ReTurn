/// Centralise toute la configuration selon l'environnement
class AppConfig {
  AppConfig._();

  static const String _env = String.fromEnvironment('ENV', defaultValue: 'dev');

  static bool get isDebug => _env != 'production';
  static bool get isProduction => _env == 'production';

  static String get apiBaseUrl {
    switch (_env) {
      case 'production':
        return 'https://api.return-app.cm/api/v1';
      case 'staging':
        return 'https://staging-api.return-app.cm/api/v1';
      default: // dev
        // Android emulator => 10.0.2.2, iOS simulator => localhost
        return 'http://10.0.2.2:8000/api/v1';
    }
  }

  /// Timeout Dio en millisecondes
  static const int connectTimeoutMs = 10000;
  static const int receiveTimeoutMs = 20000;

  /// Clé publique Sentry (optionnelle, injectée via --dart-define)
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
}
