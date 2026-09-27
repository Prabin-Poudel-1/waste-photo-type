import 'package:flutter/material.dart';

const forest = Color(0xFF173F35);
const leaf = Color(0xFFCBE69D);
const canvas = Color(0xFFF6F6EF);
const muted = Color(0xFF68776F);
const line = Color(0xFFE0E5DB);

ThemeData careTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: canvas,
  colorScheme: ColorScheme.fromSeed(
    seedColor: forest,
    primary: forest,
    secondary: leaf,
    surface: canvas,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: canvas,
    foregroundColor: forest,
    centerTitle: false,
    elevation: 0,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 38,
      height: 1.12,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.4,
      color: forest,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      height: 1.15,
      fontWeight: FontWeight.w700,
      letterSpacing: -.8,
      color: forest,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: forest,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 1.5,
      color: forest,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 1.5,
      color: muted,
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(56),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      side: const BorderSide(color: line),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  ),
  dividerTheme: const DividerThemeData(color: line),
);// Placeholder: paste the contents of mobile/lib/app/theme.dart from your app here.
