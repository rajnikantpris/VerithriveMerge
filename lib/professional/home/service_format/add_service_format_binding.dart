import 'package:get/get.dart';

import '../../../../api/user_api_service.dart';
import 'add_service_format_controller.dart';

class AddServiceFormatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AddServiceFormatController(Get.find<UserApiService>()));
  }
}

