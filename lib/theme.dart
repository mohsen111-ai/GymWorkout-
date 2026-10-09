import 'package:flutter/material.dart';

/// Mighty Bean palette, taken from the approved design board.
class C {
  static const ink = Color(0xFF0E1512);
  static const pot = Color(0xFF17211C);
  static const pot2 = Color(0xFF1F2C26);
  static const line = Color(0xFF2B3A33);
  static const text = Color(0xFFF1F5EE);
  static const soft = Color(0xFFC9D6CE);
  static const muted = Color(0xFF9DB0A5);
  static const lime = Color(0xFFC8F560);
  static const limeDark = Color(0xFF9BC93A);
  static const coral = Color(0xFFFF7F5C);
  static const sky = Color(0xFF6EC1FF);
  static const butter = Color(0xFFFFD95A);
}

class T {
  static TextStyle display(double size, {Color color = C.text}) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w800,
    letterSpacing: -size * 0.02,
    height: 1.05,
    color: color,
  );
  static TextStyle body(
    double size, {
    Color color = C.text,
    FontWeight weight = FontWeight.w400,
  }) =>
      TextStyle(fontSize: size, fontWeight: weight, color: color, height: 1.35);
  static TextStyle label({Color color = C.muted}) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
    color: color,
  );
}

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: C.ink,
    colorScheme: const ColorScheme.dark(
      primary: C.lime,
      onPrimary: C.ink,
      secondary: C.coral,
      surface: C.pot,
      onSurface: C.text,
    ),
    splashFactory: InkSparkle.splashFactory,
    textTheme: base.textTheme.apply(bodyColor: C.text, displayColor: C.text),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.pot,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: C.line, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: C.line, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: C.lime, width: 2),
      ),
      labelStyle: const TextStyle(color: C.muted),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: C.pot,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: C.pot,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
  );
}
