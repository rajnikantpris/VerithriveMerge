import 'package:get/get.dart';

import '../../../../api/user_api_service.dart';
import 'about_you_controller.dart';

class AboutYouBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
        () => AboutYouController(Get.find<UserApiService>()));
  }
}

