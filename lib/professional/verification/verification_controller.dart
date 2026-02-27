import 'package:get/get.dart';

import '../../common/base_controller.dart';
import '../../routes/app_routes.dart';

class VerificationController extends BaseController {
  void goToHomepage() {
    Get.offAllNamed(Routes.home);
  }
}

