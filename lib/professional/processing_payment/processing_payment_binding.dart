import 'package:get/get.dart';

import 'processing_payment_controller.dart';

class ProcessingPaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProcessingPaymentController>(
      () => ProcessingPaymentController(),
    );
  }
}

