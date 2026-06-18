import 'package:dio/dio.dart';
import 'app_exception.dart';

/// Convertit n'importe quelle exception en AppException
AppException mapException(Object e) {
  if (e is AppException) return e;
  if (e is DioException) return _fromDio(e);
  return AppException.unknown(e.toString());
}

AppException _fromDio(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
      return const AppException.network('Connexion trop lente. Vérifiez votre réseau.');
    case DioExceptionType.connectionError:
      return const AppException.network('Impossible de joindre le serveur. Vérifiez votre connexion.');
    case DioExceptionType.badResponse:
      return _fromResponse(e.response?.statusCode, e.response?.data);
    default:
      return AppException.unknown(e.message ?? 'Erreur inconnue');
  }
}

AppException _fromResponse(int? statusCode, dynamic data) {
  final detail = _extractDetail(data);
  switch (statusCode) {
    case 400:
      return AppException.validation(detail ?? 'Données invalides.');
    case 401:
      return AppException.unauthorized(detail ?? 'Session expirée. Reconnectez-vous.');
    case 403:
      return const AppException.unauthorized('Accès refusé.');
    case 404:
      return AppException.notFound(detail ?? 'Ressource introuvable.');
    case 422:
      return AppException.validation(detail ?? 'Validation échouée.');
    case 500:
      return AppException.server(detail ?? 'Erreur serveur. Réessayez plus tard.');
    default:
      if (statusCode != null && statusCode >= 500) {
        return AppException.server(detail ?? 'Erreur serveur. Réessayez plus tard.');
      }
      return AppException.unknown(detail ?? 'Erreur HTTP $statusCode');
  }
}

String? _extractDetail(dynamic data) {
  if (data is Map<String, dynamic>) {
    final d = data['detail'];
    if (d is String) return d;
    if (d is List && d.isNotEmpty) {
      final first = d.first;
      if (first is Map) return first['msg']?.toString();
    }
  }
  return null;
}

/// Message lisible pour l'utilisateur
String friendlyError(Object e) {
  final ex = mapException(e);
  return ex.message;
}
