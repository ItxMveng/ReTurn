import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(brightness: Brightness.light);
  static ThemeData get dark  => _build(brightness: Brightness.dark);

  static ThemeData _build({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = isDark
        ? const ColorScheme.dark(
            primary: AppColors.darkPrimary,
            primaryContainer: Color(0xFF313B3B),
            secondary: AppColors.secondary,
            background: AppColors.darkBackground,
            surface: AppColors.darkSurface,
            surfaceVariant: AppColors.darkSurfaceVariant,
            onSurface: AppColors.darkOnSurface,
            onSurfaceVariant: AppColors.darkOnSurfaceVariant,
            outline: AppColors.darkOutline,
            error: AppColors.error,
          )
        : const ColorScheme.light(
            primary: AppColors.primary,
            primaryContainer: AppColors.primaryContainer,
            onPrimaryContainer: AppColors.onPrimaryContainer,
            secondary: AppColors.secondary,
            secondaryContainer: AppColors.secondaryContainer,
            background: AppColors.background,
            surface: AppColors.surface,
            surfaceVariant: AppColors.surfaceVariant,
            onSurface: AppColors.onSurface,
            onSurfaceVariant: AppColors.onSurfaceVariant,
            outline: AppColors.outline,
            error: AppColors.error,
          );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Satoshi',
      scaffoldBackgroundColor: colorScheme.background,

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Satoshi',
        ),
      ),

      // Boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Satoshi'),
          elevation: 0,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'Satoshi'),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Satoshi'),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.6), fontSize: 14),
      ),

      // Cards
      cardTheme: CardTheme(
        elevation: 0,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
        ),
        margin: EdgeInsets.zero,
      ),

      // BottomNav
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
      ),

      // Divider
      dividerTheme: DividerThemeData(color: colorScheme.outline.withOpacity(0.6), thickness: 1),

      // Text
      textTheme: TextTheme(
        headlineLarge:  TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: colorScheme.onSurface, fontFamily: 'Satoshi'),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: colorScheme.onSurface, fontFamily: 'Satoshi'),
        headlineSmall:  TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colorScheme.onSurface, fontFamily: 'Satoshi'),
        titleLarge:     TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface, fontFamily: 'Satoshi'),
        titleMedium:    TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface, fontFamily: 'Satoshi'),
        titleSmall:     TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.onSurface, fontFamily: 'Satoshi'),
        bodyLarge:      TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: colorScheme.onSurface, fontFamily: 'Satoshi'),
        bodyMedium:     TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: colorScheme.onSurface, fontFamily: 'Satoshi'),
        bodySmall:      TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: colorScheme.onSurfaceVariant, fontFamily: 'Satoshi'),
        labelLarge:     TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.onSurface, fontFamily: 'Satoshi'),
        labelSmall:     TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: colorScheme.onSurfaceVariant, fontFamily: 'Satoshi'),
      ),
    );
  }
}
