/// Exceptions typées de l'application — union type via freezed-like pattern
sealed class AppException implements Exception {
  const AppException();

  const factory AppException.network(String message) = NetworkException;
  const factory AppException.unauthorized(String message) = UnauthorizedException;
  const factory AppException.forbidden(String message) = ForbiddenException;
  const factory AppException.notFound(String message) = NotFoundException;
  const factory AppException.validation(String message) = ValidationException;
  const factory AppException.conflict(String message) = ConflictException;
  const factory AppException.server(String message) = ServerException;
  const factory AppException.unknown(String message) = UnknownException;

  String get message;

  /// Message lisible par l'utilisateur
  String get userMessage => message;

  /// Indique si l'erreur est potentiellement récupérable (retry utile)
  bool get isRetryable => this is NetworkException || this is ServerException;

  @override
  String toString() => 'AppException(${runtimeType}): $message';
}

final class NetworkException extends AppException {
  const NetworkException(this.message);
  @override
  final String message;
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException(this.message);
  @override
  final String message;
}

final class ForbiddenException extends AppException {
  const ForbiddenException(this.message);
  @override
  final String message;
}

final class NotFoundException extends AppException {
  const NotFoundException(this.message);
  @override
  final String message;
}

final class ValidationException extends AppException {
  const ValidationException(this.message);
  @override
  final String message;
}

final class ConflictException extends AppException {
  const ConflictException(this.message);
  @override
  final String message;
}

final class ServerException extends AppException {
  const ServerException(this.message);
  @override
  final String message;
}

final class UnknownException extends AppException {
  const UnknownException(this.message);
  @override
  final String message;
}
