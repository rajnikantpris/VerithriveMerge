import 'package:get/get.dart';

import '../../../../api/user_api_service.dart';
import 'address_controller.dart';

class AddressBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AddressController(Get.find<UserApiService>()));
  }
}
