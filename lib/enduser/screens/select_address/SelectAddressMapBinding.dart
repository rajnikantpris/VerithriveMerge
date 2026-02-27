import 'package:get/get.dart';

import 'SelectAddressMapController.dart';


class SelectAddressMapBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SelectAddressMapController>(
      () => SelectAddressMapController(),
    );
  }
}

