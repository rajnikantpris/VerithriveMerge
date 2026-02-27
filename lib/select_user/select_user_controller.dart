import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/professional/onboarding/onboarding_binding.dart'
    as professional_onboarding;
import 'package:verithrive_dev/professional/onboarding/onboarding_view.dart';
import 'package:verithrive_dev/enduser/screens/onboarding/onboarding_binding.dart'
    as enduser_onboarding;
import 'package:verithrive_dev/enduser/screens/onboarding/onboarding_screen.dart';

class SelectUserController extends GetxController {
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
