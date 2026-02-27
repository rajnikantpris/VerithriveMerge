import 'package:flutter/material.dart';

class AppBarTitle extends StatelessWidget {
  final String text;
  final bool ismaintitle;
  final Color titleColor;
  final double titleFontSize;
  final String titlefontFamily;

  const AppBarTitle({
    super.key,
    required this.text,
    required this.ismaintitle,
    required this.titleColor,
    required this.titleFontSize,
    required this.titlefontFamily,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: titleColor,
        fontSize: titleFontSize,
        fontFamily: titlefontFamily,
        fontWeight: ismaintitle ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}
