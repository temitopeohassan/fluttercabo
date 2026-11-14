import 'package:flutter/material.dart';

/// Cabo brand colours, tuned for the driver app's dark, low-glare layout.
class CaboColors {
  static const deepGreen = Color(0xFF083A24);
  static const surface = Color(0xFF0E4A2F);
  static const surfaceHigh = Color(0xFF15593A);
  static const outline = Color(0xFF26704C);
  static const green = Color(0xFF1B7A45);
  static const brightGreen = Color(0xFF2BD67B);
  static const yellow = Color(0xFFFFC72C);
  static const yellowSoft = Color(0xFFFFE38A);
  static const red = Color(0xFFFF5A5F);
  static const orange = Color(0xFFFF9F43);
  static const blue = Color(0xFF4DA3FF);
  static const text = Colors.white;
  static const muted = Color(0xFFA7C6B4);
  static const faint = Color(0xFF6E9A82);
  static const onYellow = Color(0xFF062B1A);
}

const _fallback = ['NotoSansSymbols'];

/// Text styles used across screens.
class CaboText {
  static const display = TextStyle(
    fontFamily: 'Poppins',
    fontFamilyFallback: _fallback,
    fontSize: 40,
    fontWeight: FontWeight.w800,
    color: CaboColors.text,
    height: 1.1,
  );
  static const h1 = TextStyle(
    fontFamily: 'Poppins',
    fontFamilyFallback: _fallback,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: CaboColors.text,
    height: 1.2,
  );
  static const h2 = TextStyle(
    fontFamily: 'Poppins',
    fontFamilyFallback: _fallback,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: CaboColors.text,
    height: 1.25,
  );
  static const h3 = TextStyle(
    fontFamily: 'Poppins',
    fontFamilyFallback: _fallback,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: CaboColors.text,
    height: 1.3,
  );
  static const body = TextStyle(
    fontFamily: 'Poppins',
    fontFamilyFallback: _fallback,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: CaboColors.text,
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
    letterSpacing: 0.4,
  );
}

ThemeData buildCaboTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: CaboColors.green,
        brightness: Brightness.dark,
      ).copyWith(
        primary: CaboColors.yellow,
        onPrimary: CaboColors.onYellow,
        secondary: CaboColors.brightGreen,
        surface: CaboColors.deepGreen,
        onSurface: CaboColors.text,
        error: CaboColors.red,
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Poppins',
    fontFamilyFallback: _fallback,
    scaffoldBackgroundColor: CaboColors.deepGreen,
    appBarTheme: const AppBarTheme(
      backgroundColor: CaboColors.deepGreen,
      foregroundColor: CaboColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: CaboText.h3,
    ),
    dividerTheme: const DividerThemeData(
      color: CaboColors.outline,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CaboColors.surface,
      labelStyle: CaboText.muted,
      hintStyle: CaboText.muted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: CaboColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: CaboColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: CaboColors.yellow, width: 1.5),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? CaboColors.onYellow
            : CaboColors.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? CaboColors.yellow
            : CaboColors.surfaceHigh,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? CaboColors.yellow
            : Colors.transparent,
      ),
      checkColor: const WidgetStatePropertyAll(CaboColors.onYellow),
      side: const BorderSide(color: CaboColors.muted, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: CaboColors.yellow,
      thumbColor: CaboColors.yellow,
      inactiveTrackColor: CaboColors.surfaceHigh,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: CaboColors.yellow,
      linearTrackColor: CaboColors.surfaceHigh,
    ),
  );
}
