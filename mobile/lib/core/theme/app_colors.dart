import 'package:flutter/material.dart';

/// Palette de couleurs de l'application ReTurn — sensible au thème.
///
/// Les couleurs dépendantes du mode (fonds, surfaces, textes) sont exposées
/// via des getters qui basculent clair/sombre selon [brightness], piloté par
/// l'app (voir main.dart). Les écrans continuent d'utiliser `AppColors.x`
/// mais s'affichent désormais correctement en mode sombre.
abstract final class AppColors {
  // Luminosité courante, mise à jour par l'app à chaque changement de thème.
  static Brightness _brightness = Brightness.light;
  static set brightness(Brightness value) => _brightness = value;
  static bool get _dark => _brightness == Brightness.dark;

  static Color _pick(Color light, Color dark) => _dark ? dark : light;

  // ── Primaire (teal ReTurn #01696F — accent #4FCFD6 en sombre) ──────
  static Color get primary =>
      _pick(const Color(0xFF01696F), const Color(0xFF4FCFD6));
  static Color get primaryContainer =>
      _pick(const Color(0xFFD6EEF0), const Color(0xFF0A3235));
  static const onPrimary = Color(0xFFFFFFFF);
  static Color get onPrimaryContainer =>
      _pick(const Color(0xFF013A3E), const Color(0xFFA8E6EA));

  // Accent de la charte (turquoise clair)
  static const accent = Color(0xFF4FCFD6);

  // ── Secondaire (orange) ──────────────────────────────────────
  static const secondary = Color(0xFFDA7101);
  static const secondaryContainer = Color(0xFFFFDCC1);
  static const onSecondary = Color(0xFFFFFFFF);

  // ── Surfaces (dépendantes du thème) ──────────────────────────
  static Color get background =>
      _pick(const Color(0xFFF7F6F2), const Color(0xFF171614));
  static Color get surface =>
      _pick(const Color(0xFFF9F8F5), const Color(0xFF1F1E1C));
  static Color get surfaceVariant =>
      _pick(const Color(0xFFF3F0EC), const Color(0xFF26251F));
  static Color get onSurface =>
      _pick(const Color(0xFF28251D), const Color(0xFFE7E6E3));
  static Color get onSurfaceVariant =>
      _pick(const Color(0xFF7A7974), const Color(0xFF9C9B97));
  static Color get outline =>
      _pick(const Color(0xFFD4D1CA), const Color(0xFF3A3935));
  static Color get divider =>
      _pick(const Color(0xFFDCD9D5), const Color(0xFF2D2C29));

  // ── États ────────────────────────────────────────────────────
  static const error = Color(0xFFD92D5A);
  static const onError = Color(0xFFFFFFFF);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFF964219);

  // Couleurs de marque additionnelles (teal charte #01696F)
  static const kGreen = Color(0xFF01696F);
  static const kGreenDark = Color(0xFF01565B);
}
