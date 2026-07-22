/// Centralise toute la configuration selon l'environnement
class AppConfig {
  AppConfig._();

  static const String _env = String.fromEnvironment('ENV', defaultValue: 'dev');

  static bool get isDebug => _env != 'production';
  static bool get isProduction => _env == 'production';

  static String get apiBaseUrl {
    // --dart-define=API_BASE_URL=http://192.168.x.x:8000 (set by run_device.ps1)
    const fromDefine = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromDefine.isNotEmpty) return fromDefine.endsWith('/api/v1') ? fromDefine : '$fromDefine/api/v1';
    switch (_env) {
      case 'production':
        // Repli si l'APK n'est pas buildé avec --dart-define=API_BASE_URL.
        // La CID mobile injecte l'URL Render réelle (secret PROD_API_BASE_URL).
        return 'https://docretour-api.onrender.com/api/v1';
      case 'staging':
        return 'https://docretour-api.onrender.com/api/v1';
      default: // dev — Android emulator uses 10.0.2.2
        return 'http://10.0.2.2:8000/api/v1';
    }
  }

  /// Origine du backend (sans le suffixe `/api/v1`) — base du proxy média.
  static String get apiOrigin {
    final base = apiBaseUrl;
    return base.endsWith('/api/v1')
        ? base.substring(0, base.length - '/api/v1'.length)
        : base;
  }

  /// Timeout Dio en millisecondes
  static const int connectTimeoutMs = 10000;
  static const int receiveTimeoutMs = 20000;

  /// Clé publique Sentry (optionnelle, injectée via --dart-define)
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');

  /// Client ID Google (type Web) pour Google Sign-In — jamais hardcodé.
  /// Injecté au build :
  ///   flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com
  /// À défaut, Google Sign-In retombe sur le client par défaut du
  /// google-services.json de l'appareil.
  static const String googleServerClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID', defaultValue: '');
}
