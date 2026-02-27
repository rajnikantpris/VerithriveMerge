import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/screens/summary/SummaryController.dart';

class SummaryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SummaryController());
  }
}

