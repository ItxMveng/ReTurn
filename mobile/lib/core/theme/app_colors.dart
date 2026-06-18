import 'package:flutter/material.dart';

/// Palette de couleurs de l'application ReTurn
/// Primaire : Bleu-Vert (confiance, sécurité), Accent : Orange doux (action)
abstract final class AppColors {
  // ── Primaire ─────────────────────────────────────────────────
  static const primary           = Color(0xFF01696F); // Teal
  static const primaryContainer  = Color(0xFFCEDCD8);
  static const onPrimary         = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFF002022);

  // ── Secondaire ───────────────────────────────────────────────
  static const secondary         = Color(0xFFDA7101); // Orange
  static const secondaryContainer = Color(0xFFFFDCC1);
  static const onSecondary       = Color(0xFFFFFFFF);

  // ── Surfaces ─────────────────────────────────────────────────
  static const background        = Color(0xFFF7F6F2);
  static const surface           = Color(0xFFF9F8F5);
  static const surfaceVariant    = Color(0xFFF3F0EC);
  static const onSurface         = Color(0xFF28251D);
  static const onSurfaceVariant  = Color(0xFF7A7974);
  static const outline           = Color(0xFFD4D1CA);
  static const divider           = Color(0xFFDCD9D5);

  // ── États ────────────────────────────────────────────────────
  static const error             = Color(0xFFA12C7B);
  static const onError           = Color(0xFFFFFFFF);
  static const success           = Color(0xFF437A22);
  static const warning           = Color(0xFF964219);

  // Couleurs additionnelles utilisées dans l'interface
  static const kGreen            = Color(0xFF437A22);
  static const kGreenDark        = Color(0xFF2E4D14);

  // ── Dark mode ────────────────────────────────────────────────
  static const darkBackground    = Color(0xFF171614);
  static const darkSurface       = Color(0xFF1C1B19);
  static const darkSurfaceVariant = Color(0xFF22211F);
  static const darkOnSurface     = Color(0xFFCDCCCA);
  static const darkOnSurfaceVariant = Color(0xFF797876);
  static const darkOutline       = Color(0xFF393836);
  static const darkPrimary       = Color(0xFF4F98A3);
}
