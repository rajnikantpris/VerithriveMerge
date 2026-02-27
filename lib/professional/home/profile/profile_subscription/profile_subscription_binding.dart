import 'package:get/get.dart';

import '../../../../api/user_api_service.dart';
import 'profile_subscription_controller.dart';

class ProfileSubscriptionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ProfileSubscriptionController(
          Get.find<UserApiService>(),
        ));
  }
}
