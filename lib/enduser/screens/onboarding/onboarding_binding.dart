import 'package:get/get.dart';
import 'package:verithrive_dev/services/storage_service.dart';
import 'onboarding_controller.dart';

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<StorageService>()) {
      Get.put(StorageService(), permanent: true);
      Get.find<StorageService>().init();
    }
    Get.lazyPut(() => OnboardingController());
  }
}
