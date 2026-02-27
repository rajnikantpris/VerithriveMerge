import 'package:flutter/material.dart';

import '../../common/base_view.dart';
import '../../theme/image_paths.dart';
import 'splash_controller.dart';

class SplashView extends BaseView<SplashController> {
  const SplashView({super.key});

  @override
  Widget buildView(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFDDF4EE),
      child: SafeArea(
        child: Center(
          child: AppImages.splash(
            width: 220,
          ),
        ),
      ),
    );
  }
}

