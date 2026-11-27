import 'package:flutter/material.dart';

class StudioTheme {
  static const cream = Color(0xFFF4EDE4);
  static const sand = Color(0xFFD7B899);
  static const ink = Color(0xFF111111);
  static const panel = Color(0xFF1A1A1A);
  static const muted = Color(0xFFB8AFA4);

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: sand,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: ink,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: cream,
        elevation: 0,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: sand,
        thumbColor: cream,
        inactiveTrackColor: Colors.white24,
        overlayColor: sand.withValues(alpha: 0.2),
      ),
    );
  }
}
