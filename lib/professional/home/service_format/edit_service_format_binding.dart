import 'package:get/get.dart';

import '../../../../api/user_api_service.dart';
import 'edit_service_format_controller.dart';

class EditServiceFormatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => EditServiceFormatController(Get.find<UserApiService>()));
  }
}

