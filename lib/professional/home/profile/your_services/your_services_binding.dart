import 'package:get/get.dart';

import '../../../../api/user_api_service.dart';
import 'your_services_controller.dart';

class YourServicesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<YourServicesController>(
      () => YourServicesController(Get.find<UserApiService>()),
    );
  }
}

