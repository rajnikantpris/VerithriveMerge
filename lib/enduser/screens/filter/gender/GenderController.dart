import 'package:get/get.dart';
import '../FilterController.dart';
import 'package:verithrive_dev/services/analytics_service.dart';

class GenderController extends GetxController {

  // Gender filter
  final RxString selectedGender = 'Male'.obs;
  final RxBool hasManuallySelected = false.obs; // Track if user manually selected a value
  final List<String> genderOptions = const [
    'Male',
    'Female',
    'No preference'
  ];

  @override
  void onInit() {
    super.onInit();
    AnalyticsService.instance.logScreenView(
      screenName: 'GenderFilterScreen',
      screenClass: 'GenderFilterScreen',
      pageCategory: 'filter',
      elementLocation: 'view',
    );
    _loadInitialGender();
  }

  void _loadInitialGender() {
    try {
      // Load gender from FilterController (persisted filter value)
      if (Get.isRegistered<FilterController>()) {
        final filterController = Get.find<FilterController>();
        if (filterController.selectedGender.value.isNotEmpty) {
          selectedGender.value = _capitalizeGender(filterController.selectedGender.value);
          print('GenderController: Loaded gender from FilterController: ${selectedGender.value}');
          return;
        }
      }
    } catch (e) {
      print('GenderController: Error loading initial gender: $e');
    }
  }

  String _capitalizeGender(String gender) {
    // Convert gender from lowercase API format to proper UI format
    if (gender.toLowerCase() == 'male') {
      return 'Male';
    } else if (gender.toLowerCase() == 'female') {
      return 'Female';
    }
    // If already in proper format or unknown, return as is
    return gender;
  }

  // Gender filter methods
  void setGender(String gender) {
    selectedGender.value = gender;
    hasManuallySelected.value = true; // Mark as manually selected
  }

  // Reset all filters
  void reset() {
    selectedGender.value = 'Male';
    hasManuallySelected.value = false; // Reset manual selection flag
  }

  // Apply filters
  void apply() {
    Get.back(
      result: {
        'gender': selectedGender.value,
        'hasManuallySelected': hasManuallySelected.value,
      },
    );
  }

  @override
  void onClose() {
    super.onClose();
  }
}


