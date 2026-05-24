import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_exception.dart';

/// Convertit n'importe quelle exception en AppException
AppException mapException(Object error) {
  if (error is AppException) return error;
  if (error is DioException) {
    final appEx = error.requestOptions.extra['appException'];
    if (appEx is AppException) return appEx;
    return AppException.unknown(error.message ?? 'Erreur réseau inconnue.');
  }
  return AppException.unknown(error.toString());
}

/// Extension sur AsyncNotifier pour simplifier la gestion d'erreurs
extension ErrorHandlerX on StateController<AsyncValue<dynamic>> {
  AsyncValue<T> guard<T>(T Function() fn) {
    try {
      return AsyncValue.data(fn());
    } catch (e, st) {
      return AsyncValue.error(mapException(e), st);
    }
  }
}

/// Helper pour afficher un message d'erreur utilisateur
String friendlyError(Object error) {
  final ex = mapException(error);
  return ex.userMessage;
}
