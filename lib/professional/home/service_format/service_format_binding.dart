import 'package:get/get.dart';

import '../../../../api/user_api_service.dart';
import 'service_format_controller.dart';

class ServiceFormatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ServiceFormatController(Get.find<UserApiService>()));
  }
}

