// lib/theme.dart
import 'package:flutter/material.dart';

ThemeData lightTheme(Color seedColor) {
  return ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: seedColor,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.red,
      unselectedItemColor: Colors.grey,
    ),
  );
}

ThemeData darkTheme(Color seedColor) {
  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: seedColor,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.black,
      selectedItemColor: Colors.redAccent,
      unselectedItemColor: Colors.grey,
    ),
  );
}
