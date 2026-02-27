import 'package:get/get.dart';

import '../../api/user_api_service.dart';
import '../../services/storage_service.dart';
import 'payment_method_controller.dart';

class PaymentMethodBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PaymentMethodController>(
      () => PaymentMethodController(
        Get.find<UserApiService>(),
        Get.isRegistered<StorageService>() ? Get.find<StorageService>() : null,
      ),
    );
  }
}
