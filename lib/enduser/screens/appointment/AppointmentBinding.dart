import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/screens/appointment/AppointmentController.dart';

class AppointmentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AppointmentController());
  }
}
