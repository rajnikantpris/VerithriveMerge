import 'package:get/get.dart';
import '../../../../api/user_api_service.dart';
import 'transaction_summary_controller.dart';

class TransactionSummaryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TransactionSummaryController>(() => TransactionSummaryController(Get.find<UserApiService>()));
  }
}
