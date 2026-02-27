import 'package:get/get.dart';

import '../../api/user_api_service.dart';
import 'forgot_password_controller.dart';

class ForgotPasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ForgotPasswordController>(
      () => ForgotPasswordController(
        Get.find<UserApiService>(),
      ),
    );
  }
}

