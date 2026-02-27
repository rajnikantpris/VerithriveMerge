import 'package:get/get.dart';

import '../../../../api/user_api_service.dart';
import 'personal_identification_controller.dart';

class PersonalIdentificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
        () => PersonalIdentificationController(Get.find<UserApiService>()));
  }
}
