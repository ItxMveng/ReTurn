// Formatage des messages de chat : rend lisibles les messages de
// localisation et masque les données sensibles (F-12).

final _coordRe = RegExp(r'^\s*-?\d{1,3}\.\d+\s*,\s*-?\d{1,3}\.\d+\s*$');

/// true si le contenu est une paire de coordonnées GPS "lat,lng".
bool isLocationMessage(String content) => _coordRe.hasMatch(content);

/// Affichage lisible d'un message (coordonnées brutes → libellé parlant).
String displayMessage(String content) =>
    isLocationMessage(content) ? '📍 Position partagée' : content;

/// Masque partiellement un numéro de document / identifiant sensible (F-12) :
/// ne garde que les 4 derniers caractères. "100660379" → "*****0379".
String maskId(String value) {
  final v = value.trim();
  if (v.length <= 4) return '*' * v.length;
  return '${'*' * (v.length - 4)}${v.substring(v.length - 4)}';
}
