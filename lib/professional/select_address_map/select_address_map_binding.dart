import 'package:get/get.dart';

import 'select_address_map_controller.dart';

class SelectAddressMapBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SelectAddressMapController>(
      () => SelectAddressMapController(),
    );
  }
}

