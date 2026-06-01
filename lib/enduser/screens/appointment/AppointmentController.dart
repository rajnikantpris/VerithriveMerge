import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:verithrive_dev/enduser/routes/app_routes.dart';
import 'package:verithrive_dev/enduser/screens/therapy_list/TherapistListingScreen.dart';
import 'package:verithrive_dev/enduser/screens/therapy_list/TherapyBinding.dart';
// import '../../utils/location_service.dart';
import '../../utils/AppText.dart';
import '../../../services/analytics_service.dart';

class AppointmentController extends GetxController {
  var isLastMinute = false.obs;
  var selectedAvailability = ''.obs;
  var distance = 10.0.obs;
  String? category;
  String? subTypeId;
  String? label;
  List<Map<String, dynamic>>? subTypesArray;
  String? type;

  final RxDouble maxDistance = 13.0.obs; // in miles
  final double minDistance = 0.0;
  final double maxDistanceLimit = 25.0;
  // final LocationService _locationService = LocationService();

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments;
    if (arguments != null && arguments is Map<String, dynamic>) {
      category = arguments['category'] as String?;
      subTypeId = arguments['sub_type_id'] as String?;
      label = arguments['label'] as String?;
      type = arguments['type'] as String?;

      // Get sub_types array
      if (arguments['sub_types'] != null) {
        subTypesArray = List<Map<String, dynamic>>.from(
          arguments['sub_types'] as List,
        );
      }
    }
  }

  void toggleAppointmentType(bool isLast) {
    isLastMinute.value = isLast;
    if (!isLast) {
      selectedAvailability.value = '';
      distance.value = 10.0;
    }
  }

  void setDistance(double value) {
    maxDistance.value = value;
    distance.value = value;
  }

  void setAvailability(String availability) {
    selectedAvailability.value = availability;
  }

  void updateDistance(double value) {
    distance.value = value;
  }

  /// Convert availability text to API format
  /// "Available in next 3 days" -> "3_days"
  /// "Available in next 7 days" -> "7_days"
  /// "Available in next 10 days" -> "10_days"
  String? _convertAvailabilityToApiFormat(String availability) {
    if (availability.isEmpty) return null;

    if (availability == AppText.availableInNext3Days) {
      return '3_days';
    } else if (availability == AppText.availableInNext7Days) {
      return '7_days';
    } else if (availability == AppText.availableInNext10Days) {
      return '10_days';
    }

    return null;
  }

  Future<void> search() async {
    // Get current location
    // final location = await _locationService.getCurrentLocationWithLoading();

    // if (location == null) {
    //   // Location is required, don't proceed
    //   print('❌ Location is null, cannot proceed to search');
    //   return;
    // }

    // Prepare arguments with all required data
    final args = <String, dynamic>{};

    if (category != null) {
      args['category'] = category;
    }

    if (subTypeId != null && subTypeId!.isNotEmpty) {
      args['sub_type_id'] = subTypeId;
    }

    if (label != null) {
      args['label'] = label;
    }

    // Pass type and sub_types array
    if (type != null) {
      args['type'] = type;
    }

    if (subTypesArray != null && subTypesArray!.isNotEmpty) {
      args['sub_types'] = subTypesArray;
    }

    // Convert availability to API format
    if (selectedAvailability.value.isNotEmpty) {
      final availabilityApiFormat =
          _convertAvailabilityToApiFormat(selectedAvailability.value);
      if (availabilityApiFormat != null) {
        args['availability'] = availabilityApiFormat;
      }
    }

    // Add distance
    args['distance'] = distance.value;

    // Add location
    // args['latitude'] = location['latitude'];
    // args['longitude'] = location['longitude'];

    // Analytics: Log search event

    // Log what we're passing
    print('========================================');
    print('APPOINTMENT CONTROLLER - PASSING ARGUMENTS');
    print('========================================');
    print('Category: ${args['category'] ?? "null"}');
    print('Type: ${args['type'] ?? "null"}');
    print('Sub Type ID: ${args['sub_type_id'] ?? "null"}');
    print('Label: ${args['label'] ?? "null"}');
    print('Sub Types Array: ${args['sub_types'] ?? "null"}');
    print(
        'Sub Types Count: ${subTypesArray != null ? subTypesArray!.length : 0}');
    print('Availability: ${args['availability'] ?? "null"}');
    print('Distance: ${args['distance'] ?? "null"} miles');
    print('Latitude: ${args['latitude'] ?? "null"}');
    print('Longitude: ${args['longitude'] ?? "null"}');
    print('========================================');
    print('Navigating to therapy_list...');
    print('========================================');

    // Navigate to therapy list with all parameters
    Get.to(
      () => TherapistListingScreen(),
      binding: TherapyBinding(),
      arguments: args,
    );
  }

  void skip() {
    // For skip, don't get location and don't pass lat/long
    // Prepare arguments without location
    final args = <String, dynamic>{};

    if (category != null) {
      args['category'] = category;
    }

    if (subTypeId != null && subTypeId!.isNotEmpty) {
      args['sub_type_id'] = subTypeId;
    }

    if (label != null) {
      args['label'] = label;
    }

    // Pass type and sub_types array
    if (type != null) {
      args['type'] = type;
    }

    if (subTypesArray != null && subTypesArray!.isNotEmpty) {
      args['sub_types'] = subTypesArray;
    }

    // Do NOT add location (latitude/longitude) when skipping
    // args['latitude'] = location['latitude'];
    // args['longitude'] = location['longitude'];

    // Log what we're passing
    print('========================================');
    print('APPOINTMENT CONTROLLER - SKIP (PASSING ARGUMENTS)');
    print('========================================');
    print('Category: ${args['category'] ?? "null"}');
    print('Type: ${args['type'] ?? "null"}');
    print('Sub Type ID: ${args['sub_type_id'] ?? "null"}');
    print('Label: ${args['label'] ?? "null"}');
    print('Sub Types Array: ${args['sub_types'] ?? "null"}');
    print(
        'Sub Types Count: ${subTypesArray != null ? subTypesArray!.length : 0}');
    print('Availability: null (skipped)');
    print('Distance: null (skipped)');
    print('Latitude: null (skipped - not passed)');
    print('Longitude: null (skipped - not passed)');
    print('========================================');
    print('Navigating to therapy_list without location...');
    print('========================================');

    // Navigate to therapy list without location
    Get.to(
      () => TherapistListingScreen(),
      binding: TherapyBinding(),
      arguments: args,
    );
  }
}
