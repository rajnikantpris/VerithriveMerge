import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:verithrive_dev/enduser/flavors/build_config.dart';

mixin BaseWidgetMixin on StatelessWidget {
  // AppLocalizations get appLocalization => AppLocalizations.of(Get.context!)!;
  final Logger logger = BuildConfig.instance.config.logger;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: body(context),
    );
  }

  Widget body(BuildContext context);
}
