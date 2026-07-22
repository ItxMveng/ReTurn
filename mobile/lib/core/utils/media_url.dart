import '../config/app_config.dart';

/// Réécrit une URL d'image stockée (MinIO) vers le proxy média du backend.
///
/// Les URLs enregistrées en base pointent vers l'hôte public de MinIO, qui
/// peut être injoignable depuis le téléphone (IP figée). L'app, elle, atteint
/// toujours le backend : on reconstruit donc l'URL vers `/api/v1/media/...`,
/// en conservant le chemin (bucket + objet).
///
/// - `http://host:9000/bucket/user/decl/x.jpg` → `{apiOrigin}/api/v1/media/bucket/user/decl/x.jpg`
/// - chemin relatif `/bucket/...` ou `bucket/...` → idem
/// - vide/null → chaîne vide (le widget affiche son fallback)
String mediaUrl(String? stored) {
  final raw = stored?.trim() ?? '';
  if (raw.isEmpty) return '';

  String path;
  final uri = Uri.tryParse(raw);
  if (uri != null && uri.hasScheme) {
    // URL absolue : on ne garde que le chemin (après l'hôte).
    path = uri.path;
  } else {
    path = raw;
  }
  path = path.startsWith('/') ? path.substring(1) : path;
  if (path.isEmpty) return '';

  // Déjà une URL de proxy (redéploiement) → éviter le double préfixe.
  if (path.startsWith('api/v1/media/')) {
    path = path.substring('api/v1/media/'.length);
  }
  return '${AppConfig.apiOrigin}/api/v1/media/$path';
}
