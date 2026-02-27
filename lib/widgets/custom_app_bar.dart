import 'package:flutter/material.dart';

import 'app_bar_title.dart';
import '../theme/colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String appBarTitleText;
  final List<Widget>? actions;
  final Widget? leading;
  final bool isBackButtonEnabled;
  final bool isCenterTitle;
  final bool ismaintitle;
  final double? leadingWidth;
  final Color titleColor;
  final double titleFontSize;
  final String titlefontFamily;

  const CustomAppBar({
    super.key,
    required this.appBarTitleText,
    this.actions,
    this.leading,
    this.leadingWidth,
    this.ismaintitle = false,
    this.isBackButtonEnabled = true,
    this.isCenterTitle = true,
    required this.titleColor,
    required this.titleFontSize,
    required this.titlefontFamily,
  });

  @override
  Size get preferredSize => AppBar().preferredSize;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColor.white,
      centerTitle: isCenterTitle,
      elevation: 0,
      automaticallyImplyLeading: isBackButtonEnabled,
      actions: actions,
      leading: leading,
      leadingWidth: leadingWidth,
      iconTheme: const IconThemeData(color: AppColor.color000000),
      title: AppBarTitle(
        text: appBarTitleText,
        ismaintitle: ismaintitle,
        titleColor: titleColor,
        titleFontSize: titleFontSize,
        titlefontFamily: titlefontFamily,
      ),
    );
  }
}
