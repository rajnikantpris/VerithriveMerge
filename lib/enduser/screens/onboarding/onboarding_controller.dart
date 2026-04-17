import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/values/sharePrefrenceConst.dart';
import '../../routes/app_routes.dart';
import 'package:verithrive_dev/services/storage_service.dart';
import 'package:verithrive_dev/services/analytics_service.dart';

import '../main/MainScreen.dart';

class OnboardingController extends GetxController {
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;
  final StorageService _storageService = Get.find<StorageService>();

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  void nextPage() {
    if (currentPage.value < 3) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> continueAsGuest() async {
    // Analytics: Log onboarding skip/completion
    

    // Set guest flag
    await _storageService.writeBool(SharePreferenceConst.isGuest, true);
    // Navigate to main screen (home screen)
   // Get.offAllNamed(AppRoutes.main);

    Get.offAll(() => MainScreen());
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
