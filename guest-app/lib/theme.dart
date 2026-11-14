import 'package:flutter/material.dart';

/// Cabo brand colours for the rider app's light layout.
class CaboColors {
  static const green = Color(0xFF0F5B36);
  static const deepGreen = Color(0xFF0B4A2E);
  static const greenSoft = Color(0xFFE5F3EA);
  static const brightGreen = Color(0xFF22A35A);
  static const yellow = Color(0xFFFFC72C);
  static const yellowSoft = Color(0xFFFFF4D1);
  static const onYellow = Color(0xFF0B2E1C);
  static const ink = Color(0xFF12261B);
  static const muted = Color(0xFF6B7B72);
  static const line = Color(0xFFE4EBE6);
  static const surface = Color(0xFFF4F7F5);
  static const background = Colors.white;
  static const red = Color(0xFFE5484D);
  static const orange = Color(0xFFF08C2E);
  static const blue = Color(0xFF2F80ED);
}

const _fallback = ['NotoSansSymbols'];

/// Text styles used across screens.
class CaboText {
  static const display = TextStyle(
    fontFamily: 'Poppins',
    fontFamilyFallback: _fallback,
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: CaboColors.ink,
    height: 1.1,
  );
  static const h1 = TextStyle(
    fontFamily: 'Poppins',
    fontFamilyFallback: _fallback,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: CaboColors.ink,
    height: 1.2,
  );
  static const h2 = TextStyle(
    fontFamily: 'Poppins',
    fontFamilyFallback: _fallback,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: CaboColors.ink,
    height: 1.25,
  );
  static const h3 = TextStyle(
    fontFamily: 'Poppins',
    fontFamilyFallback: _fallback,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: CaboColors.ink,
    height: 1.3,
  );
  static const body = TextStyle(
    fontFamily: 'Poppins',
    fontFamilyFallback: _fallback,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: CaboColors.ink,
    height: 1.45,
  );
  static const muted = TextStyle(
    fontFamily: 'Poppins',
    fontFamilyFallback: _fallback,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: CaboColors.muted,
    height: 1.4,
  );
  static const label = TextStyle(
    fontFamily: 'Poppins',
    fontFamilyFallback: _fallback,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: CaboColors.muted,
    height: 1.3,
  );
}

ThemeData buildCaboTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: CaboColors.green,
        brightness: Brightness.light,
      ).copyWith(
        primary: CaboColors.green,
        onPrimary: Colors.white,
        secondary: CaboColors.yellow,
        onSecondary: CaboColors.onYellow,
        surface: CaboColors.background,
        onSurface: CaboColors.ink,
        error: CaboColors.red,
      );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: CaboColors.line),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Poppins',
    fontFamilyFallback: _fallback,
    scaffoldBackgroundColor: CaboColors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: CaboColors.background,
      foregroundColor: CaboColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: CaboText.h3,
    ),
    dividerTheme: const DividerThemeData(
      color: CaboColors.line,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CaboColors.surface,
      hintStyle: CaboText.muted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: CaboColors.green, width: 1.5),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? CaboColors.green
            : CaboColors.line,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? CaboColors.green
            : Colors.transparent,
      ),
      checkColor: const WidgetStatePropertyAll(Colors.white),
      side: const BorderSide(color: CaboColors.muted, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: CaboColors.green,
      thumbColor: CaboColors.green,
      inactiveTrackColor: CaboColors.line,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: CaboColors.green,
      linearTrackColor: CaboColors.line,
    ),
  );
}
