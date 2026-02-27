import 'package:get/get.dart';
import 'AvailabilityController.dart';


class AvailabilityBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AvailabilityController>(() => AvailabilityController());
  }
}


