import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../api/api_response.dart';
import '../../../api/user_api_service.dart';
import '../../../common/base_controller.dart';
import '../../../services/analytics_service.dart';
import '../../../utils/timezone_helper.dart';
import '../../../widgets/response_dialog.dart';
import '../../home/calendar_controller.dart';

class UnavailableTime {
  final TimeOfDay from;
  final TimeOfDay until;

  UnavailableTime({required this.from, required this.until});
}

class CreateAvailabilityController extends BaseController {
  CreateAvailabilityController([UserApiService? userApiService])
      : _userApiService = userApiService ??
            (Get.isRegistered<UserApiService>()
                ? Get.find<UserApiService>()
                : null);

  final UserApiService? _userApiService;

  late final GlobalKey<FormState> formKey;
  late final GlobalKey<FormState> unavailableTimeFormKey;

  @override
  void onInit() {
    super.onInit();
    // Initialize formKeys to ensure new keys are created each time
    formKey = GlobalKey<FormState>();
    unavailableTimeFormKey = GlobalKey<FormState>();
  }

  // Date controllers
  final dateController = TextEditingController();
  final repeatController = TextEditingController();
  final repeatUntilController = TextEditingController();

  // Selected values
  final selectedDate = Rxn<DateTime>();
  final selectedRepeatUntil = Rxn<DateTime>();

  // Repeat options
  final repeatOptions = [
    "Don't repeat",
    "Everyday",
    "Every week",
    "Every two week",
  ];
  final selectedRepeat = ''.obs;

  // Exclusion options
  final excludeWeekends = false.obs;
  final excludePublicHolidays = false.obs;

  // Available time
  final availableFromController = TextEditingController();
  final availableUntilController = TextEditingController();
  final selectedAvailableFrom = Rxn<TimeOfDay>();
  final selectedAvailableUntil = Rxn<TimeOfDay>();

  // Unavailable times list
  final unavailableTimes = <UnavailableTime>[].obs;

  // Current unavailable time being added
  final unavailableFromController = TextEditingController();
  final unavailableUntilController = TextEditingController();
  final selectedUnavailableFrom = Rxn<TimeOfDay>();
  final selectedUnavailableUntil = Rxn<TimeOfDay>();

  // Track if validation has been triggered
  final hasValidated = false.obs;
  final hasValidatedUnavailableTime = false.obs;

  // Track which fields have been interacted with
  final touchedFields = <String>{}.obs;

  @override
  void onClose() {
    dateController.dispose();
    repeatController.dispose();
    repeatUntilController.dispose();
    availableFromController.dispose();
    availableUntilController.dispose();
    unavailableFromController.dispose();
    unavailableUntilController.dispose();
    super.onClose();
  }

  void markFieldTouched(String fieldName) {
    touchedFields.add(fieldName);
  }

  Future<void> pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = selectedDate.value ?? now;

    final lastDate = DateTime(
      initial.year + 2,
      initial.month,
      initial.day,
    );
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now,
      lastDate: lastDate,
    );

    if (picked != null) {
      selectedDate.value = picked;
      dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      markFieldTouched('date');
      // Clear validation error for this field
      formKey.currentState?.validate();
    }
  }

  Future<void> pickRepeatUntil(BuildContext context) async {
    // Repeat until date should be after the start date
    final startDate = selectedDate.value;
    if (startDate == null) {
      Get.snackbar(
        'Error',
        'Please select start date first',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade700,
      );
      return;
    }

    // First date should be the day after start date
    // Normalize to midnight first, then add 1 day to handle month/year boundaries correctly
    final normalizedStartDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    final firstDate = normalizedStartDate.add(const Duration(days: 1));

    // Set last date to be 2 years from the start date to allow sufficient future dates
    final lastDate = DateTime(
      startDate.year + 2,
      startDate.month,
      startDate.day,
    );

    final initial = selectedRepeatUntil.value ?? firstDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      selectedRepeatUntil.value = picked;
      repeatUntilController.text = DateFormat('dd/MM/yyyy').format(picked);
      markFieldTouched('repeatUntil');
      // Clear validation error for this field
      formKey.currentState?.validate();
    }
  }

  void setRepeat(String? value) {
    if (value == null) {
      selectedRepeat.value = '';
      repeatController.text = '';
      return;
    }
    selectedRepeat.value = value;
    repeatController.text = value;
    markFieldTouched('repeat');
    // Clear validation error for this field
    formKey.currentState?.validate();
  }

  void toggleExcludeWeekends(bool? value) {
    excludeWeekends.value = value ?? false;
  }

  void toggleExcludePublicHolidays(bool? value) {
    excludePublicHolidays.value = value ?? false;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatTimeOfDay2(TimeOfDay time) {
    int hour12 = time.hour;
    final period = time.hour < 12 ? 'AM' : 'PM';

    // Convert 24-hour format to 12-hour format
    if (hour12 == 0) {
      hour12 = 12; // 0:00 becomes 12:00 AM
    } else if (hour12 > 12) {
      hour12 = hour12 - 12; // 13-23 becomes 1-11 PM
    }
    // 1-11 stays as is for AM, 12 stays as 12 for PM

    final hour = hour12.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  Future<void> pickAvailableFrom(BuildContext context) async {
    final initial =
        selectedAvailableFrom.value ?? const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      selectedAvailableFrom.value = picked;
      availableFromController.text = _formatTimeOfDay2(picked);
      markFieldTouched('availableFrom');
      // Clear validation error for this field
      formKey.currentState?.validate();
      // Re-validate unavailable time fields if they have values
      if (selectedUnavailableFrom.value != null ||
          selectedUnavailableUntil.value != null) {
        unavailableTimeFormKey.currentState?.validate();
      }
    }
  }

  Future<void> pickAvailableUntil(BuildContext context) async {
    final initial =
        selectedAvailableUntil.value ?? const TimeOfDay(hour: 17, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      selectedAvailableUntil.value = picked;
      availableUntilController.text = _formatTimeOfDay2(picked);
      markFieldTouched('availableUntil');
      // Clear validation error for this field
      formKey.currentState?.validate();
      // Re-validate unavailable time fields if they have values
      if (selectedUnavailableFrom.value != null ||
          selectedUnavailableUntil.value != null) {
        unavailableTimeFormKey.currentState?.validate();
      }
    }
  }

  Future<void> pickUnavailableFrom(BuildContext context) async {
    final initial =
        selectedUnavailableFrom.value ?? const TimeOfDay(hour: 12, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      selectedUnavailableFrom.value = picked;
      unavailableFromController.text = _formatTimeOfDay2(picked);
      markFieldTouched('unavailableFrom');
      // Validate both fields to check range validation
      unavailableTimeFormKey.currentState?.validate();
    }
  }

  Future<void> pickUnavailableUntil(BuildContext context) async {
    final initial =
        selectedUnavailableFrom.value ?? const TimeOfDay(hour: 13, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      selectedUnavailableUntil.value = picked;
      unavailableUntilController.text = _formatTimeOfDay2(picked);
      markFieldTouched('unavailableUntil');
      // Validate both fields to check range validation
      unavailableTimeFormKey.currentState?.validate();
    }
  }

  void addUnavailableTime() {
    // Mark that validation has been triggered for unavailable time form
    hasValidatedUnavailableTime.value = true;

    // Validate only unavailable time fields using the separate form key
    if (!(unavailableTimeFormKey.currentState?.validate() ?? false)) {
      return;
    }

    // If validation passes, add the unavailable time
    final from = selectedUnavailableFrom.value!;
    final until = selectedUnavailableUntil.value!;

    unavailableTimes.add(UnavailableTime(from: from, until: until));
    unavailableFromController.clear();
    unavailableUntilController.clear();
    selectedUnavailableFrom.value = null;
    selectedUnavailableUntil.value = null;
    // Clear touched fields for unavailable time so they can be validated again next time
    touchedFields.remove('unavailableFrom');
    touchedFields.remove('unavailableUntil');
    // Reset validation flag for next unavailable time entry
    hasValidatedUnavailableTime.value = false;
  }

  void removeUnavailableTime(int index) {
    unavailableTimes.removeAt(index);
  }

  /// Refresh calendar data after creating availability
  void _refreshCalendarData() {
    try {
      // Try to find CalendarController and refresh data
      if (Get.isRegistered<CalendarController>()) {
        final calendarController = Get.find<CalendarController>();
        calendarController.refreshServiceFormatAvailability();
      }
    } catch (e) {
      // CalendarController might not be available, ignore error
      debugPrint('Could not refresh calendar data: $e');
    }
  }

  Future<void> onAddAvailability(
      {bool replaceExisting = false, bool isConfirmed = false}) async {
    // Mark that validation has been triggered
    hasValidated.value = true;

    // Validate all fields using form validation
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    // Check if API service is available
    if (_userApiService == null) {
      Get.snackbar(
        'Error',
        'API service not available',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade700,
      );
      return;
    }

    // Prepare data for API call
    final startDate = selectedDate.value;
    if (startDate == null) {
      Get.snackbar(
        'Error',
        'Please select a date',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade700,
      );
      return;
    }

    final availableFrom = selectedAvailableFrom.value;
    final availableUntil = selectedAvailableUntil.value;
    if (availableFrom == null || availableUntil == null) {
      Get.snackbar(
        'Error',
        'Please select available times',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade700,
      );
      return;
    }

    // Format dates and times
    final startDateFormatted = DateFormat('dd/MM/yyyy').format(startDate);
    String? repeatUntilFormatted;
    if (selectedRepeatUntil.value != null &&
        selectedRepeat.value.isNotEmpty &&
        selectedRepeat.value != "Don't repeat") {
      repeatUntilFormatted =
          DateFormat('dd/MM/yyyy').format(selectedRepeatUntil.value!);
    }

    // Convert repeat option to API format
    String repeatValue = selectedRepeat.value;
    if (repeatValue == "Don't repeat") {
      repeatValue = "never";
    } else if (repeatValue == "Everyday") {
      repeatValue = "daily";
    } else if (repeatValue == "Every week") {
      repeatValue = "weekly";
    } else if (repeatValue == "Every two week") {
      repeatValue = "two_week";
    }

    // Format times
    final availableFromFormatted = _formatTimeOfDay(availableFrom);
    final availableUntilFormatted = _formatTimeOfDay(availableUntil);

    // Prepare unavailable times
    final unavailableTimesList = unavailableTimes.map((unavailableTime) {
      return {
        'from': _formatTimeOfDay(unavailableTime.from),
        'to': _formatTimeOfDay(unavailableTime.until),
      };
    }).toList();

    // Get current timezone
    final timezone = TimezoneHelper.getCurrentTimezone();

    // Call API
    await callDataService(
      _userApiService.addAvailability(
        startDate: startDateFormatted,
        repeat: repeatValue,
        repeatUntil: repeatUntilFormatted,
        excludeWeekends: excludeWeekends.value,
        excludePublicHolidays: excludePublicHolidays.value,
        availableFrom: availableFromFormatted,
        availableUntil: availableUntilFormatted,
        unavailableTimes: unavailableTimesList,
        timezone: timezone,
        replaceExisting: replaceExisting,
        isConfirmed: isConfirmed,
      ),
      showLoader: true,
      onSuccess: (ApiResponse<dynamic> response) {
        if (response.success) {
          // Analytics: Log professional availability created
          

          // Refresh calendar data if CalendarController is available
          _refreshCalendarData();

          // Show success dialog
          showResponseDialog(
            message: response.message ?? 'Availability added successfully',
            title: 'Success',
            isError: false,
            showButton: false,
            onOkPressed: () {
              // Navigate back after dialog is dismissed
              Get.back();
            },
          );
        } else {
          // Check if this is the confirmation error (status code 400 with specific message)
          final errorMessage = response.errorMessage;
          final isConfirmationError = response.statusCode == 400 &&
              errorMessage.toLowerCase().contains('confirm') &&
              errorMessage.toLowerCase().contains('delete') &&
              errorMessage.toLowerCase().contains('existing availability');

          if (isConfirmationError && !replaceExisting) {
            // Show confirmation dialog
            showConfirmationDialog(
              title: 'Confirm Action',
              message: errorMessage,
              yesText: 'Yes, delete',
              noText: 'No, go back',
              onYesPressed: () {
                // Retry API call with is_confirmed=true
                onAddAvailability(isConfirmed: true);
              },
              onNoPressed: () {
                dispose();
              },
            );
          } else {
            // Show regular error dialog
            showResponseDialog(
              title: 'Error',
              message: errorMessage,
              isError: true,
              showButton: true,
            );
          }
        }
      },
      onError: (error, stack) {
        // Show error dialog for unexpected errors
        showResponseDialog(
          title: 'Error',
          message: 'Failed to add availability. Please try again.',
          isError: true,
          showButton: true,
        );
      },
    );
  }

  String? validateDate(String? value) {
    // Hide error if field has value (whether touched or not)
    if (value != null && value.isNotEmpty) {
      return null;
    }
    // Only show error if validation has been triggered
    if (!hasValidated.value) {
      return null;
    }
    return 'Please select a date';
  }

  String? validateRepeat(String? value) {
    // Hide error if field has value (whether touched or not)
    if (value != null && value.isNotEmpty) {
      return null;
    }
    // Only show error if validation has been triggered
    if (!hasValidated.value) {
      return null;
    }
    return 'Please select a repeat option';
  }

  String? validateRepeatUntil(String? value) {
    // Hide error if field has value (whether touched or not)
    if (value != null && value.isNotEmpty) {
      return null;
    }
    // Only show error if validation has been triggered
    if (!hasValidated.value) {
      return null;
    }
    if (selectedRepeat.value.isNotEmpty &&
        selectedRepeat.value != "Don't repeat") {
      return 'Please select repeat until date';
    }
    return null;
  }

  String? validateAvailableFrom(String? value) {
    // Hide error if field has value (whether touched or not)
    if (value != null && value.isNotEmpty) {
      return null;
    }
    // Only show error if validation has been triggered
    if (!hasValidated.value) {
      return null;
    }
    return 'Please select a time';
  }

  String? validateAvailableUntil(String? value) {
    // Hide error if field has value (whether touched or not)
    if (value != null && value.isNotEmpty) {
      // Still validate time comparison
      if (selectedAvailableFrom.value != null &&
          selectedAvailableUntil.value != null) {
        final fromMinutes = selectedAvailableFrom.value!.hour * 60 +
            selectedAvailableFrom.value!.minute;
        final untilMinutes = selectedAvailableUntil.value!.hour * 60 +
            selectedAvailableUntil.value!.minute;
        if (untilMinutes <= fromMinutes) {
          return 'Until must be after from';
        }
      }
      return null;
    }
    // Only show error if validation has been triggered
    if (!hasValidated.value) {
      return null;
    }
    return 'Please select a time';
  }

  String? validateUnavailableFrom(String? value) {
    // Hide error if field has value (whether touched or not)
    if (value != null &&
        value.isNotEmpty &&
        selectedUnavailableFrom.value != null) {
      // Check if available time is set first
      if (selectedAvailableFrom.value == null ||
          selectedAvailableUntil.value == null) {
        return 'Set available time first';
      }

      final unavailableFromMinutes = selectedUnavailableFrom.value!.hour * 60 +
          selectedUnavailableFrom.value!.minute;
      final availableFromMinutes = selectedAvailableFrom.value!.hour * 60 +
          selectedAvailableFrom.value!.minute;
      final availableUntilMinutes = selectedAvailableUntil.value!.hour * 60 +
          selectedAvailableUntil.value!.minute;

      // Check if unavailable from time is within available time range
      if (unavailableFromMinutes < availableFromMinutes ||
          unavailableFromMinutes >= availableUntilMinutes) {
        return 'Must be within available time range';
      }

      // If unavailable until is also set, validate the range
      if (selectedUnavailableUntil.value != null) {
        final unavailableUntilMinutes =
            selectedUnavailableUntil.value!.hour * 60 +
                selectedUnavailableUntil.value!.minute;
        if (unavailableUntilMinutes > availableUntilMinutes) {
          return 'Must be within available time range';
        }
      }

      return null;
    }
    // Only show error if validation has been triggered
    if (!hasValidatedUnavailableTime.value) {
      return null;
    }
    return 'Please select a time';
  }

  String? validateUnavailableUntil(String? value) {
    // Hide error if field has value (whether touched or not)
    if (value != null &&
        value.isNotEmpty &&
        selectedUnavailableUntil.value != null) {
      // Check if available time is set first
      if (selectedAvailableFrom.value == null ||
          selectedAvailableUntil.value == null) {
        return 'Set available time first';
      }

      // Validate time comparison (until must be after from)
      if (selectedUnavailableFrom.value != null &&
          selectedUnavailableUntil.value != null) {
        final fromMinutes = selectedUnavailableFrom.value!.hour * 60 +
            selectedUnavailableFrom.value!.minute;
        final untilMinutes = selectedUnavailableUntil.value!.hour * 60 +
            selectedUnavailableUntil.value!.minute;
        if (untilMinutes <= fromMinutes) {
          return 'Until must be after from';
        }

        final availableFromMinutes = selectedAvailableFrom.value!.hour * 60 +
            selectedAvailableFrom.value!.minute;
        final availableUntilMinutes = selectedAvailableUntil.value!.hour * 60 +
            selectedAvailableUntil.value!.minute;

        // Check if unavailable time range is within available time range
        if (fromMinutes < availableFromMinutes ||
            untilMinutes > availableUntilMinutes) {
          return 'Must be within available time range';
        }
      }
      return null;
    }
    // Only show error if validation has been triggered
    if (!hasValidatedUnavailableTime.value) {
      return null;
    }
    return 'Please select a time';
  }
}
