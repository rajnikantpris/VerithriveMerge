import 'package:get/get.dart';

import '../../../api/user_api_service.dart';
import 'edit_availability_controller.dart';

class EditAvailabilityBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => EditAvailabilityController(Get.find<UserApiService>()));
  }
}

