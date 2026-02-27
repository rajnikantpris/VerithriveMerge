import 'package:get/get.dart';
import 'DistanceController.dart';

class DistanceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DistanceController>(() => DistanceController());
  }
}


