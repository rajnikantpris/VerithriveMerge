import 'package:get/get.dart';

import 'yourprofile_controller.dart';

class YourProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => YourProfileController());
  }
}

