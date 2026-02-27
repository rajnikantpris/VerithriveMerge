import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/screens/profile/ProfileController.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ProfileController(), permanent: false);
  }
}
