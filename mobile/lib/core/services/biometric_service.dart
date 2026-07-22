import 'package:local_auth/local_auth.dart';

/// Authentification biométrique (empreinte / Face ID) — F-03.
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// L'appareil supporte la biométrie ET au moins une empreinte/visage est enrôlé.
  static Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (!supported || !canCheck) return false;
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Demande l'authentification. Retourne true si validée.
  static Future<bool> authenticate({
    String reason = 'Confirmez votre identité pour ouvrir ReTurn',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // autorise le code de l'appareil en repli
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
