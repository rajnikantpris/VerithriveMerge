import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/core/base/base_controller.dart';
import 'package:verithrive_dev/professional/onboarding/onboarding_binding.dart'
    as professional_onboarding;
import 'package:verithrive_dev/professional/onboarding/onboarding_view.dart';
import 'package:verithrive_dev/enduser/screens/onboarding/onboarding_binding.dart'
    as enduser_onboarding;
import 'package:verithrive_dev/enduser/screens/onboarding/onboarding_screen.dart';
import 'package:verithrive_dev/services/notification_permission_service.dart';

class SelectUserController extends BaseController {
  final NotificationPermissionService _notificationPermissionService =
      NotificationPermissionService();

  @override
  void onReady() {
    super.onReady();
    _notificationPermissionService.ensurePermissionAfterFirstScreen();
  }
  void openProfessional() {
    Get.to(
      () => const OnboardingView(),
      binding: professional_onboarding.OnboardingBinding(),
    );
  }

  void openEndUser() {
    Get.to(
      () => const OnboardingScreen(),
      binding: enduser_onboarding.OnboardingBinding(),
    );
  }
}
