import 'dart:async';
import 'package:get/get.dart';

import '../../common/base_controller.dart';
import '../../routes/app_routes.dart';

class ProcessingPaymentController extends BaseController {
  Timer? _timer;
  final selectedPlanId = ''.obs;
  final selectedtitle = ''.obs;
  bool isFromSignup = false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      if (args['planId'] is String) {
        selectedPlanId.value = args['planId'] as String;
      }
      if (args['planTitle'] is String) {
        selectedtitle.value = args['planTitle'] as String;
      }
      if (args['isFromSignup'] is bool) {
        isFromSignup = args['isFromSignup'] as bool;
      }
    }
    _startTimer();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void _startTimer() {
    _timer = Timer(const Duration(seconds: 5), () {
      if (isFromSignup) {
        Get.offAllNamed(Routes.verification);
      } else {
        Get.offAllNamed(Routes.home);
      }
    });
  }
}

