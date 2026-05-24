import 'package:flutter/material.dart';

/// Palette de couleurs DocRetour
/// Identité : vert forêt profond + blanc cassé + accents ambre
abstract final class AppColors {
  // ── Primaire (Vert forêt) ────────────────────────────────────────────────
  static const primary        = Color(0xFF0D5C3A);
  static const primaryLight   = Color(0xFF1A7A50);
  static const primaryDark    = Color(0xFF083D27);
  static const primaryContainer = Color(0xFFB7E4C7);
  static const onPrimary      = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFF072A1B);

  // ── Secondaire (Ambre chaud) ─────────────────────────────────────────────
  static const secondary      = Color(0xFFF59E0B);
  static const secondaryLight = Color(0xFFFBBF24);
  static const secondaryDark  = Color(0xFFD97706);
  static const secondaryContainer = Color(0xFFFDE68A);
  static const onSecondary    = Color(0xFF1C1917);

  // ── Surfaces ─────────────────────────────────────────────────────────────
  static const background     = Color(0xFFF7F5F0);
  static const surface        = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFEFEDE7);
  static const surfaceTint    = Color(0xFFE8F5EE);
  static const outline        = Color(0xFFD1CFC9);
  static const outlineVariant = Color(0xFFE8E6E0);

  // ── Texte ─────────────────────────────────────────────────────────────────
  static const onBackground   = Color(0xFF1C1C1A);
  static const onSurface      = Color(0xFF28261F);
  static const onSurfaceVariant = Color(0xFF6B6960);
  static const textHint       = Color(0xFFABAA A4); // compile-safe

  // ── États ─────────────────────────────────────────────────────────────────
  static const error          = Color(0xFFDC2626);
  static const errorContainer = Color(0xFFFEE2E2);
  static const onError        = Color(0xFFFFFFFF);
  static const success        = Color(0xFF16A34A);
  static const successContainer = Color(0xFFDCFCE7);
  static const warning        = Color(0xFFF59E0B);
  static const warningContainer = Color(0xFFFEF3C7);
  static const info           = Color(0xFF0EA5E9);
  static const infoContainer  = Color(0xFFE0F2FE);

  // ── Dark mode ─────────────────────────────────────────────────────────────
  static const darkBackground     = Color(0xFF0F1A14);
  static const darkSurface        = Color(0xFF1A2B20);
  static const darkSurfaceVariant = Color(0xFF243320);
  static const darkOnBackground   = Color(0xFFE8E6E0);
  static const darkOnSurface      = Color(0xFFD6D4CE);
  static const darkOutline        = Color(0xFF3D4A42);
}
