import 'package:flutter/material.dart';

abstract final class CivicColors {
  static const canvas = Color(0xFFF4F6F9);
  static const surface = Colors.white;
  static const border = Color(0xFFE2E8F0);
  static const navy = Color(0xFF162B64);
  static const teal = Color(0xFF0F766E);
  static const green = Color(0xFF15803D);
  static const red = Color(0xFFB91C1C);
  static const ink = Color(0xFF18233C);
  static const muted = Color(0xFF4E5E75);
  static const blueLight = Color(0xFFEBF0FA);
  static const tealLight = Color(0xFFE6F4F1);
  static const greenLight = Color(0xFFEAF6EE);
  static const redLight = Color(0xFFFDEEEE);
}

const citizenPortrait = 'assets/images/aarav-sharma.webp';

ThemeData civicTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: CivicColors.canvas,
    colorScheme: const ColorScheme.light(
      primary: CivicColors.navy,
      secondary: CivicColors.teal,
      surface: CivicColors.surface,
      onSurface: CivicColors.ink,
      error: CivicColors.red,
    ),
    fontFamily: 'Inter',
    fontFamilyFallback: const ['Noto Sans Devanagari'],
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: CivicColors.border),
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: CivicColors.canvas,
      foregroundColor: CivicColors.navy,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: CivicColors.navy,
        fontFamily: 'Inter',
        fontFamilyFallback: ['Noto Sans Devanagari'],
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    textTheme: base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium!.copyWith(
        fontSize: 28,
        height: 1.2,
        letterSpacing: -.85,
        color: CivicColors.navy,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: base.textTheme.titleLarge!.copyWith(
        fontSize: 19,
        letterSpacing: -.35,
        color: CivicColors.navy,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.textTheme.titleMedium!.copyWith(
        fontSize: 15,
        color: CivicColors.ink,
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: base.textTheme.bodyMedium!.copyWith(height: 1.45),
      bodySmall: base.textTheme.bodySmall!.copyWith(
        color: CivicColors.muted,
        height: 1.4,
      ),
    ),
    dividerTheme: const DividerThemeData(color: CivicColors.border, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: CivicColors.navy, width: 1.5),
      ),
      filled: true,
      fillColor: CivicColors.surface,
      hintStyle: const TextStyle(color: CivicColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
  );
}
