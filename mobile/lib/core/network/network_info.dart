import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../errors/app_exceptions.dart';

/// Convertit une [DioException] en [AppException] métier.
AppException mapDioError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.connectionError:
      return const NetworkException();
    case DioExceptionType.badResponse:
      final code = e.response?.statusCode;
      if (code == 401) return const UnauthorizedException();
      if (code == 404) return const NotFoundException();
      if (code == 422) {
        final detail = e.response?.data['detail'];
        if (detail is List) {
          final errs = <String, List<String>>{};
          for (final item in detail) {
            final loc = (item['loc'] as List).last.toString();
            errs.putIfAbsent(loc, () => []).add(item['msg'].toString());
          }
          return ValidationException(errs);
        }
      }
      final msg = e.response?.data?['detail']?.toString() ?? 'Erreur serveur.';
      return ServerException(msg, code);
    default:
      return const NetworkException();
  }
}

/// Provider exposé pour les repositories.
final networkInfoProvider = Provider<NetworkInfo>((ref) => NetworkInfo());

class NetworkInfo {
  /// Exécute [call] et remonte une [AppException] propre en cas d'erreur.
  Future<T> request<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapDioError(e);
    } catch (e) {
      throw NetworkException(e.toString());
    }
  }
}
