import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verithrive_dev/enduser/core/values/sharePrefrenceConst.dart'
    as enduser_prefs;
import 'package:verithrive_dev/enduser/screens/main/MainScreen.dart'
    as enduser_main;
import 'package:verithrive_dev/enduser/screens/onboarding/onboarding_binding.dart'
    as enduser_onboarding;
import 'package:verithrive_dev/enduser/screens/onboarding/onboarding_screen.dart'
    as enduser_onboarding_screen;
import 'package:verithrive_dev/enduser/screens/profile/ProfileBinding.dart'
    as enduser_profile_binding;
import 'package:verithrive_dev/enduser/screens/profile/ProfileView.dart'
    as enduser_profile_view;
import 'package:verithrive_dev/select_user/select_user_binding.dart';
import 'package:verithrive_dev/select_user/select_user_view.dart';

import '../../common/base_controller.dart';
import '../../routes/app_routes.dart';

class SplashController extends BaseController {
  /// Show the splash then check login status and navigate accordingly.
  @override
  void onReady() {
    super.onReady();
    Future.delayed(const Duration(seconds: 2), _checkLoginAndNavigate);
  }

  Future<void> _checkLoginAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';

    if (token.isEmpty) {
      if (Get.currentRoute != Routes.selectUser) {
        Get.offAllNamed(Routes.selectUser);
      }
      return;
    }

    final userType = prefs.getString('userType') ?? '';

    if (userType == 'professional') {
      _navigateBasedOnUserFlags(prefs);
      return;
    }

    final isLogin =
        prefs.getBool(enduser_prefs.SharePreferenceConst.isLogin) ?? false;

    if (!isLogin) {
      Get.offAll(
        () => const enduser_onboarding_screen.OnboardingScreen(),
        binding: enduser_onboarding.OnboardingBinding(),
      );
      return;
    }

    final isPersonalDetailsCompleted = prefs.getBool(
          enduser_prefs.SharePreferenceConst.isPersonalDetails,
        ) ??
        false;

    if (isPersonalDetailsCompleted) {
      Get.offAll(() => enduser_main.MainScreen());
    } else {
      Get.offAll(
        () => const enduser_profile_view.ProfileView(),
        binding: enduser_profile_binding.ProfileBinding(),
      );
    }
  }

  /// Navigate based on user flags in priority order (same as login controller)
  void _navigateBasedOnUserFlags(SharedPreferences prefs) {
    // Read all user flags from storage
    final isProfileCreated = prefs.getBool('is_profile_created') ?? false;
    final isWorkFull = prefs.getBool('is_work_full') ?? false;
    final isProfessionalServices =
        prefs.getBool('is_professional_services') ?? false;
    final isQualification = prefs.getBool('is_qualification') ?? false;
    final isPersonalIdentification =
        prefs.getBool('is_personal_identification') ?? false;
    final isAboutYou = prefs.getBool('is_about_you') ?? false;
    final isPayment = prefs.getBool('is_payment') ?? false;
    final isPersonalDetails = prefs.getBool('is_personal_details') ?? false;
    final isTermCondition = prefs.getBool('is_term_condition') ?? false;

    // Priority order: check flags in sequence and navigate to first incomplete step

    // Step 1: Check if personal details are needed
    if (isPersonalDetails != true) {
      if (Get.currentRoute != Routes.signupPersonDetails) {
        Get.offAllNamed(Routes.signupPersonDetails);
      }
      return;
    }

    // Step 2: Check if terms and conditions are needed
    if (isTermCondition != true) {
      if (Get.currentRoute != Routes.signupTermsConditions) {
        Get.offAllNamed(Routes.signupTermsConditions);
      }
      return;
    }

    // Step 3: Check if profile creation is needed (step 0)
    if (isProfileCreated != true) {
      if (Get.currentRoute != Routes.signupProfileWizard) {
        Get.offAllNamed(
          Routes.signupProfileWizard,
          arguments: {'initialStep': 0},
        );
      }
      return;
    }

    // Step 4: Check if work address is needed (step 1)
    if (isWorkFull != true) {
      if (Get.currentRoute != Routes.signupProfileWizard) {
        Get.offAllNamed(
          Routes.signupProfileWizard,
          arguments: {'initialStep': 1},
        );
      }
      return;
    }

    // Step 5: Check if professional services are needed (step 2)
    if (isProfessionalServices != true) {
      if (Get.currentRoute != Routes.signupProfileWizard) {
        Get.offAllNamed(
          Routes.signupProfileWizard,
          arguments: {'initialStep': 2},
        );
      }
      return;
    }

    // Step 6: Check if qualifications are needed (step 3)
    if (isQualification != true) {
      if (Get.currentRoute != Routes.signupProfileWizard) {
        Get.offAllNamed(
          Routes.signupProfileWizard,
          arguments: {'initialStep': 3},
        );
      }
      return;
    }

    // Step 7: Check if personal identification is needed (step 4)
    if (isPersonalIdentification != true) {
      if (Get.currentRoute != Routes.signupProfileWizard) {
        Get.offAllNamed(
          Routes.signupProfileWizard,
          arguments: {'initialStep': 4},
        );
      }
      return;
    }

    // Step 8: Check if about you is needed (step 5)
    if (isAboutYou != true) {
      if (Get.currentRoute != Routes.signupProfileWizard) {
        Get.offAllNamed(
          Routes.signupProfileWizard,
          arguments: {'initialStep': 5},
        );
      }
      return;
    }

    // Step 9: Check if payment/subscription is needed
    if (isPayment != true) {
      if (Get.currentRoute != Routes.subscription) {
        Get.offAllNamed(Routes.subscription);
      }
      return;
    }

    // All steps completed - navigate to home
    if (Get.currentRoute != Routes.home) {
      Get.offAllNamed(Routes.home);
    }
  }
}
