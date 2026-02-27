import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class BaseController extends GetxController {
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchData(); // First time load
  }

  void refreshData() {
    isLoading(false);
    fetchData(); // Called every time tab is tapped
  }

  void fetchData() async {
    // Simulate API call
    await Future.delayed(Duration(milliseconds: 500));
    isLoading(false);
  }
}