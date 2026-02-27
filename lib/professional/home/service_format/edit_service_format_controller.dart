import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../api/api_response.dart';
import '../../../../api/user_api_service.dart';
import '../../../../common/base_controller.dart';
import '../../../../routes/app_routes.dart';
import '../../../../widgets/response_dialog.dart';
import '../calendar_controller.dart';
import '../home_controller.dart';

class EditServiceFormatController extends BaseController {
  EditServiceFormatController(this._userApiService);

  final UserApiService _userApiService;

  // Form key for validation
  late final GlobalKey<FormState> formKey;

  // Service format data
  late String serviceFormatId;
  late String serviceFormatName;
  final selectedDuration = ''.obs;
  final priceController = TextEditingController();
  final offerTextController = TextEditingController();
  final isBundle = false.obs;
  String? offerText;
  int? bundleOf;
  DateTime selectedDate = DateTime.now();

  // Validation errors map
  final fieldErrors = <String, String>{}.obs;

  // Duration options for time picker
  final durationOptions = ['15 mins', '30 mins', '45 mins', '1 hour'];

  @override
  void onInit() {
    super.onInit();
    formKey = GlobalKey<FormState>();

    // Get arguments - ServiceFormatItem and selectedDate
    final args = Get.arguments;
    if (args is Map) {
      final serviceFormat = args['serviceFormat'] as ServiceFormatItem?;
      if (args['selectedDate'] is DateTime) {
        selectedDate = args['selectedDate'] as DateTime;
      }

      if (serviceFormat != null) {
        serviceFormatId = serviceFormat.id;
        serviceFormatName = serviceFormat.name;
        isBundle.value = serviceFormat.isBundle;
        offerText = serviceFormat.offerText;

        // Parse duration from string like "45 mins" or "1 hour" or "60 mins"
        final durationStr = serviceFormat.duration;
        if (durationStr.isNotEmpty) {
          // Check if it matches one of our options
          if (durationOptions.contains(durationStr)) {
            selectedDuration.value = durationStr;
          } else {
            // Try to parse and match
            final lowerDuration = durationStr.toLowerCase().trim();
            if (lowerDuration.contains('mins')) {
              final match = RegExp(r'(\d+)').firstMatch(lowerDuration);
              if (match != null) {
                final mins = match.group(1)!;
                final minsInt = int.tryParse(mins);
                // Convert 60 mins to "1 hour"
                if (minsInt == 60) {
                  selectedDuration.value = '1 hour';
                } else {
                  final option = '$mins mins';
                  if (durationOptions.contains(option)) {
                    selectedDuration.value = option;
                  }
                }
              }
            } else if (lowerDuration.contains('hour')) {
              final match = RegExp(r'(\d+)').firstMatch(lowerDuration);
              if (match != null) {
                final hours = match.group(1)!;
                final option = '$hours hour';
                if (durationOptions.contains(option)) {
                  selectedDuration.value = option;
                } else if (hours == '1') {
                  selectedDuration.value = '1 hour';
                }
              } else {
                selectedDuration.value = '1 hour';
              }
            }
          }
        }

        // Parse price from string like "£30" or "30"
        final priceStr = serviceFormat.price;
        if (priceStr.isNotEmpty) {
          // Remove currency symbols and extract number
          final priceValue = priceStr.replaceAll(RegExp(r'[£,\s]'), '');
          priceController.text = priceValue;
        }

        // Initialize offer text if it's a bundle
        if (isBundle.value && offerText != null && offerText!.isNotEmpty) {
          offerTextController.text = offerText!;
        }
      }
    }
  }

  // Select duration option
  void selectDuration(String duration) {
    selectedDuration.value = duration;
    fieldErrors.remove('duration');
    fieldErrors.refresh();
    formKey.currentState?.validate();
  }

  // Update price
  void updatePrice(String value) {
    // Price is stored in the controller, no additional action needed
  }

  // Update offer text
  void updateOfferText(String value) {
    offerText = value;
    fieldErrors.remove('offerText');
    fieldErrors.refresh();
  }

  // Validate duration field
  String? validateDuration() {
    if (selectedDuration.value.isEmpty) {
      fieldErrors['duration'] = 'Duration is required';
      fieldErrors.refresh();
      return 'Duration is required';
    }
    fieldErrors.remove('duration');
    fieldErrors.refresh();
    return null;
  }

  // Validate price field
  String? validatePrice() {
    final price = priceController.text.trim();
    if (price.isEmpty) {
      fieldErrors['price'] = 'Price is required';
      fieldErrors.refresh();
      return 'Price is required';
    }
    final priceValue = int.tryParse(price);
    if (priceValue == null || priceValue <= 0) {
      fieldErrors['price'] = 'Please enter a valid price';
      fieldErrors.refresh();
      return 'Please enter a valid price';
    }
    fieldErrors.remove('price');
    fieldErrors.refresh();
    return null;
  }

  // Validate offer text field (optional for bundles)
  String? validateOfferText() {
    // Offer text is optional, so always return null
    fieldErrors.remove('offerText');
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

  // Update service format
  void onUpdateServiceFormat() {
    // Clear previous errors
    fieldErrors.clear();

    // Validate all fields
    bool isValid = true;
    if (validateDuration() != null) isValid = false;
    if (validatePrice() != null) isValid = false;

    if (!isValid) {
      fieldErrors.refresh();
      return;
    }

    // Prepare service format payload for API
    final durationMinutes = convertDurationToMinutes(selectedDuration.value);
    final priceValue = int.tryParse(priceController.text.trim()) ?? 0;

    if (durationMinutes == null) {
      setError('Please select a valid duration');
      return;
    }

    // Get offer text if it's a bundle
    final offerTextValue =
        isBundle.value ? offerTextController.text.trim() : null;

    // Call API to update service format
    callDataService(
      _userApiService.updateServiceFormat(
        id: serviceFormatId,
        durationMinutes: durationMinutes,
        price: priceValue,
        bundleOf: isBundle.value ? (bundleOf ?? 5) : null,
        bundlePrice: isBundle.value ? priceValue : null,
        offerText: offerTextValue?.isNotEmpty == true ? offerTextValue : null,
      ),
      showLoader: true,
      onSuccess: (ApiResponse<dynamic> response) {
        if (response.success) {
          // Show success dialog
          final successMessage =
              response.message ?? 'Service format updated successfully';
          showResponseDialog(
            message: successMessage,
            title: 'Success',
            isError: false,
            showButton: false,
            onOkPressed: () {
              Get.back();
              // Refresh the calendar view
              Get.offAllNamed(Routes.home);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                try {
                  final homeController = Get.find<HomeController>();
                  homeController.onTabSelected(1);
                } catch (e) {
                  Future.delayed(Duration(milliseconds: 200), () {
                    try {
                      final homeController = Get.find<HomeController>();
                      homeController.onTabSelected(1);
                    } catch (_) {}
                  });
                }
              });
            },
          );
        } else {
          // Show error dialog
          showResponseDialog(
            message: response.message ?? 'Failed to update service format',
            title: 'Error',
            isError: true,
            showButton: true,
          );
        }
      },
      onError: (error, stack) {
        // Show error dialog
        showResponseDialog(
          message: 'Failed to update service format. Please try again.',
          title: 'Error',
          isError: true,
          showButton: true,
        );
      },
    );
  }

  // Delete service format
  void deleteServiceFormat() {
    Get.dialog(
      AlertDialog(
        title: Text('Delete Service Format'),
        content: Text('Are you sure you want to delete this service format?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog
              // TODO: Call delete API if available
              // For now, just go back
              Get.back();
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void onClose() {
    priceController.dispose();
    offerTextController.dispose();
    super.onClose();
  }
}
