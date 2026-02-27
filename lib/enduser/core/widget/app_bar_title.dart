import 'package:flutter/material.dart';

class AppBarTitle extends StatelessWidget {
  final String text;
  final bool innertitle;

  const AppBarTitle({Key? key, required this.text, this.innertitle = false,}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
    );
  }
}
