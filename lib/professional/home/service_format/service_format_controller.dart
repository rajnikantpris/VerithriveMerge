import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../api/api_response.dart';
import '../../../../api/user_api_service.dart';
import '../../../../common/base_controller.dart';
import '../../../../models/service_model.dart';
import '../../../../routes/app_routes.dart';
import '../../../../services/analytics_service.dart';

class ServiceFormatController extends BaseController {
  ServiceFormatController(this._userApiService);

  final UserApiService _userApiService;

  // Text field controller
  final serviceFormatController = TextEditingController();

  // Show/hide service list
  final showServiceList = false.obs;

  // Checkbox selections - store service names for UI
  final selectedServices = <String>[].obs;

  // Service options for checkboxes - fetched from API
  final serviceOptions = <String>[].obs;

  // Service format models
  final serviceFormats = <ServiceFormatModel>[].obs;

  // Selected date from calendar
  DateTime? selectedDate;

  // Get selected service format models
  List<ServiceFormatModel> get selectedServiceFormatModels {
    return serviceFormats
        .where((format) => selectedServices.contains(format.name))
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    AnalyticsService.instance.logScreenView(
      screenName: 'ProfessionalServiceFormatScreen',
      screenClass: 'ServiceFormatView',
      pageCategory: 'calendar',
      elementLocation: 'view',
    );
    // Get selected date from arguments
    final dateArg = Get.arguments;
    if (dateArg is DateTime) {
      selectedDate = dateArg;
    }
    fetchServiceFormats();
  }

  /// Fetch service formats from API
  Future<void> fetchServiceFormats() async {
    await callDataService(
      _userApiService.getServiceFormats(),
      showLoader: true,
      onSuccess: (ApiResponse<dynamic> response) {
        if (response.success && response.data != null) {
          try {
            final List<dynamic> dataList = response.data as List<dynamic>;
            final formats = dataList
                .map((item) =>
                    ServiceFormatModel.fromJson(item as Map<String, dynamic>))
                .toList();

            // Filter only active and non-deleted service formats
            final activeFormats = formats
                .where((format) =>
                    format.isActive == true && format.isDeleted != true)
                .toList();

            serviceFormats.value = activeFormats;
            serviceOptions.value =
                activeFormats.map((format) => format.name ?? '').toList();
          } catch (e) {
            setError('Failed to parse service formats');
          }
        } else {
          setError(response.message ?? 'Failed to fetch service formats');
        }
      },
      onError: (error, stack) {
        setError('Failed to load service formats. Please try again.');
      },
    );
  }

  @override
  void onClose() {
    serviceFormatController.dispose();
    super.onClose();
  }

  // Toggle service list visibility
  void toggleServiceList() {
    showServiceList.value = !showServiceList.value;
  }

  // Toggle checkbox selection
  void toggleService(String service) {
    if (selectedServices.contains(service)) {
      selectedServices.remove(service);
    } else {
      selectedServices.add(service);
    }
  }

  // Check if service is selected
  bool isServiceSelected(String service) {
    return selectedServices.contains(service);
  }

  // Check if button should be enabled
  bool get isButtonEnabled {
    return selectedServices.isNotEmpty;
  }

  // Handle select services button tap
  void onSelectServices() async {
    if (isButtonEnabled) {
      // Update the service format controller text with selected services
      if (selectedServices.length == 1) {
        serviceFormatController.text = selectedServices.first;
      } else {
        serviceFormatController.text =
            '${selectedServices.length} services selected';
      }

      // Navigate to Add Service Format page with selected service format models and date
      var result = await Get.toNamed(
        Routes.addServiceFormat,
        arguments: {
          'serviceFormats': selectedServiceFormatModels,
          'selectedDate': selectedDate ?? DateTime.now(),
        },
      );

      if (result != null && result is List<String>) {
        selectedServices.clear();
        selectedServices.addAll(result);
        if (selectedServices.isNotEmpty) {
          showServiceList.value = true;
        } else {
          showServiceList.value = false;
        }
      }

      // Close the service list
    }
  }
}
