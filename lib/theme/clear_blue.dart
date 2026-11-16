import 'package:flutter/material.dart';

/// Shared tokens from the Clear Blue Figma collection.
abstract final class ClearBlue {
  static const background = Color(0xfff4f7fb);
  static const panel = Colors.white;
  static const ink = Color(0xff102d49);
  static const muted = Color(0xff5d6d7b);
  static const line = Color(0xffdce5ed);
  static const accent = Color(0xff0868b9);
  static const soft = Color(0xffe4f1ff);
  static const heading = TextStyle(
      fontFamily: 'Roboto',
      fontSize: 32,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: ink);
  static const subheading = TextStyle(
      fontFamily: 'Roboto',
      fontSize: 22,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: ink);
  static const label = TextStyle(
      fontFamily: 'Roboto',
      fontSize: 12,
      height: 1.2,
      fontWeight: FontWeight.w500,
      color: muted);

  static ThemeData get theme {
    final scheme = ColorScheme.fromSeed(seedColor: accent).copyWith(
      primary: accent,
      onPrimary: panel,
      primaryContainer: soft,
      onPrimaryContainer: accent,
      surface: panel,
      onSurface: ink,
      onSurfaceVariant: muted,
      outline: line,
      outlineVariant: line,
      surfaceContainerLowest: background,
      surfaceContainerLow: background,
    );
    final border = OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: line));
    final base = ThemeData(
        useMaterial3: true, colorScheme: scheme, fontFamily: 'Roboto');
    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme:
          base.textTheme.apply(bodyColor: ink, displayColor: ink).copyWith(
                headlineLarge: heading,
                titleLarge: subheading,
                bodyMedium: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    height: 1.4,
                    color: ink),
                bodySmall: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    height: 1.4,
                    color: muted),
              ),
      appBarTheme: const AppBarTheme(
          backgroundColor: panel,
          foregroundColor: ink,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false),
      dividerTheme: const DividerThemeData(color: line, thickness: 1),
      cardTheme: CardThemeData(
          color: panel,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: line))),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: panel,
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
              borderSide: const BorderSide(color: accent, width: 2)),
          contentPadding: const EdgeInsets.all(16),
          labelStyle: label),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: panel,
              minimumSize: const Size(48, 52),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)))),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
              foregroundColor: ink,
              backgroundColor: panel,
              minimumSize: const Size(48, 52),
              side: const BorderSide(color: line),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)))),
      bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: panel,
          surfaceTintColor: Colors.transparent,
          showDragHandle: true,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)))),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: accent, foregroundColor: panel, elevation: 2),
    );
  }
}
