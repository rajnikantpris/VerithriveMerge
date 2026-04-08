import 'package:get/get.dart';
import 'TransactionSummaryController.dart';

class TransactionSummaryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TransactionSummaryController>(() => TransactionSummaryController());
  }
}
