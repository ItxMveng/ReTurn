/// Exceptions métier de l'application ReTurn
sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

final class NetworkException extends AppException {
  const NetworkException([super.message = 'Pas de connexion internet']);
}

final class ServerException extends AppException {
  final int? statusCode;
  const ServerException(super.message, {this.statusCode});
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Session expirée, reconnectez-vous']);
}

final class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Ressource introuvable']);
}

final class ValidationException extends AppException {
  final Map<String, String>? fields;
  const ValidationException(super.message, {this.fields});
}

final class StorageException extends AppException {
  const StorageException([super.message = 'Erreur de stockage local']);
}

/// Convertit une DioException en AppException
AppException mapDioException(Object err) {
  // Handled by DioException in api_client — import only when needed
  return ServerException(err.toString());
}
