import 'package:get/get.dart';

import '../../../../api/user_api_service.dart';
import 'bank_account_controller.dart';

class BankAccountBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BankAccountController>(
      () => BankAccountController(Get.find<UserApiService>()),
    );
  }
}

