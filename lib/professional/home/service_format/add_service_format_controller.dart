import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../api/api_response.dart';
import '../../../../api/user_api_service.dart';
import '../../../../common/base_controller.dart';
import '../../../../models/service_model.dart';
import '../../../../routes/app_routes.dart';
import '../../../../widgets/response_dialog.dart';
import '../home_controller.dart';

class ServiceFormatData {
  final String serviceFormatId;
  final String serviceName;
  final bool isBundle;
  final String? time;
  final String? price;
  final String? timePerSession; // For bundles
  final String? bundlePrice; // For bundles
  final String? offerText; // For bundles
  final int? bundleOf; // For bundles

  ServiceFormatData({
    required this.serviceFormatId,
    required this.serviceName,
    required this.isBundle,
    this.time,
    this.price,
    this.timePerSession,
    this.bundlePrice,
    this.offerText,
    this.bundleOf,
  });

  ServiceFormatData copyWith({
    String? serviceFormatId,
    String? serviceName,
    bool? isBundle,
    String? time,
    String? price,
    String? timePerSession,
    String? bundlePrice,
    String? offerText,
    int? bundleOf,
  }) {
    return ServiceFormatData(
      serviceFormatId: serviceFormatId ?? this.serviceFormatId,
      serviceName: serviceName ?? this.serviceName,
      isBundle: isBundle ?? this.isBundle,
      time: time ?? this.time,
      price: price ?? this.price,
      timePerSession: timePerSession ?? this.timePerSession,
      bundlePrice: bundlePrice ?? this.bundlePrice,
      offerText: offerText ?? this.offerText,
      bundleOf: bundleOf ?? this.bundleOf,
    );
  }
}

class AddServiceFormatController extends BaseController {
  AddServiceFormatController(this._userApiService);

  final UserApiService _userApiService;

  // Form key for validation
  late final GlobalKey<FormState> formKey;

  // List of selected services passed from previous page
  final serviceFormats = <ServiceFormatData>[].obs;

  // Selected date from calendar
  DateTime selectedDate = DateTime.now();

  // Text field controller for service format selection
  final serviceFormatController = TextEditingController();

  // Validation errors map: 'field_index' -> error message
  final fieldErrors = <String, String>{}.obs;

  // Validation error for service format field
  final serviceFormatError = Rxn<String>();

  // Duration options for time picker
  final durationOptions = ['15 mins', '30 mins', '45 mins', '1 hour'];

  // Track which dropdown is open: 'time_index' or 'timePerSession_index'
  final openDropdown = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    // Initialize formKey to ensure a new key is created each time
    formKey = GlobalKey<FormState>();

    // Get arguments - can be Map or List (for backward compatibility)
    final args = Get.arguments;
    List<ServiceFormatModel> selectedServiceFormats = [];

    if (args is Map) {
      // New format with date
      selectedServiceFormats =
          args['serviceFormats'] as List<ServiceFormatModel>? ?? [];
      if (args['selectedDate'] is DateTime) {
        selectedDate = args['selectedDate'] as DateTime;
      }
    } else if (args is List) {
      // Old format (backward compatibility)
      selectedServiceFormats = args.cast<ServiceFormatModel>();
    }

    // Initialize service formats for each selected service format model
    for (var formatModel in selectedServiceFormats) {
      serviceFormats.add(ServiceFormatData(
        serviceFormatId: formatModel.id ?? '',
        serviceName: formatModel.name ?? '',
        isBundle: formatModel.isBundle ?? false,
        bundleOf: formatModel.bundleOf,
      ));
    }

    // Update service format controller text if services are selected
    if (serviceFormats.isNotEmpty) {
      if (serviceFormats.length == 1) {
        serviceFormatController.text = serviceFormats.first.serviceName;
      } else {
        serviceFormatController.text =
            '${serviceFormats.length} services selected';
      }
      // Clear validation error if services are already selected
      serviceFormatError.value = null;
    }
  }

  // Get controller for time field
  TextEditingController getTimeController(int index) {
    final key = 'time_$index';
    if (!_controllers.containsKey(key)) {
      final controller = TextEditingController();
      // Initialize with existing value if available
      if (index < serviceFormats.length && serviceFormats[index].time != null) {
        controller.text = serviceFormats[index].time!;
      }
      _controllers[key] = controller;
    }
    return _controllers[key] as TextEditingController;
  }

  // Get controller for price field
  TextEditingController getPriceController(int index) {
    final key = 'price_$index';
    if (!_controllers.containsKey(key)) {
      final controller = TextEditingController();
      // Initialize with existing value if available
      if (index < serviceFormats.length &&
          serviceFormats[index].price != null) {
        controller.text = serviceFormats[index].price!;
      }
      _controllers[key] = controller;
    }
    return _controllers[key] as TextEditingController;
  }

  // Get controller for time per session field (bundles)
  TextEditingController getTimePerSessionController(int index) {
    final key = 'timePerSession_$index';
    if (!_controllers.containsKey(key)) {
      final controller = TextEditingController();
      // Initialize with existing value if available
      if (index < serviceFormats.length &&
          serviceFormats[index].timePerSession != null) {
        controller.text = serviceFormats[index].timePerSession!;
      }
      _controllers[key] = controller;
    }
    return _controllers[key] as TextEditingController;
  }

  // Get controller for bundle price field
  TextEditingController getBundlePriceController(int index) {
    final key = 'bundlePrice_$index';
    if (!_controllers.containsKey(key)) {
      final controller = TextEditingController();
      // Initialize with existing value if available
      if (index < serviceFormats.length &&
          serviceFormats[index].bundlePrice != null) {
        controller.text = serviceFormats[index].bundlePrice!;
      }
      _controllers[key] = controller;
    }
    return _controllers[key] as TextEditingController;
  }

  // Get controller for offer text field (bundles)
  TextEditingController getOfferTextController(int index) {
    final key = 'offerText_$index';
    if (!_controllers.containsKey(key)) {
      final controller = TextEditingController();
      // Initialize with existing value if available
      if (index < serviceFormats.length &&
          serviceFormats[index].offerText != null) {
        controller.text = serviceFormats[index].offerText!;
      }
      _controllers[key] = controller;
    }
    return _controllers[key] as TextEditingController;
  }

  final Map<String, TextEditingController> _controllers = {};

  // Toggle duration dropdown
  void toggleDurationDropdown(int index, bool isBundle) {
    final key = isBundle ? 'timePerSession_$index' : 'time_$index';
    if (openDropdown.value == key) {
      openDropdown.value = null;
    } else {
      openDropdown.value = key;
    }
  }

  // Select duration option
  void selectDuration(int index, bool isBundle, String duration) {
    if (index < 0 || index >= serviceFormats.length) {
      return; // Index out of bounds, skip update
    }
    if (isBundle) {
      getTimePerSessionController(index).text = duration;
      final format = serviceFormats[index];
      serviceFormats[index] = format.copyWith(timePerSession: duration);
      // Clear error when selection is made
      fieldErrors.remove('timePerSession_$index');
      fieldErrors.refresh();
    } else {
      getTimeController(index).text = duration;
      final format = serviceFormats[index];
      serviceFormats[index] = format.copyWith(time: duration);
      // Clear error when selection is made
      fieldErrors.remove('time_$index');
      fieldErrors.refresh();
    }
    openDropdown.value = null; // Close dropdown after selection
    // Trigger form validation to update field state and clear errors
    formKey.currentState?.validate();
  }

  // Check if dropdown is open for this field
  bool isDropdownOpen(int index, bool isBundle) {
    final key = isBundle ? 'timePerSession_$index' : 'time_$index';
    return openDropdown.value == key;
  }

  // Update price
  void updatePrice(int index, String value) {
    if (index < 0 || index >= serviceFormats.length) {
      return; // Index out of bounds, skip update
    }
    final format = serviceFormats[index];
    serviceFormats[index] = format.copyWith(price: value);
  }

  // Update bundle price
  void updateBundlePrice(int index, String value) {
    if (index < 0 || index >= serviceFormats.length) {
      return; // Index out of bounds, skip update
    }
    final format = serviceFormats[index];
    serviceFormats[index] = format.copyWith(bundlePrice: value);
  }

  // Update offer text
  void updateOfferText(int index, String value) {
    if (index < 0 || index >= serviceFormats.length) {
      return; // Index out of bounds, skip update
    }
    final format = serviceFormats[index];
    serviceFormats[index] = format.copyWith(offerText: value);
  }

  // Delete service format
  void deleteServiceFormat(int index) {
    // Dispose controllers for this index
    final keysToRemove = <String>[];
    for (var key in _controllers.keys) {
      if (key.contains('_$index')) {
        _controllers[key]?.dispose();
        keysToRemove.add(key);
      }
    }
    for (var key in keysToRemove) {
      _controllers.remove(key);
    }

    serviceFormats.removeAt(index);

    // Update service format controller text
    if (serviceFormats.isEmpty) {
      serviceFormatController.text = '';
      // Show validation error if all services are deleted
      serviceFormatError.value = 'Service format is required';
    } else {
      if (serviceFormats.length == 1) {
        serviceFormatController.text = serviceFormats.first.serviceName;
      } else {
        serviceFormatController.text =
            '${serviceFormats.length} services selected';
      }
      // Clear validation error if services still exist
      serviceFormatError.value = null;
    }

    if (serviceFormats.isEmpty) {
      Get.back(result: serviceFormats);
    }
  }

  // Validate time field
  String? validateTime(int index) {
    if (index < 0 || index >= serviceFormats.length) {
      return null; // Index out of bounds, skip validation
    }
    final format = serviceFormats[index];
    if (format.time == null || format.time!.isEmpty) {
      fieldErrors['time_$index'] = 'Time is required';
      fieldErrors.refresh();
      return 'Time is required';
    }
    fieldErrors.remove('time_$index');
    fieldErrors.refresh();
    return null;
  }

  // Validate price field
  String? validatePrice(int index) {
    if (index < 0 || index >= serviceFormats.length) {
      return null; // Index out of bounds, skip validation
    }
    final format = serviceFormats[index];
    if (format.price == null || format.price!.isEmpty) {
      fieldErrors['price_$index'] = 'Price is required';
      fieldErrors.refresh();
      return 'Price is required';
    }
    // Validate that price is a valid number
    final priceValue = int.tryParse(format.price!.trim());
    if (priceValue == null) {
      fieldErrors['price_$index'] = 'Please enter a valid number';
      fieldErrors.refresh();
      return 'Please enter a valid number';
    }
    // Validate that price is greater than 0
    if (priceValue <= 0) {
      fieldErrors['price_$index'] = 'Price must be greater than 0';
      fieldErrors.refresh();
      return 'Price must be greater than 0';
    }
    fieldErrors.remove('price_$index');
    fieldErrors.refresh();
    return null;
  }

  // Validate time per session field (bundle)
  String? validateTimePerSession(int index) {
    if (index < 0 || index >= serviceFormats.length) {
      return null; // Index out of bounds, skip validation
    }
    final format = serviceFormats[index];
    if (format.timePerSession == null || format.timePerSession!.isEmpty) {
      fieldErrors['timePerSession_$index'] = 'Time per session is required';
      fieldErrors.refresh();
      return 'Time per session is required';
    }
    fieldErrors.remove('timePerSession_$index');
    fieldErrors.refresh();
    return null;
  }

  // Validate bundle price field
  String? validateBundlePrice(int index) {
    if (index < 0 || index >= serviceFormats.length) {
      return null; // Index out of bounds, skip validation
    }
    final format = serviceFormats[index];
    if (format.bundlePrice == null || format.bundlePrice!.isEmpty) {
      fieldErrors['bundlePrice_$index'] = 'Bundle price is required';
      fieldErrors.refresh();
      return 'Bundle price is required';
    }
    // Validate that bundle price is a valid number
    final bundlePriceValue = int.tryParse(format.bundlePrice!.trim());
    if (bundlePriceValue == null) {
      fieldErrors['bundlePrice_$index'] = 'Please enter a valid number';
      fieldErrors.refresh();
      return 'Please enter a valid number';
    }
    // Validate that bundle price is greater than 0
    if (bundlePriceValue <= 0) {
      fieldErrors['bundlePrice_$index'] = 'Bundle price must be greater than 0';
      fieldErrors.refresh();
      return 'Bundle price must be greater than 0';
    }
    fieldErrors.remove('bundlePrice_$index');
    fieldErrors.refresh();
    return null;
  }

  // Validate offer text field
  String? validateOfferText(int index) {
    if (index < 0 || index >= serviceFormats.length) {
      return null; // Index out of bounds, skip validation
    }
    // final format = serviceFormats[index];
    // if (format.offerText == null || format.offerText!.isEmpty) {
    //   fieldErrors['offerText_$index'] = 'Offer text is required';
    //   fieldErrors.refresh();
    //   return 'Offer text is required';
    // }
    fieldErrors.remove('offerText_$index');
    fieldErrors.refresh();
    return null;
  }

  // Convert duration string to minutes
  int? convertDurationToMinutes(String? duration) {
    if (duration == null || duration.isEmpty) {
      return null;
    }

    final lowerDuration = duration.toLowerCase().trim();

    // Handle "15 mins", "30 mins", "45 mins"
    if (lowerDuration.contains('mins')) {
      final match = RegExp(r'(\d+)').firstMatch(lowerDuration);
      if (match != null) {
        return int.tryParse(match.group(1)!);
      }
    }

    // Handle "1 hour"
    if (lowerDuration.contains('hour')) {
      final match = RegExp(r'(\d+)').firstMatch(lowerDuration);
      if (match != null) {
        return int.tryParse(match.group(1)!)! * 60;
      }
      // Default to 60 minutes if just "hour" without number
      return 60;
    }

    // Try to parse as number (assuming minutes)
    return int.tryParse(lowerDuration);
  }

  // Format date as DD/MM/YYYY
  String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  // Validate and save
  void onAddServiceFormat() {
    // First, sync controller values to serviceFormats to ensure data consistency
    for (int i = 0; i < serviceFormats.length; i++) {
      final format = serviceFormats[i];
      if (format.isBundle) {
        // Sync bundle price controller
        final bundlePriceController = getBundlePriceController(i);
        if (bundlePriceController.text.trim() != (format.bundlePrice ?? '')) {
          updateBundlePrice(i, bundlePriceController.text);
        }
        // Sync offer text controller
        final offerTextController = getOfferTextController(i);
        if (offerTextController.text.trim() != (format.offerText ?? '')) {
          updateOfferText(i, offerTextController.text);
        }
      } else {
        // Sync price controller
        final priceController = getPriceController(i);
        if (priceController.text.trim() != (format.price ?? '')) {
          updatePrice(i, priceController.text);
        }
      }
    }

    // Clear previous errors
    fieldErrors.clear();
    serviceFormatError.value = null;

    // Validate service format field first
    bool isValid = true;
    if (validateServiceFormat() != null) {
      isValid = false;
    }

    // Validate all fields
    for (int i = 0; i < serviceFormats.length; i++) {
      final format = serviceFormats[i];
      if (format.isBundle) {
        if (validateTimePerSession(i) != null) isValid = false;
        if (validateBundlePrice(i) != null) isValid = false;
        // if (validateOfferText(i) != null) isValid = false;
      } else {
        if (validateTime(i) != null) isValid = false;
        if (validatePrice(i) != null) isValid = false;
      }
    }

    if (!isValid) {
      // Refresh UI to show errors and trigger form validation
      fieldErrors.refresh();
      formKey.currentState?.validate();
      return;
    }

    // Prepare service formats for API
    final List<Map<String, dynamic>> serviceFormatsPayload = [];
    final formattedDate = formatDate(selectedDate);

    for (final format in serviceFormats) {
      if (format.isBundle) {
        // Bundle format
        final bundlePayload = <String, dynamic>{
          'service_format_id': format.serviceFormatId,
          'is_bundle': true,
          'bundle_of': format.bundleOf ?? 5, // Default to 5 if not specified
          'bundle_price': int.tryParse(format.bundlePrice ?? '0') ?? 0,
          'service_format_date': formattedDate,
        };

        // Add duration_minutes if timePerSession is provided
        final durationMinutes = convertDurationToMinutes(format.timePerSession);
        if (durationMinutes != null) {
          bundlePayload['duration_minutes'] = durationMinutes;
        }

        // Add offer_text if provided
        if (format.offerText != null && format.offerText!.isNotEmpty) {
          bundlePayload['offer_text'] = format.offerText;
        }

        serviceFormatsPayload.add(bundlePayload);
      } else {
        // Regular format
        final regularPayload = <String, dynamic>{
          'service_format_id': format.serviceFormatId,
          'is_bundle': false,
          'price': int.tryParse(format.price ?? '0') ?? 0,
          'service_format_date': formattedDate,
        };

        // Add duration_minutes if time is provided
        final durationMinutes = convertDurationToMinutes(format.time);
        if (durationMinutes != null) {
          regularPayload['duration_minutes'] = durationMinutes;
        }

        serviceFormatsPayload.add(regularPayload);
      }
    }

    // Call API to save service formats
    callDataService(
      _userApiService.createServiceFormats(
        serviceFormats: serviceFormatsPayload,
      ),
      showLoader: true,
      onSuccess: (ApiResponse<dynamic> response) {
        if (response.success) {
          // Show success dialog
          showResponseDialog(
            message: response.message ?? 'Service formats added successfully',
            title: 'Success',
            isError: false,
            showButton: false,
            onOkPressed: () {
              // Navigate to home and select calendar tab
              Get.offAllNamed(Routes.home);

              // Set calendar tab (index 1) after navigation
              // Use post-frame callback to ensure the home view is built
              WidgetsBinding.instance.addPostFrameCallback((_) {
                try {
                  final homeController = Get.find<HomeController>();
                  homeController.onTabSelected(1); // Calendar tab is at index 1
                } catch (e) {
                  // If controller is not found yet, try again after a short delay
                  Future.delayed(Duration(milliseconds: 200), () {
                    try {
                      final homeController = Get.find<HomeController>();
                      homeController.onTabSelected(1);
                    } catch (_) {
                      // Controller still not found, navigation will handle it
                    }
                  });
                }
              });
            },
          );
        } else {
          // Show error dialog
          showResponseDialog(
            title: 'Error',
            message: response.errorMessage.isNotEmpty
                ? response.errorMessage
                : 'Failed to save service formats',
            isError: true,
            showButton: true,
          );
        }
      },
      onError: (error, stack) {
        // Show error dialog for unexpected errors
        showResponseDialog(
          title: 'Error',
          message: 'Failed to save service formats. Please try again.',
          isError: true,
          showButton: true,
        );
      },
    );
  }

  // Navigate to service format selection page
  void navigateToServiceFormat() async {
    // await Get.toNamed(
    //   Routes.serviceFormat,
    //   arguments: selectedDate,
    // );

    Get.back(result: selectedDate);
    // Note: When services are selected, ServiceFormatController navigates to
    // AddServiceFormat with new arguments, creating a new instance.
    // The validation will be cleared in onInit when services are present.
  }

  // Validate service format field
  String? validateServiceFormat() {
    if (serviceFormats.isEmpty) {
      serviceFormatError.value = 'Service format is required';
      return 'Service format is required';
    }
    serviceFormatError.value = null;
    return null;
  }

  @override
  void onClose() {
    // Dispose all controllers
    serviceFormatController.dispose();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.onClose();
  }
}
