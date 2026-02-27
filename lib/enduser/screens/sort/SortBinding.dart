import 'package:get/get.dart';
import 'SortController.dart';

class SortBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SortController>(() => SortController());
  }
}

