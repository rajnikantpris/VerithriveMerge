import 'package:get/get.dart';
import 'package:verithrive_dev/services/analytics_service.dart';

class TrainerPreferenceController extends GetxController {
  final RxString selectedPreference = ''.obs;

  final List<String> preferences = const [
    'Male only',
    'Female only',
    'No preference',
  ];

  @override
  void onInit() {
    super.onInit();
    AnalyticsService.instance.logScreenView(
      screenName: 'TrainerPreferenceScreen',
      screenClass: 'TrainerPreferenceScreen',
      pageCategory: 'fitness',
      elementLocation: 'view',
    );
  }

  void selectPreference(String value) {
    selectedPreference.value = value;
  }
}

