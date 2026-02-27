import 'package:get/get.dart';
import 'TrainerPreferenceController.dart';

class TrainerPreferenceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TrainerPreferenceController>(() => TrainerPreferenceController());
  }
}

