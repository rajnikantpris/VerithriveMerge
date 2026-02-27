import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../therapy_list/TherapistController.dart';

class SortController extends GetxController {
  final RxString selectedSortOption = ''.obs;

  final List<SortOption> sortOptions = const [
    SortOption(
      title: 'Price (low to high)',
      icon: Icons.attach_money,
      value: 'price_low_to_high',
    ),
    SortOption(
      title: 'Price (high to low)',
      icon: Icons.attach_money,
      value: 'price_high_to_low',
    ),
    SortOption(
      title: 'Distance (nearest to furthest away)',
      icon: Icons.location_on_outlined,
      value: 'distance_nearest',
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    _loadCurrentSort();
  }

  void _loadCurrentSort() {
    try {
      if (Get.isRegistered<TherapistController>()) {
        final therapistController = Get.find<TherapistController>();
        if (therapistController.sortBy.value.isNotEmpty) {
          // Convert API format back to UI format
          String uiFormat = _convertApiFormatToUi(therapistController.sortBy.value);
          selectedSortOption.value = uiFormat;
          print('SortController: Loaded current sort: ${selectedSortOption.value}');
        }
      }
    } catch (e) {
      print('SortController: Error loading current sort: $e');
    }
  }

  String _convertApiFormatToUi(String apiFormat) {
    if (apiFormat == 'price_low') {
      return 'price_low_to_high';
    } else if (apiFormat == 'price_high') {
      return 'price_high_to_low';
    } else if (apiFormat == 'distance') {
      return 'distance_nearest';
    }
    return apiFormat;
  }

  void selectSortOption(String value) {
    if (selectedSortOption.value == value) {
      selectedSortOption.value = ''; // Deselect if same option clicked
      // If deselected, apply default sort (empty string means no sort)
      _applySort('');
    } else {
      selectedSortOption.value = value;
      // Apply sort immediately when option is selected
      _applySort(value);
    }
  }

  bool isSelected(String value) {
    return selectedSortOption.value == value;
  }

  void _applySort(String sortValue) {
    try {
      if (Get.isRegistered<TherapistController>()) {
        final therapistController = Get.find<TherapistController>();
        therapistController.applySort(sortValue);
        print('SortController: Applied sort: $sortValue');
      }
      // Don't close the screen - let user see the selection
      // Screen will close when user presses back button
    } catch (e) {
      print('Error applying sort: $e');
    }
  }

  void apply() {
    Get.back(result: selectedSortOption.value);
  }
}

class SortOption {
  final String title;
  final String value;
  final IconData icon;

  const SortOption({
    required this.title,
    required this.value,
    required this.icon,
  });
}

