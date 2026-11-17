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

    final ThemeData baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: 'Manrope',
    );

    final TextTheme manropeTextTheme = baseTheme.textTheme.apply(
      fontFamily: 'Manrope',
    );

    return baseTheme.copyWith(
      textTheme: manropeTextTheme,

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

      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),

      visualDensity: VisualDensity.standard,
    );
  }
}
