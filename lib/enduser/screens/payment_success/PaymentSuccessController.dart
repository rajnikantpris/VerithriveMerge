import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/routes/app_routes.dart';
import 'package:verithrive_dev/enduser/screens/main/MainScreen.dart';

class PaymentSuccessController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    // Auto redirect to home after success screen (optional)
    // Future.delayed(Duration(seconds: 7), () {
    //   Get.offAllNamed(AppRoutes.main);
    // });
  }

  void goToHomepage() {
    Get.offAll(
      () => MainScreen(),
    );
  }
}
