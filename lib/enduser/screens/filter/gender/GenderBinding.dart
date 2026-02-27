import 'package:get/get.dart';

import 'GenderController.dart';

class GenderBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GenderController>(() => GenderController());
  }
}


