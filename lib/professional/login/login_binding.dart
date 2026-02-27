import 'package:get/get.dart';

import '../../api/user_api_service.dart';
import '../../services/storage_service.dart';
import 'login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfessionalLoginController>(
      () => ProfessionalLoginController(
        Get.find<UserApiService>(),
        Get.isRegistered<StorageService>() ? Get.find<StorageService>() : null,
      ),
    );
  }
}
