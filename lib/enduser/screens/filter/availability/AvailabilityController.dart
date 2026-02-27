import 'package:get/get.dart';
import '../FilterController.dart';

class AvailabilityController extends GetxController {
  // Availability filter
  final RxString selectedAvailability = 'Available in next 3 days'.obs;
  final RxBool hasManuallySelected = false.obs; // Track if user manually selected a value
  final List<String> availabilityOptions = const [
    'Available in next 3 days',
    'Available in next 7 days',
    'Available in next 10 days',
  ];

  @override
  void onInit() {
    super.onInit();
    _loadInitialAvailability();
  }

  void _loadInitialAvailability() {
    try {
      // Load availability from FilterController (persisted filter value)
      if (Get.isRegistered<FilterController>()) {
        final filterController = Get.find<FilterController>();
        if (filterController.selectedAvailability.value.isNotEmpty) {
          selectedAvailability.value = filterController.selectedAvailability.value;
          print('AvailabilityController: Loaded availability from FilterController: ${selectedAvailability.value}');
          return;
        }
      }
    } catch (e) {
      print('AvailabilityController: Error loading initial availability: $e');
    }
  }

  // Availability filter methods
  void setAvailability(String availability) {
    selectedAvailability.value = availability;
    hasManuallySelected.value = true; // Mark as manually selected
  }

}


