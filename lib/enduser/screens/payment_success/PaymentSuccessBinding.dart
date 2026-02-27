import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/screens/payment_success/PaymentSuccessController.dart';

class PaymentSuccessBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(PaymentSuccessController());
  }
}
