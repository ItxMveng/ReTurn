import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Brand colors ─────────────────────────────────────────────────────────────
const Color kGreen     = Color(0xFF22C55E);  // accent — bright green
const Color kGreenDark = Color(0xFF16A34A);  // hover/pressed green
const Color kForest    = Color(0xFF0D2B1F);  // deep forest green (dark surfaces)

// ── Light theme (vert + blanc) ────────────────────────────────────────────────
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary:       kGreen,
    onPrimary:     Colors.white,
    secondary:     kForest,
    onSecondary:   Colors.white,
    surface:       Color(0xFFF0FDF4),
    onSurface:     Color(0xFF0D2B1F),
    surfaceContainerHighest: Color(0xFFDCFCE7),
    error:         Color(0xFFEF4444),
    onError:       Colors.white,
    outline:       Color(0xFFBBF7D0),
  ),
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    foregroundColor: kForest,
    titleTextStyle: TextStyle(
      color: kForest, fontSize: 18, fontWeight: FontWeight.w700,
    ),
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFF8FFFE),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFBBF7D0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFBBF7D0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: kGreen, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFEF4444)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    labelStyle: const TextStyle(color: Color(0xFF4B7A5C)),
    hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kGreen,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: kForest,
      minimumSize: const Size.fromHeight(52),
      side: const BorderSide(color: Color(0xFFBBF7D0), width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: kGreen,
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFDCFCE7)),
    ),
  ),
  chipTheme: const ChipThemeData(
    labelStyle: TextStyle(fontSize: 12),
  ),
  dividerTheme: const DividerThemeData(color: Color(0xFFDCFCE7)),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: kGreen,
    foregroundColor: Colors.white,
    shape: CircleBorder(),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);

// ── Dark theme (vert sombre) ──────────────────────────────────────────────────
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary:       kGreen,
    onPrimary:     Colors.white,
    secondary:     Color(0xFF4ADE80),
    onSecondary:   Color(0xFF0D2B1F),
    surface:       Color(0xFF0F1F17),
    onSurface:     Color(0xFFE2F5EB),
    surfaceContainerHighest: Color(0xFF1A3327),
    error:         Color(0xFFFF6B6B),
    onError:       Colors.white,
    outline:       Color(0xFF2D5A40),
  ),
  scaffoldBackgroundColor: const Color(0xFF0A1410),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    foregroundColor: Color(0xFFE2F5EB),
    titleTextStyle: TextStyle(
      color: Color(0xFFE2F5EB), fontSize: 18, fontWeight: FontWeight.w700,
    ),
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF1A3327),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF2D5A40)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF2D5A40)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: kGreen, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    labelStyle: const TextStyle(color: Color(0xFF86B89A)),
    hintStyle: const TextStyle(color: Color(0xFF4A7A5E)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kGreen,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: kGreen,
      minimumSize: const Size.fromHeight(52),
      side: const BorderSide(color: Color(0xFF2D5A40), width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: kGreen,
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: const Color(0xFF1A3327),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFF2D5A40)),
    ),
  ),
  chipTheme: const ChipThemeData(labelStyle: TextStyle(fontSize: 12)),
  dividerTheme: const DividerThemeData(color: Color(0xFF2D5A40)),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: kGreen,
    foregroundColor: Colors.white,
    shape: CircleBorder(),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);

// ── Night-Blue theme (vert + bleu nuit) ───────────────────────────────────────
final ThemeData nightBlueTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary:       kGreen,
    onPrimary:     Colors.white,
    secondary:     Color(0xFF60A5FA),
    onSecondary:   Color(0xFF0D1B2A),
    surface:       Color(0xFF0D1B2A),
    onSurface:     Color(0xFFE2EAF5),
    surfaceContainerHighest: Color(0xFF152336),
    error:         Color(0xFFFF6B6B),
    onError:       Colors.white,
    outline:       Color(0xFF1E3A5F),
  ),
  scaffoldBackgroundColor: const Color(0xFF091525),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    foregroundColor: Color(0xFFE2EAF5),
    titleTextStyle: TextStyle(
      color: Color(0xFFE2EAF5), fontSize: 18, fontWeight: FontWeight.w700,
    ),
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF152336),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF1E3A5F)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF1E3A5F)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: kGreen, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    labelStyle: const TextStyle(color: Color(0xFF7EA8CC)),
    hintStyle: const TextStyle(color: Color(0xFF3A5A7A)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kGreen,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: kGreen,
      minimumSize: const Size.fromHeight(52),
      side: const BorderSide(color: Color(0xFF1E3A5F), width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: kGreen,
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: const Color(0xFF152336),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFF1E3A5F)),
    ),
  ),
  chipTheme: const ChipThemeData(labelStyle: TextStyle(fontSize: 12)),
  dividerTheme: const DividerThemeData(color: Color(0xFF1E3A5F)),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: kGreen,
    foregroundColor: Colors.white,
    shape: CircleBorder(),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);

// ── Helpers (to keep screens theme-agnostic) ─────────────────────────────────
// Header gradient adapts to theme brightness
List<Color> headerGradient(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  if (cs.brightness == Brightness.light) {
    return const [Color(0xFF0A1F16), Color(0xFF0D2B1F)];
  }
  return [cs.surface, cs.surfaceContainerHighest];
}
