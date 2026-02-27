import 'package:get/get.dart';

import 'FilterController.dart';

class FilterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FilterController>(() => FilterController());
  }
}









