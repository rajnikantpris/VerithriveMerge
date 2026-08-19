import 'package:get/get.dart';

import '../../common/base_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/analytics_service.dart';

class VerificationController extends BaseController {
  @override
  void onInit() {
    super.onInit();
    AnalyticsService.instance.logScreenView(
      screenName: 'ProfessionalVerificationScreen',
      screenClass: 'VerificationView',
      pageCategory: 'register',
      elementLocation: 'view',
    );
  }

  void goToHomepage() {
    Get.offAllNamed(Routes.home);
  }
}

