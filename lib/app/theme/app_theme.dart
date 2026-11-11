import 'package:flutter/material.dart';

class AppTheme {
  static const Color brandColor = Color(0xFF176B68);

  static final ThemeData lightTheme = _buildTheme(Brightness.light);

  static final ThemeData darkTheme = _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: brandColor,
      brightness: brightness,
    );

    final bool isLight = brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,

      scaffoldBackgroundColor: isLight
          ? const Color(0xFFF4F7F6)
          : const Color(0xFF101918),

      appBarTheme: AppBarTheme(
        backgroundColor: isLight
            ? const Color(0xFFF4F7F6)
            : const Color(0xFF101918),
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),

      visualDensity: VisualDensity.standard,
    );
  }
}
