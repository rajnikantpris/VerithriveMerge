import 'package:get/get.dart';

import '../../api/user_api_service.dart';
import 'subscription_controller.dart';

class SubscriptionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SubscriptionController>(
      () => SubscriptionController(Get.find<UserApiService>()),
    );
  }
}

