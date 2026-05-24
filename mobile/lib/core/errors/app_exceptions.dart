/// Exceptions métier centralisées pour ReTurn
sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);
}

final class NetworkException extends AppException {
  const NetworkException([String msg = 'Erreur réseau. Vérifiez votre connexion.'])
      : super(msg);
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException([String msg = 'Session expirée. Veuillez vous reconnecter.'])
      : super(msg);
}

final class NotFoundException extends AppException {
  const NotFoundException([String msg = 'Ressource introuvable.']) : super(msg);
}

final class ServerException extends AppException {
  final int? statusCode;
  const ServerException([String msg = 'Erreur serveur.', this.statusCode])
      : super(msg);
}

final class ValidationException extends AppException {
  final Map<String, List<String>> errors;
  const ValidationException(this.errors)
      : super('Données invalides.');
}

final class StorageException extends AppException {
  const StorageException([String msg = 'Erreur de stockage local.']) : super(msg);
}
