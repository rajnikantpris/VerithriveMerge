import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verithrive_dev/enduser/core/values/sharePrefrenceConst.dart'
    as enduser_prefs;
import 'package:verithrive_dev/enduser/screens/main/MainScreen.dart'
    as enduser_main;
import 'package:verithrive_dev/enduser/screens/profile/ProfileBinding.dart'
    as enduser_profile_binding;
import 'package:verithrive_dev/enduser/screens/profile/ProfileView.dart'
    as enduser_profile_view;
import 'package:verithrive_dev/services/deep_link_service.dart';

import '../../common/base_controller.dart';
import '../../routes/app_routes.dart';

class SplashController extends BaseController {
  Timer? _navigationTimer;

  @override
  void onReady() {
    super.onReady();
    _navigationTimer?.cancel();
    _navigationTimer = Timer(const Duration(seconds: 2), () {
      if (isClosed) return;
      _checkLoginAndNavigate();
    });
  }

  @override
  void onClose() {
    _navigationTimer?.cancel();
    _navigationTimer = null;
    super.onClose();
  }

  Future<void> _checkLoginAndNavigate() async {
    if (isClosed) return;

    final prefs = await SharedPreferences.getInstance();
    if (isClosed) return;

    final token = prefs.getString('access_token') ?? '';

    if (token.isEmpty) {
      if (Get.currentRoute != Routes.selectUser) {
        Get.offAllNamed(Routes.selectUser);
      }
      return;
    }

    final userType = prefs.getString('userType') ?? '';
    final userId = prefs.getString('user_id') ?? '';

    final hasProfessionalFlags = prefs.containsKey('is_profile_created') ||
        prefs.containsKey('is_work_full') ||
        prefs.containsKey('is_professional_services');

    debugPrint(
      'Splash: userType=$userType, userId=$userId, hasProfessionalFlags=$hasProfessionalFlags',
    );

    final isProfessional = userType == 'professional' ||
        (userType.isEmpty && hasProfessionalFlags) ||
        (userType.isEmpty &&
            userId.isNotEmpty &&
            _checkIfProfessionalUserId(prefs));

    if (isProfessional) {
      debugPrint('Splash: Navigating to professional flow');
      _navigateBasedOnUserFlags(prefs);
      return;
    }

    debugPrint('Splash: Navigating to end user flow');
    final isPersonalDetailsCompleted = prefs.getBool(
          enduser_prefs.SharePreferenceConst.isPersonalDetails,
        ) ??
        false;

    if (isPersonalDetailsCompleted) {
      final route = Get.currentRoute.toLowerCase();
      final onTherapistDetail = route.contains('therapistdetail');

      // Detail was pushed on Splash — rebuild stack as Main → Detail.
      // Never leave Splash under Detail (Back would show Splash).
      if (onTherapistDetail) {
        debugPrint(
          'Splash: Detail on top of Splash — reanchor Main under Detail',
        );
        DeepLinkService.instance.reanchorProfileOnMain();
        return;
      }

      Get.offAll(() => enduser_main.MainScreen());
      // MainScreen.initState is the single place that opens a pending deep link.
      // Do not also call handlePending here — that caused Detail to open twice.
    } else {
      Get.offAll(
        () => const enduser_profile_view.ProfileView(),
        binding: enduser_profile_binding.ProfileBinding(),
      );
    }
  }

  bool _checkIfProfessionalUserId(SharedPreferences prefs) {
    final professionalKeys = [
      'is_profile_created',
      'is_work_full',
      'is_professional_services',
      'is_qualification',
      'is_personal_identification',
      'is_about_you',
      'is_payment',
      'is_personal_details',
      'is_term_condition'
    ];

    return professionalKeys.any((key) => prefs.containsKey(key));
  }

  void _navigateBasedOnUserFlags(SharedPreferences prefs) {
    final isProfileCreated = prefs.getBool('is_profile_created') ?? false;
    final isWorkFull = prefs.getBool('is_work_full') ?? false;
    final isProfessionalServices =
        prefs.getBool('is_professional_services') ?? false;
    final isQualification = prefs.getBool('is_qualification') ?? false;
    final isPersonalIdentification =
        prefs.getBool('is_personal_identification') ?? false;
    final isAboutYou = prefs.getBool('is_about_you') ?? false;
    final isPersonalDetails = prefs.getBool('is_personal_details') ?? false;
    final isTermCondition = prefs.getBool('is_term_condition') ?? false;

    if (isPersonalDetails != true) {
      if (Get.currentRoute != Routes.signupPersonDetails) {
        Get.offAllNamed(Routes.signupPersonDetails);
      }
      return;
    }

    if (isTermCondition != true) {
      if (Get.currentRoute != Routes.signupTermsConditions) {
        Get.offAllNamed(Routes.signupTermsConditions);
      }
      return;
    }

    if (isProfileCreated != true) {
      if (Get.currentRoute != Routes.signupProfileWizard) {
        Get.offAllNamed(
          Routes.signupProfileWizard,
          arguments: {'initialStep': 0},
        );
      }
      return;
    }

    if (isWorkFull != true) {
      if (Get.currentRoute != Routes.signupProfileWizard) {
        Get.offAllNamed(
          Routes.signupProfileWizard,
          arguments: {'initialStep': 1},
        );
      }
      return;
    }

    if (isProfessionalServices != true) {
      if (Get.currentRoute != Routes.signupProfileWizard) {
        Get.offAllNamed(
          Routes.signupProfileWizard,
          arguments: {'initialStep': 2},
        );
      }
      return;
    }

    if (isQualification != true) {
      if (Get.currentRoute != Routes.signupProfileWizard) {
        Get.offAllNamed(
          Routes.signupProfileWizard,
          arguments: {'initialStep': 3},
        );
      }
      return;
    }

    if (isPersonalIdentification != true) {
      if (Get.currentRoute != Routes.signupProfileWizard) {
        Get.offAllNamed(
          Routes.signupProfileWizard,
          arguments: {'initialStep': 4},
        );
      }
      return;
    }

    if (isAboutYou != true) {
      if (Get.currentRoute != Routes.signupProfileWizard) {
        Get.offAllNamed(
          Routes.signupProfileWizard,
          arguments: {'initialStep': 5},
        );
      }
      return;
    }

    if (Get.currentRoute != Routes.home) {
      Get.offAllNamed(Routes.home);
    }
  }
}
