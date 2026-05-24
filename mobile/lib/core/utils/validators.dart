/// Validateurs de formulaires
final class Validators {
  Validators._();

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Numéro requis';
    final cleaned = v.trim().replaceAll(RegExp(r'[\s\-()]'), '');
    if (cleaned.length < 9) return 'Numéro trop court';
    if (!RegExp(r'^[+0-9]+$').hasMatch(cleaned)) return 'Numéro invalide';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Mot de passe requis';
    if (v.length < 6) return 'Min. 6 caractères';
    return null;
  }

  static String? required(String? v, {String field = 'Ce champ'}) {
    if (v == null || v.trim().isEmpty) return '$field est requis';
    return null;
  }

  static String? minLength(String? v, int min, {String field = 'Ce champ'}) {
    if (v == null || v.trim().length < min) return '$field doit faire au moins $min caractères';
    return null;
  }

  static String? name(String? v) {
    if (v == null || v.trim().isEmpty) return 'Nom requis';
    if (v.trim().length < 2) return 'Nom trop court';
    return null;
  }
}
