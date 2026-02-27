import 'package:get/get.dart';

import '../../api/user_api_service.dart';
import 'signup_profile_wizard_controller.dart';

class SignupProfileWizardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SignupProfileWizardController>(
      () => SignupProfileWizardController(Get.find<UserApiService>()),
    );
  }
}
