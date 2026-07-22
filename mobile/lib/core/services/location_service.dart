import 'package:geolocator/geolocator.dart';

/// Géolocalisation (F-14) — récupère la position, avec précision volontairement
/// réduite à l'échelle de la commune (arrondi ~1 km) pour la confidentialité.
class LocationService {
  /// Position courante arrondie, ou null si indisponible/refusée.
  static Future<({double latitude, double longitude})?> coarsePosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.low),
      );
      // Arrondi à 2 décimales (~1,1 km) → niveau commune, pas adresse exacte.
      return (
        latitude: _round2(pos.latitude),
        longitude: _round2(pos.longitude),
      );
    } catch (_) {
      return null;
    }
  }

  static double _round2(double v) => (v * 100).roundToDouble() / 100;
}
