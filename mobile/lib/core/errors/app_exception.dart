/// Exception unifiée utilisée dans toute l'app
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  const factory AppException.network(String message) = NetworkException;
  const factory AppException.unauthorized(String message) = UnauthorizedException;
  const factory AppException.notFound(String message) = NotFoundException;
  const factory AppException.server(String message) = ServerException;
  const factory AppException.unknown(String message) = UnknownException;
  const factory AppException.validation(String message) = ValidationException;

  @override
  String toString() => 'AppException($message)';
}

final class NetworkException extends AppException {
  const NetworkException(super.message);
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message);
}

final class NotFoundException extends AppException {
  const NotFoundException(super.message);
}

final class ServerException extends AppException {
  const ServerException(super.message);
}

final class UnknownException extends AppException {
  const UnknownException(super.message);
}

final class ValidationException extends AppException {
  const ValidationException(super.message);
}
