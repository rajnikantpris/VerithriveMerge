import 'package:flutter/material.dart';

import 'colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    fontFamily: 'Poppins',
    colorScheme: ColorScheme.fromSeed(seedColor: AppColor.color_32435F),
    useMaterial3: true,
    scaffoldBackgroundColor: AppColor.white,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: AppColor.white,
      elevation: 0,
      foregroundColor: AppColor.color000000,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColor.color_32435F,
        foregroundColor: AppColor.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColor.color_2FC4B2,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
  );

  static ThemeData get dark => ThemeData(
    fontFamily: 'Poppins',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColor.white,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(centerTitle: true),
  );
}
