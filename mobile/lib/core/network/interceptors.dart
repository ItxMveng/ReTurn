import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../storage/secure_storage.dart';
import '../errors/app_exception.dart';

/// Injecte le JWT dans chaque requête et gère le refresh automatique
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, this._dio);
  final SecureStorageService _storage;
  final Dio _dio;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Ne pas injecter de token sur les routes publiques
    const publicPaths = ['/auth/register', '/auth/login', '/auth/refresh'];
    if (publicPaths.any((p) => options.path.contains(p))) {
      return handler.next(options);
    }
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        final refreshToken = await _storage.getRefreshToken();
        if (refreshToken == null) {
          await _storage.clearTokens();
          return handler.next(err);
        }
        // Appel refresh
        final refreshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
        final res = await refreshDio.post('/auth/refresh', data: {'refresh_token': refreshToken});
        final newAccess = res.data['access_token'] as String;
        final newRefresh = res.data['refresh_token'] as String;
        await _storage.saveTokens(accessToken: newAccess, refreshToken: newRefresh);
        // Rejouer la requête originale avec le nouveau token
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newAccess';
        final retryRes = await _dio.fetch(opts);
        return handler.resolve(retryRes);
      } catch (_) {
        await _storage.clearTokens();
        return handler.next(err);
      }
    }
    handler.next(err);
  }
}

/// Logger pour toutes les requêtes/réponses en mode debug
class LoggingInterceptor extends Interceptor {
  final _logger = Logger(
    printer: PrettyPrinter(methodCount: 0, printEmojis: true),
    level: Level.debug,
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.d('[REQ] ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.i('[RES] ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e('[ERR] ${err.response?.statusCode} ${err.requestOptions.path}', error: err.message);
    handler.next(err);
  }
}

/// Convertit les erreurs Dio en AppException typées
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    final AppException appEx;
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      appEx = const AppException.network('Délai d\'attente dépassé. Vérifiez votre connexion.');
    } else if (err.type == DioExceptionType.connectionError) {
      appEx = const AppException.network('Impossible de contacter le serveur.');
    } else {
      switch (statusCode) {
        case 400:
          final msg = err.response?.data?['detail'] ?? 'Requête invalide.';
          appEx = AppException.validation(msg.toString());
        case 401:
          appEx = const AppException.unauthorized('Session expirée. Veuillez vous reconnecter.');
        case 403:
          appEx = const AppException.forbidden('Accès refusé.');
        case 404:
          appEx = const AppException.notFound('Ressource introuvable.');
        case 409:
          final msg = err.response?.data?['detail'] ?? 'Conflit de données.';
          appEx = AppException.conflict(msg.toString());
        case 422:
          final msg = err.response?.data?['detail'] ?? 'Données invalides.';
          appEx = AppException.validation(msg.toString());
        case 500:
          appEx = const AppException.server('Erreur serveur. Réessayez plus tard.');
        default:
          appEx = AppException.unknown(err.message ?? 'Erreur inconnue.');
      }
    }
    err.requestOptions.extra['appException'] = appEx;
    handler.next(err);
  }
}
