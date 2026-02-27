import 'package:get/get.dart';

import '../../api/user_api_service.dart';
import '../../services/storage_service.dart';
import 'verify_email_controller.dart';

class VerifyEmailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VerifyEmailController>(
      () => VerifyEmailController(
        Get.find<UserApiService>(),
        Get.isRegistered<StorageService>()
            ? Get.find<StorageService>()
            : null,
      ),
    );
  }
}
