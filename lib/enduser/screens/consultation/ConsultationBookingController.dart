import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:verithrive_dev/enduser/routes/app_routes.dart';
import 'package:verithrive_dev/enduser/screens/cart/CartBinding.dart';
import 'package:verithrive_dev/enduser/screens/cart/CartScreen.dart';
import '../../core/base/base_controller.dart';
import '../../data/repository/project_repository.dart';
import '../../network/exceptions/not_found_exception.dart';
import '../../utils/api_services.dart';

class ConsultationBookingController extends BaseController {
  final ProjectRepository _repository =
      Get.find(tag: (ProjectRepository).toString());

  // Received parameters
  String? professionalId;
  int? durationMinutes; // Duration from previous screen
  String? serviceName;
  double? servicePrice;
  String? serviceLocation;
  String? serviceFormatId; // service_format_id for summary screen
  String? professionalServiceFormatId; // _id for create-booking API
  String? bookingId; // booking_id for edit mode
  bool isEditMode = false; // Flag to indicate edit modee
  String category = '';
  String itemVariant = '';
  String itemBrand = '';

  // Observable variables
  var selectedMonth = DateTime.now().obs;
  var selectedDate = Rxn<DateTime>(); // Will be set by service format date
  var selectedTimeSlot = Rxn<String>();
  var isLoadingAvailability = false.obs;
  var isInitializingAvailability =
      false.obs; // Flag to prevent multiple initial calls

  // Dynamic time slots list from API
  var timeSlots = <String>[].obs;

  // Service format dates from API (legacy / fallback)
  var serviceFormatDates = <String>[].obs;

  // Full availability schedule from service-format-availability API (drives green/red dots)
  final rawAvailabilities = <Map<String, dynamic>>[].obs;

  // Dates confirmed available/unavailable from per-date API responses
  final confirmedAvailableDates = <String>{}.obs;
  final confirmedUnavailableDates = <String>{}.obs;

  // Availability data - true means available, false means unavailable
  final RxMap<String, bool> slotAvailability = <String, bool>{}.obs;

  // Past time slots (disabled) - only for today's date
  final RxMap<String, bool> pastTimeSlots = <String, bool>{}.obs;

  // API response data
  String? availableFrom;
  String? availableUntil;
  List<Map<String, dynamic>> unavailableTimes = [];
  List<Map<String, dynamic>> professionalServiceFormats = [];

  // API message for display
  var apiMessage = ''.obs;

  // Prevent auto-select from overriding the user's chosen date
  bool _hasUserSelectedDate = false;
  bool _hasCompletedInitialAutoSelect = false;

  // Date string (dd/MM/yyyy) for the in-flight availability request
  String? _pendingAvailabilityDate;

  @override
  void onInit() {
    try {
      super.onInit();
      _receiveArguments();

      // Set selectedDate to today if not provided in arguments
      if (selectedDate.value == null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        selectedDate.value = today;
        selectedMonth.value = DateTime(now.year, now.month, 1);
        print(
            'Set initial selected date to today: ${DateFormat('dd/MM/yyyy').format(today)}');
      } else {
        // Ensure selectedMonth matches the selectedDate month
        selectedMonth.value =
            DateTime(selectedDate.value!.year, selectedDate.value!.month, 1);
      }

      // Clear previous selection
      selectedTimeSlot.value = null;
      // Load availability - this will trigger service format date selection
      loadAvailability();
    } catch (e, stackTrace) {
      print('CRASH PREVENTED in onInit: $e');
      print('Stack trace: $stackTrace');
      // Set safe defaults - set both month and today's date
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      selectedDate.value = today;
      selectedMonth.value = DateTime(now.year, now.month, 1);
    }
  }

  void _receiveArguments() {
    try {
      final arguments = Get.arguments;
      print('========================================');
      print('ConsultationBookingController - Received Arguments:');
      print('========================================');

      if (arguments != null && arguments is Map<String, dynamic>) {
        try {
          professionalId = arguments['professional_id']?.toString();
        } catch (e) {
          print('Error parsing professional_id: $e');
        }

        try {
          if (arguments['duration_minutes'] != null) {
            if (arguments['duration_minutes'] is int) {
              durationMinutes = arguments['duration_minutes'] as int;
            } else if (arguments['duration_minutes'] is num) {
              durationMinutes = (arguments['duration_minutes'] as num).toInt();
            }
          }
        } catch (e) {
          print('Error parsing duration_minutes: $e');
        }

        try {
          serviceName = arguments['service_name']?.toString();
        } catch (e) {
          print('Error parsing service_name: $e');
        }

        try {
          if (arguments['price'] != null) {
            if (arguments['price'] is double) {
              servicePrice = arguments['price'] as double;
            } else if (arguments['price'] is num) {
              servicePrice = (arguments['price'] as num).toDouble();
            }
          }
        } catch (e) {
          print('Error parsing price: $e');
        }

        try {
          serviceLocation = arguments['location']?.toString();
        } catch (e) {
          print('Error parsing location: $e');
        }

        try {
          serviceFormatId = arguments['service_format_id']?.toString();
        } catch (e) {
          print('Error parsing service_format_id: $e');
        }

        try {
          professionalServiceFormatId =
              arguments['professional_service_format_id']?.toString();
        } catch (e) {
          print('Error parsing professional_service_format_id: $e');
        }

        try {
          bookingId = arguments['booking_id']?.toString();
        } catch (e) {
          print('Error parsing booking_id: $e');
        }

        try {
          isEditMode = arguments['is_edit_mode'] == true;
        } catch (e) {
          print('Error parsing is_edit_mode: $e');
          isEditMode = false;
        }

        try {
          if (arguments['category'] != null) {
            category = arguments['category'].toString();
          }
        } catch (e) {
          print('Error parsing category: $e');
        }

        try {
          if (arguments['item_variant'] != null) {
            itemVariant = arguments['item_variant'].toString();
          }
        } catch (e) {
          print('Error parsing item_variant: $e');
        }

        try {
          if (arguments['item_brand'] != null) {
            itemBrand = arguments['item_brand'].toString();
          }
        } catch (e) {
          print('Error parsing item_brand: $e');
        }

        // If edit mode and selected_date is provided, use it
        if (arguments['selected_date'] != null) {
          print("RAJNIKANT --->" + arguments['selected_date'].toString());
          try {
            DateTime? selectedDateArg;
            if (arguments['selected_date'] is DateTime) {
              selectedDateArg = arguments['selected_date'] as DateTime;
            } else if (arguments['selected_date'] is String) {
              // Try to parse string date
              selectedDateArg =
                  DateTime.tryParse(arguments['selected_date'] as String);
            }

            if (selectedDateArg != null) {
              selectedDate.value = DateTime(selectedDateArg.year,
                  selectedDateArg.month, selectedDateArg.day);
              selectedMonth.value =
                  DateTime(selectedDateArg.year, selectedDateArg.month, 1);
              // Date came from navigation args — treat as intentional selection
              _hasUserSelectedDate = true;
              _hasCompletedInitialAutoSelect = true;
            }
          } catch (e) {
            print('Error parsing selected_date: $e');
          }
        }

        print('Professional ID: ${professionalId ?? "null"}');
        print('Duration Minutes: ${durationMinutes ?? "null"}');
        print('Service Name: ${serviceName ?? "null"}');
        print('Service Price: ${servicePrice ?? "null"}');
        print('Service Location: ${serviceLocation ?? "null"}');
        print('Service Format ID (for summary): ${serviceFormatId ?? "null"}');
        print(
            'Professional Service Format ID (_id for create-booking): ${professionalServiceFormatId ?? "null"}');
        print('Booking ID (for edit): ${bookingId ?? "null"}');
        print('Is Edit Mode: $isEditMode');
      } else {
        print('No arguments received or arguments is not a Map');
        print('Arguments type: ${arguments?.runtimeType ?? "null"}');
        print('Arguments value: $arguments');
      }
      print('========================================');
    } catch (e, stackTrace) {
      print('CRASH PREVENTED in _receiveArguments: $e');
      print('Stack trace: $stackTrace');
      // Set defaults to prevent further crashes
      isEditMode = false;
    }
  }

  // Navigate to previous month (only if not current month)
  void previousMonth() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final newMonth = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month - 1,
    );

    // Only allow navigation if not going before current month
    if (newMonth.isAfter(currentMonth) ||
        newMonth.isAtSameMomentAs(currentMonth)) {
      selectedMonth.value = newMonth;
      // Refresh calendar dots for the newly visible month when needed
      if (rawAvailabilities.isEmpty) {
        Future.microtask(() => _prefetchMonthAvailabilityDots());
      }
    }
  }

  // Navigate to next month
  void nextMonth() {
    selectedMonth.value = DateTime(
      selectedMonth.value.year,
      selectedMonth.value.month + 1,
    );
    if (rawAvailabilities.isEmpty) {
      Future.microtask(() => _prefetchMonthAvailabilityDots());
    }
  }

  // Select a specific day
  void selectDay(DateTime day) {
    // Only allow selection of today or future dates
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDayDate = DateTime(day.year, day.month, day.day);

    if (selectedDayDate.isBefore(today)) {
      return; // Don't allow selection of past dates
    }

    // Only call loadAvailability if date actually changed
    if (selectedDate.value == null ||
        !selectedDayDate.isAtSameMomentAs(selectedDate.value!)) {
      _hasUserSelectedDate = true;
      _hasCompletedInitialAutoSelect = true;
      selectedDate.value = selectedDayDate;
      selectedTimeSlot.value = null; // Reset time slot selection
      // Reload availability for selected day
      loadAvailability();
    }
  }

  // Select a time slot
  void selectTimeSlot(String time) {
    try {
      if (time.isEmpty) {
        print('Error: Time slot is empty');
        return;
      }

      if (slotAvailability[time] != true) {
        print('Time slot is not available: $time');
        return;
      }

      selectedTimeSlot.value = time;

      // Parse the selected time slot to get from time
      TimeOfDay? fromTime = _parseTimeSlotString(time);
      if (fromTime == null) {
        print('Error: Could not parse time slot: $time');
        selectedTimeSlot.value = null;
        return;
      }

      // Calculate until time based on duration
      int slotDuration = durationMinutes ?? 30;
      TimeOfDay untilTime = _addMinutes(fromTime, slotDuration);

      // Get service format details - use from arguments first, then from API response
      String finalServiceName = serviceName ?? 'Consultation - in person';
      double finalServicePrice = servicePrice ?? 0.0;
      String finalLocation = serviceLocation ?? '';
      // service_format_id for summary screen
      String finalServiceFormatId = serviceFormatId ?? '';
      // professional_service_format_id (_id) for create-booking/update-booking API
      String finalProfessionalServiceFormatId =
          professionalServiceFormatId ?? '';

      // Always try to extract from API response if available (especially important for edit mode)
      if (professionalServiceFormats.isNotEmpty) {
        Map<String, dynamic>? matchedServiceFormat;

        // Try to match by service_format_name and duration_minutes
        if (serviceName != null && durationMinutes != null) {
          try {
            matchedServiceFormat = professionalServiceFormats.firstWhere(
              (format) {
                String? formatName = format['service_format_name']?.toString();
                int? formatDuration = format['duration_minutes'] is num
                    ? (format['duration_minutes'] as num).toInt()
                    : null;
                return formatName == serviceName &&
                    formatDuration == durationMinutes;
              },
            );
          } catch (e) {
            // No exact match found, try name only
            matchedServiceFormat = null;
          }
        }

        // If no match found, try to match by service_format_name only
        if (matchedServiceFormat == null && serviceName != null) {
          try {
            matchedServiceFormat = professionalServiceFormats.firstWhere(
              (format) =>
                  format['service_format_name']?.toString() == serviceName,
            );
          } catch (e) {
            // No match found
            matchedServiceFormat = null;
          }
        }

        // If still no match, use first available service format
        if (matchedServiceFormat == null &&
            professionalServiceFormats.isNotEmpty) {
          matchedServiceFormat = professionalServiceFormats.first;
        }

        // Use API response if not provided in arguments
        if (matchedServiceFormat != null) {
          try {
            if (serviceName == null) {
              finalServiceName =
                  matchedServiceFormat['service_format_name']?.toString() ??
                      finalServiceName;
            }
          } catch (e) {
            print('Error extracting service_name from matched format: $e');
          }

          try {
            if (servicePrice == null) {
              // Check if it's a bundle (has bundle_price) or regular (has price)
              bool isBundle = matchedServiceFormat['is_bundle'] == true;

              if (isBundle) {
                // For bundles, use bundle_price
                if (matchedServiceFormat['bundle_price'] != null) {
                  if (matchedServiceFormat['bundle_price'] is num) {
                    finalServicePrice =
                        (matchedServiceFormat['bundle_price'] as num)
                            .toDouble();
                  }
                }
              } else {
                // For non-bundles, use price
                if (matchedServiceFormat['price'] != null) {
                  if (matchedServiceFormat['price'] is num) {
                    finalServicePrice =
                        (matchedServiceFormat['price'] as num).toDouble();
                  }
                }
              }
            }
          } catch (e) {
            print('Error extracting price from matched format: $e');
          }

          // Extract service_format_id and _id from API response
          // Always update from matched format if available (overrides arguments)
          try {
            // Note: API response doesn't have service_format_id, only _id
            // Use _id as service_format_id if not provided in arguments
            // Update service_format_id (use _id if service_format_id doesn't exist in response)
            String? extractedServiceFormatId =
                matchedServiceFormat['service_format_id']?.toString();
            if (extractedServiceFormatId == null ||
                extractedServiceFormatId.isEmpty) {
              // Fallback to _id if service_format_id is not available
              extractedServiceFormatId =
                  matchedServiceFormat['_id']?.toString() ??
                      matchedServiceFormat['id']?.toString();
            }
            if (extractedServiceFormatId != null &&
                extractedServiceFormatId.isNotEmpty) {
              //finalServiceFormatId = extractedServiceFormatId;
            }

            // Update professional_service_format_id (_id) - CRITICAL for update-booking API
            String? extractedProfessionalServiceFormatId =
                matchedServiceFormat['_id']?.toString() ??
                    matchedServiceFormat['id']?.toString();
            if (extractedProfessionalServiceFormatId != null &&
                extractedProfessionalServiceFormatId.isNotEmpty) {
              finalProfessionalServiceFormatId =
                  extractedProfessionalServiceFormatId;
            }
          } catch (e) {
            print('Error extracting IDs from matched format: $e');
          }
        }

        // Debug logging for edit mode
        if (isEditMode) {
          print('========================================');
          print('Edit Mode - Service Format Matching:');
          print('serviceName: $serviceName');
          print('durationMinutes: $durationMinutes');
          print(
              'professionalServiceFormats count: ${professionalServiceFormats.length}');
          if (professionalServiceFormats.isNotEmpty) {
            print('Available formats:');
            for (var format in professionalServiceFormats) {
              try {
                String formatName =
                    format['service_format_name']?.toString() ?? 'Unknown';
                int? duration = format['duration_minutes'] is num
                    ? (format['duration_minutes'] as num).toInt()
                    : null;
                String? id =
                    format['_id']?.toString() ?? format['id']?.toString();
                String? serviceFormatId =
                    format['service_format_id']?.toString();
                bool isBundle = format['is_bundle'] == true;
                String priceInfo = isBundle
                    ? 'bundle_price: ${format['bundle_price']}'
                    : 'price: ${format['price']}';
                print(
                    '  - $formatName (duration: $duration, _id: $id, service_format_id: $serviceFormatId, $priceInfo)');
              } catch (e) {
                print('  - Error printing format: $e');
              }
            }
          }
          print('matchedServiceFormat: $matchedServiceFormat');
          print('finalServiceFormatId: $finalServiceFormatId');
          print(
              'finalProfessionalServiceFormatId: $finalProfessionalServiceFormatId');
          print('========================================');
        }
      } else {
        // If professionalServiceFormats is empty, log warning
        if (isEditMode) {
          print(
              'WARNING: professionalServiceFormats is empty! Cannot extract service format IDs.');
          print('This may cause issues when updating the booking.');
        }
      }

      // Final validation for edit mode - ensure professional_service_format_id is present
      if (isEditMode && finalProfessionalServiceFormatId.isEmpty) {
        print(
            'ERROR: professional_service_format_id is still empty after extraction!');
        print('This will cause update-booking API to fail.');
      }

      print('========================================');
      print('ConsultationBookingController - Passing to Cart:');
      print('service_format_id (for summary): $finalServiceFormatId');
      print(
          'professional_service_format_id (_id for create-booking/update-booking): $finalProfessionalServiceFormatId');
      print('booking_id (for edit mode): $bookingId');
      print('is_edit_mode: $isEditMode');
      if (isEditMode && finalProfessionalServiceFormatId.isEmpty) {
        print(
            'WARNING: professional_service_format_id is EMPTY - update-booking API will fail!');
      }
      print('========================================');

      // Automatically navigate to cart screen when time slot is selected
      Future.delayed(Duration(milliseconds: 300), () async {
        try {
          // Get available time slots (only AVAILABLE, not PAST or UNAVAILABLE)
          List<TimeOfDay> availableTimeSlots = [];
          for (String slotString in timeSlots) {
            if (slotAvailability[slotString] == true) {
              TimeOfDay? slotTime = _parseTimeSlotString(slotString);
              if (slotTime != null) {
                availableTimeSlots.add(slotTime);
              }
            }
          }

          // Navigate to cart with pre-filled times and service details
          final result = await Get.to(
            () => CartScreen(),
            binding: CartBinding(),
            arguments: {
              'selected_date': selectedDate.value,
              'from_time': fromTime,
              'until_time': untilTime,
              'service_name': finalServiceName,
              'price': finalServicePrice,
              'location': finalLocation,
              'professional_id': professionalId ?? '',
              'service_format_id': finalServiceFormatId,
              'professional_service_format_id':
                  finalProfessionalServiceFormatId,
              'booking_id': bookingId,
              'is_edit_mode': isEditMode,
              'available_time_slots': availableTimeSlots,
              'slot_duration_minutes': slotDuration,
              'category': category,
              'item_variant': itemVariant,
              'item_brand': itemBrand,
            },
          );
          // Clear selection when returning from cart
          if (result == true || result == null) {
            selectedTimeSlot.value = null;
          }
        } catch (e) {
          print('CRASH PREVENTED in selectTimeSlot navigation: $e');
          selectedTimeSlot.value = null;
        }
      });
    } catch (e, stackTrace) {
      print('CRASH PREVENTED in selectTimeSlot: $e');
      print('Stack trace: $stackTrace');
      selectedTimeSlot.value = null;
    }
  }

  // Parse time slot string like "2:30 PM" to TimeOfDay
  TimeOfDay? _parseTimeSlotString(String timeSlot) {
    try {
      if (timeSlot.isEmpty) return null;

      // Remove spaces and split by space to get time and period
      String cleaned = timeSlot.trim();
      List<String> parts = cleaned.split(' ');

      if (parts.length < 2) return null;

      String timePart = parts[0]; // "2:30" or "2"
      String period = parts[1].toUpperCase(); // "AM" or "PM"

      if (period != 'AM' && period != 'PM') return null;

      // Split time part by colon
      List<String> timeComponents = timePart.split(':');
      if (timeComponents.isEmpty) return null;

      int? hour = int.tryParse(timeComponents[0].trim());
      int minute = 0;

      if (hour == null) return null;

      if (timeComponents.length > 1) {
        minute = int.tryParse(timeComponents[1].trim()) ?? 0;
      }

      // Validate hour and minute
      if (hour < 1 || hour > 12 || minute < 0 || minute >= 60) {
        return null;
      }

      // Convert to 24-hour format
      if (period == 'PM' && hour != 12) {
        hour += 12;
      } else if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      print('Error parsing time slot: $timeSlot, error: $e');
      return null;
    }
  }

  // Check if a time slot is available
  bool isSlotAvailable(String time) {
    return slotAvailability[time] ?? false;
  }

  // Check if a time slot is disabled (past time for today)
  bool isSlotDisabled(String time) {
    return pastTimeSlots[time] ?? false;
  }

  // Check if a time slot is unavailable (from API)
  bool isSlotUnavailable(String time) {
    // Unavailable if not available AND not disabled (disabled is separate)
    return !(slotAvailability[time] ?? false) &&
        !(pastTimeSlots[time] ?? false);
  }

  // Check if a time slot is selected
  bool isSlotSelected(String time) {
    return selectedTimeSlot.value == time;
  }

  // Format month and year
  String getFormattedMonth() {
    try {
      return DateFormat('MMMM yyyy').format(selectedMonth.value);
    } catch (e) {
      print('Error formatting month: $e');
      return DateFormat('MMMM yyyy').format(DateTime.now());
    }
  }

  // Get all days from current date onwards in the selected month
  List<DateTime> getAvailableDays() {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    // Get the first and last day of the selected month
    DateTime firstDayOfMonth =
        DateTime(selectedMonth.value.year, selectedMonth.value.month, 1);
    DateTime lastDayOfMonth =
        DateTime(selectedMonth.value.year, selectedMonth.value.month + 1, 0);

    // Determine the start date (today if in current month, otherwise first day of selected month)
    DateTime startDate;
    if (selectedMonth.value.year == now.year &&
        selectedMonth.value.month == now.month) {
      startDate = today; // Start from today if viewing current month
    } else {
      startDate =
          firstDayOfMonth; // Start from first day if viewing future month
    }

    // Generate all days from startDate to lastDayOfMonth
    List<DateTime> availableDays = [];
    DateTime currentDate = startDate;

    while (currentDate.isBefore(lastDayOfMonth) ||
        currentDate.isAtSameMomentAs(lastDayOfMonth)) {
      availableDays
          .add(DateTime(currentDate.year, currentDate.month, currentDate.day));
      currentDate = currentDate.add(Duration(days: 1));
    }

    return availableDays;
  }

  // Check if a day is selected
  bool isDaySelected(DateTime day) {
    if (selectedDate.value == null) return false;
    DateTime dayDate = DateTime(day.year, day.month, day.day);
    DateTime selectedDayDate = DateTime(selectedDate.value!.year,
        selectedDate.value!.month, selectedDate.value!.day);
    return dayDate.isAtSameMomentAs(selectedDayDate);
  }

  // Green dot = professional has availability on this date; red = not available
  bool hasServiceFormatAvailable(DateTime day) {
    // Register Obx dependencies
    rawAvailabilities.length;
    confirmedAvailableDates.length;
    confirmedUnavailableDates.length;
    serviceFormatDates.length;

    final formattedDate = DateFormat('yyyy-MM-dd').format(day);

    if (confirmedUnavailableDates.contains(formattedDate)) {
      return false;
    }
    if (confirmedAvailableDates.contains(formattedDate)) {
      return true;
    }

    // Prefer full availability schedule from service-format API
    if (rawAvailabilities.isNotEmpty) {
      return rawAvailabilities.any(
        (availability) => _isDateInAvailability(day, availability),
      );
    }

    // Fallback: service_format_date list
    return serviceFormatDates.contains(formattedDate);
  }

  /// Whether [date] falls within an availability schedule entry
  /// (same rules as professional calendar green/red dots).
  bool _isDateInAvailability(DateTime date, Map<String, dynamic> availability) {
    try {
      final startDateStr = availability['start_date']?.toString();
      if (startDateStr == null || startDateStr.isEmpty) return false;

      final startDate = startDateStr.contains('T')
          ? DateTime.parse(startDateStr)
          : DateFormat('yyyy-MM-dd').parse(startDateStr);

      final checkDate = DateTime(date.year, date.month, date.day);
      final normalizedStartDate =
          DateTime(startDate.year, startDate.month, startDate.day);

      final repeat = availability['repeat']?.toString() ?? '';
      final repeatUntilStr = availability['repeat_until']?.toString();
      final excludeWeekends = availability['exclude_weekends'] == true;
      final isActive = availability['is_active'];

      if (isActive == false) return false;
      if (checkDate.isBefore(normalizedStartDate)) return false;

      if (repeatUntilStr != null && repeatUntilStr.isNotEmpty) {
        final repeatUntil = repeatUntilStr.contains('T')
            ? DateTime.parse(repeatUntilStr)
            : DateFormat('yyyy-MM-dd').parse(repeatUntilStr);
        final normalizedRepeatUntil =
            DateTime(repeatUntil.year, repeatUntil.month, repeatUntil.day);
        if (checkDate.isAfter(normalizedRepeatUntil)) return false;
      }

      bool matchesRepeat = false;
      switch (repeat.toLowerCase()) {
        case 'daily':
        case 'everyday':
          matchesRepeat = true;
          break;
        case 'weekly':
        case 'every week':
          matchesRepeat = checkDate.weekday == normalizedStartDate.weekday;
          break;
        case 'two_week':
        case 'every two week':
          final daysDiff = checkDate.difference(normalizedStartDate).inDays;
          matchesRepeat =
              daysDiff >= 0 && daysDiff % 14 == 0;
          break;
        case 'monthly':
        case 'every month':
          matchesRepeat = checkDate.day == normalizedStartDate.day;
          break;
        case "don't repeat":
        case 'dont repeat':
        case 'never':
          matchesRepeat = checkDate.isAtSameMomentAs(normalizedStartDate);
          break;
        default:
          matchesRepeat = checkDate.isAtSameMomentAs(normalizedStartDate);
      }

      if (!matchesRepeat) return false;

      if (excludeWeekends) {
        final weekday = checkDate.weekday;
        if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Error checking date in availability: $e');
      return false;
    }
  }

  void _mergeRawAvailabilities(List<Map<String, dynamic>> newItems) {
    if (newItems.isEmpty) return;

    for (final item in newItems) {
      final id = item['id']?.toString() ?? item['_id']?.toString();
      if (id == null || id.isEmpty) {
        rawAvailabilities.add(item);
        continue;
      }

      final existingIndex = rawAvailabilities.indexWhere(
        (availability) =>
            (availability['id']?.toString() ??
                availability['_id']?.toString()) ==
            id,
      );

      if (existingIndex >= 0) {
        rawAvailabilities[existingIndex] = item;
      } else {
        rawAvailabilities.add(item);
      }
    }

    rawAvailabilities.refresh();
  }

  void _markDateAvailabilityConfirmed(DateTime day, bool isAvailable) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    if (isAvailable) {
      confirmedUnavailableDates.remove(key);
      confirmedAvailableDates.add(key);
    } else {
      confirmedAvailableDates.remove(key);
      confirmedUnavailableDates.add(key);
    }
    confirmedAvailableDates.refresh();
    confirmedUnavailableDates.refresh();
  }

  bool _isPrefetchingMonthDots = false;
  String? _lastPrefetchedMonthKey;

  /// When API does not return an availability schedule, check each visible day
  /// via the service-format-availability details endpoint for green/red dots.
  Future<void> _prefetchMonthAvailabilityDots() async {
    if (_isPrefetchingMonthDots) return;
    if (professionalId == null || professionalId!.isEmpty) return;
    // Schedule already drives dots — no need to hit API per day
    if (rawAvailabilities.isNotEmpty) return;

    final month = selectedMonth.value;
    final monthKey = '${month.year}-${month.month}';
    if (_lastPrefetchedMonthKey == monthKey) {
      return;
    }

    _isPrefetchingMonthDots = true;
    _lastPrefetchedMonthKey = monthKey;

    try {
      final days = getAvailableDays();
      final daysToCheck = <DateTime>[];

      for (final day in days) {
        final key = DateFormat('yyyy-MM-dd').format(day);
        if (confirmedAvailableDates.contains(key) ||
            confirmedUnavailableDates.contains(key)) {
          continue;
        }

        if (selectedDate.value != null) {
          final selected = selectedDate.value!;
          if (day.year == selected.year &&
              day.month == selected.month &&
              day.day == selected.day) {
            continue;
          }
        }

        daysToCheck.add(day);
      }

      // Check in small batches to avoid flooding the API
      const batchSize = 5;
      for (var i = 0; i < daysToCheck.length; i += batchSize) {
        final batch = daysToCheck.skip(i).take(batchSize);
        await Future.wait(batch.map(_checkDayAvailabilityForDot));

        // If schedule appeared from any response, stop per-day checks
        if (rawAvailabilities.isNotEmpty) break;
      }

      // After dots resolve, only auto-select once on first load — never override user tap
      if (!_hasUserSelectedDate &&
          !_hasCompletedInitialAutoSelect &&
          selectedDate.value != null &&
          !hasServiceFormatAvailable(selectedDate.value!)) {
        _autoSelectServiceFormatDate(null);
      }
    } catch (e) {
      print('Error prefetching month availability dots: $e');
    } finally {
      _isPrefetchingMonthDots = false;
    }
  }

  Future<void> _checkDayAvailabilityForDot(DateTime day) async {
    try {
      final formattedDate = DateFormat('dd/MM/yyyy').format(day);

      Map<String, dynamic> toJson() {
        final Map<String, dynamic> data = <String, dynamic>{};
        data['date'] = formattedDate;
        data['professional_id'] = professionalId;
        if (serviceFormatId != null && serviceFormatId!.isNotEmpty) {
          data['professional_service_format_id'] = serviceFormatId;
        }
        return data;
      }

      final response = await _repository.sendGetApiWithParamRequest(
        toJson,
        timeslot_availability,
        true,
      );

      bool hasAvailability = false;
      try {
        dynamic responseData;
        if (response != null && response.data != null) {
          responseData = response.data;
        } else if (response is Map<String, dynamic>) {
          responseData = response;
        }

        if (responseData is Map<String, dynamic>) {
          final success = responseData['success'] == true;
          final data = responseData['data'];
          if (success && data is Map<String, dynamic>) {
            final from = data['available_from']?.toString() ?? '';
            final until = data['available_until']?.toString() ?? '';
            hasAvailability = from.isNotEmpty && until.isNotEmpty;

            // Merge schedule if present so later months can use it
            List<dynamic>? availabilitiesList;
            if (data['availabilities'] is List) {
              availabilitiesList = data['availabilities'] as List;
            } else if (data['availability'] is List) {
              availabilitiesList = data['availability'] as List;
            }
            if (availabilitiesList != null && availabilitiesList.isNotEmpty) {
              _mergeRawAvailabilities(
                availabilitiesList.whereType<Map<String, dynamic>>().toList(),
              );
            }
          }
        }
      } catch (e) {
        print('Error parsing day availability for $formattedDate: $e');
        hasAvailability = false;
      }

      _markDateAvailabilityConfirmed(day, hasAvailability);
    } on NotFoundException {
      _markDateAvailabilityConfirmed(day, false);
    } catch (e) {
      // Don't mark as unavailable on transient errors — leave undecided
      print('Error checking day availability for dot: $e');
    }
  }

  // Auto-select first date that has availability (schedule or service format date)
  // Only used for initial load — never overrides a user-selected date.
  void _autoSelectServiceFormatDate(String? targetServiceFormatDate) {
    try {
      if (_hasUserSelectedDate || isEditMode) {
        return;
      }
      if (_hasCompletedInitialAutoSelect) {
        return;
      }

      DateTime? targetDateOnly;

      if (targetServiceFormatDate != null &&
          targetServiceFormatDate.isNotEmpty) {
        final targetDate = DateTime.parse(targetServiceFormatDate);
        targetDateOnly =
            DateTime(targetDate.year, targetDate.month, targetDate.day);
      } else {
        // Prefer first future date covered by availability schedule
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final searchEnd = DateTime(today.year, today.month + 2, 0);

        DateTime cursor = today;
        while (!cursor.isAfter(searchEnd)) {
          if (hasServiceFormatAvailable(cursor)) {
            targetDateOnly = cursor;
            break;
          }
          cursor = cursor.add(const Duration(days: 1));
        }

        // Fallback: first service_format_date
        if (targetDateOnly == null && serviceFormatDates.isNotEmpty) {
          final sortedDates = List<String>.from(serviceFormatDates)..sort();
          final firstDate = DateTime.parse(sortedDates.first);
          targetDateOnly =
              DateTime(firstDate.year, firstDate.month, firstDate.day);
        }
      }

      _hasCompletedInitialAutoSelect = true;

      if (targetDateOnly == null) {
        print('No available dates found for auto-select');
        return;
      }

      final current = selectedDate.value;
      final alreadySelected = current != null &&
          DateTime(current.year, current.month, current.day)
              .isAtSameMomentAs(targetDateOnly);

      if (alreadySelected) {
        return;
      }

      selectedDate.value = targetDateOnly;
      selectedMonth.value =
          DateTime(targetDateOnly.year, targetDateOnly.month, 1);
      print(
          'Auto-selected available date: ${DateFormat('yyyy-MM-dd').format(targetDateOnly)}');

      // Defer reload so current API success handler can finish
      Future.microtask(() => loadAvailability());
    } catch (e) {
      print('Error in _autoSelectServiceFormatDate: $e');
      _hasCompletedInitialAutoSelect = true;
    }
  }

  // Auto-select first available service format date (legacy method)
  void _autoSelectFirstServiceFormatDate() {
    _autoSelectServiceFormatDate(null);
  }

  // Load availability data from API
  Future<void> loadAvailability() async {
    try {
      // Prevent multiple simultaneous calls
      if (isLoadingAvailability.value) {
        print('API call already in progress, will refresh after it completes...');
        return;
      }

      if (professionalId == null || professionalId!.isEmpty) {
        print('Error: Professional ID is null or empty');
        isLoadingAvailability.value = false;
        apiMessage.value = 'Professional ID is required';
        return;
      }

      // Only proceed if we have a selected date
      if (selectedDate.value == null) {
        print(
            'No selected date available - skipping API call (waiting for service format date selection)');
        isLoadingAvailability.value = false;
        return;
      }

      isLoadingAvailability.value = true;

      // Format date as DD/MM/YYYY - only use selected date, no fallback to current date
      String formattedDate;
      try {
        formattedDate = DateFormat('dd/MM/yyyy').format(selectedDate.value!);
        _pendingAvailabilityDate = formattedDate;
        print('Using selected date for API: $formattedDate');
      } catch (e) {
        print('Error formatting selected date: $e');
        isLoadingAvailability.value = false;
        return;
      }

      callAvailabilityAPI(formattedDate);
    } catch (e, stackTrace) {
      print('CRASH PREVENTED in loadAvailability: $e');
      print('Stack trace: $stackTrace');
      isLoadingAvailability.value = false;
      apiMessage.value = 'Error loading availability';
    }
  }

  void callAvailabilityAPI(String date) {
    Map<String, dynamic> toJson() {
      final Map<String, dynamic> data = <String, dynamic>{};
      data['date'] = date;
      data['professional_id'] = professionalId;
      data['professional_service_format_id'] = serviceFormatId;

      print('========================================');
      print('Availability API Request (GET):');
      print(data);
      print('========================================');

      return data;
    }

    var service = _repository.sendGetApiWithParamRequest(
        toJson, timeslot_availability, true);
    callDataService(
      service,
      onSuccess: _handleAvailabilitySuccess,
      onError: _handleAvailabilityError,
      isShowLoading: true,
    );
  }

  Future<void> _handleAvailabilitySuccess(dynamic baseResponse) async {
    try {
      // If user selected another day while this request was in flight, reload that day
      if (selectedDate.value != null && _pendingAvailabilityDate != null) {
        final currentDateStr =
            DateFormat('dd/MM/yyyy').format(selectedDate.value!);
        if (currentDateStr != _pendingAvailabilityDate) {
          print(
              'Stale availability response for $_pendingAvailabilityDate; reloading $currentDateStr');
          isLoadingAvailability.value = false;
          _pendingAvailabilityDate = null;
          loadAvailability();
          return;
        }
      }

      Map<String, dynamic> responseData;
      if (baseResponse != null && baseResponse.data != null) {
        responseData = baseResponse.data is Map<String, dynamic>
            ? baseResponse.data
            : baseResponse.data as Map<String, dynamic>;
      } else if (baseResponse is Map<String, dynamic>) {
        responseData = baseResponse;
      } else {
        throw Exception('Invalid response format');
      }

      bool success = responseData['success'] ?? false;
      String message = responseData['message'] ?? '';

      if (success == true && responseData['data'] != null) {
        Map<String, dynamic>? dataMap;
        try {
          if (responseData['data'] is Map<String, dynamic>) {
            dataMap = responseData['data'] as Map<String, dynamic>;
          } else {
            print('Error: data is not a Map');
            throw Exception('Invalid data format');
          }
        } catch (e) {
          print('Error parsing data map: $e');
          throw Exception('Invalid data format');
        }

        if (dataMap == null) {
          throw Exception('Data map is null');
        }

        try {
          availableFrom = dataMap['available_from']?.toString();
        } catch (e) {
          print('Error parsing available_from: $e');
        }

        try {
          availableUntil = dataMap['available_until']?.toString();
        } catch (e) {
          print('Error parsing available_until: $e');
        }

        // Parse unavailable times
        unavailableTimes = [];
        try {
          if (dataMap['unavailable_times'] != null) {
            if (dataMap['unavailable_times'] is List) {
              unavailableTimes = List<Map<String, dynamic>>.from(
                (dataMap['unavailable_times'] as List).map((item) {
                  if (item is Map<String, dynamic>) {
                    return item;
                  }
                  return <String, dynamic>{};
                }),
              );
            }
          }
        } catch (e) {
          print('Error parsing unavailable_times: $e');
          unavailableTimes = [];
        }

        // Parse professional service formats
        professionalServiceFormats = [];
        try {
          if (dataMap['professional_service_formats'] != null) {
            if (dataMap['professional_service_formats'] is List) {
              professionalServiceFormats = List<Map<String, dynamic>>.from(
                (dataMap['professional_service_formats'] as List).map((item) {
                  try {
                    if (item is Map<String, dynamic>) {
                      // Create a safe copy of the item to prevent crashes
                      Map<String, dynamic> safeItem = {};

                      // Copy all fields safely using containsKey to avoid crashes
                      if (item.containsKey('_id'))
                        safeItem['_id'] = item['_id'];
                      if (item.containsKey('id')) safeItem['id'] = item['id'];
                      if (item.containsKey('service_format_name'))
                        safeItem['service_format_name'] =
                            item['service_format_name'];
                      if (item.containsKey('is_bundle'))
                        safeItem['is_bundle'] = item['is_bundle'];
                      if (item.containsKey('duration_minutes'))
                        safeItem['duration_minutes'] = item['duration_minutes'];

                      // Handle bundle-specific fields
                      if (item['is_bundle'] == true) {
                        if (item.containsKey('bundle_of'))
                          safeItem['bundle_of'] = item['bundle_of'];
                        if (item.containsKey('bundle_price'))
                          safeItem['bundle_price'] = item['bundle_price'];
                        if (item.containsKey('offer_text'))
                          safeItem['offer_text'] = item['offer_text'];
                      } else {
                        // Handle non-bundle fields
                        if (item.containsKey('price'))
                          safeItem['price'] = item['price'];
                        if (item.containsKey('offer_text'))
                          safeItem['offer_text'] = item['offer_text'];
                      }

                      // Optional fields (may not exist in API response)
                      if (item.containsKey('service_format_id'))
                        safeItem['service_format_id'] =
                            item['service_format_id'];
                      if (item.containsKey('service_format_date'))
                        safeItem['service_format_date'] =
                            item['service_format_date'];
                      if (item.containsKey('timezone'))
                        safeItem['timezone'] = item['timezone'];

                      return safeItem;
                    }
                    return <String, dynamic>{};
                  } catch (e) {
                    print('Error processing service format item: $e');
                    return <String, dynamic>{};
                  }
                }).where((item) => item.isNotEmpty), // Filter out empty maps
              );
            }
          }
        } catch (e) {
          print('Error parsing professional_service_formats: $e');
          professionalServiceFormats = [];
        }

        // Parse availabilities schedule for calendar green/red dots
        try {
          List<dynamic>? availabilitiesList;
          if (dataMap['availabilities'] is List) {
            availabilitiesList = dataMap['availabilities'] as List;
          } else if (dataMap['availability'] is List) {
            availabilitiesList = dataMap['availability'] as List;
          }

          if (availabilitiesList != null) {
            if (availabilitiesList.isEmpty) {
              print('Availabilities list empty for selected date');
              if (rawAvailabilities.isEmpty) {
                Future.microtask(() => _prefetchMonthAvailabilityDots());
              }
            } else {
              _mergeRawAvailabilities(
                availabilitiesList.whereType<Map<String, dynamic>>().toList(),
              );
              print(
                  'Parsed ${rawAvailabilities.length} availability schedule entries for calendar dots');
            }
          } else {
            // No schedule in response — check remaining visible days via API
            print(
                'No availabilities array in response; prefetching month calendar dots');
            Future.microtask(() => _prefetchMonthAvailabilityDots());
          }
        } catch (e) {
          print('Error parsing availabilities: $e');
        }

        // Selected date has availability when available_from/until are present
        final bool selectedDateHasAvailability =
            (availableFrom != null && availableFrom!.isNotEmpty) &&
                (availableUntil != null && availableUntil!.isNotEmpty);
        if (selectedDate.value != null) {
          _markDateAvailabilityConfirmed(
            selectedDate.value!,
            selectedDateHasAvailability,
          );
        }

        // Parse service format dates for calendar (fallback)
        try {
          List<String> dates = [];
          String? selectedServiceFormatDate;

          for (var format in professionalServiceFormats) {
            if (format.containsKey('service_format_date')) {
              String? serviceFormatDate =
                  format['service_format_date']?.toString();
              if (serviceFormatDate != null && serviceFormatDate.isNotEmpty) {
                // Parse ISO date and convert to YYYY-MM-DD format
                try {
                  DateTime parsedDate = DateTime.parse(serviceFormatDate);
                  String formattedDate =
                      DateFormat('yyyy-MM-dd').format(parsedDate);
                  if (!dates.contains(formattedDate)) {
                    dates.add(formattedDate);
                  }

                  // Check if this format matches the current service being booked
                  // Use multiple criteria for better matching
                  bool isMatchingService = false;

                  // Check by professional service format ID
                  String? formatId = format['_id']?.toString();
                  if (professionalServiceFormatId != null &&
                      formatId == professionalServiceFormatId) {
                    isMatchingService = true;
                    print(
                        'Matched by professionalServiceFormatId: $professionalServiceFormatId');
                  }

                  // Check by service format ID
                  String? serviceFormatIdFromFormat =
                      format['service_format_id']?.toString();
                  if (serviceFormatId != null &&
                      serviceFormatIdFromFormat == serviceFormatId) {
                    isMatchingService = true;
                    print('Matched by serviceFormatId: $serviceFormatId');
                  }

                  // Check by service name and duration (for additional matching)
                  String? serviceName =
                      format['service_format_name']?.toString();
                  int? duration = format['duration_minutes'] as int?;
                  if (serviceName != null && duration != null) {
                    // Match by service name and duration if IDs don't match
                    if ((serviceName.toLowerCase().contains('consultation') &&
                            duration == 30) ||
                        (serviceName.toLowerCase().contains('bundle') &&
                            duration == 45) ||
                        (serviceName.toLowerCase().contains('session') &&
                            duration == 15)) {
                      isMatchingService = true;
                      print(
                          'Matched by service name and duration: $serviceName, $duration');
                    }
                  }

                  if (isMatchingService) {
                    selectedServiceFormatDate = formattedDate;
                    print('Found matching service format date: $formattedDate');
                  }
                } catch (e) {
                  print(
                      'Error parsing service_format_date: $serviceFormatDate, error: $e');
                }
              }
            }
          }

          serviceFormatDates.value = dates;
          print('Service format dates extracted: ${serviceFormatDates.value}');

          // Auto-select the matching service format date, or first available from schedule
          _autoSelectServiceFormatDate(selectedServiceFormatDate);
        } catch (e) {
          print('Error extracting service format dates: $e');
          serviceFormatDates.value = [];
          _autoSelectServiceFormatDate(null);
        }

        print('========================================');
        print('Availability API Success:');
        print('Available From: $availableFrom');
        print('Available Until: $availableUntil');
        print('Unavailable Times: $unavailableTimes');
        print('========================================');

        // Generate time slots from API response
        _generateTimeSlotsFromAPI();

        // Clear API message on success
        apiMessage.value = '';
      } else {
        // Show error message when success is false
        print('Availability API Error: $message');
        timeSlots.value = [];
        slotAvailability.value = {};
        pastTimeSlots.value = {};

        if (selectedDate.value != null) {
          _markDateAvailabilityConfirmed(selectedDate.value!, false);
        }

        // Still try to resolve calendar dots for other days
        if (rawAvailabilities.isEmpty) {
          Future.microtask(() => _prefetchMonthAvailabilityDots());
        }

        // Store API message for display in UI
        apiMessage.value =
            message.isNotEmpty ? message : 'No availability found';

        // Don't show dialog, just display message in UI
      }
    } catch (e) {
      print('Error parsing availability response: $e');
      timeSlots.value = [];
      slotAvailability.value = {};
      pastTimeSlots.value = {};
    } finally {
      isLoadingAvailability.value = false;
      _pendingAvailabilityDate = null;
    }
  }

  void _handleAvailabilityError(dynamic e) {
    try {
      print('Availability API Error: $e');

      // If user changed date mid-request, reload the newly selected date
      if (selectedDate.value != null && _pendingAvailabilityDate != null) {
        final currentDateStr =
            DateFormat('dd/MM/yyyy').format(selectedDate.value!);
        if (currentDateStr != _pendingAvailabilityDate) {
          isLoadingAvailability.value = false;
          _pendingAvailabilityDate = null;
          loadAvailability();
          return;
        }
      }

      if (selectedDate.value != null) {
        _markDateAvailabilityConfirmed(selectedDate.value!, false);
      }

      if (e is NotFoundException) {
        timeSlots.value = [];
        slotAvailability.value = {};
        pastTimeSlots.value = {};
        apiMessage.value = e.message?.toString() ?? 'No availability found';
        isLoadingAvailability.value = false;
      } else {
        // Handle other errors
        timeSlots.value = [];
        slotAvailability.value = {};
        pastTimeSlots.value = {};
        apiMessage.value = 'Error loading availability';
        isLoadingAvailability.value = false;
      }
      _pendingAvailabilityDate = null;
    } catch (error) {
      print('CRASH PREVENTED in _handleAvailabilityError: $error');
      isLoadingAvailability.value = false;
      _pendingAvailabilityDate = null;
    }
  }

  void _generateTimeSlotsFromAPIOld() {
    try {
      if (availableFrom == null ||
          availableUntil == null ||
          availableFrom!.isEmpty ||
          availableUntil!.isEmpty) {
        print('Error: available_from or available_until is null or empty');
        timeSlots.value = [];
        slotAvailability.value = {};
        pastTimeSlots.value = {};
        return;
      }

      // Parse available_from and available_until (format: "HH:mm")
      TimeOfDay? fromTime = _parseTimeString(availableFrom!);
      TimeOfDay? untilTime = _parseTimeString(availableUntil!);

      if (fromTime == null || untilTime == null) {
        print(
            'Error: Could not parse time strings - from: $availableFrom, until: $availableUntil');
        timeSlots.value = [];
        slotAvailability.value = {};
        pastTimeSlots.value = {};
        return;
      }

      // Use duration from previous screen, default to 30 minutes if not provided
      int slotDuration = durationMinutes ?? 30;

      // Check if selected date is today
      bool isToday = _isToday();

      // Get current time for comparison (only needed if today is selected)
      TimeOfDay? currentTimeOfDay;
      if (isToday) {
        final now = DateTime.now();
        currentTimeOfDay = TimeOfDay(hour: now.hour, minute: now.minute);
      }

      // Generate time slots
      List<String> slots = [];
      Map<String, bool> availability = {};
      Map<String, bool> pastSlots = {};

      TimeOfDay currentTime = fromTime;

      while (_isTimeBeforeOrEqual(currentTime, untilTime)) {
        String timeSlot = _formatTimeSlot(currentTime);
        slots.add(timeSlot);

        // Check if this time slot overlaps with unavailable_times (from API)
        // Pass slot duration to check if entire slot overlaps with unavailable range
        bool isUnavailable = _isTimeSlotUnavailable(currentTime, slotDuration);

        // Check if time slot is in the past (only for today)
        bool isPast = false;
        if (isToday && currentTimeOfDay != null) {
          isPast = _isTimeSlotInPast(currentTime, currentTimeOfDay);
          pastSlots[timeSlot] = isPast;
        } else {
          pastSlots[timeSlot] = false;
        }

        // Past slots should not be available, but keep unavailable logic separate
        // Availability is false if either unavailable OR past
        availability[timeSlot] = !isUnavailable && !isPast;

        // Move to next slot
        currentTime = _addMinutes(currentTime, slotDuration);
      }

      timeSlots.value = slots;
      slotAvailability.value = availability;
      pastTimeSlots.value = pastSlots;

      print('Generated ${slots.length} time slots');
      print('Availability map: $availability');
      if (isToday) {
        print('Today is selected - past time slots are disabled');
      }
    } catch (e, stackTrace) {
      print('CRASH PREVENTED in _generateTimeSlotsFromAPI: $e');
      print('Stack trace: $stackTrace');
      timeSlots.value = [];
      slotAvailability.value = {};
      pastTimeSlots.value = {};
    }
  }

  void _generateTimeSlotsFromAPI() {
    try {
      // Validate input data
      if (availableFrom == null ||
          availableUntil == null ||
          availableFrom!.isEmpty ||
          availableUntil!.isEmpty) {
        print('Error: available_from or available_until is null or empty');
        timeSlots.value = [];
        slotAvailability.value = {};
        pastTimeSlots.value = {};
        return;
      }

      // Parse available_from and available_until (format: "HH:mm")
      TimeOfDay? fromTime = _parseTimeString(availableFrom!);
      TimeOfDay? untilTime = _parseTimeString(availableUntil!);

      if (fromTime == null || untilTime == null) {
        print(
            'Error: Could not parse time strings - from: $availableFrom, until: $availableUntil');
        timeSlots.value = [];
        slotAvailability.value = {};
        pastTimeSlots.value = {};
        return;
      }

      // Use duration from previous screen, default to 30 minutes if not provided
      int slotDuration = durationMinutes ?? 30;

      // CRITICAL FIX: Validate slot duration to prevent infinite loops
      if (slotDuration <= 0) {
        print(
            'Error: Invalid slot duration: $slotDuration. Using default 30 minutes.');
        slotDuration = 30;
      }

      // Additional safety check: limit maximum duration to prevent crashes
      if (slotDuration > 480) {
        // 8 hours max
        print(
            'Warning: Slot duration too large: $slotDuration. Capping at 480 minutes.');
        slotDuration = 480;
      }

      // Log slot generation parameters
      print('========================================');
      print('Generating Time Slots:');
      print('Available From: $availableFrom');
      print('Available Until: $availableUntil');
      print('Slot Duration: $slotDuration minutes');
      print('Unavailable Times: $unavailableTimes');
      print('========================================');

      // Check if selected date is today
      bool isToday = _isToday();

      // Get current time for comparison (only needed if today is selected)
      TimeOfDay? currentTimeOfDay;
      if (isToday) {
        try {
          final now = DateTime.now();
          currentTimeOfDay = TimeOfDay(hour: now.hour, minute: now.minute);
        } catch (e) {
          print('Error getting current time: $e');
          currentTimeOfDay = null;
        }
      }

      // Generate time slots
      List<String> slots = [];
      Map<String, bool> availability = {};
      Map<String, bool> pastSlots = {};
      Set<int> slotStartMinutesSet =
          {}; // Track slot start times to avoid duplicates

      TimeOfDay currentTime = fromTime;

      // CRITICAL FIX: Add safety counter to prevent infinite loops
      int maxIterations =
          1000; // Safety limit (e.g., 15-minute slots over 24 hours = ~96 slots)
      int iterationCount = 0;

      // Convert times to minutes for easier comparison
      int fromMinutes = fromTime.hour * 60 + fromTime.minute;
      int untilMinutes = untilTime.hour * 60 + untilTime.minute;

      // Handle cases where until time is on next day (e.g., from 22:00 to 02:00)
      if (untilMinutes <= fromMinutes) {
        untilMinutes += 24 * 60; // Add 24 hours
      }

      // Collect boundary times from unavailable periods
      // Only include boundaries that align with slot duration OR are at major unavailable period boundaries
      List<int> boundaryTimes = [];
      Set<int> majorBoundaries =
          {}; // Start of first unavailable period, end of last

      // Find major boundaries (start of first unavailable, end of last unavailable in sequence)
      if (unavailableTimes.isNotEmpty) {
        List<int> allBoundaries = [];
        for (var unavailable in unavailableTimes) {
          try {
            if (unavailable is! Map<String, dynamic>) continue;

            String? fromStr = unavailable['from']?.toString();
            String? toStr = unavailable['to']?.toString();

            if (fromStr != null &&
                toStr != null &&
                fromStr.isNotEmpty &&
                toStr.isNotEmpty) {
              TimeOfDay? unavailableFromTime = _parseTimeString(fromStr);
              TimeOfDay? unavailableToTime = _parseTimeString(toStr);

              if (unavailableFromTime != null && unavailableToTime != null) {
                int unavailableFromMinutes =
                    unavailableFromTime.hour * 60 + unavailableFromTime.minute;
                int unavailableToMinutes =
                    unavailableToTime.hour * 60 + unavailableToTime.minute;

                allBoundaries.add(unavailableFromMinutes);
                allBoundaries.add(unavailableToMinutes);
              }
            }
          } catch (e) {
            continue;
          }
        }
        allBoundaries.sort();
        if (allBoundaries.isNotEmpty) {
          majorBoundaries.add(allBoundaries.first); // First unavailable start
          majorBoundaries.add(allBoundaries.last); // Last unavailable end
        }
      }

      // Collect boundaries, prioritizing major ones and those that align with slot duration
      for (var unavailable in unavailableTimes) {
        try {
          if (unavailable is! Map<String, dynamic>) continue;

          String? fromStr = unavailable['from']?.toString();
          String? toStr = unavailable['to']?.toString();

          if (fromStr != null &&
              toStr != null &&
              fromStr.isNotEmpty &&
              toStr.isNotEmpty) {
            TimeOfDay? unavailableFromTime = _parseTimeString(fromStr);
            TimeOfDay? unavailableToTime = _parseTimeString(toStr);

            if (unavailableFromTime != null && unavailableToTime != null) {
              int unavailableFromMinutes =
                  unavailableFromTime.hour * 60 + unavailableFromTime.minute;
              int unavailableToMinutes =
                  unavailableToTime.hour * 60 + unavailableToTime.minute;

              // Check if boundary aligns with slot duration (is a multiple of slotDuration from fromMinutes)
              bool fromAligns =
                  (unavailableFromMinutes - fromMinutes) % slotDuration == 0;
              bool toAligns =
                  (unavailableToMinutes - fromMinutes) % slotDuration == 0;
              bool fromIsMajor =
                  majorBoundaries.contains(unavailableFromMinutes);
              bool toIsMajor = majorBoundaries.contains(unavailableToMinutes);

              // Add boundary if it aligns with slot duration OR is a major boundary
              if (unavailableFromMinutes >= fromMinutes &&
                  unavailableFromMinutes <= untilMinutes) {
                if (fromAligns || fromIsMajor) {
                  boundaryTimes.add(unavailableFromMinutes);
                }
              }
              if (unavailableToMinutes >= fromMinutes &&
                  unavailableToMinutes <= untilMinutes) {
                if (toAligns || toIsMajor) {
                  boundaryTimes.add(unavailableToMinutes);
                }
              }
            }
          }
        } catch (e) {
          print('Error processing unavailable time boundaries: $e');
          continue;
        }
      }
      boundaryTimes.sort();

      // Generate slots sequentially, inserting boundaries and continuing intervals from boundaries
      List<int> sortedSlotTimes = [];
      int currentMinutes = fromMinutes;
      int boundaryIndex = 0;

      while (currentMinutes <= untilMinutes && iterationCount < maxIterations) {
        iterationCount++;

        // Check if slot starting at currentMinutes would fit (start + duration <= until)
        if (currentMinutes + slotDuration > untilMinutes) {
          // Slot would extend beyond available time, skip it
          break;
        }

        // Check if there's a boundary before next regular slot
        int nextRegularSlot = currentMinutes + slotDuration;
        bool foundBoundary = false;

        // Look for boundaries between current and next regular slot
        while (boundaryIndex < boundaryTimes.length) {
          int boundary = boundaryTimes[boundaryIndex];

          // Skip boundaries that are before current position
          if (boundary < currentMinutes) {
            boundaryIndex++;
            continue;
          }

          // If boundary is after next regular slot, process regular slot first
          if (boundary >= nextRegularSlot) {
            break;
          }

          // Found a boundary between current and next regular slot
          // Check if slot starting at boundary would fit
          if (boundary + slotDuration <= untilMinutes) {
            if (!sortedSlotTimes.contains(boundary)) {
              sortedSlotTimes.add(boundary);
            }
            // Continue from boundary instead of current position
            currentMinutes = boundary;
            foundBoundary = true;
            boundaryIndex++;
            break;
          } else {
            // Boundary slot would extend beyond available time, skip this boundary
            boundaryIndex++;
          }
        }

        // If no boundary found, add regular slot and move to next
        if (!foundBoundary) {
          if (!sortedSlotTimes.contains(currentMinutes)) {
            sortedSlotTimes.add(currentMinutes);
          }
          currentMinutes = nextRegularSlot;
        } else {
          // Already updated currentMinutes to boundary, continue loop
          continue;
        }
      }

      // Sort final list
      sortedSlotTimes.sort();

      // Generate slots from sorted times
      iterationCount = 0;
      for (int slotStartMinutes in sortedSlotTimes) {
        if (iterationCount >= maxIterations) break;
        iterationCount++;

        try {
          // Calculate current hour and minute
          int hour = (slotStartMinutes ~/ 60) % 24;
          int minute = slotStartMinutes % 60;
          currentTime = TimeOfDay(hour: hour, minute: minute);

          String timeSlot = _formatTimeSlot(currentTime);

          // Skip duplicate slots (by time string)
          if (slots.contains(timeSlot)) {
            continue;
          }

          // Add slot regardless of availability - we'll mark it as unavailable later
          slots.add(timeSlot);
          slotStartMinutesSet.add(slotStartMinutes);

          // Check if this time slot overlaps with unavailable_times (from API)
          // Pass slot duration to check if entire slot overlaps with unavailable range
          bool isUnavailable =
              _isTimeSlotUnavailable(currentTime, slotDuration);

          // Check if time slot is in the past (only for today)
          bool isPast = false;
          if (isToday && currentTimeOfDay != null) {
            try {
              isPast = _isTimeSlotInPast(currentTime, currentTimeOfDay);
              pastSlots[timeSlot] = isPast;
            } catch (e) {
              print('Error checking if slot is in past: $e');
              pastSlots[timeSlot] = false;
            }
          } else {
            pastSlots[timeSlot] = false;
          }

          // Availability is false if either unavailable OR past
          // Note: Slots that overlap unavailable times are still generated, just marked unavailable
          availability[timeSlot] = !isUnavailable && !isPast;

          // Debug logging for ALL slots
          TimeOfDay slotEndTime = _addMinutes(currentTime, slotDuration);
          String slotEndStr = _formatTimeSlot(slotEndTime);
          String status = isUnavailable
              ? "UNAVAILABLE"
              : isPast
                  ? "PAST"
                  : "AVAILABLE";
          print('Slot ${slots.length}: $timeSlot - $slotEndStr ($status)');
        } catch (e) {
          print('Error processing time slot at $slotStartMinutes: $e');
          continue;
        }
      }

      // Check if we hit the iteration limit (potential infinite loop)
      if (iterationCount >= maxIterations) {
        print(
            'WARNING: Hit maximum iteration limit. Possible infinite loop prevented.');
      }

      // Final validation
      if (slots.isEmpty) {
        print('Warning: No time slots generated. Check availability times.');
      }

      timeSlots.value = slots;
      slotAvailability.value = availability;
      pastTimeSlots.value = pastSlots;

      print('========================================');
      print('Slot Generation Complete:');
      print('Total slots generated: ${slots.length}');
      print('Slot duration: $slotDuration minutes');
      print('Available from: $availableFrom, until: $availableUntil');
      print(
          'Available slots: ${availability.values.where((v) => v == true).length}');
      print(
          'Unavailable slots: ${availability.values.where((v) => v == false).length}');
      if (isToday) {
        print('Today is selected - past time slots are disabled');
      }
      print('----------------------------------------');
      print('All Generated Slots:');
      for (int i = 0; i < slots.length; i++) {
        String slot = slots[i];
        bool isAvail = availability[slot] ?? false;
        bool isUnavail = !isAvail && !(pastSlots[slot] ?? false);
        bool isPast = pastSlots[slot] ?? false;
        String status = isUnavail
            ? "UNAVAILABLE"
            : isPast
                ? "PAST"
                : "AVAILABLE";
        print('  ${i + 1}. $slot ($status)');
      }
      print('========================================');
    } catch (e, stackTrace) {
      print('CRASH PREVENTED in _generateTimeSlotsFromAPI: $e');
      print('Stack trace: $stackTrace');
      timeSlots.value = [];
      slotAvailability.value = {};
      pastTimeSlots.value = {};
    }
  }

  TimeOfDay? _parseTimeString(String timeStr) {
    try {
      if (timeStr.isEmpty) return null;

      List<String> parts = timeStr.split(':');
      if (parts.length >= 2) {
        int? hour = int.tryParse(parts[0].trim());
        int? minute = int.tryParse(parts[1].trim());

        if (hour != null &&
            minute != null &&
            hour >= 0 &&
            hour < 24 &&
            minute >= 0 &&
            minute < 60) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
    } catch (e) {
      print('Error parsing time string: $timeStr, error: $e');
    }
    return null;
  }

  String _formatTimeSlot(TimeOfDay time) {
    int hour = time.hour;
    int minute = time.minute;
    String period = hour >= 12 ? 'PM' : 'AM';

    if (hour > 12) {
      hour = hour - 12;
    } else if (hour == 0) {
      hour = 12;
    }

    String minuteStr =
        minute == 0 ? '' : ':${minute.toString().padLeft(2, '0')}';
    return '$hour$minuteStr $period';
  }

  bool _isTimeBeforeOrEqualOld(TimeOfDay time1, TimeOfDay time2) {
    int minutes1 = time1.hour * 60 + time1.minute;
    int minutes2 = time2.hour * 60 + time2.minute;
    return minutes1 <= minutes2;
  }

  bool _isTimeBeforeOrEqual(TimeOfDay time1, TimeOfDay time2) {
    try {
      int minutes1 = time1.hour * 60 + time1.minute;
      int minutes2 = time2.hour * 60 + time2.minute;
      return minutes1 <= minutes2;
    } catch (e) {
      print('Error in _isTimeBeforeOrEqual: $e');
      return false; // Safe default
    }
  }

  TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
    int totalMinutes = time.hour * 60 + time.minute + minutes;
    int newHour = (totalMinutes ~/ 60) % 24;
    int newMinute = totalMinutes % 60;
    return TimeOfDay(hour: newHour, minute: newMinute);
  }

  bool _isTimeSlotUnavailable(TimeOfDay slotTime, int slotDuration) {
    try {
      int slotStartMinutes = slotTime.hour * 60 + slotTime.minute;
      int slotEndMinutes = slotStartMinutes + slotDuration;

      if (unavailableTimes.isEmpty) return false;

      for (var unavailable in unavailableTimes) {
        try {
          if (unavailable is! Map<String, dynamic>) continue;

          String? fromStr = unavailable['from']?.toString();
          String? toStr = unavailable['to']?.toString();

          if (fromStr != null &&
              toStr != null &&
              fromStr.isNotEmpty &&
              toStr.isNotEmpty) {
            TimeOfDay? fromTime = _parseTimeString(fromStr);
            TimeOfDay? toTime = _parseTimeString(toStr);

            if (fromTime != null && toTime != null) {
              int unavailableStartMinutes =
                  fromTime.hour * 60 + fromTime.minute;
              int unavailableEndMinutes = toTime.hour * 60 + toTime.minute;

              // Handle case where unavailable time spans midnight
              if (unavailableEndMinutes <= unavailableStartMinutes) {
                unavailableEndMinutes += 24 * 60;
              }

              // Check if slot is unavailable
              // A slot is unavailable ONLY if the slot START time is within an unavailable range
              // If slot starts before unavailable time but ends during it, it's still available
              // (because you can book it starting from the available time)
              bool slotStartsInRange =
                  slotStartMinutes >= unavailableStartMinutes &&
                      slotStartMinutes < unavailableEndMinutes;

              if (slotStartsInRange) {
                return true;
              }
            }
          }
        } catch (e) {
          print('Error checking unavailable time slot: $e');
          continue;
        }
      }
    } catch (e) {
      print('Error in _isTimeSlotUnavailable: $e');
    }

    return false;
  }

  // Check if selected date is today
  bool _isToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDayDate = DateTime(selectedDate.value!.year,
        selectedDate.value!.month, selectedDate.value!.day);
    return selectedDayDate.isAtSameMomentAs(today);
  }

  // Check if a time slot is in the past (for today's date)
  bool _isTimeSlotInPast(TimeOfDay slotTime, TimeOfDay currentTime) {
    int slotMinutes = slotTime.hour * 60 + slotTime.minute;
    int currentMinutes = currentTime.hour * 60 + currentTime.minute;

    // Time slot is in the past if it's before current time
    return slotMinutes < currentMinutes;
  }

  // Confirm booking (kept for backward compatibility, but now handled in selectTimeSlot)
  void confirmBooking() {
    Get.to(
      () => CartScreen(),
      binding: CartBinding(),
    );
  }
}
