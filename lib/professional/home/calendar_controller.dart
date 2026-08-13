import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../api/api_response.dart';
import '../../api/user_api_service.dart';
import '../../common/base_controller.dart';
import '../../models/bookings_list_model.dart';
import '../../utils/logger.dart';
import '../../services/notification_service.dart';
import '../../services/analytics_service.dart';
import '../../theme/colors.dart';
import '../../theme/hight_width_sizes.dart';
import '../../widgets/response_dialog.dart';
import 'home_controller.dart';

class ServiceFormatItem {
  final String id;
  final String name;
  final String duration;
  final String price;
  final bool isBundle;
  final String? offerText;

  ServiceFormatItem({
    required this.id,
    required this.name,
    required this.duration,
    required this.price,
    this.isBundle = false,
    this.offerText,
  });
}

class AvailabilityItem {
  final String id;
  final String availableFrom;
  final List<String> breakTimes;

  AvailabilityItem({
    required this.id,
    required this.availableFrom,
    required this.breakTimes,
  });
}

class CalendarController extends BaseController {
  CalendarController(this._userApiService);

  final UserApiService _userApiService;

  // Get NotificationService if available
  NotificationService? get _notificationService =>
      Get.isRegistered<NotificationService>()
          ? Get.find<NotificationService>()
          : null;

  // Get HomeController to access profile data
  HomeController? get _homeController =>
      Get.isRegistered<HomeController>() ? Get.find<HomeController>() : null;

  // Check if user is approved (from profile data) - reactive
  bool get isUserApproved {
    final profile = _homeController?.profileDetails.value;
    return profile?.isApproved ?? false;
  }

  // Observable for approval status to trigger UI updates
  bool get isUserApprovedObs {
    final profile = _homeController?.profileDetails.value;
    return profile?.isApproved ?? false;
  }

  final addToCalendar = false.obs;
  final selectedDate = DateTime.now().obs;
  final hasUserSelectedDate = false.obs;
  final dateScrollController = ScrollController();
  final showMonthView = false.obs;

  // Dummy service format data
  final serviceFormats = <ServiceFormatItem>[].obs;

  // Dummy availability data
  final availabilities = <AvailabilityItem>[].obs;

  // Upcoming booked sessions for the selected date
  final upcomingSessions = <SessionData>[].obs;

  // Store raw availability data for calendar events
  final rawAvailabilities = <Map<String, dynamic>>[].obs;

  // Get notification count from shared service
  int get notificationCount =>
      _notificationService?.notificationCount.value ?? 0;

  @override
  void onInit() {
    super.onInit();
    // Scroll to selected date after the widget is built
    ever(selectedDate, (_) {
      _scrollToSelectedDate();
      // Fetch service format and availability when date changes if not a guest
      if (_homeController != null && !_homeController!.isGuestUser()) {
        _fetchServiceFormatAvailability();
        loadBookingsList();
      }
    });
    // Also scroll on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
    // Fetch service format and availability for current date on init if not a guest
    if (_homeController != null && !_homeController!.isGuestUser()) {
      _fetchServiceFormatAvailability();
      loadBookingsList();
      // Load notification count from shared service
      _notificationService?.fetchNotificationCount();
    }
  }

  @override
  void onClose() {
    dateScrollController.dispose();
    super.onClose();
  }

  void _scrollToSelectedDate() {
    // Use WidgetsBinding to ensure the list is built before scrolling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!dateScrollController.hasClients) return;

      final dates = monthDates;
      final selected = selectedDate.value;
      final index = dates.indexWhere(
        (date) =>
            date.day == selected.day &&
            date.month == selected.month &&
            date.year == selected.year,
      );

      if (index >= 0) {
        // Calculate scroll position:
        // Item width (45) + left margin (2) + right margin (2) = 49
        // Separator width (1) between items
        // For index i, position = i * (49 + 1) = i * 50
        final itemWidth = HightWidthSizes.setValue_45 +
            HightWidthSizes.setValue_2 +
            HightWidthSizes.setValue_2;
        final separatorWidth = HightWidthSizes.setValue_1;
        final targetOffset = index * (itemWidth + separatorWidth);

        // Center the selected item in the viewport if possible
        final viewportWidth = dateScrollController.position.viewportDimension;
        final centeredOffset =
            targetOffset - (viewportWidth / 2) + (itemWidth / 2);
        final finalOffset = centeredOffset.clamp(
          0.0,
          dateScrollController.position.maxScrollExtent,
        );

        dateScrollController.animateTo(
          finalOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void toggleCalendarView() {
    showMonthView.toggle();

    // When switching back to week view, ensure the week strip scrolls
    // to the currently selected date. The previous scroll attempts may
    // have been skipped while the week view was offstage.
    if (!showMonthView.value) {
      _scrollToSelectedDate();
    }
  }

  void toggleAddToCalendar(bool? value) {
    addToCalendar.value = value ?? false;
  }

  void goToPreviousMonth() {
    selectedDate.value = _shiftMonth(-1);
  }

  void goToNextMonth() {
    selectedDate.value = _shiftMonth(1);
  }

  List<DateTime> get monthDates {
    final start = DateTime(
      selectedDate.value.year,
      selectedDate.value.month,
      1,
    );
    final daysInMonth = DateTime(start.year, start.month + 1, 0).day;
    return List.generate(
      daysInMonth,
      (index) => DateTime(start.year, start.month, index + 1),
    );
  }

  void selectDate(DateTime date) {
    hasUserSelectedDate.value = true;
    selectedDate.value = date;
    // Data will be fetched automatically by the ever() listener in onInit
  }

  /// Check if the selected date is in the past (before today)
  bool get isSelectedDatePast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(
      selectedDate.value.year,
      selectedDate.value.month,
      selectedDate.value.day,
    );
    return selected.isBefore(today);
  }

  /// Load upcoming bookings for the selected date
  Future<void> loadBookingsList({DateTime? date}) async {
    final targetDate = date ??
        (hasUserSelectedDate.value ? selectedDate.value : DateTime.now());

    await callDataService(
      _userApiService.getBookingsList(date: targetDate),
      onSuccess: (response) {
        try {
          if (response.data is Map<String, dynamic>) {
            final bookingsData = BookingsListData.fromJson(
              response.data as Map<String, dynamic>,
            );

            if (bookingsData.upcomingBookings?.items != null &&
                bookingsData.upcomingBookings!.items!.isNotEmpty) {
              upcomingSessions.assignAll(
                bookingsData.upcomingBookings!.items!
                    .map((booking) => _convertBookingToSession(booking))
                    .toList(),
              );
            } else {
              upcomingSessions.clear();
            }
          }
        } catch (e, stackTrace) {
          logError('Error parsing bookings response',
              error: e, stackTrace: stackTrace);
        }
      },
      onError: (error, stack) {
        logError('Failed to load bookings', error: error, stackTrace: stack);
      },
    );
  }

  SessionData _convertBookingToSession(BookingItem booking) {
    final userId = booking.userId;
    String timeRange = '';
    String dateLabel = '';

    if (booking.bookingTimeRange != null &&
        booking.bookingTimeRange!.isNotEmpty) {
      try {
        final parts = booking.bookingTimeRange!.split(' - ');
        if (parts.length == 2) {
          final startPart = parts[0].trim();
          final endPart = parts[1].trim();
          final startParts = startPart.split(' ');
          if (startParts.length >= 3) {
            final startTime =
                '${startParts[startParts.length - 2]} ${startParts[startParts.length - 1]}';
            timeRange = '$startTime - $endPart';

            final dateStr = startParts[0];
            final dateParts = dateStr.split('/');
            if (dateParts.length == 3) {
              try {
                final day = int.parse(dateParts[0]);
                final month = int.parse(dateParts[1]);
                final year = int.parse(dateParts[2]);
                const months = [
                  'January',
                  'February',
                  'March',
                  'April',
                  'May',
                  'June',
                  'July',
                  'August',
                  'September',
                  'October',
                  'November',
                  'December',
                ];
                dateLabel = '$day ${months[month - 1]} $year';
              } catch (e) {
                dateLabel = dateStr;
              }
            }
          }
        }
      } catch (e) {
        // Fall through to other parsing methods
      }
    }

    if (timeRange.isEmpty && booking.localEnd != null) {
      try {
        final parts = booking.localEnd!.split(' ');
        if (parts.length == 2) {
          final timePart = parts[1];
          if (booking.serviceFormatSnapshot?.durationMinutes != null) {
            final duration = booking.serviceFormatSnapshot!.durationMinutes!;
            final endTimeParts = timePart.split(':');
            if (endTimeParts.length == 2) {
              final endHour = int.parse(endTimeParts[0]);
              final endMinute = int.parse(endTimeParts[1]);
              final endTotalMinutes = endHour * 60 + endMinute;
              final startTotalMinutes = endTotalMinutes - duration;
              final startHour = (startTotalMinutes ~/ 60) % 24;
              final startMinute = startTotalMinutes % 60;
              final startTime = _formatTime12Hour(startHour, startMinute);
              final endTime = _formatTime12Hour(endHour, endMinute);
              timeRange = '$startTime - $endTime';
            } else {
              timeRange = timePart;
            }
          } else {
            final timeParts = timePart.split(':');
            if (timeParts.length == 2) {
              final hour = int.parse(timeParts[0]);
              final minute = int.parse(timeParts[1]);
              timeRange = _formatTime12Hour(hour, minute);
            } else {
              timeRange = timePart;
            }
          }
        }
      } catch (e) {
        if (booking.bookingStart != null && booking.bookingEnd != null) {
          try {
            final start = DateTime.parse(booking.bookingStart!);
            final end = DateTime.parse(booking.bookingEnd!);
            final startLocal = start.toLocal();
            final endLocal = end.toLocal();
            final startTime =
                _formatTime12Hour(startLocal.hour, startLocal.minute);
            final endTime = _formatTime12Hour(endLocal.hour, endLocal.minute);
            timeRange = '$startTime - $endTime';
          } catch (e2) {
            timeRange = 'Time unavailable';
          }
        }
      }
    } else if (booking.bookingStart != null && booking.bookingEnd != null) {
      try {
        final start = DateTime.parse(booking.bookingStart!);
        final end = DateTime.parse(booking.bookingEnd!);
        final startLocal = start.toLocal();
        final endLocal = end.toLocal();
        final startTime = _formatTime12Hour(startLocal.hour, startLocal.minute);
        final endTime = _formatTime12Hour(endLocal.hour, endLocal.minute);
        timeRange = '$startTime - $endTime';
      } catch (e) {
        timeRange = 'Time unavailable';
      }
    }

    if (timeRange.isEmpty) {
      timeRange = 'Time unavailable';
    }

    if (dateLabel.isEmpty && booking.bookingDateLocal != null) {
      try {
        final parsedDate = DateTime.parse(booking.bookingDateLocal!);
        const months = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ];
        dateLabel =
            '${parsedDate.day} ${months[parsedDate.month - 1]} ${parsedDate.year}';
      } catch (e) {
        dateLabel = booking.bookingDateLocal ?? '';
      }
    }

    final serviceName = booking.serviceFormatSnapshot?.name ?? 'Session';

    return SessionData(
      id: booking.id ?? '',
      title: serviceName,
      name: booking.userName ?? 'Client',
      timeRange: timeRange,
      dateLabel: dateLabel,
      isInProgress: booking.status == 'in_progress',
      durationMinutes: booking.serviceFormatSnapshot?.durationMinutes,
      userId: userId,
    );
  }

  String _formatTime12Hour(int hour24, int minute) {
    final hour12 = hour24 == 0
        ? 12
        : hour24 > 12
            ? hour24 - 12
            : hour24;
    final period = hour24 < 12 ? 'AM' : 'PM';
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hour12:$minuteStr $period';
  }

  /// Format date to DD/MM/YYYY format
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format time range from available_from and available_until
  String _formatTimeRange(String from, String until) {
    if (from.isEmpty && until.isEmpty) return '';
    if (from.isEmpty) return _formatTime(until);
    if (until.isEmpty) return _formatTime(from);
    return '${_formatTime(from)} - ${_formatTime(until)}';
  }

  /// Format time from 24-hour format (HH:mm) to 12-hour format with AM/PM
  String _formatTime(String time24) {
    if (time24.isEmpty) return '';
    try {
      // Parse 24-hour format (e.g., "09:00", "17:00")
      final parts = time24.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;

        // Convert to 12-hour format
        final period = hour >= 12 ? 'PM' : 'AM';
        int hour12;
        if (hour == 0) {
          hour12 = 12; // 0:00 becomes 12:00 AM
        } else if (hour > 12) {
          hour12 = hour - 12; // 13-23 becomes 1-11 PM
        } else {
          hour12 = hour; // 1-12 stays as is
        }

        final hour12Str = hour12.toString().padLeft(2, '0');
        final minuteStr = minute.toString().padLeft(2, '0');

        return '$hour12Str:$minuteStr $period';
      }
      return time24;
    } catch (e) {
      return time24;
    }
  }

  /// Format unavailable_times array into list of break time strings
  List<String> _formatBreakTimes(dynamic unavailableTimes) {
    if (unavailableTimes == null) return [];

    try {
      if (unavailableTimes is List && unavailableTimes.isNotEmpty) {
        final breakTimeStrings = unavailableTimes
            .map((breakTime) {
              if (breakTime is Map<String, dynamic>) {
                final from = breakTime['from']?.toString() ?? '';
                final to = breakTime['to']?.toString() ?? '';
                if (from.isNotEmpty && to.isNotEmpty) {
                  return '${_formatTime(from)} - ${_formatTime(to)}';
                } else if (from.isNotEmpty) {
                  return _formatTime(from);
                }
              }
              return null;
            })
            .whereType<String>()
            .toList();

        return breakTimeStrings;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Public method to refresh service format and availability data
  Future<void> refreshServiceFormatAvailability() async {
    await _fetchServiceFormatAvailability();
  }

  /// Fetch service format and availability for the selected date
  Future<void> _fetchServiceFormatAvailability() async {
    final dateString = _formatDate(selectedDate.value);

    await callDataService(
      _userApiService.getServiceFormatAvailability(date: dateString),
      onSuccess: (ApiResponse<dynamic> response) {
        if (response.success && response.data != null) {
          _parseApiResponse(response.data);
        }
      },
      onError: (error, stack) {
        // Error is already handled by callDataService
        // You can add custom error handling here if needed
      },
    );
  }

  /// Parse API response and update serviceFormats and availabilities
  void _parseApiResponse(dynamic data) {
    try {
      // Handle different response structures
      Map<String, dynamic>? dataMap;

      if (data is Map<String, dynamic>) {
        // Check if data is nested under 'data' key
        if (data['data'] is Map<String, dynamic>) {
          dataMap = data['data'] as Map<String, dynamic>;
        } else {
          dataMap = data;
        }
      }

      if (dataMap != null) {
        // Update service formats if present in response
        List<dynamic>? serviceFormatsList;

        if (dataMap['service_formats'] is List) {
          serviceFormatsList = dataMap['service_formats'] as List;
        } else if (dataMap['serviceFormats'] is List) {
          serviceFormatsList = dataMap['serviceFormats'] as List;
        } else if (dataMap['service_format'] is List) {
          serviceFormatsList = dataMap['service_format'] as List;
        }

        // If service_formats is present in response (even if empty), update the list
        if (serviceFormatsList != null) {
          if (serviceFormatsList.isEmpty) {
            // Clear dummy data if API returns empty array
            serviceFormats.clear();
          } else {
            final formats = serviceFormatsList
                .map((item) {
                  if (item is Map<String, dynamic>) {
                    // Extract name from nested service_format_id
                    String name = '';
                    if (item['service_format_id'] is Map<String, dynamic>) {
                      final serviceFormatId =
                          item['service_format_id'] as Map<String, dynamic>;
                      name = serviceFormatId['name']?.toString() ?? '';
                    }
                    // Fallback to direct name field if nested structure not found
                    if (name.isEmpty) {
                      name = item['name']?.toString() ??
                          item['service_format_name']?.toString() ??
                          '';
                    }

                    // Check if this is a bundle
                    final isBundle = item['is_bundle'] == true;

                    // Extract duration from duration_minutes
                    // For bundles, show per session duration
                    String duration = '';
                    if (isBundle) {
                      // Bundle format: show "Per session: X mins" if duration_minutes exists
                      if (item['duration_minutes'] != null) {
                        final minutes = item['duration_minutes'];
                        if (minutes is int) {
                          // Convert 60 minutes to "1 hour"
                          if (minutes == 60) {
                            duration = '1 hour';
                          } else {
                            duration = '$minutes mins';
                          }
                        } else if (minutes is String) {
                          final minutesInt = int.tryParse(minutes);
                          if (minutesInt != null && minutesInt == 60) {
                            duration = '1 hour';
                          } else {
                            duration = '$minutes mins';
                          }
                        } else {
                          duration = minutes.toString();
                        }
                      } else if (item['bundle_of'] != null) {
                        // Fallback to bundle info if no duration
                        final bundleOf = item['bundle_of'];
                        if (bundleOf is int) {
                          duration = 'Bundle of $bundleOf';
                        } else {
                          duration = 'Bundle of ${bundleOf.toString()}';
                        }
                      }
                    } else if (item['duration_minutes'] != null) {
                      // Regular service format with duration
                      final minutes = item['duration_minutes'];
                      if (minutes is int) {
                        // Convert 60 minutes to "1 hour"
                        if (minutes == 60) {
                          duration = '1 hour';
                        } else {
                          duration = '$minutes mins';
                        }
                      } else if (minutes is String) {
                        final minutesInt = int.tryParse(minutes);
                        if (minutesInt != null && minutesInt == 60) {
                          duration = '1 hour';
                        } else {
                          duration = '$minutes mins';
                        }
                      } else {
                        duration = minutes.toString();
                      }
                    } else if (item['duration'] != null) {
                      duration = item['duration'].toString();
                    }

                    // Extract price (can be number or string)
                    // For bundles, use bundle_price instead of price
                    String price = '';
                    if (isBundle && item['bundle_price'] != null) {
                      // Bundle price
                      final bundlePrice = item['bundle_price'];
                      if (bundlePrice is num) {
                        price = '£$bundlePrice';
                      } else {
                        price = bundlePrice.toString();
                      }
                    } else if (item['price'] != null) {
                      // Regular price
                      if (item['price'] is num) {
                        price = '£${item['price']}';
                      } else {
                        price = item['price'].toString();
                      }
                    }

                    // Extract offer_text for bundles
                    String? offerText;
                    if (isBundle && item['offer_text'] != null) {
                      offerText = item['offer_text'].toString();
                    }

                    return ServiceFormatItem(
                      id: item['id']?.toString() ??
                          item['_id']?.toString() ??
                          '',
                      name: name,
                      duration: duration,
                      price: price,
                      isBundle: isBundle,
                      offerText: offerText,
                    );
                  }
                  return null;
                })
                .whereType<ServiceFormatItem>()
                .toList();

            if (formats.isNotEmpty) {
              serviceFormats.value = formats;

              // Get professional details from HomeController
              final profile = _homeController?.profileDetails.value;
              final professionalId = profile?.professionTypeId ?? '';
              final professionalName = profile?.profession_name ?? '';

              // Analytics: Log service format list view
              final analyticsItems = formats
                  .map(
                    (format) => AnalyticsService.instance.buildItem(
                      itemId: format.id.isNotEmpty ? format.id : '',
                      itemName: professionalName.isNotEmpty
                          ? professionalName
                          : (format.name.isNotEmpty ? format.name : ''),
                      itemCategory: professionalName.isNotEmpty
                          ? professionalName
                          : 'service_format',
                      itemCategory2: format.name,
                      itemVariant: format.isBundle ? 'bundle' : 'standard',
                      price: double.tryParse(format.price
                              .replaceAll(RegExp(r'[^0-9.]'), '')) ??
                          0.0,
                      quantity: 1,
                    ),
                  )
                  .toList();

              AnalyticsService.instance.logViewItemListEvent(
                items: analyticsItems,
                itemListId:
                    professionalId.isNotEmpty ? professionalId : 'unknown',
                itemListName:
                    professionalName.isNotEmpty ? professionalName : 'unknown',
                currency: 'GBP',
                screenName: 'ProfessionalCalendarScreen',
                screenClass: 'CalendarTab',
                pageCategory: 'calendar',
              );
            }
          }
        }

        // Update availabilities if present in response
        List<dynamic>? availabilitiesList;

        if (dataMap['availabilities'] is List) {
          availabilitiesList = dataMap['availabilities'] as List;
        } else if (dataMap['availability'] is List) {
          availabilitiesList = dataMap['availability'] as List;
        }

        // If availability is present in response (even if empty), update the list
        if (availabilitiesList != null) {
          if (availabilitiesList.isEmpty) {
            // Only clear the selected-date list; keep month calendar dots.
            availabilities.clear();
          } else {
            _mergeRawAvailabilities(
              availabilitiesList.whereType<Map<String, dynamic>>().toList(),
            );

            final availList = availabilitiesList
                .map((item) {
                  if (item is Map<String, dynamic>) {
                    // Format available from/until into a range
                    final availableFrom =
                        item['available_from']?.toString() ?? '';
                    final availableUntil =
                        item['available_until']?.toString() ?? '';
                    final availableFromFormatted =
                        _formatTimeRange(availableFrom, availableUntil);

                    // Format unavailable_times into break time list
                    final unavailableTimes = item['unavailable_times'];
                    final breakTimesList = _formatBreakTimes(unavailableTimes);

                    return AvailabilityItem(
                      id: item['id']?.toString() ??
                          item['_id']?.toString() ??
                          '',
                      availableFrom: availableFromFormatted,
                      breakTimes: breakTimesList,
                    );
                  }
                  return null;
                })
                .whereType<AvailabilityItem>()
                .toList();

            if (availList.isNotEmpty) {
              availabilities.value = availList;
            }
          }
        }
      }
    } catch (e) {
      // Handle parsing errors - keep existing dummy data
      debugPrint('Error parsing API response: $e');
    }
  }

  DateTime _shiftMonth(int delta) {
    final current = selectedDate.value;
    final target = DateTime(current.year, current.month + delta, 1);
    final daysInTargetMonth = DateTime(target.year, target.month + 1, 0).day;
    final clampedDay = current.day.clamp(1, daysInTargetMonth);
    return DateTime(target.year, target.month, clampedDay);
  }

  String getMonthYearText() {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[selectedDate.value.month - 1]} ${selectedDate.value.year}';
  }

  /// Green = has availability, Red = not available.
  List<Color> getEventColorsForDate(DateTime date) {
    rawAvailabilities.length;

    final hasAvailability = rawAvailabilities.any(
      (availability) => _isDateInAvailability(date, availability),
    );

    return [
      hasAvailability ? AppColor.greenText : AppColor.color_E74C3C,
    ];
  }

  /// Whether the professional has availability on [date].
  bool hasAvailabilityOnDate(DateTime date) {
    rawAvailabilities.length;
    return rawAvailabilities.any(
      (availability) => _isDateInAvailability(date, availability),
    );
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

  /// Delete service format by ID
  Future<void> deleteServiceFormat(String id) async {
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.deleteServiceFormat(id: id),
      showLoader: true,
      onSuccess: (ApiResponse<dynamic> response) {
        if (response.success) {
          // Remove the service format from the list
          serviceFormats.removeWhere((item) => item.id == id);
          // Refresh the data to ensure consistency
          _fetchServiceFormatAvailability();
          // Show success message
          showResponseDialog(
            message: response.message ?? 'Service format deleted successfully',
            title: 'Success',
            isError: false,
            showButton: false,
          );
        } else {
          // Show error message
          showResponseDialog(
            title: 'Error',
            message: response.errorMessage.isNotEmpty
                ? response.errorMessage
                : 'Failed to delete service format',
            isError: true,
            showButton: true,
          );
        }
      },
      onError: (error, stack) {
        // Show error message
        showResponseDialog(
          title: 'Error',
          message: 'Failed to delete service format. Please try again.',
          isError: true,
          showButton: true,
        );
      },
    );
  }

  /// Delete availability by ID
  Future<void> deleteAvailability(String id) async {
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.deleteAvailability(id: id),
      showLoader: true,
      onSuccess: (ApiResponse<dynamic> response) {
        if (response.success) {
          // Remove the availability from the list
          availabilities.removeWhere((item) => item.id == id);
          // Also remove from raw availabilities
          rawAvailabilities.removeWhere((item) {
            final itemId =
                item['id']?.toString() ?? item['_id']?.toString() ?? '';
            return itemId == id;
          });
          // Refresh the data to ensure consistency
          _fetchServiceFormatAvailability();
          // Show success message
          showResponseDialog(
            message: response.message ?? 'Availability deleted successfully',
            title: 'Success',
            isError: false,
            showButton: false,
          );
        } else {
          // Show error message
          showResponseDialog(
            title: 'Error',
            message: response.errorMessage.isNotEmpty
                ? response.errorMessage
                : 'Failed to delete availability',
            isError: true,
            showButton: true,
          );
        }
      },
      onError: (error, stack) {
        // Show error message
        showResponseDialog(
          title: 'Error',
          message: 'Failed to delete availability. Please try again.',
          isError: true,
          showButton: true,
        );
      },
    );
  }

  /// Fetch notification count (delegates to shared service)
  Future<void> fetchNotificationCount() async {
    await _notificationService?.fetchNotificationCount();
  }

  /// Check if a date falls within an availability range
  bool _isDateInAvailability(DateTime date, Map<String, dynamic> availability) {
    try {
      // Parse start_date
      final startDateStr = availability['start_date']?.toString();
      if (startDateStr == null) return false;

      final startDate = startDateStr.contains('T')
          ? DateTime.parse(startDateStr)
          : DateFormat('yyyy-MM-dd').parse(startDateStr);

      // Normalize dates to compare only date part
      final checkDate = DateTime(date.year, date.month, date.day);
      final normalizedStartDate =
          DateTime(startDate.year, startDate.month, startDate.day);

      // Check repeat pattern
      final repeat = availability['repeat']?.toString() ?? '';
      final repeatUntilStr = availability['repeat_until']?.toString();
      final excludeWeekends = availability['exclude_weekends'] == true;
      // Note: exclude_public_holidays is available but not implemented yet
      // final excludePublicHolidays = availability['exclude_public_holidays'] == true;
      final isActive = availability['is_active'];

      // Check if availability is active (default to true if not specified)
      if (isActive == false) return false;

      // Check if date is before start date
      if (checkDate.isBefore(normalizedStartDate)) return false;

      // Parse repeat_until if exists
      if (repeatUntilStr != null && repeatUntilStr.isNotEmpty) {
        final repeatUntil = repeatUntilStr.contains('T')
            ? DateTime.parse(repeatUntilStr)
            : DateFormat('yyyy-MM-dd').parse(repeatUntilStr);
        final normalizedRepeatUntil =
            DateTime(repeatUntil.year, repeatUntil.month, repeatUntil.day);
        if (checkDate.isAfter(normalizedRepeatUntil)) return false;
      }

      // Check if date matches repeat pattern
      bool matchesRepeat = false;

      switch (repeat.toLowerCase()) {
        case 'daily':
          matchesRepeat = true;
          break;
        case 'weekly':
          matchesRepeat = checkDate.weekday == normalizedStartDate.weekday;
          break;
        case 'monthly':
          matchesRepeat = checkDate.day == normalizedStartDate.day;
          break;
        case "don't repeat":
        case "dont repeat":
          matchesRepeat = checkDate.isAtSameMomentAs(normalizedStartDate);
          break;
        default:
          // If repeat is not specified or unknown, check if it's the start date
          matchesRepeat = checkDate.isAtSameMomentAs(normalizedStartDate);
      }

      if (!matchesRepeat) return false;

      // Check exclude weekends
      if (excludeWeekends) {
        final weekday = checkDate.weekday;
        if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
          return false;
        }
      }

      // Note: exclude_public_holidays check would require a public holidays list
      // For now, we'll skip this check

      return true;
    } catch (e) {
      debugPrint('Error checking date in availability: $e');
      return false;
    }
  }
}
