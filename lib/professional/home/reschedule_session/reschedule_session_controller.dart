import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../api/api_response.dart';
import '../../../api/user_api_service.dart';
import '../../../common/base_controller.dart';
import '../../../utils/timezone_helper.dart';
import '../../../widgets/response_dialog.dart';
import '../home_controller.dart';

class RescheduleSessionController extends BaseController {
  RescheduleSessionController();

  // Get UserApiService if available
  UserApiService? get _userApiService =>
      Get.isRegistered<UserApiService>() ? Get.find<UserApiService>() : null;

  late final GlobalKey<FormState> formKey;

  // Get session data from arguments
  SessionData? get session => Get.arguments as SessionData?;

  // Controllers for form fields
  final dateController = TextEditingController();
  final fromTimeController = TextEditingController();
  final untilTimeController = TextEditingController();

  // Selected values
  final selectedDate = Rxn<DateTime>();
  final selectedFromTime = Rxn<TimeOfDay>();
  final selectedUntilTime = Rxn<TimeOfDay>();

  // Get duration from session (in minutes)
  int? get durationMinutes => session?.durationMinutes;

  @override
  void onInit() {
    super.onInit();
    // Initialize formKey to ensure a new key is created each time
    formKey = GlobalKey<FormState>();
    _initializeFields();
  }

  void _initializeFields() {
    if (session != null) {
      // Parse the date from session.dateLabel (format: "12 July 2025")
      try {
        final parsedDate = DateFormat('dd MMMM yyyy').parse(session!.dateLabel);
        selectedDate.value = parsedDate;
        dateController.text = DateFormat('dd/MM/yyyy').format(parsedDate);
      } catch (e) {
        // If parsing fails, use current date
        selectedDate.value = DateTime.now();
        dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
      }

      // Parse time range (format: "6:00 AM - 6:45 AM" or "06:00 - 6:45 AM")
      try {
        final timeParts = session!.timeRange.split(' - ');
        if (timeParts.length >= 2) {
          final fromTimeStr = timeParts[0].trim();
          final untilTimeStr = timeParts[1].trim();

          // Parse from time (handle both 12-hour and 24-hour format)
          final fromMatch =
              RegExp(r'(\d+):(\d+)\s*(AM|PM)?', caseSensitive: false)
                  .firstMatch(fromTimeStr);
          if (fromMatch != null) {
            var hour = int.parse(fromMatch.group(1)!);
            final minute = int.parse(fromMatch.group(2)!);
            final period = fromMatch.group(3)?.toUpperCase();

            // Convert to 24-hour format
            if (period != null) {
              if (period == 'PM' && hour != 12) {
                hour += 12;
              } else if (period == 'AM' && hour == 12) {
                hour = 0;
              }
            }
            // If no period, assume 24-hour format (already correct)

            selectedFromTime.value = TimeOfDay(hour: hour, minute: minute);
            fromTimeController.text = _formatTimeOfDay(selectedFromTime.value!);
          }

          // Parse until time (handle AM/PM)
          final untilMatch =
              RegExp(r'(\d+):(\d+)\s*(AM|PM)', caseSensitive: false)
                  .firstMatch(untilTimeStr);
          if (untilMatch != null) {
            var hour = int.parse(untilMatch.group(1)!);
            final minute = int.parse(untilMatch.group(2)!);
            final period = untilMatch.group(3)!.toUpperCase();

            if (period == 'PM' && hour != 12) {
              hour += 12;
            } else if (period == 'AM' && hour == 12) {
              hour = 0;
            }

            selectedUntilTime.value = TimeOfDay(hour: hour, minute: minute);
            untilTimeController.text =
                _formatTimeOfDay(selectedUntilTime.value!);
          }

          // If duration is available, recalculate until time based on from time and duration
          if (durationMinutes != null &&
              durationMinutes! > 0 &&
              selectedFromTime.value != null) {
            _calculateUntilTime();
          }
        }
      } catch (e) {
        // Default times if parsing fails
        selectedFromTime.value = const TimeOfDay(hour: 14, minute: 0);
        fromTimeController.text = '2:00 PM';

        // Calculate until time based on duration if available
        if (durationMinutes != null && durationMinutes! > 0) {
          _calculateUntilTime();
        } else {
          selectedUntilTime.value = const TimeOfDay(hour: 14, minute: 45);
          untilTimeController.text = '2:45 PM';
        }
      }
    } else {
      // Default values if no session provided
      selectedDate.value = DateTime.now();
      dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
      selectedFromTime.value = const TimeOfDay(hour: 14, minute: 0);
      fromTimeController.text = '2:00 PM';

      // Calculate until time based on duration if available
      if (durationMinutes != null && durationMinutes! > 0) {
        _calculateUntilTime();
      } else {
        selectedUntilTime.value = const TimeOfDay(hour: 14, minute: 45);
        untilTimeController.text = '2:45 PM';
      }
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour12 = time.hour == 0
        ? 12
        : time.hour > 12
            ? time.hour - 12
            : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '$hour12:$minute $period';
  }

  @override
  void onClose() {
    dateController.dispose();
    fromTimeController.dispose();
    untilTimeController.dispose();
    super.onClose();
  }

  Future<void> pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = selectedDate.value ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      selectedDate.value = picked;
      dateController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<void> pickFromTime(BuildContext context) async {
    final initial =
        selectedFromTime.value ?? const TimeOfDay(hour: 14, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null) {
      selectedFromTime.value = picked;
      fromTimeController.text = _formatTimeOfDay(picked);

      // Auto-calculate until time based on duration
      if (durationMinutes != null && durationMinutes! > 0) {
        _calculateUntilTime();
      }

      // Re-validate until time field if it's already filled
      if (untilTimeController.text.isNotEmpty) {
        formKey.currentState?.validate();
      }
    }
  }

  /// Calculate until time based on from time and duration
  void _calculateUntilTime() {
    if (selectedFromTime.value == null ||
        durationMinutes == null ||
        durationMinutes! <= 0) {
      return;
    }

    final fromTime = selectedFromTime.value!;
    final fromTotalMinutes = fromTime.hour * 60 + fromTime.minute;
    final untilTotalMinutes = fromTotalMinutes + durationMinutes!;

    // Handle overflow to next day
    final untilHour = (untilTotalMinutes ~/ 60) % 24;
    final untilMinute = untilTotalMinutes % 60;

    selectedUntilTime.value = TimeOfDay(hour: untilHour, minute: untilMinute);
    untilTimeController.text = _formatTimeOfDay(selectedUntilTime.value!);
  }

  // Until time is auto-calculated, so no picker needed
  // This method is kept for compatibility but shouldn't be called
  Future<void> pickUntilTime(BuildContext context) async {
    // Until time is auto-calculated based on duration
    // No time picker should be shown
  }

  void onReschedule() async {
    if (formKey.currentState?.validate() ?? false) {
      if (selectedDate.value == null) {
        Get.snackbar(
          'Validation Error',
          'Please select a date',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade700,
        );
        return;
      }
      if (selectedFromTime.value == null) {
        Get.snackbar(
          'Validation Error',
          'Please select a start time',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade700,
        );
        return;
      }
      if (selectedUntilTime.value == null) {
        Get.snackbar(
          'Validation Error',
          'Please select an end time',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade700,
        );
        return;
      }

      // Validate that until time is after from time
      // This should always be true if duration is set correctly, but check anyway
      final fromMinutes =
          selectedFromTime.value!.hour * 60 + selectedFromTime.value!.minute;
      final untilMinutes =
          selectedUntilTime.value!.hour * 60 + selectedUntilTime.value!.minute;

      if (untilMinutes <= fromMinutes) {
        Get.snackbar(
          'Validation Error',
          'End time must be after start time',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade700,
        );
        return;
      }

      // Validate that duration matches the time difference
      if (durationMinutes != null && durationMinutes! > 0) {
        final calculatedDuration = untilMinutes - fromMinutes;
        if (calculatedDuration != durationMinutes) {
          // Recalculate to ensure it matches duration
          _calculateUntilTime();
          // Re-get the updated until time
          final updatedUntilMinutes = selectedUntilTime.value!.hour * 60 +
              selectedUntilTime.value!.minute;
          if (updatedUntilMinutes <= fromMinutes) {
            Get.snackbar(
              'Validation Error',
              'Invalid time range',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red.shade50,
              colorText: Colors.red.shade700,
            );
            return;
          }
        }
      }

      // Check if session and API service are available
      if (session == null) {
        Get.snackbar(
          'Error',
          'Session information not available',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade700,
        );
        return;
      }

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

      // Format date as "dd/MM/yyyy"
      final formattedDate =
          DateFormat('dd/MM/yyyy').format(selectedDate.value!);

      // Format times as "HH:mm" (24-hour format)
      final formattedFromTime =
          '${selectedFromTime.value!.hour.toString().padLeft(2, '0')}:${selectedFromTime.value!.minute.toString().padLeft(2, '0')}';
      final formattedToTime =
          '${selectedUntilTime.value!.hour.toString().padLeft(2, '0')}:${selectedUntilTime.value!.minute.toString().padLeft(2, '0')}';

      // Get timezone
      final timezone = TimezoneHelper.getCurrentTimezone();

      // Call API to reschedule session
      await callDataService<ApiResponse<dynamic>>(
        _userApiService!.rescheduleBooking(
          bookingId: session!.id,
          date: formattedDate,
          fromTime: formattedFromTime,
          toTime: formattedToTime,
          timezone: timezone,
        ),
        showLoader: true,
        onSuccess: (response) {
          if (response.success) {
            // Show success dialog
            showResponseDialog(
              message: response.message ?? 'Booking rescheduled successfully',
              isError: false,
              showButton: false,
              title: 'Success',
              onOkPressed: () {
                // Reload bookings list in HomeController
                if (Get.isRegistered<HomeController>()) {
                  final homeController = Get.find<HomeController>();
                  homeController.loadBookingsList();
                }
                Get.back();
              },
            );
          } else {
            // Show error dialog
            showResponseDialog(
              message: response.errorMessage.isNotEmpty
                  ? response.errorMessage
                  : 'Failed to reschedule session',
              title: 'Error',
              showButton: true,
              isError: true,
            );
          }
        },
        onError: (error, stack) {
          // Show error dialog
          showResponseDialog(
            message: 'Failed to reschedule session. Please try again.',
            isError: true,
            title: 'Error',
            showButton: true,
          );
        },
      );
    }
  }

  String? validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a date';
    }
    return null;
  }

  String? validateTime(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a time';
    }
    return null;
  }

  String? validateUntilTime(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a time';
    }
    if (selectedFromTime.value != null && selectedUntilTime.value != null) {
      final fromMinutes =
          selectedFromTime.value!.hour * 60 + selectedFromTime.value!.minute;
      final untilMinutes =
          selectedUntilTime.value!.hour * 60 + selectedUntilTime.value!.minute;
      if (untilMinutes <= fromMinutes) {
        return 'End time must be after start time';
      }
    }
    return null;
  }
}
