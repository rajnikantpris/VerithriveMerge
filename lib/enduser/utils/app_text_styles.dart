import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Rubik Regular
  static TextStyle rubikRegular({
    double fontSize = 14,
    Color color = AppColors.blueColor,
  }) {
    return TextStyle(
      fontFamily: 'Rubik',
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.normal,
    );
  }

  // Rubik Medium
  static TextStyle rubikMedium({
    double fontSize = 14,
    Color color = AppColors.blueColor,
  }) {
    return TextStyle(
      fontFamily: 'Rubik',
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w500,
    );
  }

  // Rubik Bold
  static TextStyle rubikBold({
    double fontSize = 14,
    Color color = AppColors.blueColor,
  }) {
    return TextStyle(
      fontFamily: 'Rubik',
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle titleStyle({
    double fontSize = 23,
    Color color = AppColors.blueColor,
  }) {
    return TextStyle(
      fontFamily: 'Rubik',
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle titleStyleBlack({
    double fontSize = 24,
    Color color = AppColors.black,
  }) {
    return TextStyle(
      fontFamily: 'Rubik',
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle appBarTitle({
    double fontSize = 18,
    Color color = AppColors.black,
  }) {
    return TextStyle(
      fontFamily: 'Rubik',
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle labelStyle({
    double fontSize = 14,
    Color color = AppColors.color2D2D2D,
  }) {
    return TextStyle(
      fontFamily: 'Rubik',
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w400,
    );
  }

  static TextStyle inputStyle({
    double fontSize = 14,
    Color color = AppColors.color2D2D2D,
  }) {
    return TextStyle(
      fontFamily: 'Rubik',
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w400,
    );
  }

  static TextStyle hintStyle({
    double fontSize = 14,
    Color color = AppColors.color9D9D9D,
  }) {
    return TextStyle(
      fontFamily: 'Rubik',
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w400,
    );
  }

  static TextStyle helperStyle({
    double fontSize = 14,
    Color color = AppColors.color929292,
  }) {
    return TextStyle(
      fontFamily: 'Rubik',
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w400,
    );
  }

  static TextStyle linkStyle({
    double fontSize = 14,
    Color color = AppColors.primaryColor,
  }) {
    return TextStyle(
      fontFamily: 'Rubik',
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle homeTitleStyle({
    double fontSize = 20,
    Color color = AppColors.blueColor,
  }) {
    return TextStyle(
      fontFamily: 'Rubik',
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle priceSemiboldStyle({
    double fontSize = 16,
    Color color = AppColors.black,
  }) {
    return TextStyle(
      fontFamily: 'Rubik',
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle homeTextStyle({
    double fontSize = 14,
    Color color = AppColors.blueColor,
  }) {
    return TextStyle(
      fontFamily: 'Rubik',
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle regularTextStyle({
    double fontSize = 14,
    Color color = AppColors.blueColor,
  }) {
    return TextStyle(
      fontFamily: 'Rubik',
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w400,
      decoration: TextDecoration.none
    );
  }

  static TextStyle mediumTextStyle({
    double fontSize = 14,
    Color color = AppColors.blueColor,
  }) {
    return TextStyle(
      fontFamily: 'Rubik',
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle semiboldTextStyle({
    double fontSize = 14,
    Color color = AppColors.blueColor,
  }) {
    return TextStyle(
      fontFamily: 'Rubik',
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle popinMediumTextStyle({
    double fontSize = 14,
    Color color = AppColors.black,
  }) {
    return TextStyle(
      fontFamily: 'Popin',
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle popinRegularTextStyle({
    double fontSize = 14,
    Color color = AppColors.black,
  }) {
    return TextStyle(
      fontFamily: 'Popin',
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w400,
    );
  }

  static TextStyle popinSemiboldTextStyle({
    double fontSize = 14,
    Color color = AppColors.black,
  }) {
    return TextStyle(
      fontFamily: 'Popin',
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle boldTextStyle({
    double fontSize = 14,
    Color color = AppColors.blueColor,
  }) {
    return TextStyle(
      fontFamily: 'Rubik',
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle buttonTextStyle({
    double fontSize = 16,
    Color color = AppColors.white,
  }) {
    return TextStyle(
      fontFamily: 'Rubik',
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle appBarTitleTextStyle({
    double fontSize = 18,
    Color color = AppColors.color2D3648,
  }) {
    return TextStyle(
      fontFamily: 'Rubik',
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle lightTextStyle({
    double fontSize = 14,
    Color color = AppColors.black,
  }) {
    return TextStyle(
      fontFamily: 'Rubik',
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w300,
    );
  }


  // Helper Text Style
/*  static TextStyle helperStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.grey,
  );*/

  // Button Text Style
  static TextStyle buttonStyle = TextStyle(
    fontSize: 16,
    fontFamily: 'Rubik',
    fontWeight: FontWeight.w500,
    color: AppColors.white,
  );



  static TextStyle clickTextStyle = TextStyle(
    fontSize: 14,
    fontFamily: 'Rubik',
    fontWeight: FontWeight.w500,
    color: AppColors.blueColor,
  );

  // Private constructor to prevent instantiation
  AppTextStyles._();
}
