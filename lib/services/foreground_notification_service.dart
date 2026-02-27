import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/screens/main/MainScreen.dart';
import 'package:verithrive_dev/professional/home/chat/chat_binding.dart';
import 'package:verithrive_dev/professional/home/chat/chat_view.dart';
import 'package:verithrive_dev/professional/home/home_binding.dart';
import 'package:verithrive_dev/professional/home/home_view.dart';
import 'package:verithrive_dev/professional/notification/notification_view.dart';

import '../enduser/screens/main/MainTabController.dart';
import '../enduser/screens/message/ChatDetailBinding.dart';
import '../enduser/screens/message/ChatDetailScreen.dart';
import '../professional/notification/notification_binding.dart';
import '../utils/logger.dart';
import '../routes/app_routes.dart';
import '../professional/home/messages_controller.dart';
import '../professional/home/home_controller.dart';
import '../professional/home/calendar_controller.dart';
import '../professional/home/chat/chat_controller.dart';
import 'notification_service.dart';
import 'storage_service.dart';

// ── End-user imports ──────────────────────────────────────────────────────────
import 'package:verithrive_dev/enduser/routes/app_routes.dart'
as enduser_routes;
import 'package:verithrive_dev/enduser/screens/message/MessagesController.dart'
as enduser_msg;
import 'package:verithrive_dev/enduser/screens/message/ChatDetailController.dart';
import 'package:verithrive_dev/enduser/screens/booking/BookingsController.dart';
import 'package:verithrive_dev/enduser/screens/home_main/HomeMainController.dart';
import 'package:verithrive_dev/enduser/models/Conversation.dart';
import 'package:verithrive_dev/enduser/data/repository/project_repository.dart';
import 'package:verithrive_dev/enduser/utils/api_services.dart';
import 'package:verithrive_dev/enduser/network/exceptions/not_found_exception.dart';
import 'package:verithrive_dev/enduser/network/exceptions/api_exception.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import 'package:verithrive_dev/enduser/utils/app_text_styles.dart';
// ─────────────────────────────────────────────────────────────────────────────

// ── Booking notification type lists ──────────────────────────────────────────

const List<String> _bookingNotificationTypes = [
  'booking_rescheduled_by_professional',
  'booking_cancelled_by_professional',
  'booking_three_day_reminder',
  'booking_one_day_reminder',
  'booking_one_hour_reminder',
  'booking_end_reminder',
  'booking_ended',
  'booking_started',
  'booking_start_reminder',
  'booking_completed_review',
  'review_reminder',
  'final_review_reminder',
];

const List<String> _reviewNotificationTypes = [
  'booking_completed_review',
  'review_reminder',
  'final_review_reminder',
];

bool _isBookingNotificationType(String? type) {
  if (type == null) return false;
  return _bookingNotificationTypes.contains(type);
}

bool _isReviewNotificationType(String? type) {
  if (type == null) return false;
  return _reviewNotificationTypes.contains(type);
}

// ─────────────────────────────────────────────────────────────────────────────
// Top-level callback required by onDidReceiveBackgroundNotificationResponse.
// Must be a top-level function annotated with @pragma so the background
// isolate can locate it.
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
void onBackgroundNotificationTapped(NotificationResponse response) {
  ForegroundNotificationService.handleLocalNotificationTap(
      response.payload ?? '');
}

// ─────────────────────────────────────────────────────────────────────────────

/// Unified notification service for both the professional and end-user sides.
class ForegroundNotificationService {
  ForegroundNotificationService._();

  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // Channel IDs
  static const String _professionalChannelId = 'notification_id';
  static const String _enduserChannelId = 'custom_notification_channel';

  /// Notification pending while the splash/home navigation stack is being built.
  static RemoteMessage? _pendingNotification;

  /// Prevents duplicate handling when a messageId is seen more than once.
  static String? _lastHandledNotificationId;

  static RemoteMessage? get pendingNotification => _pendingNotification;
  static void clearPendingNotification() => _pendingNotification = null;

  // ── Public entry points ────────────────────────────────────────────────────

  /// Call from Home after it has fully loaded to process any stored notification.
  static void handlePendingNotificationIfAny() {
    if (_pendingNotification != null) {
      final message = _pendingNotification!;
      _pendingNotification = null;
      logInfo(
          'Handling pending notification after Home loaded: ${message.messageId}');
      _handleNotificationTap(message);
    }
  }

  /// Public wrapper used by the top-level background callback.
  static void handleLocalNotificationTap(String payload) {
    _handleNotificationTapFromPayload(payload);
  }

  // ── Initialization ─────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onForegroundNotificationTapped,
      // Must be a top-level @pragma function for the background isolate:
      onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationTapped,
    );

    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }

    logInfo('ForegroundNotificationService initialized');
  }

  static Future<void> _createNotificationChannels() async {
    final plugin = _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await plugin?.createNotificationChannel(const AndroidNotificationChannel(
      _professionalChannelId,
      'Notifications',
      description: 'This channel is used for app notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ));

    await plugin?.createNotificationChannel(const AndroidNotificationChannel(
      _enduserChannelId,
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
    ));

    logInfo('Android notification channels created');
  }

  // ── FCM message listeners ──────────────────────────────────────────────────

  static void setupForegroundMessageHandler() {
    try {
      // App in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        logInfo('=== FOREGROUND MESSAGE RECEIVED ===');
        logInfo('Message ID: ${message.messageId}');
        logInfo('Data: ${message.data}');

        final notificationType = message.data['type']?.toString();

        // Show review dialog immediately when app is in foreground
        if (_isReviewNotificationType(notificationType)) {
          logInfo(
              'Review notification in foreground ($notificationType) – opening dialog');
          _openReviewDialog(message.data);
        }

        showForegroundNotification(message);
      });

      // App in background, user taps notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        logInfo(
            'Notification tapped (app was background): ${message.messageId}');

        if (_pendingNotification != null) {
          logInfo(
              'Pending notification exists – Home will handle it, skipping');
          return;
        }

        if (Get.currentRoute == Routes.splash) {
          logInfo('Still at splash – storing as pending');
          _pendingNotification = message;
          return;
        }

        _handleNotificationTap(message);
      });

      logInfo('Foreground message handler setup complete');
    } catch (e, stackTrace) {
      logError('Error setting up foreground message handler',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Top-level background FCM handler delegate.
  /// The actual top-level function lives in main.dart; it calls this method
  /// after re-initialising Firebase.
  static Future<void> backgroundMessageHandler(RemoteMessage message) async {
    if (message.notification == null) {
      // Data-only message – FCM won't show anything, so we must.
      await showForegroundNotification(message);
    } else {
      final type = message.data['type']?.toString() ?? '';
      logInfo(
          'Background FCM message (type: $type) – FCM handles display automatically');
    }
  }

  /// Check whether the app was cold-started from a notification.
  static Future<void> checkInitialMessage() async {
    try {
      final initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        logInfo(
            'Cold-start from notification: ${initialMessage.messageId}');
        // Store for Home to handle after its own initialisation
        _pendingNotification = initialMessage;
      }
    } catch (e, stackTrace) {
      logError('Error checking initial message',
          error: e, stackTrace: stackTrace);
    }
  }

  // ── Show local notification ────────────────────────────────────────────────

  static Future<void> showForegroundNotification(RemoteMessage message) async {
    try {
      final data = message.data;
      final notificationType = data['type']?.toString();

      // ── Suppress notification if user is already in the relevant chat ──
      if (notificationType == 'chat_message') {
        final senderId = data['sender_id']?.toString();
        final roomId = data['room_id']?.toString();

        if (_shouldHideProfessionalChatNotification(message)) {
          logInfo(
              'Professional chat screen open for same user – suppressing notification');
          _refreshChatInbox();
          return;
        }

        if (_isChatDetailActiveWithUser(senderId, roomId)) {
          logInfo(
              'End-user chat detail open for same user – suppressing notification');
          _refreshEnduserMessagesInbox();
          return;
        }
      }

      // ── Refresh data appropriate to the notification type ──
      _refreshNotificationCount();

      if (notificationType == 'chat_message') {
        _refreshChatInbox();
        _refreshEnduserMessagesInbox();
      } else if (notificationType == 'new_booking' ||
          notificationType == 'booking_cancelled' ||
          notificationType == 'booking_updated') {
        _refreshCalendar();
      } else if (_isBookingNotificationType(notificationType)) {
        _refreshEnduserBookings();
      } else if (notificationType == 'application_approved') {
        _refreshProfile();
      }

      // ── Build title / body ──
      final notification = message.notification;
      final String title =
          notification?.title ?? data['title'] ?? data['heading'] ?? '';
      final String body =
          notification?.body ?? data['body'] ?? data['message'] ?? '';

      if (title.isEmpty && body.isEmpty) {
        logInfo('Skipping notification – both title and body are empty');
        return;
      }

      // ── Android details ──
      final androidDetails = AndroidNotificationDetails(
        _professionalChannelId,
        'Notifications',
        channelDescription: 'This channel is used for app notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        showWhen: true,
        enableLights: true,
        color: const Color(0xFF2196F3),
      );

      // ── iOS details ──
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
      );

      // Use a stable ID derived from messageId so duplicate FCM deliveries
      // don't stack multiple banners for the same message.
      final int notificationId = message.messageId != null
          ? message.messageId!.hashCode.abs() % 2147483647
          : DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _localNotifications.show(
        notificationId,
        title.isNotEmpty ? title : 'Notification',
        body.isNotEmpty ? body : 'You have a new notification',
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: data.toString(),
      );

      logInfo(
          'Notification shown – ID: $notificationId, Title: $title');
    } catch (e, stackTrace) {
      logError('Error showing foreground notification',
          error: e, stackTrace: stackTrace);
    }
  }

  // ── Local notification tap callbacks ──────────────────────────────────────

  // Foreground tap – can be a static method (no isolate restriction).
  static void _onForegroundNotificationTapped(NotificationResponse response) {
    logInfo('Local notification tapped (foreground): ${response.payload}');
    _handleNotificationTapFromPayload(response.payload ?? '');
  }

  // ── Routing on FCM tap ─────────────────────────────────────────────────────

  static void _handleNotificationTap(RemoteMessage message) {
    try {
      final data = message.data;
      final notificationType = data['type']?.toString();
      final messageId = message.messageId;

      logInfo(
          'Handling FCM tap – type: $notificationType, id: $messageId');

      // Deduplicate
      if (messageId != null && messageId == _lastHandledNotificationId) {
        logInfo('Duplicate tap ignored: $messageId');
        return;
      }
      if (messageId != null) _lastHandledNotificationId = messageId;

      _refreshNotificationCount();

      // End-user review / booking
      if (_isBookingNotificationType(notificationType)) {
        if (_isReviewNotificationType(notificationType)) {
          _openReviewDialog(data);
        } else {
          _openBookingsTab();
        }
        return;
      }

      // Chat
      if (notificationType == 'chat_message') {
        _refreshChatInbox();
        _refreshEnduserMessagesInbox();
        _navigateToChat(message);
        return;
      }

      // Professional booking types
      if (notificationType == 'new_booking' ||
          notificationType == 'booking_cancelled' ||
          notificationType == 'booking_updated') {
        _refreshCalendar();
        if (Get.currentRoute != Routes.home) {
          //Get.toNamed(Routes.home);
          Get.to(
                () => HomeView(),
            binding: HomeBinding(),
          );
          Future.delayed(
              const Duration(milliseconds: 300), _selectCalendarTab);
        } else {
          _selectCalendarTab();
        }
        return;
      }

      // Application approved
      if (notificationType == 'application_approved') {
        _refreshProfile();
        //Get.toNamed(Routes.notifications);

        Get.to(
              () => NotificationView(),
          binding: NotificationBinding(),
        );
        return;
      }

      logInfo('Unknown notification type: $notificationType');
    } catch (e, stackTrace) {
      logError('Error handling FCM notification tap',
          error: e, stackTrace: stackTrace);
    }
  }

  // ── Routing on local notification payload tap ─────────────────────────────

  static void _handleNotificationTapFromPayload(String payload) {
    try {
      logInfo('Handling local notification tap, payload: $payload');

      _refreshNotificationCount();

      final type = _extractValueFromPayload(payload, 'type');

      // End-user review / booking
      if (_isBookingNotificationType(type)) {
        if (_isReviewNotificationType(type)) {
          _openReviewDialog(_payloadToMap(payload));
        } else {
          _openBookingsTab();
        }
        return;
      }

      // Chat
      if (type == 'chat_message') {
        _refreshChatInbox();
        _refreshEnduserMessagesInbox();
        _navigateToChatFromPayload(payload);
        return;
      }

      // Professional booking
      if (type == 'new_booking' ||
          type == 'booking_cancelled' ||
          type == 'booking_updated') {
        _refreshCalendar();
        if (Get.currentRoute != Routes.home) {
          //Get.toNamed(Routes.home);
          Get.to(
                () => HomeView(),
            binding: HomeBinding(),
          );
          Future.delayed(
              const Duration(milliseconds: 300), _selectCalendarTab);
        } else {
          _selectCalendarTab();
        }
        return;
      }

      // Application approved
      if (type == 'application_approved') {
        _refreshProfile();
       // Get.toNamed(Routes.notifications);
        Get.to(
              () => NotificationView(),
          binding: NotificationBinding(),
        );
        return;
      }
    } catch (e, stackTrace) {
      logError('Error handling local notification tap from payload',
          error: e, stackTrace: stackTrace);
    }
  }

  // ── App lifecycle ──────────────────────────────────────────────────────────

  static void refreshAllDataOnAppResume() {
    try {
      logInfo('App resumed – refreshing all data');

      if (!_isAuthenticated() || _isPublicRoute()) {
        logInfo('Not authenticated or on public route – skipping refresh');
        return;
      }

      _refreshNotificationCount();
      _refreshChatInbox();
      _refreshEnduserMessagesInbox();
      _refreshCalendar();
      _refreshProfile();
      _refreshEnduserBookings();

      logInfo('All data refresh triggered');
    } catch (e, stackTrace) {
      logError('Error refreshing data on app resume',
          error: e, stackTrace: stackTrace);
    }
  }

  // ── Auth / route guards ────────────────────────────────────────────────────

  static bool _isAuthenticated() {
    if (!Get.isRegistered<StorageService>()) return false;
    final token = Get.find<StorageService>().readString('access_token');
    return token != null && token.isNotEmpty;
  }

  static bool _isPublicRoute() {
    final publicRoutes = [
      Routes.splash,
      Routes.onboarding,
      Routes.login,
      Routes.signup,
      Routes.forgotPassword,
      Routes.verifyEmail,
      Routes.createNewPassword,
      Routes.signupPersonDetails,
      Routes.signupTermsConditions,
      Routes.signupProfileWizard,
    ];
    return publicRoutes.contains(Get.currentRoute);
  }

  // ── Data refresh helpers ───────────────────────────────────────────────────

  static void _refreshNotificationCount() {
    try {
      if (Get.isRegistered<NotificationService>()) {
        Get.find<NotificationService>().fetchNotificationCount();
        logInfo('Professional notification count refreshed');
      }
      if (Get.isRegistered<HomeMainController>(tag: 'home')) {
        Get.find<HomeMainController>(tag: 'home').fetchNotificationCount();
        logInfo('End-user notification count refreshed');
      }
    } catch (e, stackTrace) {
      logError('Error refreshing notification count',
          error: e, stackTrace: stackTrace);
    }
  }

  static void _refreshChatInbox() {
    try {
      if (Get.isRegistered<MessagesController>()) {
        Get.find<MessagesController>().checkAndReconnectSocket();
        logInfo('Professional chat inbox refreshed');
      }
    } catch (e, stackTrace) {
      logError('Error refreshing professional chat inbox',
          error: e, stackTrace: stackTrace);
    }
  }

  static void _refreshEnduserMessagesInbox() {
    try {
      if (Get.isRegistered<enduser_msg.MessagesController>(tag: 'messages')) {
        Get.find<enduser_msg.MessagesController>(tag: 'messages')
            .silentRefreshInbox();
        logInfo('End-user messages inbox refreshed');
      }
    } catch (e, stackTrace) {
      logError('Error refreshing end-user messages inbox',
          error: e, stackTrace: stackTrace);
    }
  }

  static void _refreshEnduserBookings() {
    try {
      if (Get.isRegistered<BookingsController>(tag: 'bookings')) {
        Get.find<BookingsController>(tag: 'bookings').refreshData();
        logInfo('End-user bookings refreshed');
      }
    } catch (e, stackTrace) {
      logError('Error refreshing end-user bookings',
          error: e, stackTrace: stackTrace);
    }
  }

  static void _refreshProfile() {
    try {
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().loadProfileDetails();
        logInfo('Profile data refreshed');
      }
    } catch (e, stackTrace) {
      logError('Error refreshing profile data',
          error: e, stackTrace: stackTrace);
    }
  }

  static void _refreshCalendar() {
    try {
      if (Get.isRegistered<CalendarController>()) {
        Get.find<CalendarController>().refreshServiceFormatAvailability();
        logInfo('Calendar refreshed');
      }
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().loadBookingsList();
        logInfo('Bookings list refreshed');
      }
    } catch (e, stackTrace) {
      logError('Error refreshing calendar', error: e, stackTrace: stackTrace);
    }
  }

  // ── Tab selection helpers ──────────────────────────────────────────────────

  static void _selectCalendarTab() {
    try {
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().onTabSelected(0);
        logInfo('Calendar tab selected');
      }
    } catch (e, stackTrace) {
      logError('Error selecting Calendar tab',
          error: e, stackTrace: stackTrace);
    }
  }

  static void _selectMessagesTab() {
    try {
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().onTabSelected(2);
        logInfo('Messages tab selected');
      }
    } catch (e, stackTrace) {
      logError('Error selecting Messages tab',
          error: e, stackTrace: stackTrace);
    }
  }

  // ── End-user: open Bookings tab ────────────────────────────────────────────

  static void _openBookingsTab() {
    try {
      if (Get.isRegistered<MainTabController>()) {
        Get.find<MainTabController>().setTab(1);
        logInfo('Switched to Bookings tab via MainTabController');
        _refreshEnduserBookings();
      } else {
/*        Get.toNamed(enduser_routes.AppRoutes.main,
            arguments: {'openTab': 1});*/

        Get.to(
              () => MainScreen(),
            arguments: {'openTab': 1}
        );
        logInfo('Navigated to MainScreen Bookings tab');
      }
    } catch (e, stackTrace) {
      logError('Error opening Bookings tab',
          error: e, stackTrace: stackTrace);
    }
  }

  // ── End-user: review dialog ────────────────────────────────────────────────

  static Future<void> _openReviewDialog(Map<String, dynamic> data) async {
    try {
      final professionalId = data['professional_id']?.toString() ?? '';
      final bookingId = data['booking_id']?.toString() ?? '';
      final professionalName = data['professional_name']?.toString() ??
          data['full_name']?.toString() ??
          'Professional';

      if (professionalId.isEmpty || bookingId.isEmpty) {
        logInfo(
            'Missing professional_id or booking_id – falling back to Bookings tab');
        _openBookingsTab();
        return;
      }

      logInfo(
          'Opening review dialog – professional: $professionalName, booking: $bookingId');

   /*   await Get.toNamed(enduser_routes.AppRoutes.main,
          arguments: {'openTab': 0});*/


      await Get.to(
              () => MainScreen(),
          arguments: {'openTab': 0}
      );


      _showReviewDialogWithRetry(professionalName, professionalId, bookingId);
    } catch (e, stackTrace) {
      logError('Error opening review dialog',
          error: e, stackTrace: stackTrace);
      _openBookingsTab();
    }
  }

  static void _showReviewDialogWithRetry(
      String professionalName,
      String professionalId,
      String bookingId,
      ) {
    int retryCount = 0;
    const int maxRetries = 10;

    void tryShow() {
      retryCount++;
      logInfo(
          'Review dialog attempt $retryCount/$maxRetries');
      if (Get.isRegistered<HomeMainController>()) {
        Get.find<HomeMainController>()
            .showReviewDialog(professionalName, professionalId, bookingId);
      } else if (retryCount < maxRetries) {
        Future.delayed(const Duration(milliseconds: 500), tryShow);
      } else {
        logInfo(
            'HomeMainController unavailable after $maxRetries attempts – showing fallback dialog');
        _showFallbackReviewDialog(professionalName, professionalId, bookingId);
      }
    }

    tryShow();
  }

  static void _showFallbackReviewDialog(
      String professionalName,
      String professionalId,
      String bookingId,
      ) {
    final TextEditingController reviewController = TextEditingController();
    final RxInt rating = 0.obs;
    final RxBool isSubmitting = false.obs;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Content area ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 24),
                      Expanded(
                        child: Text(
                          'Rate your recent session with\n"$professionalName"',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.popinMediumTextStyle(),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Icon(
                          Icons.close,
                          color: Colors.grey.shade600,
                          size: 24,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Star rating
                  Obx(
                        () => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () => rating.value = index + 1,
                          child: Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 4),
                            child: SvgPicture.asset(
                              AppAssets.rating_selected,
                              // Use colorFilter to avoid deprecated 'color' param
                              colorFilter: ColorFilter.mode(
                                index < rating.value
                                    ? AppColors.ratingSelectedColor
                                    : AppColors.unselectedTabColor,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Review text field
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: reviewController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Write a review',
                        hintStyle: AppTextStyles.popinRegularTextStyle(
                          fontSize: 14,
                          color: AppColors.color919191,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: AppTextStyles.regularTextStyle(
                        fontSize: 14,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Submit button ──────────────────────────────────────────────
            Obx(
                  () => Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: isSubmitting.value
                      ? Colors.grey
                      : AppColors.primaryColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isSubmitting.value
                        ? null
                        : () async {
                      if (rating.value == 0) {
                        Get.snackbar(
                          'Rating Required',
                          'Please select a rating before submitting',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.orange.shade100,
                          duration: const Duration(seconds: 2),
                        );
                        return;
                      }

                      isSubmitting.value = true;

                      try {
                        await _submitReview(
                          professionalId: professionalId,
                          bookingId: bookingId,
                          rating: rating.value,
                          review: reviewController.text.trim(),
                        );
                        Get.back();
                        Get.snackbar(
                          'Review Submitted',
                          'Thank you for your feedback!',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor:
                          AppColors.primaryColor.withOpacity(0.2),
                          duration: const Duration(seconds: 2),
                        );
                      } catch (e) {
                        String errorMessage =
                            'Failed to submit review. Please try again.';
                        if (e is NotFoundException) {
                          errorMessage = e.message;
                        } else if (e is ApiException) {
                          errorMessage = e.message;
                        } else {
                          final s = e.toString();
                          errorMessage =
                          s.startsWith('Exception: ')
                              ? s.replaceFirst('Exception: ', '')
                              : s;
                        }
                        Get.snackbar(
                          'Error',
                          errorMessage,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red.shade100,
                          duration: const Duration(seconds: 3),
                        );
                      } finally {
                        isSubmitting.value = false;
                      }
                    },
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: Center(
                      child: isSubmitting.value
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                          : Text(
                        'Add review',
                        style: AppTextStyles.buttonTextStyle(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  static Future<void> _submitReview({
    required String professionalId,
    required String bookingId,
    required int rating,
    required String review,
  }) async {
    const String repoTag = 'ProjectRepository';
    if (!Get.isRegistered<ProjectRepository>(tag: repoTag)) {
      throw Exception('Repository not available');
    }

    final ProjectRepository repository =
    Get.find<ProjectRepository>(tag: repoTag);

    final Map<String, dynamic> requestData = {
      'professional_id': professionalId,
      'booking_id': bookingId,
      'rating': rating,
      'review': review,
    };

    final response = await repository.sendPostApiRequest(
          () => requestData,
      professionals_rate_review,
      true,
    );

    Map<String, dynamic> responseData;
    if (response != null) {
      final dynamic raw = response is Map ? response : response.data;
      if (raw is Map<String, dynamic>) {
        responseData = raw;
      } else {
        throw Exception('Invalid response format');
      }
    } else {
      throw Exception('Invalid response format');
    }

    final bool success = responseData['success'] as bool? ?? false;
    if (!success) {
      throw Exception(
          responseData['message']?.toString() ?? 'Failed to submit review');
    }

    logInfo('Review submitted: ${responseData['message']}');
  }

  // ── End-user chat check ────────────────────────────────────────────────────

  /// Returns true when the end-user ChatDetail screen is already open for the
  /// same conversation that the incoming notification belongs to.
  static bool _isChatDetailActiveWithUser(
      String? senderId, String? roomId) {
    try {
      if (!Get.isRegistered<ChatDetailController>()) return false;
      final current =
          Get.find<ChatDetailController>().conversation;
      return current.userId == senderId || current.id == roomId;
    } catch (e) {
      logError('Error checking end-user chat detail status', error: e);
      return false;
    }
  }

  // ── Professional chat check ────────────────────────────────────────────────

  static bool _shouldHideProfessionalChatNotification(
      RemoteMessage message) {
    try {
      if (!Get.isRegistered<ChatController>()) return false;
      final peerUserId =
          Get.find<ChatController>().peer.value.userId;
      if (peerUserId == null || peerUserId.isEmpty) return false;

      final senderId = _extractSenderIdFromData(message.data);
      if (senderId == null || senderId.isEmpty) return false;

      final shouldHide = senderId == peerUserId;
      logInfo(
          'Professional chat hide check – peer: $peerUserId, sender: $senderId, hide: $shouldHide');
      return shouldHide;
    } catch (e) {
      logError('Error in professional chat hide check', error: e);
      return false;
    }
  }

  /// Extract sender ID from FCM data map, handling both plain-string and
  /// nested-object forms of sender_id.
  static String? _extractSenderIdFromData(Map<String, dynamic> data) {
    try {
      final dynamic raw = data['sender_id'] ??
          data['senderId'] ??
          data['user_id'] ??
          data['userId'] ??
          data['from_id'] ??
          data['fromId'];

      if (raw == null) return null;
      if (raw is String) return raw;
      if (raw is Map<String, dynamic>) {
        return raw['_id']?.toString() ??
            raw['id']?.toString() ??
            raw['userId']?.toString() ??
            raw['user_id']?.toString();
      }
      return raw.toString();
    } catch (e) {
      logError('Error extracting sender ID', error: e);
      return null;
    }
  }

  // ── Navigate to chat from RemoteMessage ────────────────────────────────────

  static void _navigateToChat(RemoteMessage message) {
    try {
      final Map<String, dynamic> data = message.data;

      // ── End-user path: room_id present ──
      final String? roomId =
          data['room_id']?.toString() ?? data['roomId']?.toString();
      final String? senderId = _extractSenderIdFromData(data);
      final bool isEnduserChat = roomId != null && roomId.isNotEmpty;

      if (isEnduserChat) {
        if (Get.currentRoute == enduser_routes.AppRoutes.chat_detail) {
          logInfo('Already on end-user chat detail – skipping');
          return;
        }

        final String senderName =
            data['full_name']?.toString() ?? 'Unknown';
        final String profilePicture =
            data['profile_picture']?.toString() ?? '';
        final String lastMessage =
            data['body']?.toString() ?? 'New message';
        final String title = data['title']?.toString() ?? 'New Message';

        final Conversation conversation = Conversation(
          id: roomId,
          name: senderName,
          lastMessage: lastMessage,
          lastMessageTime: DateTime.now(),
          userId: senderId,
          isOnline: false,
          profileImageUrl: profilePicture,
        );

     /*   Get.toNamed(
          enduser_routes.AppRoutes.chat_detail,
          arguments: {
            'conversation': conversation,
            'notificationData': {
              'title': title,
              'body': lastMessage,
              'sender_id': senderId,
              'room_id': roomId,
              'full_name': senderName,
              'profile_picture': profilePicture,
              'timestamp': data['timestamp'],
              'click_action': data['click_action'],
            },
          },
        );*/

        Get.to(
              () => ChatDetailScreen(),
          binding: ChatDetailBinding(),
          arguments: {
            'conversation': conversation,
            'notificationData': {
              'title': title,
              'body': lastMessage,
              'sender_id': senderId,
              'room_id': roomId,
              'full_name': senderName,
              'profile_picture': profilePicture,
              'timestamp': data['timestamp'],
              'click_action': data['click_action'],
            },
          },
        );


        logInfo('Navigated to end-user chat detail');
        return;
      }

      // ── Professional path: chat_id / userId ──
      if (Get.currentRoute == Routes.chat) {
        logInfo('Already on professional chat screen – skipping');
        return;
      }

      final String? chatId = data['chat_id']?.toString() ??
          data['chatId']?.toString();

      String? name;
      bool isOnline = false;
      String? avatarAsset;

      final dynamic senderObj = data['sender_id'] ?? data['senderId'];
      if (senderObj is Map<String, dynamic>) {
        name = senderObj['full_name']?.toString() ??
            senderObj['fullName']?.toString() ??
            senderObj['name']?.toString();
        isOnline = senderObj['is_online'] as bool? ?? false;
        avatarAsset = senderObj['profile_picture']?.toString() ??
            senderObj['avatar']?.toString();
      }

      name ??= message.notification?.title ??
          data['full_name']?.toString() ??
          data['name']?.toString() ??
          'User';

      final Map<String, dynamic> args = {
        'userId': senderId,
        'name': name,
        'isOnline': isOnline,
        if (avatarAsset != null && avatarAsset.isNotEmpty)
          'avatarAsset': avatarAsset,
        if (chatId != null && chatId.isNotEmpty) 'chatId': chatId,
      };

      logInfo(
          'Navigating to professional chat – userId: $senderId, name: $name');
     // Get.toNamed(Routes.chat, arguments: args);

      Get.to(
            () => ChatView(),
        binding: ChatBinding(),
          arguments: args
      );

    } catch (e, stackTrace) {
      logError('Error navigating to chat',
          error: e, stackTrace: stackTrace);
      _fallbackToMessagesTab();
    }
  }

  // ── Navigate to chat from local notification payload ───────────────────────

  static void _navigateToChatFromPayload(String payload) {
    try {
      // ── End-user path: room_id present ──
      final String? roomId = _extractValueFromPayload(payload, 'room_id');
      if (roomId != null && roomId.isNotEmpty) {
        if (Get.currentRoute == enduser_routes.AppRoutes.chat_detail) {
          logInfo('Already on end-user chat detail – skipping');
          return;
        }

        final String? senderId =
        _extractValueFromPayload(payload, 'sender_id');
        final String senderName =
            _extractValueFromPayload(payload, 'full_name') ?? 'Unknown';
        final String profilePicture =
            _extractValueFromPayload(payload, 'profile_picture') ?? '';
        final String lastMessage =
            _extractValueFromPayload(payload, 'body') ?? 'New message';
        final String title =
            _extractValueFromPayload(payload, 'title') ?? 'New Message';

        final Conversation conversation = Conversation(
          id: roomId,
          name: senderName,
          lastMessage: lastMessage,
          lastMessageTime: DateTime.now(),
          userId: senderId,
          isOnline: false,
          profileImageUrl: profilePicture,
        );

/*        Get.toNamed(
          enduser_routes.AppRoutes.chat_detail,
          arguments: {
            'conversation': conversation,
            'notificationData': {
              'title': title,
              'body': lastMessage,
              'sender_id': senderId,
              'room_id': roomId,
              'full_name': senderName,
              'profile_picture': profilePicture,
            },
          },
        );*/

        Get.to(
                () => ChatDetailScreen(),
            binding: ChatDetailBinding(),
          arguments: {
            'conversation': conversation,
            'notificationData': {
              'title': title,
              'body': lastMessage,
              'sender_id': senderId,
              'room_id': roomId,
              'full_name': senderName,
              'profile_picture': profilePicture,
            },
          },
        );

        logInfo('Navigated to end-user chat detail from payload');
        return;
      }

      // ── Professional path ──
      if (Get.currentRoute == Routes.chat) {
        logInfo('Already on professional chat screen – skipping');
        return;
      }

      // sender_id might be an object: "sender_id: {_id: xxx, full_name: yyy}"
      String? userId;
      String? name;
      bool isOnline = false;

      final RegExpMatch? senderObjMatch =
      RegExp(r'sender_id\s*:\s*\{([^}]+)\}').firstMatch(payload);
      if (senderObjMatch != null) {
        final String senderContent = senderObjMatch.group(1) ?? '';
        userId = _extractValueFromFragment(senderContent, '_id');
        name = _extractValueFromFragment(senderContent, 'full_name');
        isOnline =
            RegExp(r'is_online\s*:\s*(true|false)')
                .firstMatch(senderContent)
                ?.group(1) ==
                'true';
      }

      userId ??= _extractValueFromPayload(payload, 'user_id') ??
          _extractValueFromPayload(payload, 'userId');

      name ??= _extractValueFromPayload(payload, 'full_name') ?? 'User';

      final String? chatId =
          _extractValueFromPayload(payload, 'chat_id') ??
              _extractValueFromPayload(payload, 'chatId');

      if (userId != null && userId.isNotEmpty) {
        final Map<String, dynamic> args = {
          'userId': userId,
          'name': name,
          'isOnline': isOnline,
          if (chatId != null && chatId.isNotEmpty) 'chatId': chatId,
        };
        logInfo(
            'Navigating to professional chat from payload – userId: $userId');
       // Get.toNamed(Routes.chat, arguments: args);

        Get.to(
                () => ChatView(),
            binding: ChatBinding(),
            arguments: args
        );

        return;
      }

      logInfo('Could not extract userId from payload – falling back');
      _fallbackToMessagesTab();
    } catch (e, stackTrace) {
      logError('Error navigating to chat from payload',
          error: e, stackTrace: stackTrace);
      _fallbackToMessagesTab();
    }
  }

  static void _fallbackToMessagesTab() {
    if (Get.currentRoute != Routes.home) {
      Get.toNamed(Routes.home);
      Get.to(
              () => HomeView(),
          binding: HomeBinding(),
      );
      Future.delayed(const Duration(milliseconds: 300), _selectMessagesTab);
    } else {
      _selectMessagesTab();
    }
  }

  // ── Payload parsing utilities ──────────────────────────────────────────────

  /// Extract a value by key from a Dart map toString() payload like:
  /// "{key1: value1, key2: value2}"
  static String? _extractValueFromPayload(String payload, String key) {
    try {
      final match = RegExp('$key\\s*:\\s*([^,}]+)').firstMatch(payload);
      if (match == null) return null;
      return _stripQuotes(match.group(1)?.trim() ?? '');
    } catch (_) {
      return null;
    }
  }

  /// Same as above but operates on a sub-fragment (e.g. inside a nested object).
  static String? _extractValueFromFragment(String fragment, String key) {
    try {
      final match = RegExp('$key\\s*:\\s*([^,}]+)').firstMatch(fragment);
      if (match == null) return null;
      return _stripQuotes(match.group(1)?.trim() ?? '');
    } catch (_) {
      return null;
    }
  }

  /// Convert a Dart map toString() payload string to a real Map<String, dynamic>.
  static Map<String, dynamic> _payloadToMap(String payload) {
    try {
      String p = payload.trim();
      if (p.startsWith('{') && p.endsWith('}')) {
        p = p.substring(1, p.length - 1);
      }
      final Map<String, dynamic> result = {};
      for (final String pair in p.split(',')) {
        final int idx = pair.indexOf(':');
        if (idx == -1) continue;
        final String key   = _stripQuotes(pair.substring(0, idx).trim());
        final String value = _stripQuotes(pair.substring(idx + 1).trim());
        result[key] = value;
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  /// Remove surrounding single or double quotes from a string value.
  static String _stripQuotes(String value) {
    if (value.length >= 2) {
      final first = value[0];
      final last  = value[value.length - 1];
      if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
        return value.substring(1, value.length - 1);
      }
    }
    // Also remove any remaining stray quote characters
    return value.replaceAll('"', '').replaceAll("'", '');
  }
}