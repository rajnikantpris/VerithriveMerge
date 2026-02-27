import 'package:get/get.dart';

import '../../../../api/user_api_service.dart';
import 'personal_details_controller.dart';

class PersonalDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PersonalDetailsController>(
      () => PersonalDetailsController(Get.find<UserApiService>()),
    );
  }
}

