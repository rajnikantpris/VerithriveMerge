import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../therapy_list/TherapistController.dart';

class FilterController extends GetxController {
  // Professional filter - store selected sub_type_id
  final RxString selectedProfessionalSubType = ''.obs;
  final RxBool hasManuallySelectedProfessional = false.obs; // Track manual selection

  // Distance filter
  final RxDouble maxDistance = 13.0.obs; // in miles
  final double minDistance = 0.0;
  final double maxDistanceLimit = 25.0;

  RxBool hasFilter = false.obs;
  @override
  void onInit() {
    super.onInit();
    _loadAllFilterValues();
  }

  void _loadAllFilterValues() {
    try {
      // Get all filter values from TherapistController if available
      if (Get.isRegistered<TherapistController>()) {
       final  therapistController = Get.find<TherapistController>();

          // Check if any filter is actually applied (not default values)
          hasFilter.value = therapistController.selectedProfessionalSubType.value.isNotEmpty ||
             (therapistController.selectedDistance.value > 0.0 && therapistController.selectedDistance.value != 13.0) ||
             (therapistController.distance != null && therapistController.distance != 13.0) ||
             therapistController.minPrice.value > 0.0 ||
             therapistController.maxPrice.value < 1000.0 ||
             (therapistController.selectedAvailabilityFilter.value.isNotEmpty &&
              therapistController.selectedAvailabilityFilter.value != 'Available in next 3 days') ||
             (therapistController.selectedGender.value.isNotEmpty &&
              therapistController.selectedGender.value != 'Male');


         // Load Professional Sub Type (only if not empty - actually applied)
        if (therapistController.selectedProfessionalSubType != null &&
            therapistController.selectedProfessionalSubType!.isNotEmpty) {
          selectedProfessionalSubType.value = therapistController.selectedProfessionalSubType.value!;
          print('FilterController: Loaded professional sub type: ${selectedProfessionalSubType.value}');
        }

        // Load Distance - Only load if actually applied (selectedDistance > 0 and != 13.0, or distance from arguments != 13.0)
        if (therapistController.selectedDistance != null &&
            therapistController.selectedDistance.value! > 0.0 &&
            therapistController.selectedDistance.value! != 13.0) {
          maxDistance.value = therapistController.selectedDistance.value!;
          print('FilterController: Loaded distance from selectedDistance: ${maxDistance.value}');
        } else if (therapistController.distance != null && therapistController.distance != 13.0) {
          maxDistance.value = therapistController.distance!;
          print('FilterController: Loaded distance from arguments: ${maxDistance.value}');
        }

        // Load Price Range - Only load if actually applied (not defaults)
        if (therapistController.minPrice != null && therapistController.minPrice.value! > 0.0) {
          minPrice.value = therapistController.minPrice.value!;
          print('FilterController: Loaded min price: ${minPrice.value}');
        }
        if (therapistController.maxPrice != null && therapistController.maxPrice.value! < 1000.0) {
          maxPrice.value = therapistController.maxPrice.value!;
          print('FilterController: Loaded max price: ${maxPrice.value}');
        }

        // Load Availability - Only load if actually applied (not default)
        if (therapistController.selectedAvailabilityFilter != null &&
            therapistController.selectedAvailabilityFilter!.isNotEmpty &&
            therapistController.selectedAvailabilityFilter.value! != 'Available in next 3 days') {
          selectedAvailability.value = therapistController.selectedAvailabilityFilter.value!;
          print('FilterController: Loaded availability: ${selectedAvailability.value}');
        } else if (therapistController.availability != null &&
                   therapistController.availability!.isNotEmpty) {
          // Convert API format to UI format if needed
          String uiFormat = _convertAvailabilityToUiFormat(therapistController.availability!);
          // Only set if it's not the default
          if (uiFormat != 'Available in next 3 days') {
            selectedAvailability.value = uiFormat;
            print('FilterController: Loaded availability from arguments: ${selectedAvailability.value}');
          }
        }

        // Load Gender - Only load if actually applied (not default Male)
        if (therapistController.selectedGender != null &&
            therapistController.selectedGender!.isNotEmpty &&
            therapistController.selectedGender.value! != 'Male') {
          selectedGender.value = _capitalizeGender(therapistController.selectedGender.value!);
          print('FilterController: Loaded gender: ${selectedGender.value}');
        }
      }
    } catch (e) {
      print('FilterController: Error loading filter values: $e');
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

  String _convertAvailabilityToUiFormat(String apiFormat) {
    // Convert API format to UI format
    if (apiFormat == '3_days' || apiFormat == '7_days') {
      return 'Available in next 3 days';
    } else if (apiFormat == '10_days' || apiFormat == '14_days') {
      return 'Available in next 10 days';
    } else if (apiFormat == '30_days') {
      return 'Available in next 10 days';
    } else if (apiFormat == 'anytime') {
      return 'Available anytime';
    }
    // If already in UI format, return as is
    return apiFormat;
  }

  // Price filter
  final RxDouble minPrice = 0.0.obs;
  final RxDouble maxPrice = 1000.0.obs;

  // Availability filter
  final RxString selectedAvailability = 'Available in next 3 days'.obs;
  final RxBool hasManuallySelectedAvailability = false.obs; // Track manual selection
  final List<String> availabilityOptions = const [
    'Available in next 3 days',
    'Available in next 7 days',
    'Available in next 10 days',
    'Available anytime',
  ];

  // Gender filter
  final RxString selectedGender = 'Male'.obs;
  final RxBool hasManuallySelectedGender = false.obs; // Track manual selection
  final List<String> genderOptions = const [
    'Male',
    'Female',
  ];

  // Track if any filter has been applied (not default values)
  bool get hasAnyFilterApplied {
    // Check if any filter value differs from default values
    // Professional filter applied (only if manually selected)
    if (selectedProfessionalSubType.value.isNotEmpty && hasManuallySelectedProfessional.value) {
      return true;
    }

    // Distance filter applied (not default 13.0)
    if (maxDistance.value != 13.0) {
      return true;
    }

    // Price filter applied (min > 0 or max < 1000)
    if (minPrice.value > 0.0 || maxPrice.value < 1000.0) {
      return true;
    }

    // Availability filter applied (not default "Available in next 3 days" or manually selected)
    if (selectedAvailability.value != 'Available in next 3 days' || hasManuallySelectedAvailability.value) {
      return true;
    }

    // Gender filter applied (not default "Male" or manually selected)
    if (selectedGender.value != 'Male' || hasManuallySelectedGender.value) {
      return true;
    }

    // No filters applied (all are default values)
    return false;
  }

  // Professional filter methods
  void setProfessionalSubType(String subTypeId, {bool manuallySelected = false}) {
    selectedProfessionalSubType.value = subTypeId;
    hasManuallySelectedProfessional.value = manuallySelected;
  }

  // Distance filter methods
  void setDistance(double value) {
    maxDistance.value = value;
  }

  // Price filter methods
  void setPriceRange(double min, double max) {
    minPrice.value = min;
    maxPrice.value = max;
  }

  // Availability filter methods
  void setAvailability(String availability, {bool manuallySelected = false}) {
    selectedAvailability.value = availability;
    hasManuallySelectedAvailability.value = manuallySelected;
  }

  // Gender filter methods
  void setGender(String gender, {bool manuallySelected = false}) {
    selectedGender.value = gender;
    hasManuallySelectedGender.value = manuallySelected;
  }

  void reset() {
    try {
      // Reset all filter values to defaults
      selectedProfessionalSubType.value = '';
      hasManuallySelectedProfessional.value = false;
      maxDistance.value = 13.0;
      minPrice.value = 0.0;
      maxPrice.value = 1000.0;
      selectedAvailability.value = 'Available in next 3 days';
      selectedGender.value = 'Male';
      hasManuallySelectedAvailability.value = false;
      hasManuallySelectedGender.value = false;

      // Clear filters in TherapistController
      if (Get.isRegistered<TherapistController>()) {
        final therapistController = Get.find<TherapistController>();

        // Clear all filters in TherapistController
        therapistController.selectedProfessionalSubType.value = '';
        therapistController.selectedGender.value = '';
        therapistController.minPrice.value = 0.0;
        therapistController.maxPrice.value = 1000.0;
        therapistController.selectedAvailabilityFilter.value = '';
        therapistController.selectedDistance.value = 0.0;

        // Reset title to default
        therapistController.initializeTitle();

        // Update hasFilter observable
        hasFilter.value = false;

        // Call API to reload therapists without filters
        therapistController.callProfessionalsListAPI();
      }

      // Close the filter screen
      Get.back();
    } catch (e) {
      print('Error resetting filters: $e');
    }
  }

  // Apply filters - send to TherapistController
  void applyFilters() {
    try {
      final therapistController = Get.find<TherapistController>();

      Map<String, dynamic> filterData = {};

      if (selectedProfessionalSubType.value.isNotEmpty) {
        filterData['profession_sub_type'] = selectedProfessionalSubType.value;
      }

      if (selectedGender.value.isNotEmpty && (selectedGender.value != 'Male' || hasManuallySelectedGender.value)) {
        filterData['gender'] = selectedGender.value;
      }

      if (minPrice.value > 0.0) {
        filterData['minPrice'] = minPrice.value;
      }

      if (maxPrice.value < 1000.0) {
        filterData['maxPrice'] = maxPrice.value;
      }

      // Always pass availability filter if manually selected or not default
      if (selectedAvailability.value.isNotEmpty && 
          (selectedAvailability.value != 'Available in next 3 days' || hasManuallySelectedAvailability.value)) {
        filterData['availability'] = selectedAvailability.value;
      }

      // Always pass distance if it's different from default
      // Also check if TherapistController has a distance from initial arguments
      if (maxDistance.value != 13.0) {
        filterData['distance'] = maxDistance.value;
      } else if (therapistController.distance != null && therapistController.distance != 13.0) {
        // Pass the initial distance from arguments if filter distance is still default
        filterData['distance'] = therapistController.distance!;
      }

      therapistController.applyFilters(filterData);

      // Update hasFilter observable after applying filters
      // Check if any actual filter (not default) is being applied or manually selected
      hasFilter.value = (selectedProfessionalSubType.value.isNotEmpty && hasManuallySelectedProfessional.value) ||
          (maxDistance.value != 13.0) ||
          minPrice.value > 0.0 ||
          maxPrice.value < 1000.0 ||
          (selectedAvailability.value != 'Available in next 3 days' || hasManuallySelectedAvailability.value) ||
          (selectedGender.value != 'Male' || hasManuallySelectedGender.value);

      Get.back();
    } catch (e) {
      print('Error applying filters: $e');
    }
  }
}


