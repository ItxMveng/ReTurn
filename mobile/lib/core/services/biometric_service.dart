import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

final _log = Logger();

/// Service wrapper autour de local_auth ^2.x pour la biométrie
/// Gère l'authentification fingerprint/face ID sur Android/iOS
class BiometricService {
  BiometricService() : _localAuth = LocalAuthentication();

  final LocalAuthentication _localAuth;

  /// Vérifie si l'appareil supporte la biométrie hardware
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      _log.w('Erreur vérification support biométrie: $e');
      return false;
    }
  }

  /// Vérifie si des données biométriques sont enregistrées sur l'appareil
  Future<bool> isBiometricEnrolled() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      _log.w('Erreur vérification enrollment biométrie: $e');
      return false;
    }
  }

  /// Liste les types de biométrie disponibles (fingerprint, face, iris)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      _log.w('Erreur récupération biométries disponibles: $e');
      return [];
    }
  }

  /// Authentifie l'utilisateur avec biométrie.
  ///
  /// Utilise [AuthenticationOptions] conforme à local_auth ^2.x.
  /// Les anciens paramètres nommés directs (useErrorDialogs, stickyAuth,
  /// biometricOnly) ont été supprimés dans local_auth ^2.0 — ils doivent
  /// être passés via l'objet [AuthenticationOptions].
  ///
  /// Retourne true si l'authentification réussit, false sinon.
  Future<bool> authenticate({
    required String localizedReason,
    bool useErrorDialogs = true,
    bool stickyAuth = false,
    bool biometricOnly = false,
  }) async {
    try {
      final result = await _localAuth.authenticate(
        localizedReason: localizedReason,
        // ✅ local_auth ^2.x : les options sont encapsulées dans AuthenticationOptions
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: biometricOnly,
        ),
      );
      if (result) {
        _log.d('Authentification biométrique réussie');
      } else {
        _log.w('Authentification biométrique refusée par l\'utilisateur');
      }
      return result;
    } on PlatformException catch (e) {
      // Codes d'erreur documentés dans local_auth/error_codes.dart
      switch (e.code) {
        case auth_error.notAvailable:
          _log.w('Biométrie non disponible: ${e.message}');
        case auth_error.notEnrolled:
          _log.w('Aucune biométrie enregistrée: ${e.message}');
        case auth_error.lockedOut:
          _log.w('Biométrie verrouillée (trop de tentatives): ${e.message}');
        case auth_error.permanentlyLockedOut:
          _log.e('Biométrie verrouillée définitivement: ${e.message}');
        default:
          _log.w('Erreur biométrie [${e.code}]: ${e.message}');
      }
      return false;
    } catch (e) {
      _log.w('Échec authentification biométrique inattendu: $e');
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

  /// Vérifie si la biométrie est disponible ET configurée sur l'appareil
  Future<bool> isBiometricAvailable() async {
    final supported = await isDeviceSupported();
    if (!supported) return false;
    return await isBiometricEnrolled();
  }

  /// Retourne un message localisé selon le type de biométrie disponible
  Future<String> getLocalizedReason(String userName) async {
    final available = await getAvailableBiometrics();
    if (available.contains(BiometricType.face)) {
      return 'Authentifiez-vous avec Face ID pour accéder à votre compte ($userName)';
    } else if (available.contains(BiometricType.fingerprint) ||
        available.contains(BiometricType.strong)) {
      return 'Authentifiez-vous avec votre empreinte pour accéder à votre compte ($userName)';
    } else if (available.contains(BiometricType.iris)) {
      return 'Authentifiez-vous avec reconnaissance irienne pour accéder à votre compte ($userName)';
    }
    return 'Authentifiez-vous pour accéder à votre compte ($userName)';
  }
}
