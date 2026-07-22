import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Sélection d'images robuste, partagée par toutes les features.
///
/// IMPORTANT : le manifest Android déclare `android.permission.CAMERA`
/// (exigée par le plugin `camera`). Dans ce cas, image_picker EXIGE que la
/// permission soit accordée à l'exécution AVANT `pickImage(camera)` — sinon
/// l'appel échoue silencieusement (écran noir / aucun retour).
class MediaService {
  MediaService._();

  /// Ouvre la caméra ou la galerie et retourne le fichier choisi.
  /// Retourne `(file: null, error: message)` en cas de refus de permission
  /// ou d'erreur — message prêt à afficher à l'utilisateur.
  static Future<({XFile? file, String? error})> pickImage({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    int imageQuality = 80,
    double maxWidth = 1600,
  }) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (status.isPermanentlyDenied) {
        return (
          file: null,
          error: 'Accès caméra refusé. Autorisez la caméra dans '
              'Paramètres > Applications > ReTurn > Autorisations.',
        );
      }
      if (!status.isGranted) {
        return (
          file: null,
          error: 'L\'accès à la caméra est nécessaire pour prendre la photo.',
        );
      }
    }
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        preferredCameraDevice: preferredCameraDevice,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
      );
      return (file: file, error: null);
    } catch (_) {
      return (
        file: null,
        error: source == ImageSource.camera
            ? 'Impossible d\'ouvrir la caméra. Réessayez.'
            : 'Impossible d\'ouvrir la galerie. Réessayez.',
      );
    }
  }
}
