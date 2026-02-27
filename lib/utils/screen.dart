import 'dart:io';

import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Helpers for screen dimensions and scaling.
class Screen {
  static double get width => ScreenUtil().screenWidth;
  static double get height => ScreenUtil().screenHeight;
  static double get scale => width / 375;
  static double get heightScale => height / 812;

  static bool get isIphone => Platform.isIOS;
  static bool get isAndroid => Platform.isAndroid;
}

extension ScreenScale on num {
  /// Calculates width-based scale using a 375pt reference.
  double get ss => this * Screen.scale;

  /// Calculates height-based scale using an 812pt reference.
  double get sh => this * Screen.heightScale;
}
