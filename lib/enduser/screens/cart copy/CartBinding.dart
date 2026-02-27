import 'package:get/get.dart';


import 'CartController.dart';

class CartBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CartController());
  }
}
