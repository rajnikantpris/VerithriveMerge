import 'package:get/get.dart';

class TrainerPreferenceController extends GetxController {
  final RxString selectedPreference = ''.obs;

  final List<String> preferences = const [
    'Male only',
    'Female only',
    'No preference',
  ];

  void selectPreference(String value) {
    selectedPreference.value = value;
  }
}

