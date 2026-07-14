import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:verithrive_dev/enduser/screens/filter/professional/ProfessionalController.dart';
import 'package:verithrive_dev/professional/home/profile_controller.dart';

import '../../api/dio_client.dart';
import '../../api/user_api_service.dart';
import '../../common/base_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/storage_service.dart';
import '../../services/firebase_token_service.dart';
import '../../services/foreground_notification_service.dart';
import '../../services/notification_permission_service.dart';
import '../../services/notification_service.dart';
import '../../services/socket_service.dart';
import '../../theme/colors.dart';
import '../../theme/font_sizes.dart';
import '../../theme/fonts.dart';
import '../../theme/hight_width_sizes.dart';
import '../../utils/device_info_helper.dart';
import '../../utils/logger.dart';
import '../../models/bookings_list_model.dart';
import '../../models/profile_details_model.dart';
import '../../widgets/response_dialog.dart';
import '../signup_terms_conditions/professional_webview_screen.dart';
import '../strip_account_create/strip_account_create_webview.dart';
import 'home_model.dart';
import 'messages_controller.dart';

class HomeController extends BaseController {
  HomeController(this._api);

  // ignore: unused_field
  final DioClient _api;

  final NotificationPermissionService _notificationPermissionService =
      NotificationPermissionService();

  // Get UserApiService if available
  UserApiService? get _userApiService =>
      Get.isRegistered<UserApiService>() ? Get.find<UserApiService>() : null;

  // Get NotificationService if available
  NotificationService? get _notificationService =>
      Get.isRegistered<NotificationService>()
          ? Get.find<NotificationService>()
          : null;

  final greeting = 'Welcome to Verithrive'.obs;
  final items = <HomeItem>[].obs;
  final currentIndex = 0.obs;
  final addToCalendar = false.obs;
  final selectedDate = DateTime.now().obs;
  final hasUserSelectedDate = false.obs;
  final dateScrollController = ScrollController();
  final showMonthView = false.obs;

  // Session management
  final upcomingSessions = <SessionData>[].obs;
  final cancelledSessions = <SessionData>[].obs;
  final pastSessions = <SessionData>[].obs;

  /// Date key (`yyyy-MM-dd`) → whether that day has any booking.
  final bookingPresenceByDate = <String, bool>{}.obs;
  bool _isLoadingMonthBookingDots = false;

  // Profile details
  final profileDetails = Rxn<ProfileDetailsModel>();
  bool _stripeOnboardingDialogShown = false;
  bool _approvalDialogShown = false;
  bool _subscriptionDialogShown = false;
  bool _didAuthenticatedStartup = false;
  bool _scheduledAuthStartupRetry = false;

  // Get notification count from shared service
  int get notificationCount =>
      _notificationService?.notificationCount.value ?? 0;

  // Get SocketService if available
  SocketService? get _socketService =>
      Get.isRegistered<SocketService>() ? Get.find<SocketService>() : null;

  @override
  void onInit() {
    super.onInit();
    _maybeStartAuthenticatedFlows();
    // Clear all sessions initially
    upcomingSessions.clear();
    cancelledSessions.clear();
    pastSessions.clear();
    // loadItems();
    // Scroll to selected date after the widget is built
    ever(selectedDate, (_) => _scrollToSelectedDate());
    // Reload bookings when date changes (only if user has selected a date and not a guest)
    ever(selectedDate, (_) {
      if (hasUserSelectedDate.value && !_isGuestUser()) {
        loadBookingsList();
      }
    });
    // Also scroll on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
  }

  @override
  void onReady() {
    super.onReady();
    _maybeStartAuthenticatedFlows();
    _notificationPermissionService.ensurePermissionAfterFirstScreen().then((_) {
      if (!_isGuestUser()) {
        updateDeviceToken();
      }
    });
    // Handle pending notification if app was opened from terminated state via notification
    // This ensures proper navigation stack: Splash -> Home -> Chat
    _handlePendingNotification();
  }

  void _maybeStartAuthenticatedFlows() {
    if (_didAuthenticatedStartup) return;
    if (!Get.isRegistered<StorageService>()) {
      if (!_scheduledAuthStartupRetry) {
        _scheduledAuthStartupRetry = true;
        Future.delayed(
          const Duration(milliseconds: 200),
          _maybeStartAuthenticatedFlows,
        );
      }
      return;
    }

    if (_isGuestUser()) return;

    _didAuthenticatedStartup = true;

    loadProfileDetails(showStripeDialog: true);
    updateDeviceToken();
    loadBookingsList();
    loadMonthBookingDots();
    _notificationService?.fetchNotificationCount();
    _connectSocket();
  }

  /// Handle pending notification from app launch (terminated state)
  /// This is called after Home is fully ready to ensure proper navigation stack
  void _handlePendingNotification() {
    // Use a small delay to ensure Home is fully rendered
    Future.delayed(const Duration(milliseconds: 300), () {
      ForegroundNotificationService.handlePendingNotificationIfAny();
    });
  }

  /// Cancel a booking session
  ///
  /// [sessionId] - The booking ID to cancel
  Future<void> cancelSession(String sessionId) async {
    final apiService = _userApiService;
    if (apiService == null) {
      logError('UserApiService not available');
      return;
    }

    final session = upcomingSessions.firstWhereOrNull((s) => s.id == sessionId);
    if (session == null) {
      logError('Session not found: $sessionId');
      return;
    }

    await callDataService(
      apiService.cancelBooking(bookingId: sessionId),
      onSuccess: (response) {
        // Move session from upcoming to cancelled on successful API call
        upcomingSessions.remove(session);
        cancelledSessions.add(SessionData(
          id: session.id,
          title: session.title,
          name: session.name,
          timeRange: session.timeRange,
          dateLabel: session.dateLabel,
          isCancelled: true,
          isPasted: session.isPasted,
          durationMinutes: session.durationMinutes,
        ));
        logInfo('Booking cancelled successfully: $sessionId');
      },
      onError: (error, stack) {
        logError('Failed to cancel booking', error: error, stackTrace: stack);
      },
    );
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

  void onTabSelected(int index) {
    // If the tab is already selected, don't do anything to avoid redundant API calls and loaders
    if (currentIndex.value == index) {
      return;
    }

    // Check if user is a guest
    final isGuest = _isGuestUser();

    // If any tab except Home (index 0) is selected, and user is a guest,
    // redirect to login (except maybe Messages which we might handle differently)
    if (isGuest && index != 0) {
      if (Get.currentRoute != Routes.login) {
        Get.toNamed(Routes.login);
      }
      return;
    }

    if (index == 2) {
      // Check and reconnect socket when Messages tab is selected
      print('Messages tab selected - checking socket connection');
      if (Get.isRegistered<MessagesController>()) {
        final messagesController = Get.find<MessagesController>();
        messagesController.checkAndReconnectSocket();
        print('Messages tab selected - Get.isRegistered<MessagesController>');
      }
    }

    currentIndex(index);

    // Only load profile details if not a guest
    if (!isGuest) {
      if (index == 3) {
        if (Get.isRegistered<ProfileController>()) {
          final profileController = Get.find<ProfileController>();
          profileController.fetchProfileDetails(showStripeDialog: true);
        }
      } else if (index == 0 || index == 1) {
        // Only refresh profile details when switching to Home tab
        loadProfileDetails();
      }
    }
  }

  /// Check if the current user is a guest (no access token)
  bool isGuestUser() {
    if (!Get.isRegistered<StorageService>()) {
      return true; // No storage service means guest
    }
    final storage = Get.find<StorageService>();
    final token = storage.readString('access_token');
    return token == null || token.isEmpty;
  }

  // Backwards compatibility for internal calls
  bool _isGuestUser() => isGuestUser();

  void toggleCalendarView() {
    showMonthView.toggle();

    // When switching back to week view, ensure the week strip scrolls
    // to the currently selected date. The previous scroll attempts may
    // have been skipped while the week view was offstage.
    if (!showMonthView.value) {
      _scrollToSelectedDate();
    } else if (!_isGuestUser()) {
      loadMonthBookingDots();
    }
  }

  void toggleAddToCalendar(bool? value) {
    addToCalendar.value = value ?? false;
  }

  void goToPreviousMonth() {
    hasUserSelectedDate.value = true;
    selectedDate.value = _shiftMonth(-1);
    // loadBookingsList() will be called automatically via ever(selectedDate) listener
    if (!_isGuestUser()) {
      loadMonthBookingDots();
    }
  }

  void goToNextMonth() {
    hasUserSelectedDate.value = true;
    selectedDate.value = _shiftMonth(1);
    // loadBookingsList() will be called automatically via ever(selectedDate) listener
    if (!_isGuestUser()) {
      loadMonthBookingDots();
    }
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
    // Fetch bookings for the selected date if not a guest
    if (!_isGuestUser()) {
      loadBookingsList();
    }
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

  /// Load bookings list for the selected date (or current date if not selected)
  ///
  /// Uses the currently selected date or current date, and current timezone
  Future<void> loadBookingsList({DateTime? date}) async {
    final apiService = _userApiService;
    if (apiService == null) {
      logError('UserApiService not available');
      return;
    }

    // Use provided date, selected date, or current date
    final targetDate = date ??
        (hasUserSelectedDate.value ? selectedDate.value : DateTime.now());

    await callDataService(
      apiService.getBookingsList(date: targetDate),
      showLoader: true,
      onSuccess: (response) {
        try {
          // Parse the response using the model
          // response.data is already the inner 'data' object from the API response
          if (response.data is Map<String, dynamic>) {
            final bookingsData = BookingsListData.fromJson(
              response.data as Map<String, dynamic>,
            );

            // Update upcoming sessions
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

            // Update cancelled sessions
            if (bookingsData.cancelledBookings?.items != null &&
                bookingsData.cancelledBookings!.items!.isNotEmpty) {
              cancelledSessions.assignAll(
                bookingsData.cancelledBookings!.items!
                    .map((booking) => _convertBookingToSession(
                          booking,
                          isCancelled: true,
                        ))
                    .toList(),
              );
            } else {
              cancelledSessions.clear();
            }

            // Update past sessions
            if (bookingsData.pastBookings?.items != null &&
                bookingsData.pastBookings!.items!.isNotEmpty) {
              pastSessions.assignAll(
                bookingsData.pastBookings!.items!
                    .map((booking) => _convertBookingToSession(
                          booking,
                          isPasted: true,
                        ))
                    .toList(),
              );
            } else {
              pastSessions.clear();
            }

            _setBookingPresence(
              targetDate,
              _hasAnyBooking(bookingsData),
            );

            logInfo(
              'Bookings loaded: ${bookingsData.upcomingBookings?.total ?? 0} upcoming, '
              '${bookingsData.cancelledBookings?.total ?? 0} cancelled, '
              '${bookingsData.pastBookings?.total ?? 0} past',
            );
            logInfo(
              'Displaying: ${upcomingSessions.length} upcoming sessions, '
              '${cancelledSessions.length} cancelled sessions, '
              '${pastSessions.length} past sessions',
            );
          } else {
            logError(
                'Response data is not a Map: ${response.data?.runtimeType}');
            logError('Response data: ${response.data}');
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

  String _bookingDateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  bool _hasAnyBooking(BookingsListData data) {
    return (data.upcomingBookings?.items?.isNotEmpty ?? false) ||
        (data.cancelledBookings?.items?.isNotEmpty ?? false) ||
        (data.pastBookings?.items?.isNotEmpty ?? false);
  }

  void _setBookingPresence(DateTime date, bool hasBooking) {
    bookingPresenceByDate[_bookingDateKey(date)] = hasBooking;
    bookingPresenceByDate.refresh();
  }

  bool _isTodayOrFuture(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    return !dateOnly.isBefore(today);
  }

  /// Green = booking exists, Red = no booking.
  /// Dots are only shown for today and future dates.
  List<Color> getEventColorsForDate(DateTime date) {
    bookingPresenceByDate.length;
    if (!_isTodayOrFuture(date)) return const <Color>[];

    final hasBooking = bookingPresenceByDate[_bookingDateKey(date)] == true;
    return [
      hasBooking ? AppColor.greenText : AppColor.color_E74C3C,
    ];
  }

  /// Whether any booking exists on [date] (today/future only).
  bool hasBookingOnDate(DateTime date) {
    bookingPresenceByDate.length;
    if (!_isTodayOrFuture(date)) return false;
    return bookingPresenceByDate[_bookingDateKey(date)] == true;
  }

  /// Whether a booking status dot should be shown for [date].
  bool shouldShowBookingDot(DateTime date) => _isTodayOrFuture(date);

  /// Prefetch booking presence for today + future days in the visible month.
  Future<void> loadMonthBookingDots({DateTime? month}) async {
    if (_isGuestUser() || _isLoadingMonthBookingDots) return;

    final apiService = _userApiService;
    if (apiService == null) return;

    final reference = month ?? selectedDate.value;
    final daysInMonth = DateTime(reference.year, reference.month + 1, 0).day;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _isLoadingMonthBookingDots = true;

    try {
      final datesToLoad = <DateTime>[];
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(reference.year, reference.month, day);
        if (!date.isBefore(today)) {
          datesToLoad.add(date);
        }
      }

      if (datesToLoad.isEmpty) return;

      await Future.wait(
        datesToLoad.map((date) async {
          try {
            final response = await apiService.getBookingsList(date: date);
            if (response.success && response.data is Map<String, dynamic>) {
              final bookingsData = BookingsListData.fromJson(
                response.data as Map<String, dynamic>,
              );
              _setBookingPresence(date, _hasAnyBooking(bookingsData));
            } else {
              _setBookingPresence(date, false);
            }
          } catch (e) {
            logError('Failed to load booking dot for $date', error: e);
          }
        }),
      );
    } finally {
      _isLoadingMonthBookingDots = false;
    }
  }

  /// Convert BookingItem to SessionData
  SessionData _convertBookingToSession(BookingItem booking,
      {bool isCancelled = false, bool isPasted = false}) {
    // Get user ID from booking
    final userId = booking.userId;
    // Format time range - prefer booking_time_range if available
    String timeRange = '';
    String dateLabel = '';

    // First, try to use booking_time_range format: "06/01/2026 07:00 PM - 08:00 PM"
    if (booking.bookingTimeRange != null &&
        booking.bookingTimeRange!.isNotEmpty) {
      try {
        final parts = booking.bookingTimeRange!.split(' - ');
        if (parts.length == 2) {
          // Extract time range (already formatted)
          final startPart = parts[0].trim(); // "06/01/2026 07:00 PM"
          final endPart = parts[1].trim(); // "08:00 PM"

          // Extract date and time from start part
          final startParts = startPart.split(' ');
          if (startParts.length >= 3) {
            // Extract time from start: "07:00 PM"
            final startTime =
                '${startParts[startParts.length - 2]} ${startParts[startParts.length - 1]}';
            // End time already has format: "08:00 PM"
            timeRange = '$startTime - $endPart';

            // Extract date: "06/01/2026"
            final dateStr = startParts[0];
            // Parse date and format for dateLabel
            final dateParts = dateStr.split('/');
            if (dateParts.length == 3) {
              try {
                final day = int.parse(dateParts[0]);
                final month = int.parse(dateParts[1]);
                final year = int.parse(dateParts[2]);
                final months = [
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
                  'December'
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

    // If booking_time_range wasn't available or parsing failed, try other methods
    if (timeRange.isEmpty && booking.localEnd != null) {
      // local_end format: '2026-01-01 09:15'
      try {
        final parts = booking.localEnd!.split(' ');
        if (parts.length == 2) {
          final timePart = parts[1]; // '09:15'
          // Calculate start time from end time and duration
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
            // Parse timePart and format in 12-hour
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
        // Fallback to parsing UTC times
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
      // Fallback: parse UTC times and convert to local
      try {
        final start = DateTime.parse(booking.bookingStart!);
        final end = DateTime.parse(booking.bookingEnd!);
        // Convert UTC to local time
        final startLocal = start.toLocal();
        final endLocal = end.toLocal();
        final startTime = _formatTime12Hour(startLocal.hour, startLocal.minute);
        final endTime = _formatTime12Hour(endLocal.hour, endLocal.minute);
        timeRange = '$startTime - $endTime';
      } catch (e) {
        timeRange = 'Time unavailable';
      }
    }

    // Final fallback if timeRange is still empty
    if (timeRange.isEmpty) {
      timeRange = 'Time unavailable';
    }

    // Format date label if not already set from booking_time_range
    if (dateLabel.isEmpty && booking.bookingDateLocal != null) {
      try {
        final date = DateTime.parse(booking.bookingDateLocal!);
        final months = [
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
          'December'
        ];
        dateLabel = '${date.day} ${months[date.month - 1]} ${date.year}';
      } catch (e) {
        dateLabel = booking.bookingDateLocal ?? '';
      }
    }

    // Get service name from snapshot
    final serviceName = booking.serviceFormatSnapshot?.name ?? 'Session';

    // Get duration from snapshot
    final durationMinutes = booking.serviceFormatSnapshot?.durationMinutes;

    return SessionData(
      id: booking.id ?? '',
      title: serviceName,
      name: booking.userName ?? 'Client',
      timeRange: timeRange,
      dateLabel: dateLabel,
      isCancelled: isCancelled,
      isPasted: isPasted,
      isInProgress: booking.status == 'in_progress',
      durationMinutes: durationMinutes,
      userId: userId,
    );
  }

  /// Format time in 12-hour format with AM/PM
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

  /// Fetch notification count (delegates to shared service)
  Future<void> fetchNotificationCount() async {
    await _notificationService?.fetchNotificationCount();
  }

  /// Update device token for push notifications
  ///
  /// Collects all device information and FCM token, then calls the API
  Future<void> updateDeviceToken() async {
    final apiService = _userApiService;
    if (apiService == null) {
      logError('UserApiService not available');
      return;
    }

    try {
      // Get FCM token
      final fcmToken = await FirebaseTokenService.getFCMToken();
      if (fcmToken == null || fcmToken.isEmpty) {
        logError('Failed to get FCM token');
        return;
      }

      // Get device information
      final deviceId = await DeviceInfoHelper.getDeviceId();
      final deviceType = DeviceInfoHelper.getDeviceType();
      final platform = DeviceInfoHelper.getPlatform();
      final appVersion = await DeviceInfoHelper.getAppVersion();
      final language = DeviceInfoHelper.getLanguage();
      final deviceName = await DeviceInfoHelper.getDeviceName();
      final osVersion = await DeviceInfoHelper.getOSVersion();

      // Get location (optional)
      Position? position = await DeviceInfoHelper.getCurrentLocation();
      double? latitude;
      double? longitude;
      if (position != null) {
        latitude = position.latitude;
        longitude = position.longitude;
      }

      await callDataService(
        apiService.updateDeviceToken(
          deviceId: deviceId,
          deviceToken: fcmToken,
          deviceType: deviceType,
          platform: platform,
          appVersion: appVersion,
          language: language,
          deviceName: deviceName,
          osVersion: osVersion,
          latitude: latitude,
          longitude: longitude,
          requireRegistrationDevice: false,
        ),
        onSuccess: (response) {
          logInfo('Device token updated successfully');
        },
        onError: (error, stack) {
          logError('Failed to update device token',
              error: error, stackTrace: stack);
        },
      );
    } catch (e, stackTrace) {
      logError('Error in updateDeviceToken', error: e, stackTrace: stackTrace);
    }
  }

  /// Connect Socket.IO for authenticated users
  Future<void> _connectSocket() async {
    if (_socketService == null) return;

    // Get current user ID
    String? userId;
    String? token;
    if (Get.isRegistered<StorageService>()) {
      final storage = Get.find<StorageService>();
      userId = storage.readString('user_id');
      token = storage.readString('access_token');
    }

    print('HomeController - Connecting socket with User ID: $userId');

    // Connect socket with user ID
    await _socketService!.connect(userId: userId, token: token);
  }

  /// Load user profile details
  ///
  /// Fetches user profile details from the API
  Future<void> loadProfileDetails({bool showStripeDialog = false}) async {
    final apiService = _userApiService;
    if (apiService == null) {
      logError('UserApiService not available');
      return;
    }

    await callDataService(
      apiService.getProfileDetails(),
      showLoader: true,
      onSuccess: (response) {
        if (response.success && response.data != null) {
          try {
            final data = response.data as Map<String, dynamic>?;
            if (data != null) {
              // Parse response using model
              final profile = ProfileDetailsModel.fromJson(data);
              profileDetails.value = profile;
              logInfo('Profile details loaded successfully');
              logInfo('User: ${profile.fullName}, Email: ${profile.email}');
              if (showStripeDialog) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _maybeShowApprovalDialog(profile);
                });
              }
            } else {
              logError('Profile data is null');
            }
          } catch (e, stackTrace) {
            logError('Error parsing profile details',
                error: e, stackTrace: stackTrace);
          }
        } else {
          logError('Failed to load profile details: ${response.message}');
        }
      },
      onError: (error, stack) {
        logError('Failed to load profile details',
            error: error, stackTrace: stack);
      },
    );
  }

  Future<void> _maybeShowApprovalDialog(ProfileDetailsModel profile) async {
    if (_approvalDialogShown) return;
    if (_isGuestUser()) return;
    if (Get.context == null) return;
    if (Get.isDialogOpen == true) return;

    if (!(profile.isApproved ?? false)) {
      _approvalDialogShown = true;
      showResponseDialog(
        title: 'Application Under Review',
        message:
            'Your professional application has been successfully submitted. Please wait while we review your application. Once it is approved, you will be able to access and use our services.',
        isError: false,
        showButton: true,
      );
      return;
    }

    // If approved, check subscription
    await _maybeShowSubscriptionDialog(profile);
  }

  Future<void> _maybeShowSubscriptionDialog(ProfileDetailsModel profile) async {
    if (_subscriptionDialogShown) return;
    if (_isGuestUser()) return;
    if (Get.context == null) return;
    if (Get.isDialogOpen == true) return;

    // Check if user is already on subscription screen - don't show redundant dialog
    final currentRoute = Get.currentRoute;
    if (currentRoute == Routes.profileSubscription) {
      return;
    }

    if (!(profile.isSubscription ?? false)) {
      _subscriptionDialogShown = true;
      showConfirmationDialog(
        title: 'Subscription Required',
        message:
            'Your profile has been approved. Please proceed with subscription payment to activate your account.',
        onYesPressed: () {
          Get.toNamed(Routes.profileSubscription);
        },
        onNoPressed: () {
          // Dismiss dialog without checking other logic
        },
        yesText: 'Subscribe',
        noText: 'Later',
      );
      return;
    }

    // If has subscription, show stripe onboarding dialog
    await _maybeShowStripeOnboardingDialog(profile);
  }

  Future<void> _maybeShowStripeOnboardingDialog(
      ProfileDetailsModel profile) async {
    if (_stripeOnboardingDialogShown) return;
    if (_isGuestUser()) return;
    if (Get.context == null) return;
    if (Get.isDialogOpen == true) return;

    final connectStatusRaw =
        (profile.stripeDetailsConnectStatus ?? profile.stripeConnectStatus)
            ?.trim()
            .toLowerCase();
    final onboardingUrl =
        (profile.stripeDetailsOnboardingLink ?? profile.onboardingLink)?.trim();

    if (connectStatusRaw == 'completed') return;
    if (onboardingUrl == null || onboardingUrl.isEmpty) return;

    _stripeOnboardingDialogShown = true;

    await showDialog(
      context: Get.context!,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: HightWidthSizes.setValue_16,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius:
                    BorderRadius.circular(HightWidthSizes.setValue_10),
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
                  Text(
                    'Get Started with Stripe',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.rubikMedium,
                      fontWeight: FontWeight.w500,
                      fontSize: FontSizes.setFontValue_20,
                      color: AppColor.color_2D3648,
                    ),
                  ),
                  SizedBox(height: HightWidthSizes.setValue_16),
                  Text(
                    'Please complete your Stripe onboarding to enable charges and payouts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.rubikRegular,
                      fontWeight: FontWeight.w400,
                      fontSize: FontSizes.setFontValue_14,
                      color: AppColor.color_2D2D2D,
                    ),
                  ),
                  SizedBox(height: HightWidthSizes.setValue_24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        final result = await Get.to(() =>
                            StripAccountWebViewScreen(url: onboardingUrl));

                        // When returning from WebView, check result and navigate if successful
                        if (result == 'success') {
                          loadProfileDetails(showStripeDialog: true);
                          showResponseDialog(
                            message: 'Stripe account created successfully.',
                            title: 'Stripe Account Created',
                            showButton: true,
                            onOkPressed: () => Get.toNamed(Routes.bankAccount),
                          );
                        } else if (result == 'failed') {
                          loadProfileDetails(showStripeDialog: true);
                          showResponseDialog(
                            message:
                                'Stripe account create failed. Please try again.',
                            title: 'Stripe Account Create Failed',
                            isError: true,
                            showButton: true,
                            onOkPressed: () {},
                          );
                          // await Get.to(
                          //   () => ProfessionalWebViewScreen(url: onboardingUrl),
                          // );
                          // await loadProfileDetails(showStripeDialog: true);
                        }
                      },
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
                        'Create Account',
                        style: TextStyle(
                          fontFamily: AppFonts.rubikMedium,
                          fontWeight: FontWeight.w500,
                          fontSize: FontSizes.setFontValue_16,
                          color: AppColor.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: HightWidthSizes.setValue_12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
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
                        'Later',
                        style: TextStyle(
                          fontFamily: AppFonts.rubikRegular,
                          fontWeight: FontWeight.w400,
                          fontSize: FontSizes.setFontValue_16,
                          color: AppColor.color_B53232,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

// Future<void> loadItems() async {
//   await callDataService(
//     _api.getRequest<dynamic>('/home'),
//     onSuccess: (response) {
//       final raw = response.data;
//
//       // Support both wrapped (BaseModel) and raw list responses.
//       final map = raw is Map<String, dynamic> ? raw : null;
//
//       if (map != null) {
//         final base = BaseModel.fromJson(map);
//         if ((base.message ?? '').isNotEmpty) {
//           message(base.message!);
//         }
//
//         final dynamic data =
//             map['items'] ??
//             ((map['data'] as Map<String, dynamic>?)?['items']);
//
//         if (data is List) {
//           items.assignAll(
//             data
//                 .whereType<Map<String, dynamic>>()
//                 .map(HomeItem.fromJson)
//                 .toList(),
//           );
//           return;
//         }
//       }
//
//       if (raw is List) {
//         items.assignAll(
//           raw
//               .whereType<Map<String, dynamic>>()
//               .map(HomeItem.fromJson)
//               .toList(),
//         );
//       }
//     },
//     onError: (error, stack) {
//       logError('Failed to load home items', error: error, stackTrace: stack);
//       items.assignAll(const [
//         HomeItem(
//           title: 'Offline example',
//           subtitle: 'Showing fallback data while API is unavailable',
//         ),
//       ]);
//       setError('Could not reach the server. Showing cached sample data.');
//     },
//     mapErrorMessage: (_) =>
//         'Could not reach the server. Showing cached sample data.',
//   );
// }
}

class SessionData {
  SessionData({
    required this.id,
    required this.title,
    required this.name,
    required this.timeRange,
    required this.dateLabel,
    this.isCancelled = false,
    this.isPasted = false,
    this.isInProgress = false,
    this.durationMinutes,
    this.userId,
  });

  final String id;
  final String title;
  final String name;
  final String timeRange;
  final String dateLabel;
  final bool isCancelled;
  final bool isPasted;
  final bool isInProgress;
  final int? durationMinutes;
  final String? userId;
}
