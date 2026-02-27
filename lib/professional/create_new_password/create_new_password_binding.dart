import 'package:get/get.dart';

import '../../api/user_api_service.dart';
import 'create_new_password_controller.dart';

class CreateNewPasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateNewPasswordController>(
      () => CreateNewPasswordController(
        Get.find<UserApiService>(),
      ),
    );
  }
}


