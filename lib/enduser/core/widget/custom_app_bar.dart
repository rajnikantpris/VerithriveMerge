import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'app_bar_title.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String appBarTitleText;
  final List<Widget>? actions;
  final bool isBackButtonEnabled;
  final bool isCenter;
  final bool bottomline;
  final bool innertitle;

  CustomAppBar({
    Key? key,
    required this.appBarTitleText,
    this.actions,
    this.isBackButtonEnabled = true,
    this.isCenter = true,
    this.bottomline = false,
    this.innertitle = true,
  }) : super(key: key);

  @override
  Size get preferredSize => AppBar().preferredSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppBar(
        bottom: bottomline
            ? PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey.withOpacity(0.1),
            height: 1.0,
          ),
        )
            : null,
        backgroundColor: AppColors.pageBackground,
        centerTitle: isCenter,
        elevation: 0, // Set to 0 when using Container shadow
        automaticallyImplyLeading: isBackButtonEnabled,
        actions: actions,
        iconTheme: const IconThemeData(
          color: AppColors.black,
          size: 24,
        ),
        title: AppBarTitle(
          text: appBarTitleText,
          innertitle: innertitle,
        ),
      ),
    );
  }
}
