import 'package:get/get.dart';

import '../../../../api/user_api_service.dart';
import 'notification_settings_controller.dart';

class NotificationSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => NotificationSettingsController(Get.find<UserApiService>()),
    );
  }
}

