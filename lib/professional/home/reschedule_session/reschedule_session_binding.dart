import 'package:get/get.dart';

import 'reschedule_session_controller.dart';

class RescheduleSessionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RescheduleSessionController());
  }
}

