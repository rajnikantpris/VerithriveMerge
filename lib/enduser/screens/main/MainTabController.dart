import 'package:get/get.dart';

class MainTabController extends GetxController {
  final RxInt currentIndex = 0.obs;

  void setTab(int index) {
    currentIndex.value = index;
  }
}

