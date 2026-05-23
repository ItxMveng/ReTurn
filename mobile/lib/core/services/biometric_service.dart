import 'package:local_auth/local_auth.dart';
import 'package:logger/logger.dart';

final _log = Logger();

/// Service wrapper autour de local_auth pour la biométrie
/// Gère l'authentification fingerprint/face ID sur Android/iOS
class BiometricService {
  BiometricService() : _localAuth = LocalAuthentication();

  final LocalAuthentication _localAuth;

  /// Vérifie si l'appareil supporte la biométrie
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      _log.w('Erreur vérification support biométrie: $e');
      return false;
    }
  }

  /// Vérifie si des données biométriques sont enregistrées
  Future<bool> isBiometricEnrolled() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      _log.w('Erreur vérification enrollment biométrie: $e');
      return false;
    }
  }

  /// Liste les types de biométrie disponibles
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      _log.w('Erreur récupération biométries disponibles: $e');
      return [];
    }
  }

  /// Authentifie l'utilisateur avec biométrie
  /// 
  /// [localizedReason] - Message affiché à l'utilisateur (requis sur iOS)
  /// [useErrorDialogs] - Affiche les dialogues d'erreur système ( défaut: true)
  /// [stickyAuth] - Reste authentifié même si l'app passe en background (défaut: false)
  /// [biometricOnly] - Force l'utilisation biométrique uniquement (défaut: false)
  /// 
  /// Retourne true si l'authentification réussit, false sinon
  Future<bool> authenticate({
    required String localizedReason,
    bool useErrorDialogs = true,
    bool stickyAuth = false,
    bool biometricOnly = false,
  }) async {
    try {
      final result = await _localAuth.authenticate(
        localizedReason: localizedReason,
        useErrorDialogs: useErrorDialogs,
        stickyAuth: stickyAuth,
        biometricOnly: biometricOnly,
      );
      _log.d('Authentification biométrique réussie');
      return result;
    } catch (e) {
      _log.w('Échec authentification biométrique: $e');
      return false;
    }
  }

  /// Annule toute authentification biométrique en cours
  Future<void> cancelAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
      _log.d('Authentification biométrique annulée');
    } catch (e) {
      _log.w('Erreur annulation authentification: $e');
    }
  }

  /// Vérifie si la biométrie est disponible et configurée
  Future<bool> isBiometricAvailable() async {
    final supported = await isDeviceSupported();
    if (!supported) return false;
    final enrolled = await isBiometricEnrolled();
    return enrolled;
  }

  /// Retourne un message localisé selon le type de biométrie disponible
  Future<String> getLocalizedReason(String userName) async {
    final available = await getAvailableBiometrics();
    if (available.contains(BiometricType.face)) {
      return 'Authentifiez-vous avec Face ID pour accéder à $userName';
    } else if (available.contains(BiometricType.fingerprint) ||
               available.contains(BiometricType.strong)) {
      return 'Authentifiez-vous avec votre empreinte pour accéder à $userName';
    } else if (available.contains(BiometricType.iris)) {
      return 'Authentifiez-vous avec reconnaissance irienne pour accéder à $userName';
    }
    return 'Authentifiez-vous pour accéder à $userName';
  }
}
