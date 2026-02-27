import 'dart:async';
import 'package:get/get.dart';

import '../../common/base_controller.dart';
import '../../routes/app_routes.dart';

class ProcessingPaymentController extends BaseController {
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _startTimer();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void _startTimer() {
    _timer = Timer(const Duration(seconds: 5), () {
      Get.offAllNamed(Routes.verification);
    });
  }
}

