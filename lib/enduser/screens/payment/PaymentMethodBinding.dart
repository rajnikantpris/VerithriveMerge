import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/screens/payment/PaymentMethodController.dart';

class PaymentMethodBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => PaymentMethodController());
  }
}
