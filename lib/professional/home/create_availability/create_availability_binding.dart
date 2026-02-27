import 'package:get/get.dart';

import '../../../api/user_api_service.dart';
import 'create_availability_controller.dart';

class CreateAvailabilityBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CreateAvailabilityController(
          Get.isRegistered<UserApiService>()
              ? Get.find<UserApiService>()
              : null,
        ));
  }
}

