import 'package:flutter/material.dart';

/// Couleurs publiques utilisées directement dans les widgets
const kGreen = Color(0xFF437A22);
const kGreenDark = Color(0xFF2E4D14);

const _green = Color(0xFF01696F);
const _greenDark = Color(0xFF4F98A3);
const _bgLight = Color(0xFFF7F6F2);
const _bgDark = Color(0xFF171614);
const _surfaceLight = Color(0xFFF9F8F5);
const _surfaceDark = Color(0xFF1C1B19);

class AppTheme {
  static ThemeData get light => _build(
        brightness: Brightness.light,
        seed: _green,
        bg: _bgLight,
        surface: _surfaceLight,
        onSurface: const Color(0xFF28251D),
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        seed: _greenDark,
        bg: _bgDark,
        surface: _surfaceDark,
        onSurface: const Color(0xFFCDCCCA),
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color seed,
    required Color bg,
    required Color surface,
    required Color onSurface,
  }) {
    final cs = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      surface: surface,
    ).copyWith(surface: bg);

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: bg,
      fontFamily: 'Satoshi',
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Satoshi',
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: onSurface,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
              fontFamily: 'Satoshi',
              fontWeight: FontWeight.w700,
              fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: onSurface.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: onSurface.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: seed, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: onSurface.withValues(alpha: 0.08)),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: seed.withValues(alpha: 0.1),
        labelStyle: TextStyle(
            color: seed, fontWeight: FontWeight.w600, fontSize: 12),
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
    );
  }
}
