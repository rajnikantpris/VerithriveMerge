import 'package:get/get.dart';

import '../../../../api/user_api_service.dart';
import 'account_controller.dart';

class AccountBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AccountController(Get.find<UserApiService>()));
  }
}

