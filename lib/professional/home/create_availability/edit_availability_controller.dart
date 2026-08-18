import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../api/api_response.dart';
import '../../../api/user_api_service.dart';
import '../../../common/base_controller.dart';
import '../../../theme/colors.dart';
import '../../../theme/fonts.dart';
import '../../../theme/font_sizes.dart';
import '../../../theme/hight_width_sizes.dart';
import '../../../utils/timezone_helper.dart';
import '../../../widgets/response_dialog.dart';
import '../calendar_controller.dart';
import '../../../services/analytics_service.dart';

class UnavailableTime {
  final TimeOfDay from;
  final TimeOfDay until;

  UnavailableTime({required this.from, required this.until});
}

class EditAvailabilityController extends BaseController {
  EditAvailabilityController([UserApiService? userApiService])
      : _userApiService = userApiService ??
            (Get.isRegistered<UserApiService>()
                ? Get.find<UserApiService>()
                : null);

  final UserApiService? _userApiService;

  late final GlobalKey<FormState> formKey;
  late final GlobalKey<FormState> unavailableTimeFormKey;

  // Availability ID
  late String availabilityId;

  @override
  void onInit() {
    super.onInit();
    AnalyticsService.instance.logScreenView(
      screenName: 'ProfessionalEditAvailabilityScreen',
      screenClass: 'EditAvailabilityView',
      pageCategory: 'calendar',
      elementLocation: 'view',
    );
    formKey = GlobalKey<FormState>();
    unavailableTimeFormKey = GlobalKey<FormState>();

    // Get arguments - AvailabilityItem and raw availability data
    final args = Get.arguments;
    if (args is Map) {
      final availability = args['availability'] as AvailabilityItem?;
      final rawAvailability = args['rawAvailability'] as Map<String, dynamic>?;

      if (availability != null) {
        availabilityId = availability.id;

        // Prefer raw availability data (24-hour format) if available
        if (rawAvailability != null) {
          // Parse available_from and available_until from raw data (24-hour format)
          final availableFrom =
              rawAvailability['available_from']?.toString() ?? '';
          final availableUntil =
              rawAvailability['available_until']?.toString() ?? '';

          if (availableFrom.isNotEmpty) {
            final fromTime = _parseTimeString(availableFrom);
            if (fromTime != null) {
              selectedAvailableFrom.value = fromTime;
              availableFromController.text = _formatTimeOfDay2(fromTime);
            }
          }

          if (availableUntil.isNotEmpty) {
            final untilTime = _parseTimeString(availableUntil);
            if (untilTime != null) {
              selectedAvailableUntil.value = untilTime;
              availableUntilController.text = _formatTimeOfDay2(untilTime);
            }
          }

          // Parse unavailable_times from raw data (24-hour format)
          final unavailableTimesList = rawAvailability['unavailable_times'];
          if (unavailableTimesList is List) {
            for (final unavailableTime in unavailableTimesList) {
              if (unavailableTime is Map<String, dynamic>) {
                final from = unavailableTime['from']?.toString() ?? '';
                final to = unavailableTime['to']?.toString() ?? '';
                if (from.isNotEmpty && to.isNotEmpty) {
                  final fromTime = _parseTimeString(from);
                  final untilTime = _parseTimeString(to);
                  if (fromTime != null && untilTime != null) {
                    unavailableTimes.add(UnavailableTime(
                      from: fromTime,
                      until: untilTime,
                    ));
                  }
                }
              }
            }
          }
        } else {
          // Fallback to parsing formatted strings (12-hour format with AM/PM)
          // Parse available from time (format: "9:00 AM - 5:00 PM")
          final availableFromStr = availability.availableFrom;
          if (availableFromStr.isNotEmpty) {
            final parts = availableFromStr.split(' - ');
            if (parts.length == 2) {
              final fromTime = _parseTimeString(parts[0].trim());
              final untilTime = _parseTimeString(parts[1].trim());
              if (fromTime != null) {
                selectedAvailableFrom.value = fromTime;
                availableFromController.text = _formatTimeOfDay2(fromTime);
              }
              if (untilTime != null) {
                selectedAvailableUntil.value = untilTime;
                availableUntilController.text = _formatTimeOfDay2(untilTime);
              }
            }
          }

          // Parse break time (unavailable times) from list
          final breakTimesList = availability.breakTimes;
          if (breakTimesList.isNotEmpty) {
            for (final breakTime in breakTimesList) {
              final parts = breakTime.split(' - ');
              if (parts.length == 2) {
                final fromTime = _parseTimeString(parts[0].trim());
                final untilTime = _parseTimeString(parts[1].trim());
                if (fromTime != null && untilTime != null) {
                  unavailableTimes.add(UnavailableTime(
                    from: fromTime,
                    until: untilTime,
                  ));
                }
              }
            }
          }
        }

        // Set date from selectedDate if provided
        if (args['selectedDate'] is DateTime) {
          final date = args['selectedDate'] as DateTime;
          selectedDate.value = date;
          dateController.text = _formatDate(date);
        }
      }
    }
  }

  // Date controllers
  final dateController = TextEditingController();
  final selectedDate = Rxn<DateTime>();

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
  final hasValidatedUnavailableTime = false.obs;

  @override
  void onClose() {
    dateController.dispose();
    availableFromController.dispose();
    availableUntilController.dispose();
    unavailableFromController.dispose();
    unavailableUntilController.dispose();
    super.onClose();
  }

  Future<void> pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = selectedDate.value ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      selectedDate.value = picked;
      dateController.text = _formatDate(picked);
      formKey.currentState?.validate();
    }
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
      formKey.currentState?.validate();
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
      formKey.currentState?.validate();
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

    // Check if the new unavailable time overlaps with existing ones
    final overlappingTime = _checkOverlapWithExisting(from, until);
    if (overlappingTime != null) {
      // Show dialog for overlapping time
      _showOverlapDialog(overlappingTime);
      return;
    }

    unavailableTimes.add(UnavailableTime(from: from, until: until));
    unavailableFromController.clear();
    unavailableUntilController.clear();
    selectedUnavailableFrom.value = null;
    selectedUnavailableUntil.value = null;
    // Reset validation flag for next unavailable time entry
    hasValidatedUnavailableTime.value = false;
  }

  /// Check if the new unavailable time overlaps with any existing unavailable time
  /// Returns the overlapping time if found, null otherwise
  UnavailableTime? _checkOverlapWithExisting(
      TimeOfDay newFrom, TimeOfDay newUntil) {
    final newFromMinutes = newFrom.hour * 60 + newFrom.minute;
    final newUntilMinutes = newUntil.hour * 60 + newUntil.minute;

    for (final existingTime in unavailableTimes) {
      final existingFromMinutes =
          existingTime.from.hour * 60 + existingTime.from.minute;
      final existingUntilMinutes =
          existingTime.until.hour * 60 + existingTime.until.minute;

      // Check for overlap: new time starts before existing ends AND new time ends after existing starts
      if (newFromMinutes < existingUntilMinutes &&
          newUntilMinutes > existingFromMinutes) {
        return existingTime;
      }
    }

    return null;
  }

  /// Show dialog when unavailable time overlaps with existing one
  void _showOverlapDialog(UnavailableTime overlappingTime) {
    final overlappingFrom = _formatTimeOfDay2(overlappingTime.from);
    final overlappingUntil = _formatTimeOfDay2(overlappingTime.until);

    Get.dialog(
      PopScope(
        canPop: true,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: HightWidthSizes.setValue_16,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(HightWidthSizes.setValue_10),
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: HightWidthSizes.setValue_10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: EdgeInsets.all(HightWidthSizes.setValue_24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title
                Text(
                  'Unavailable Time Already Added',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.rubikMedium,
                    fontWeight: FontWeight.w500,
                    fontSize: FontSizes.setFontValue_20,
                    color: AppColor.color_2D3648,
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_16),

                // Message
                Text(
                  'This unavailable time already exists:\n$overlappingFrom - $overlappingUntil',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.rubikRegular,
                    fontWeight: FontWeight.w400,
                    fontSize: FontSizes.setFontValue_14,
                    color: AppColor.color_2D2D2D,
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_24),

                // OK button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.color_2FC4B2,
                      foregroundColor: AppColor.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        vertical: HightWidthSizes.setValue_14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          HightWidthSizes.setValue_10,
                        ),
                      ),
                    ),
                    child: Text(
                      'OK',
                      style: TextStyle(
                        fontFamily: AppFonts.rubikMedium,
                        fontWeight: FontWeight.w500,
                        fontSize: FontSizes.setFontValue_16,
                        color: AppColor.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void removeUnavailableTime(int index) {
    unavailableTimes.removeAt(index);
  }

  /// Refresh calendar data after editing availability
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

  String? validateDate(String? value) {
    if (selectedDate.value == null) {
      return 'Date is required';
    }
    return null;
  }

  String? validateAvailableFrom(String? value) {
    // Hide error if field has value (whether touched or not)
    if (value != null && value.isNotEmpty) {
      return null;
    }
    // Only show error if validation has been triggered
    // For edit screen, we'll validate on form submit
    return null;
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
    // For edit screen, we'll validate on form submit
    return null;
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

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
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

  TimeOfDay? _parseTimeString(String timeStr) {
    try {
      final trimmed = timeStr.trim();

      // First, try to parse as 24-hour format (HH:mm) - direct from API
      if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(trimmed)) {
        final parts = trimmed.split(':');
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0].trim()) ?? 0;
          final minute = int.tryParse(parts[1].trim()) ?? 0;
          if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
            return TimeOfDay(hour: hour, minute: minute);
          }
        }
      }

      // Otherwise, handle 12-hour format with AM/PM (e.g., "9:00 AM", "10 AM", "1:00 PM", "6 PM")
      final isPM = trimmed.toUpperCase().contains('PM');
      final isAM = trimmed.toUpperCase().contains('AM');

      // Remove AM/PM
      final timeOnly = trimmed.replaceAll(RegExp(r'[AaPp][Mm]'), '').trim();

      final parts = timeOnly.split(':');
      int hour = 0;
      int minute = 0;

      if (parts.length == 2) {
        hour = int.tryParse(parts[0].trim()) ?? 0;
        minute = int.tryParse(parts[1].trim()) ?? 0;
      } else if (parts.length == 1) {
        hour = int.tryParse(parts[0].trim()) ?? 0;
        minute = 0;
      } else {
        return null;
      }

      // Convert to 24-hour format
      if (isPM && hour != 12) {
        hour += 12;
      } else if (isAM && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  String _formatTimeForApi(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> onUpdateAvailability() async {
    // Validate all fields
    if (selectedDate.value == null) {
      Get.snackbar(
        'Error',
        'Please select a date',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade700,
      );
      return;
    }

    if (selectedAvailableFrom.value == null) {
      Get.snackbar(
        'Error',
        'Please select available from time',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade700,
      );
      return;
    }

    if (selectedAvailableUntil.value == null) {
      Get.snackbar(
        'Error',
        'Please select available until time',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade700,
      );
      return;
    }

    // Validate time comparison
    if (selectedAvailableFrom.value != null &&
        selectedAvailableUntil.value != null) {
      final from = selectedAvailableFrom.value!;
      final until = selectedAvailableUntil.value!;
      final fromMinutes = from.hour * 60 + from.minute;
      final untilMinutes = until.hour * 60 + until.minute;
      if (untilMinutes <= fromMinutes) {
        Get.snackbar(
          'Error',
          'Until time must be after from time',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade700,
        );
        return;
      }
    }

    final apiService = _userApiService;
    if (apiService == null) {
      Get.snackbar(
        'Error',
        'API service not available',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade700,
      );
      return;
    }

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

    // Prepare unavailable times
    final unavailableTimesList = unavailableTimes
        .map((ut) => {
              'from': _formatTimeForApi(ut.from),
              'to': _formatTimeForApi(ut.until),
            })
        .toList();

    // Get timezone
    final timezone = await TimezoneHelper.getCurrentTimezone();

    // Format date as yyyy-MM-dd
    final formattedDate = DateFormat('yyyy-MM-dd').format(startDate);

    // Format times for API (HH:mm format)
    final formattedAvailableFrom = _formatTimeForApi(availableFrom);
    final formattedAvailableUntil = _formatTimeForApi(availableUntil);

    // Call API to update availability
    callDataService(
      apiService.updateAvailability(
        id: availabilityId,
        startDate: formattedDate,
        availableFrom: formattedAvailableFrom,
        availableUntil: formattedAvailableUntil,
        unavailableTimes: unavailableTimesList,
        timezone: timezone,
      ),
      showLoader: true,
      onSuccess: (ApiResponse<dynamic> response) {
        if (response.success) {
          // Show success dialog
          final successMessage =
              response.message ?? 'Availability updated successfully';
          showResponseDialog(
            message: successMessage,
            title: 'Success',
            isError: false,
            showButton: false,
            onOkPressed: () {
              // Refresh calendar data if CalendarController is available
              _refreshCalendarData();

              // Navigate back
              Get.back();
            },
          );
        } else {
          // Show error dialog
          showResponseDialog(
            message: response.message ?? 'Failed to update availability',
            title: 'Error',
            isError: true,
            showButton: true,
          );
        }
      },
      onError: (error, stack) {
        // Show error dialog
        showResponseDialog(
          message: 'Failed to update availability. Please try again.',
          title: 'Error',
          isError: true,
          showButton: true,
        );
      },
    );
  }
}
