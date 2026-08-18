import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/base_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/storage_service.dart';
import '../../services/analytics_service.dart';

class OnboardingController extends BaseController {
  final totalSteps = 3;
  final currentStep = 1.obs;
  late final PageController pageController;
  Timer? _autoScrollTimer;
  bool _isScrollingForward = true;

  // Get StorageService
  StorageService? get _storageService =>
      Get.isRegistered<StorageService>() ? Get.find<StorageService>() : null;

  @override
  void onInit() {
    super.onInit();
    AnalyticsService.instance.logScreenView(
      screenName: 'ProfessionalOnboardingScreen',
      screenClass: 'OnboardingView',
      pageCategory: 'onboarding',
      elementLocation: 'view',
    );
    pageController = PageController(initialPage: 0);
   // _startAutoScroll();
  }

  @override
  void onClose() {
    _autoScrollTimer?.cancel();
    pageController.dispose();
    super.onClose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (pageController.hasClients) {
        int currentPageIndex =
            currentStep.value - 1; // Convert 1-based to 0-based
        int nextPage;

        if (_isScrollingForward) {
          // Moving forward: 1 -> 2 -> 3 -> 4
          if (currentPageIndex >= totalSteps - 1) {
            // Reached the last page (4), reverse direction
            _isScrollingForward = false;
            nextPage = currentPageIndex - 1; // Go to page 3 (index 2)
          } else {
            nextPage = currentPageIndex + 1; // Move forward
          }
        } else {
          // Moving backward: 4 -> 3 -> 2 -> 1
          if (currentPageIndex <= 0) {
            // Reached the first page (1), reverse direction
            _isScrollingForward = true;
            nextPage = currentPageIndex + 1; // Go to page 2 (index 1)
          } else {
            nextPage = currentPageIndex - 1; // Move backward
          }
        }

        pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void onPageChanged(int page) {
    currentStep.value = page + 1;
  }

  void joinNow() {
    // Analytics: Log onboarding join action
    

    if (Get.currentRoute != Routes.signup) {
      Get.toNamed(Routes.signup);
    }
  }

  void logIn() {
    // Analytics: Log onboarding login action
    

    if (Get.currentRoute != Routes.login) {
      Get.toNamed(Routes.login);
    }
  }

  Future<void> continueAsGuest() async {
    // Analytics: Log onboarding guest action
    

    // Set userType to professional even for guest so Splash knows which flow to use
    if (_storageService != null) {
      await _storageService!.writeString('userType', 'professional');
    }
    _goToHome();
  }

  void _goToHome() {
    if (Get.currentRoute != Routes.home) {
      Get.offAllNamed(Routes.home);
    }
  }
}
