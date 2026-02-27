import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/screens/appointment/AppointmentController.dart';
import 'package:verithrive_dev/enduser/screens/consultation/ConsultationBookingController.dart';

class ConsultationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ConsultationBookingController());
  }
}
