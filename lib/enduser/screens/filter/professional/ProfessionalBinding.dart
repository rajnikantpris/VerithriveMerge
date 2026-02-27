import 'package:get/get.dart';

import 'ProfessionalController.dart';

class ProfessionalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfessionalController>(() => ProfessionalController());
  }
}


