import 'package:get/get.dart';

import '../../api/user_api_service.dart';
import 'signup_controller.dart';

class SignupBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SignupController>(
        () => SignupController(Get.find<UserApiService>()));
  }
}
