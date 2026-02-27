import 'package:get/get.dart';

import '../../api/user_api_service.dart';
import 'home_controller.dart';
import 'calendar_controller.dart';
import 'messages_controller.dart';
import 'profile_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeController(Get.find()));
    Get.lazyPut(() => CalendarController(Get.find<UserApiService>()));
    Get.lazyPut(() => MessagesController(Get.find<UserApiService>()));
    Get.lazyPut(() => ProfileController(
          Get.isRegistered<UserApiService>()
              ? Get.find<UserApiService>()
              : null,
        ));
  }
}
