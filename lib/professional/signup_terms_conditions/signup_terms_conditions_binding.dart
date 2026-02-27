import 'package:get/get.dart';

import 'signup_terms_conditions_controller.dart';

class SignupTermsConditionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SignupTermsConditionsController>(
      () => SignupTermsConditionsController(),
    );
  }
}
