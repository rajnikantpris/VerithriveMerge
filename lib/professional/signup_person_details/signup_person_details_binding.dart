import 'package:get/get.dart';

import '../../api/dio_client.dart';
import 'signup_person_details_controller.dart';

class SignupPersonDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SignupPersonDetailsController>(
      () => SignupPersonDetailsController(Get.find<DioClient>()),
    );
  }
}

