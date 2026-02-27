import 'package:flutter/material.dart';
import '../values/app_colors.dart';

class ListTileWidget extends StatelessWidget {
  final String titletext;
  final bool isSubtitle;
  final String? subtitle;
  final Function()? onClicked;

  const ListTileWidget({
     Key? key,
    required this.titletext,
    this.isSubtitle = false,
    this.subtitle,
    required this.onClicked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) =>ListTile(
    onTap: onClicked,
    title: Text(titletext),
    subtitle: isSubtitle?Text(subtitle!):Container(),
    trailing:   Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: const Icon(
        Icons.arrow_forward_ios,
        color:AppColors.black,
        size: 15.0,
      ),
    ),);

}