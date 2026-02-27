import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/screens/filter/price/PriceController.dart';

class PriceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PriceController>(() => PriceController());
  }
}


