import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_assets.dart';
import 'splash_controller.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access controller to ensure it's initialized
    controller;
    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      body: Center(
        child: Image.asset(
          AppAssets.app_logo_splash,
          width: 200,
          height: 200,
          fit: BoxFit.contain,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stackTrace) {
                return const Icon(
                  Icons.error_outline,
                  size: 200,
                  color: AppColors.primaryColor,
                );
              },
        ),
      ),
    );
  }
}
