import 'package:get/get.dart';

import '../../api/user_api_service.dart';
import 'notification_controller.dart';

class NotificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => NotificationController(Get.find<UserApiService>()));
  }
}

