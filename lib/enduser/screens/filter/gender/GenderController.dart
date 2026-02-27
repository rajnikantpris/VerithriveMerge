import 'package:get/get.dart';
import '../FilterController.dart';

class GenderController extends GetxController {

  // Gender filter
  final RxString selectedGender = 'Male'.obs;
  final RxBool hasManuallySelected = false.obs; // Track if user manually selected a value
  final List<String> genderOptions = const [
    'Male',
    'Female',
  ];

  @override
  void onInit() {
    super.onInit();
    _loadInitialGender();
  }

  void _loadInitialGender() {
    try {
      // Load gender from FilterController (persisted filter value)
      if (Get.isRegistered<FilterController>()) {
        final filterController = Get.find<FilterController>();
        if (filterController.selectedGender.value.isNotEmpty) {
          selectedGender.value = filterController.selectedGender.value;
          print('GenderController: Loaded gender from FilterController: ${selectedGender.value}');
          return;
        }
      }
    } catch (e) {
      print('GenderController: Error loading initial gender: $e');
    }
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


