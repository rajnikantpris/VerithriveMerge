import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../FilterController.dart';
import 'package:verithrive_dev/services/analytics_service.dart';

class PriceController extends GetxController {
  // Price filter
  final minPriceController = TextEditingController();
  final maxPriceController = TextEditingController();

  // RangeValues for the slider (both min and max)
  var priceRangeValues = const RangeValues(0, 1000).obs;

  @override
  void onInit() {
    super.onInit();
    AnalyticsService.instance.logScreenView(
      screenName: 'PriceFilterScreen',
      screenClass: 'PriceFilterScreen',
      pageCategory: 'filter',
      elementLocation: 'view',
    );
    _loadInitialPriceRange();
  }

  void _loadInitialPriceRange() {
    try {
      // Load price range from FilterController (persisted filter value)
      if (Get.isRegistered<FilterController>()) {
        final filterController = Get.find<FilterController>();
        if (filterController.minPrice.value != 0.0 || filterController.maxPrice.value != 1000.0) {
          priceRangeValues.value = RangeValues(
            filterController.minPrice.value,
            filterController.maxPrice.value,
          );
          minPriceController.text = priceRangeValues.value.start.round().toString();
          maxPriceController.text = priceRangeValues.value.end.round().toString();
          print('PriceController: Loaded price range from FilterController: ${priceRangeValues.value.start} - ${priceRangeValues.value.end}');
          return;
        }
      }
      
      // Fallback: Initialize with default values
      minPriceController.text = priceRangeValues.value.start.round().toString();
      maxPriceController.text = priceRangeValues.value.end.round().toString();
    } catch (e) {
      print('PriceController: Error loading initial price range: $e');
      minPriceController.text = priceRangeValues.value.start.round().toString();
      maxPriceController.text = priceRangeValues.value.end.round().toString();
    }
  }

  // Update range from slider (when user drags the slider)
  void setPriceRange(RangeValues values) {
    priceRangeValues.value = values;
    minPriceController.text = values.start.round().toString();
    maxPriceController.text = values.end.round().toString();
  }

  @override
  void onClose() {
    minPriceController.dispose();
    maxPriceController.dispose();
    super.onClose();
  }

  // Update minimum price from text field (when user types)
  void setMinPrice(String value) {
    if (value.isEmpty) {
      priceRangeValues.value = RangeValues(0, priceRangeValues.value.end);
      return;
    }

    final minPrice = double.tryParse(value);
    if (minPrice != null && minPrice >= 0) {
      final currentMax = priceRangeValues.value.end;

      // Ensure min is not greater than max and within limits
      if (minPrice <= currentMax && minPrice <= 1000) {
        priceRangeValues.value = RangeValues(minPrice, currentMax);
      } else if (minPrice > currentMax) {
        // If user types min > max, adjust max too
        priceRangeValues.value = RangeValues(minPrice, minPrice);
        maxPriceController.text = minPrice.round().toString();
      }
    }
  }

  // Update maximum price from text field (when user types)
  void setMaxPrice(String value) {
    if (value.isEmpty) {
      priceRangeValues.value = RangeValues(priceRangeValues.value.start, 1000);
      return;
    }

    final maxPrice = double.tryParse(value);
    if (maxPrice != null && maxPrice >= 0) {
      final currentMin = priceRangeValues.value.start;

      // Ensure max is not less than min and within limits
      if (maxPrice >= currentMin && maxPrice <= 1000) {
        priceRangeValues.value = RangeValues(currentMin, maxPrice);
      } else if (maxPrice < currentMin) {
        // If user types max < min, adjust min too
        priceRangeValues.value = RangeValues(maxPrice, maxPrice);
        minPriceController.text = maxPrice.round().toString();
      }
    }
  }

  // Get current min price
  double get minPrice => priceRangeValues.value.start;

  // Get current max price
  double get maxPrice => priceRangeValues.value.end;

  // Reset all filters
  void reset() {
    priceRangeValues.value = const RangeValues(0, 1000);
    minPriceController.text = '0';
    maxPriceController.text = '1000';
  }

  // Apply filters
  void apply() {
    Get.back(
      result: {
        'minPrice': priceRangeValues.value.start,
        'maxPrice': priceRangeValues.value.end,
      },
    );
  }

}