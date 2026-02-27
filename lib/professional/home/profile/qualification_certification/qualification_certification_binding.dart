import 'package:get/get.dart';

import '../../../../api/user_api_service.dart';
import 'qualification_certification_controller.dart';

class QualificationCertificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => QualificationCertificationController(Get.find<UserApiService>()));
  }
}

