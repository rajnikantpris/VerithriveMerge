import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../enduser/screens/message/ChatDetailBinding.dart';
import '../enduser/screens/message/ChatDetailScreen.dart';
import '../utils/logger.dart';
import '../routes/app_routes.dart';
import '../professional/home/messages_controller.dart' hide MessagesController;
import '../professional/home/home_controller.dart';
import '../professional/home/calendar_controller.dart';
import '../professional/home/chat/chat_controller.dart';
import '../enduser/screens/message/MessagesController.dart';
import '../enduser/screens/message/ChatDetailController.dart';
import '../enduser/screens/booking/BookingsController.dart';
import '../enduser/screens/home_main/HomeMainController.dart';
import '../enduser/screens/main/MainTabController.dart';
import '../enduser/models/Conversation.dart';
import '../enduser/routes/app_routes.dart' as enduser_routes;
import '../enduser/app/modules/notification/model/NotificationPayloadModel.dart';
import '../enduser/data/repository/project_repository.dart';
import '../enduser/network/exceptions/not_found_exception.dart';
import '../enduser/network/exceptions/api_exception.dart';
import '../enduser/utils/app_assets.dart';
import '../enduser/utils/app_colors.dart';
import '../enduser/utils/app_text_styles.dart';
import '../enduser/utils/api_services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'storage_service.dart';

/// Notification types that should open the Bookings tab for end users
const List<String> _endUserBookingNotificationTypes = [
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

/// Service to handle foreground notifications for both user types
class ForegroundNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  /// Stores pending notification data when app is opened from terminated state
  /// This allows splash to navigate to Home first, then Home can navigate to Chat
  static RemoteMessage? _pendingNotification;

  /// Track the last handled notification message ID to prevent duplicate handling
  static String? _lastHandledNotificationId;

  /// Check if there's a pending notification to handle after Home loads
  static RemoteMessage? get pendingNotification => _pendingNotification;

  /// Clear pending notification after it's been handled
  static void clearPendingNotification() {
    _pendingNotification = null;
  }

  /// Get the current user type from storage
  static String? _getUserType() {
    try {
      if (!Get.isRegistered<StorageService>()) {
        logInfo('StorageService not registered, cannot determine user type');
        return null;
      }
      final storage = Get.find<StorageService>();
      final userType = storage.readString('userType');
      logInfo('Retrieved user type: $userType');
      return userType;
    } catch (e) {
      logError('Error getting user type', error: e);
      return null;
    }
  }

  /// Check if current user is professional
  static bool _isProfessionalUser() {
    final userType = _getUserType();
    return userType == 'professional';
  }

  /// Check if current user is end user
  static bool _isEndUser() {
    final userType = _getUserType();
    return  userType == 'normal';
  }

  /// Check if notification type is booking-related for end users
  static bool _isEndUserBookingNotificationType(String? type) {
    if (type == null) return false;
    return _endUserBookingNotificationTypes.contains(type);
  }

  /// Handle pending notification - call this from Home after it's ready
  static void handlePendingNotificationIfAny() {
    if (_pendingNotification != null) {
      final message = _pendingNotification!;
      _pendingNotification = null;
      logInfo('Handling pending notification after Home loaded: ${message.messageId}');
      _handleNotificationTap(message);
    }
  }

  /// Initialize local notifications
  static Future<void> initialize() async {
    // Android initialization settings
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Initialization settings for both platforms
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }

    logInfo('Foreground notification service initialized');
  }

  /// Create notification channel for Android
  static Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'notification_id', // Same as in AndroidManifest.xml
      'Notifications',
      description: 'This channel is used for app notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    logInfo('Android notification channel created');
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    logInfo('Notification tapped: ${response.payload}');
    _handleNotificationTapFromPayload(response.payload ?? '');
  }

  /// Show notification when app is in foreground
  static Future<void> showForegroundNotification(
      RemoteMessage message,
      ) async {
    try {
      logInfo('=== ATTEMPTING TO SHOW FOREGROUND NOTIFICATION ===');
      logInfo('Message ID: ${message.messageId}');
      logInfo('Message data: ${message.data}');
      logInfo('Notification object exists: ${message.notification != null}');
      logInfo('Notification title: ${message.notification?.title}');
      logInfo('Notification body: ${message.notification?.body}');
      logInfo('User type: ${_getUserType()}');

      final notification = message.notification;
      final android = message.notification?.android;

      // Extract title and body from notification or data payload
      String title = notification?.title ??
          message.data['title'] ??
          message.data['heading'] ??
          'Notification';
      String body = notification?.body ??
          message.data['body'] ??
          message.data['message'] ??
          message.data['description'] ??
          '';

      logInfo('Extracted title: $title');
      logInfo('Extracted body: $body');

      // If both title and body are empty, skip showing notification
      if (title.isEmpty && body.isEmpty) {
        logError('Cannot show notification: both title and body are empty');
        return;
      }

      // Check notification type and refresh appropriate screen
      final notificationType = message.data['type']?.toString();
      logInfo('Notification type: $notificationType');

      // Refresh notification count for any notification received
      _refreshNotificationCount();

      // Handle based on user type
      if (_isProfessionalUser()) {
        await _handleProfessionalForegroundNotification(message, notificationType);
      } else if (_isEndUser()) {
        await _handleEndUserForegroundNotification(message, notificationType);
      } else {
        logInfo('Unknown user type, using default notification handling');
        await _handleDefaultForegroundNotification(message, notificationType);
      }

      logInfo('Preparing notification - Title: $title, Body: $body');

      // Android notification details
      final androidDetails = AndroidNotificationDetails(
        'notification_id', // Same channel ID as in AndroidManifest.xml
        'Notifications',
        channelDescription: 'This channel is used for app notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: android?.smallIcon ?? '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        showWhen: true,
        enableLights: true,
        color: const Color(0xFF2196F3),
      );

      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Notification details for both platforms
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Generate a unique notification ID
      final notificationId = message.messageId != null
          ? message.messageId.hashCode
          : DateTime.now().millisecondsSinceEpoch.remainder(100000);

      // Show the notification
      await _localNotifications.show(
        notificationId,
        title,
        body,
        details,
        payload: message.data.toString(),
      );

      logInfo(
          'Foreground notification shown successfully - ID: $notificationId, Title: $title');
    } catch (e, stackTrace) {
      logError('Error showing foreground notification',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Handle foreground notifications for professional users
  static Future<void> _handleProfessionalForegroundNotification(
      RemoteMessage message,
      String? notificationType,
      ) async {
    if (notificationType == 'chat_message') {
      logInfo('Professional chat message notification received - refreshing inbox');
      _refreshChatInbox();

      // Check if chat is open and if message is from the same user
      if (_shouldHideChatNotification(message)) {
        logInfo('Chat is open for same user - hiding notification');
        return; // Don't show notification if chat is open for the same user
      }
    } else if (notificationType == 'new_booking' ||
        notificationType == 'booking_cancelled' ||
        notificationType == 'booking_updated') {
      logInfo(
          'Professional booking notification received (type: $notificationType) - refreshing calendar');
      _refreshCalendar();
    } else if (notificationType == 'application_approved') {
      logInfo(
          'Professional profile approval notification received - refreshing profile data');
      _refreshProfile();
      _refreshCalendar();
    }
  }

  /// Handle foreground notifications for end users
  static Future<void> _handleEndUserForegroundNotification(
      RemoteMessage message,
      String? notificationType,
      ) async {
    final data = message.data;

    if (notificationType == 'chat_message') {
      logInfo('End user chat message notification received - refreshing inbox');
      _refreshEndUserMessagesInbox();

      // Check if chat detail screen is active with same user
      if (_isEndUserChatDetailActiveWithUser(
        data['sender_id']?.toString(),
        data['room_id']?.toString(),
      )) {
        logInfo('End user chat detail screen is active with same user - skipping notification');
        return;
      }
    } else if (_isEndUserBookingNotificationType(notificationType)) {
      logInfo('End user booking notification received (type: $notificationType) - refreshing bookings');
      _refreshEndUserBookings();

      // Handle review-related notifications in foreground - show dialog immediately
      if (notificationType == "booking_completed_review" ||
          notificationType == "review_reminder" ||
          notificationType == "final_review_reminder") {
        logInfo("Handling ${notificationType} in foreground for end user");
        _openEndUserReviewDialog(data);
      }
    } else {
      // For other notification types, refresh notification count
      logInfo("End user notification received (type: $notificationType) - refreshing notification count");
      _refreshEndUserNotificationCount();
    }
  }

  /// Handle default foreground notifications when user type is unknown
  static Future<void> _handleDefaultForegroundNotification(
      RemoteMessage message,
      String? notificationType,
      ) async {
    // Default handling - refresh notification count
    _refreshNotificationCount();
    logInfo('Default notification handling for type: $notificationType');
  }

  /// Setup Firebase foreground message handler
  static void setupForegroundMessageHandler() {
    try {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        logInfo('=== FOREGROUND MESSAGE RECEIVED ===');
        logInfo('Message ID: ${message.messageId}');
        logInfo('From: ${message.from}');
        logInfo('Data: ${message.data}');
        logInfo('Notification Title: ${message.notification?.title}');
        logInfo('Notification Body: ${message.notification?.body}');
        logInfo('===================================');

        if(Platform.isIOS) {
          if (message.notification == null) {
            // Show the notification
            showForegroundNotification(message);
          }
        }else{
          showForegroundNotification(message);
        }
      });

      // Handle message opened app (when user taps notification while app is in background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        logInfo(
            'Notification opened app (from background): ${message.messageId}');

        // If there's a pending notification, it means app was opened from terminated state
        // and we should let Home handle it via the pending notification mechanism
        // to ensure proper navigation stack: Splash -> Home -> Chat
        if (_pendingNotification != null) {
          logInfo(
              'Skipping onMessageOpenedApp - pending notification exists, will be handled by Home');
          return;
        }

        // Only handle if we're NOT at splash screen (app was actually in background)
        // This prevents race condition where splash hasn't navigated to home yet
        if (Get.currentRoute == Routes.splash) {
          logInfo(
              'Skipping onMessageOpenedApp - still at splash, storing as pending');
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

  /// Check if app was opened from a terminated state via notification
  /// Call this after app initialization
  /// Instead of navigating directly, store the notification for Home to handle
  /// This ensures proper navigation stack: Splash -> Home -> Chat
  static Future<void> checkInitialMessage() async {
    try {
      final initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        logInfo(
            'App opened from terminated state via notification: ${initialMessage.messageId}');
        // Store the notification - Home will handle it after loading
        // This ensures navigation stack: Splash -> Home -> Chat
        _pendingNotification = initialMessage;
      }
    } catch (e, stackTrace) {
      logError('Error checking initial message',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Check if user is authenticated
  static bool _isAuthenticated() {
    if (!Get.isRegistered<StorageService>()) {
      return false;
    }
    final storage = Get.find<StorageService>();
    final token = storage.readString('access_token');
    return token != null && token.isNotEmpty;
  }

  /// Check if current route is a public route (login, signup, etc.)
  static bool _isPublicRoute() {
    final currentRoute = Get.currentRoute;
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
    return publicRoutes.contains(currentRoute);
  }

  /// Refresh all data when app resumes from background
  /// This ensures views are updated when user returns to app after receiving notifications
  /// Similar to handleNotificationClick pattern in reference code
  static void refreshAllDataOnAppResume() {
    try {
      logInfo('App resumed from background - refreshing all data');

      // Only refresh data if user is authenticated and not on public routes
      if (!_isAuthenticated() || _isPublicRoute()) {
        logInfo(
            'User not authenticated or on public route, skipping data refresh');
        return;
      }

      // Always refresh notification count
      _refreshNotificationCount();

      // Refresh chat inbox if available
      _refreshChatInbox();

      // Refresh calendar and bookings if available
      _refreshCalendar();

      // Refresh profile data if available
      _refreshProfile();

      logInfo('All data refresh triggered on app resume');
    } catch (e, stackTrace) {
      logError('Error refreshing data on app resume',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Refresh notification count
  static void _refreshNotificationCount() {
    try {
      if (Get.isRegistered<NotificationService>()) {
        final notificationService = Get.find<NotificationService>();
        notificationService.fetchNotificationCount();
        logInfo('Notification count refresh triggered');
      } else {
        logInfo('NotificationService not registered, skipping count refresh');
      }
    } catch (e, stackTrace) {
      logError('Error refreshing notification count',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Refresh chat inbox if MessagesController is available
  static void _refreshChatInbox() {
    try {
      if (Get.isRegistered<MessagesController>()) {
        final messagesController = Get.find<MessagesController>();
        messagesController.checkAndReconnectSocket();
        logInfo('Chat inbox refresh triggered');
      } else {
        logInfo('MessagesController not registered, skipping inbox refresh');
      }
    } catch (e, stackTrace) {
      logError('Error refreshing chat inbox', error: e, stackTrace: stackTrace);
    }
  }

  /// Refresh profile data if HomeController is available
  static void _refreshProfile() {
    try {
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        homeController.loadProfileDetails();
        logInfo('Profile data refresh triggered');
      } else {
        logInfo('HomeController not registered, skipping profile refresh');
      }
    } catch (e, stackTrace) {
      logError('Error refreshing profile data',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Handle notification tap based on message data
  static void _handleNotificationTap(RemoteMessage message) {
    try {
      final notificationType = message.data['type']?.toString();
      final messageId = message.messageId;
      logInfo('Handling notification tap - Type: $notificationType, ID: $messageId, User Type: ${_getUserType()}');

      // Prevent duplicate handling of the same notification
      if (messageId != null && messageId == _lastHandledNotificationId) {
        logInfo('Notification already handled, skipping duplicate: $messageId');
        return;
      }

      // Mark this notification as handled
      if (messageId != null) {
        _lastHandledNotificationId = messageId;
      }

      // Always refresh notification count when notification is tapped
      _refreshNotificationCount();

      // Route based on user type
      if (_isProfessionalUser()) {
        _handleProfessionalNotificationTap(message, notificationType);
      } else if (_isEndUser()) {
        _handleEndUserNotificationTap(message, notificationType);
      } else {
        logInfo('Unknown user type, using default notification handling');
        _handleDefaultNotificationTap(message, notificationType);
      }
    } catch (e, stackTrace) {
      logError('Error handling notification tap',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Handle notification tap for professional users
  static void _handleProfessionalNotificationTap(RemoteMessage message, String? notificationType) {
    if (notificationType == 'chat_message') {
      // Refresh chat inbox data
      _refreshChatInbox();
      // Navigate to specific chat
      _navigateToChat(message);
    } else if (notificationType == 'new_booking' ||
        notificationType == 'booking_cancelled' ||
        notificationType == 'booking_updated') {
      // Refresh calendar and bookings data
      _refreshCalendar();
      // Navigate to home and select Calendar tab (index 1)
      if (Get.currentRoute != Routes.home) {
        Get.toNamed(Routes.home);
        // Wait a bit for navigation to complete, then select Calendar tab
        Future.delayed(const Duration(milliseconds: 300), () {
          _selectCalendarTab();
        });
        logInfo('Navigated to home (calendar tab) for $notificationType');
      } else {
        // Already on home screen, just select Calendar tab
        _selectCalendarTab();
        logInfo(
            'Already on home screen, selected Calendar tab for $notificationType');
      }
    } else if (notificationType == 'application_approved') {
      // Refresh profile data when approval notification is tapped
      _refreshProfile();
      // Navigate to notifications screen
      Get.toNamed(Routes.notifications);
      logInfo('Navigated to notifications screen for application approval');
    } else {
      // Handle other notification types if needed
      logInfo('Unknown notification type for professional: $notificationType');
    }
  }

  /// Handle notification tap for end users
  static void _handleEndUserNotificationTap(RemoteMessage message, String? notificationType) {
    final data = message.data;

    if (_isEndUserBookingNotificationType(notificationType)) {
      if (notificationType == "booking_completed_review" ||
          notificationType == "review_reminder" ||
          notificationType == "final_review_reminder") {
        _openEndUserReviewDialog(data);
        logInfo(
            'Opened review dialog from ${notificationType} notification (FCM tap)');
      } else {
        _openEndUserBookingsTab();
        logInfo("Navigated to Bookings tab from booking notification (FCM tap)");
      }
      return;
    }

    // Handle chat message notification - navigate to chat detail
    if (notificationType == "chat_message") {
      _refreshEndUserMessagesInbox();
      _navigateToEndUserChat(message);
      return;
    }

    // Handle other notification types
    logInfo('Unknown notification type for end user: $notificationType');
  }

  /// Handle default notification tap when user type is unknown
  static void _handleDefaultNotificationTap(RemoteMessage message, String? notificationType) {
    logInfo('Default notification handling for type: $notificationType');
  }

  /// Select Messages tab (index 2) in HomeController
  static void _selectMessagesTab() {
    try {
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        homeController.onTabSelected(2); // Messages tab is at index 2
        logInfo('Messages tab selected');
      } else {
        logInfo('HomeController not registered, cannot select Messages tab');
      }
    } catch (e, stackTrace) {
      logError('Error selecting Messages tab',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Select Calendar tab (index 1) in HomeController
  static void _selectCalendarTab() {
    try {
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        homeController.onTabSelected(0); // Calendar tab is at index 1
        logInfo('Calendar tab selected');
      } else {
        logInfo('HomeController not registered, cannot select Calendar tab');
      }
    } catch (e, stackTrace) {
      logError('Error selecting Calendar tab',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Refresh calendar if CalendarController is available
  static void _refreshCalendar() {
    try {
      if (Get.isRegistered<CalendarController>()) {
        final calendarController = Get.find<CalendarController>();
        calendarController.refreshServiceFormatAvailability();
        logInfo('Calendar refresh triggered');
      } else {
        logInfo('CalendarController not registered, skipping calendar refresh');
      }

      // Also refresh bookings in HomeController if available
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        homeController.loadBookingsList();
        logInfo('Bookings list refresh triggered');
      }
    } catch (e, stackTrace) {
      logError('Error refreshing calendar', error: e, stackTrace: stackTrace);
    }
  }

  /// Handle notification tap from local notification payload
  static void _handleNotificationTapFromPayload(String payload) {
    try {
      // Parse payload - it's a string representation of the data map
      // Format: "{key1: value1, key2: value2}"
      logInfo('Parsing payload: $payload, User Type: ${_getUserType()}');

      // Always refresh notification count when notification is tapped
      _refreshNotificationCount();

      // Route based on user type
      if (_isProfessionalUser()) {
        _handleProfessionalNotificationTapFromPayload(payload);
      } else if (_isEndUser()) {
        _handleEndUserNotificationTapFromPayload(payload);
      } else {
        logInfo('Unknown user type, using default payload handling');
        _handleDefaultNotificationTapFromPayload(payload);
      }
    } catch (e, stackTrace) {
      logError('Error handling notification tap from payload',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Handle notification tap from payload for professional users
  static void _handleProfessionalNotificationTapFromPayload(String payload) {
    // Extract type from payload string
    if (payload.contains("type: chat_message") ||
        payload.contains("'type': 'chat_message'")) {
      // Refresh chat inbox data
      _refreshChatInbox();
      // Navigate to specific chat from payload
      _navigateToChatFromPayload(payload);
    } else if (payload.contains("type: new_booking") ||
        payload.contains("'type': 'new_booking'") ||
        payload.contains("type: booking_cancelled") ||
        payload.contains("'type': 'booking_cancelled'") ||
        payload.contains("type: booking_updated") ||
        payload.contains("'type': 'booking_updated'")) {
      // Refresh calendar and bookings data
      _refreshCalendar();
      // Navigate to home and select Calendar tab (index 1)
      if (Get.currentRoute != Routes.home) {
        Get.toNamed(Routes.home);
        // Wait a bit for navigation to complete, then select Calendar tab
        Future.delayed(const Duration(milliseconds: 300), () {
          _selectCalendarTab();
        });
        logInfo('Professional navigated to home (calendar tab) from payload');
      } else {
        // Already on home screen, just select Calendar tab
        _selectCalendarTab();
        logInfo('Professional already on home screen, selected Calendar tab from payload');
      }
    } else if (payload.contains("type: application_approved") ||
        payload.contains("'type': 'application_approved'")) {
      // Refresh profile data and navigate to notifications screen
      _refreshProfile();
      Get.toNamed(Routes.notifications);
      logInfo(
          'Professional navigated to notifications screen from payload for application approval');
    }
  }

  /// Handle notification tap from payload for end users
  static void _handleEndUserNotificationTapFromPayload(String payload) {
    // Check for booking notifications first
    if (payload.contains("type: booking_rescheduled_by_professional") ||
        payload.contains("'type': 'booking_rescheduled_by_professional'") ||
        payload.contains("type: booking_cancelled_by_professional") ||
        payload.contains("'type': 'booking_cancelled_by_professional'") ||
        payload.contains("type: booking_three_day_reminder") ||
        payload.contains("'type': 'booking_three_day_reminder'") ||
        payload.contains("type: booking_one_day_reminder") ||
        payload.contains("'type': 'booking_one_day_reminder'") ||
        payload.contains("type: booking_one_hour_reminder") ||
        payload.contains("'type': 'booking_one_hour_reminder'") ||
        payload.contains("type: booking_end_reminder") ||
        payload.contains("'type': 'booking_end_reminder'") ||
        payload.contains("type: booking_ended") ||
        payload.contains("'type': 'booking_ended'") ||
        payload.contains("type: booking_started") ||
        payload.contains("'type': 'booking_started'") ||
        payload.contains("type: booking_start_reminder") ||
        payload.contains("'type': 'booking_start_reminder'")) {
      _openEndUserBookingsTab();
      logInfo("End user navigated to Bookings tab from booking notification (local tap)");
      return;
    }

    // Handle review-related notifications
    if (payload.contains("type: booking_completed_review") ||
        payload.contains("'type': 'booking_completed_review'") ||
        payload.contains("type: review_reminder") ||
        payload.contains("'type': 'review_reminder'") ||
        payload.contains("type: final_review_reminder") ||
        payload.contains("'type': 'final_review_reminder'")) {
      // Parse payload to extract data
      Map<String, dynamic> data = _parsePayloadToMap(payload);
      _openEndUserReviewDialog(data);
      logInfo("End user opened review dialog from ${data['type']} notification (local tap)");
      return;
    }

    // Handle chat message notifications
    if (payload.contains("type: chat_message") ||
        payload.contains("'type': 'chat_message'")) {
      _refreshEndUserMessagesInbox();
      _navigateToEndUserChatFromPayload(payload);
      logInfo("End user navigated to chat from chat message notification (local tap)");
      return;
    }

    logInfo('End user unknown notification type in payload: $payload');
  }

  /// Handle default notification tap from payload when user type is unknown
  static void _handleDefaultNotificationTapFromPayload(String payload) {
    logInfo('Default payload handling for: $payload');
  }

  /// Parse payload string to Map
  static Map<String, dynamic> _parsePayloadToMap(String payload) {
    try {
      // Remove outer braces if present
      if (payload.startsWith('{') && payload.endsWith('}')) {
        payload = payload.substring(1, payload.length - 1);
      }

      Map<String, dynamic> mapped = {};
      List<String> keyValuePairs = payload.split(',');
      for (String keyValuePair in keyValuePairs) {
        List<String> keyValue = keyValuePair.split(':');
        if (keyValue.length == 2) {
          String key = keyValue[0].trim().replaceAll(RegExp(r'[{}"]'), '');
          String value = keyValue
              .sublist(1)
              .join(':')
              .trim()
              .replaceAll(RegExp(r'["}]'), '');
          mapped[key] = value;
        }
      }
      return mapped;
    } catch (e) {
      logError("Error parsing payload to map: $e");
      return {};
    }
  }

  /// Navigate to end user chat from payload
  static void _navigateToEndUserChatFromPayload(String payload) {
    try {
      Map<String, dynamic> valueMap = _parsePayloadToMap(payload);

      // Extract chat room information from notification model
      final chatRoomId = valueMap['room_id']?.toString();
      final receiverId = valueMap['sender_id']?.toString();
      final senderName = valueMap['full_name']?.toString() ?? 'Unknown';
      final profilePicture = valueMap['profile_picture']?.toString() ?? '';
      final lastMessage = valueMap['body']?.toString() ?? 'New message';
      final title = valueMap['title']?.toString() ?? 'New Message';

      logInfo("=== END USER NOTIFICATION EXTRACTION DEBUG ===");
      logInfo("Extracted chatRoomId: $chatRoomId");
      logInfo("Extracted receiverId: $receiverId");
      logInfo("Extracted senderName: $senderName");
      logInfo("Extracted profilePicture: $profilePicture");

      // Create conversation object for navigation with all payload data
      final conversation = Conversation(
        id: chatRoomId ?? '',
        name: senderName,
        lastMessage: lastMessage,
        lastMessageTime: DateTime.now(),
        userId: receiverId,
        isOnline: false,
        profileImageUrl: profilePicture,
      );

      Get.to(
            () => ChatDetailScreen(),
        binding: ChatDetailBinding(),
        arguments: {
          'conversation': conversation,
          'notificationData': {
            'title': title,
            'body': lastMessage,
            'sender_id': receiverId,
            'room_id': chatRoomId,
            'full_name': senderName,
            'profile_picture': profilePicture,
            'timestamp': valueMap['timestamp'],
            'click_action': valueMap['click_action'],
          },
        },
      );

      // Navigate to chat detail screen with conversation data
/*      Get.toNamed(
        enduser_routes.AppRoutes.chat_detail,
        arguments: {
          'conversation': conversation,
          'notificationData': {
            'title': title,
            'body': lastMessage,
            'sender_id': receiverId,
            'room_id': chatRoomId,
            'full_name': senderName,
            'profile_picture': profilePicture,
            'timestamp': valueMap['timestamp'],
            'click_action': valueMap['click_action'],
          },
        },
      );*/

      logInfo("End user navigated to chat detail from notification");
    } catch (e, stackTrace) {
      logError('Error navigating end user to chat from payload',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Check if chat notification should be hidden
  /// Returns true if chat is open and message is from the same user
  static bool _shouldHideChatNotification(RemoteMessage message) {
    try {
      // Check if ChatController is registered (chat is open)
      if (!Get.isRegistered<ChatController>()) {
        return false; // Chat is not open, show notification
      }

      final chatController = Get.find<ChatController>();
      final peerUserId = chatController.peer.value.userId;

      if (peerUserId == null || peerUserId.isEmpty) {
        return false; // Can't determine peer, show notification
      }

      // Extract sender ID from notification data
      final senderId = _extractSenderIdFromNotification(message.data);

      if (senderId == null || senderId.isEmpty) {
        return false; // Can't determine sender, show notification
      }

      // Compare sender ID with peer user ID
      final shouldHide = senderId == peerUserId;
      logInfo(
          'Chat notification check - Peer: $peerUserId, Sender: $senderId, Hide: $shouldHide');
      return shouldHide;
    } catch (e) {
      logError('Error checking if chat notification should be hidden',
          error: e);
      return false; // On error, show notification
    }
  }

  /// Extract sender ID from notification data
  static String? _extractSenderIdFromNotification(Map<String, dynamic> data) {
    try {
      // Try to extract sender ID from various possible fields
      final senderIdData = data['sender_id'] ??
          data['senderId'] ??
          data['user_id'] ??
          data['userId'] ??
          data['from_id'] ??
          data['fromId'];

      if (senderIdData == null) return null;

      // If it's already a string, return it
      if (senderIdData is String) {
        return senderIdData;
      }

      // If it's a Map/object, extract the _id field
      if (senderIdData is Map<String, dynamic>) {
        return senderIdData['_id']?.toString() ??
            senderIdData['id']?.toString() ??
            senderIdData['userId']?.toString() ??
            senderIdData['user_id']?.toString();
      }

      // Try to convert to string as fallback
      return senderIdData.toString();
    } catch (e) {
      logError('Error extracting sender ID from notification', error: e);
      return null;
    }
  }

  /// Navigate to specific chat from notification
  static void _navigateToChat(RemoteMessage message) {
    try {
      // Prevent double navigation - check if already on chat route
      if (Get.currentRoute == Routes.chat) {
        logInfo('Already on chat screen, skipping navigation');
        return;
      }

      final data = message.data;

      // Extract user ID and chat ID from notification data
      final userId = _extractSenderIdFromNotification(data) ??
          data['user_id']?.toString() ??
          data['userId']?.toString();

      final chatId = data['chat_id']?.toString() ??
          data['chatId']?.toString() ??
          data['room_id']?.toString() ??
          data['roomId']?.toString();

      // Extract name from notification - check sender_id.full_name if sender_id is an object
      String? name;
      bool isOnline = false;
      String? avatarAsset;

      // First try to extract from sender_id object if it exists
      final senderIdData = data['sender_id'] ?? data['senderId'];
      if (senderIdData is Map<String, dynamic>) {
        name = senderIdData['full_name']?.toString() ??
            senderIdData['fullName']?.toString() ??
            senderIdData['name']?.toString();
        // Extract online status from sender object
        isOnline = senderIdData['is_online'] as bool? ??
            senderIdData['isOnline'] as bool? ??
            false;
        // Extract avatar/profile picture
        avatarAsset = senderIdData['profile_picture']?.toString() ??
            senderIdData['profilePicture']?.toString() ??
            senderIdData['avatar']?.toString();
      }

      // Fallback to other fields if not found in sender_id
      name ??= message.notification?.title ??
          data['name']?.toString() ??
          data['full_name']?.toString() ??
          data['sender_name']?.toString() ??
          data['senderName']?.toString() ??
          'User';

      // Try to get online status from root data if not in sender object
      if (!isOnline) {
        isOnline = data['is_online'] as bool? ??
            data['isOnline'] as bool? ??
            false;
      }

      // Create arguments for chat navigation
      final arguments = <String, dynamic>{
        'userId': userId,
        'name': name, // Use 'name' to match what chat controller expects
        'isOnline': isOnline,
        if (avatarAsset != null && avatarAsset.isNotEmpty)
          'avatarAsset': avatarAsset,
        if (chatId != null && chatId.isNotEmpty) 'chatId': chatId,
      };

      logInfo(
          'Navigating to chat - UserId: $userId, Name: $name, isOnline: $isOnline, ChatId: $chatId');

      // Navigate to chat screen
      Get.toNamed(Routes.chat, arguments: arguments);
    } catch (e, stackTrace) {
      logError('Error navigating to chat from notification',
          error: e, stackTrace: stackTrace);
      // Fallback: navigate to messages tab
      if (Get.currentRoute != Routes.home) {
        Get.toNamed(Routes.home);
        Future.delayed(const Duration(milliseconds: 300), () {
          _selectMessagesTab();
        });
      } else {
        _selectMessagesTab();
      }
    }
  }

  /// Navigate to specific chat from payload string
  static void _navigateToChatFromPayload(String payload) {
    try {
      // Prevent double navigation - check if already on chat route
      if (Get.currentRoute == Routes.chat) {
        logInfo('Already on chat screen, skipping navigation from payload');
        return;
      }

      // Try to extract user ID and chat ID from payload string
      // Payload format: "{key1: value1, key2: value2}"
      String? userId;
      String? chatId;
      String? name;
      bool isOnline = false;

      // Extract userId - try multiple patterns
      // Note: sender_id might be an object like {_id: xxx, full_name: yyy}
      // So we need to extract _id from within sender_id object first
      final senderIdObjectPattern = RegExp(r"sender_id\s*:\s*\{([^}]+)\}");
      final senderIdObjectMatch = senderIdObjectPattern.firstMatch(payload);
      if (senderIdObjectMatch != null) {
        final senderIdContent = senderIdObjectMatch.group(1) ?? '';
        // Extract _id from sender_id object
        final idPattern = RegExp(r"_id\s*:\s*([^,}]+)");
        final idMatch = idPattern.firstMatch(senderIdContent);
        if (idMatch != null) {
          userId = idMatch.group(1)?.trim().replaceAll("'", '').replaceAll('"', '');
        }
        // Extract full_name from sender_id object
        final nameInSenderPattern = RegExp(r"full_name\s*:\s*([^,}]+)");
        final nameInSenderMatch = nameInSenderPattern.firstMatch(senderIdContent);
        if (nameInSenderMatch != null) {
          name = nameInSenderMatch.group(1)?.trim().replaceAll("'", '').replaceAll('"', '');
        }
        // Extract is_online from sender_id object
        final onlinePattern = RegExp(r"is_online\s*:\s*(true|false)");
        final onlineMatch = onlinePattern.firstMatch(senderIdContent);
        if (onlineMatch != null) {
          isOnline = onlineMatch.group(1) == 'true';
        }
      }

      // If userId not found in sender_id object, try other patterns
      if (userId == null || userId.isEmpty) {
        final userIdPatterns = [
          RegExp(r"user_id\s*:\s*([^,}]+)"),
          RegExp(r"userId\s*:\s*([^,}]+)"),
        ];
        for (final pattern in userIdPatterns) {
          final match = pattern.firstMatch(payload);
          if (match != null) {
            final extracted = match.group(1)?.trim() ?? '';
            userId = extracted.replaceAll("'", '').replaceAll('"', '');
            // Skip if it looks like an object (starts with {)
            if (!userId.startsWith('{')) {
              break;
            }
            userId = null;
          }
        }
      }

      // Extract chatId - try multiple patterns
      final chatIdPatterns = [
        RegExp(r"chat_id\s*:\s*([^,}]+)"),
        RegExp(r"chatId\s*:\s*([^,}]+)"),
        RegExp(r"room_id\s*:\s*([^,}]+)"),
        RegExp(r"roomId\s*:\s*([^,}]+)"),
      ];
      for (final pattern in chatIdPatterns) {
        final match = pattern.firstMatch(payload);
        if (match != null) {
          final extracted = match.group(1)?.trim() ?? '';
          chatId = extracted.replaceAll("'", '').replaceAll('"', '');
          break;
        }
      }

      // Extract name if not found in sender_id object - try multiple patterns
      if (name == null || name.isEmpty) {
        final namePatterns = [
          RegExp(r"full_name\s*:\s*([^,}]+)"),
          RegExp(r"fullName\s*:\s*([^,}]+)"),
          RegExp(r"sender_name\s*:\s*([^,}]+)"),
          RegExp(r"senderName\s*:\s*([^,}]+)"),
        ];
        for (final pattern in namePatterns) {
          final match = pattern.firstMatch(payload);
          if (match != null) {
            final extracted = match.group(1)?.trim() ?? '';
            name = extracted.replaceAll("'", '').replaceAll('"', '');
            break;
          }
        }
      }

      // Extract is_online if not found in sender_id object
      if (!isOnline) {
        final onlinePatterns = [
          RegExp(r"is_online\s*:\s*(true|false)"),
          RegExp(r"isOnline\s*:\s*(true|false)"),
        ];
        for (final pattern in onlinePatterns) {
          final match = pattern.firstMatch(payload);
          if (match != null) {
            isOnline = match.group(1) == 'true';
            break;
          }
        }
      }

      if (userId != null && userId.isNotEmpty) {
        // Create arguments for chat navigation
        final arguments = <String, dynamic>{
          'userId': userId,
          'name': name ?? 'User',
          'isOnline': isOnline,
          if (chatId != null && chatId.isNotEmpty) 'chatId': chatId,
        };

        logInfo(
            'Navigating to chat from payload - UserId: $userId, Name: $name, isOnline: $isOnline, ChatId: $chatId');

        // Navigate to chat screen
        Get.toNamed(Routes.chat, arguments: arguments);
        return;
      }

      // Fallback: navigate to messages tab if can't extract userId
      logInfo(
          'Could not extract userId from payload, navigating to messages tab');
      if (Get.currentRoute != Routes.home) {
        Get.toNamed(Routes.home);
        Future.delayed(const Duration(milliseconds: 300), () {
          _selectMessagesTab();
        });
      } else {
        _selectMessagesTab();
      }
    } catch (e, stackTrace) {
      logError('Error navigating to chat from payload',
          error: e, stackTrace: stackTrace);
      // Fallback: navigate to messages tab
      if (Get.currentRoute != Routes.home) {
        Get.toNamed(Routes.home);
        Future.delayed(const Duration(milliseconds: 300), () {
          _selectMessagesTab();
        });
      } else {
        _selectMessagesTab();
      }
    }
  }

  // ==================== END USER SPECIFIC METHODS ====================

  /// Check if end user chat detail screen is active with the same user
  static bool _isEndUserChatDetailActiveWithUser(String? senderId, String? roomId) {
    try {
      // Check if ChatDetailController is registered and active
      if (!Get.isRegistered<ChatDetailController>()) {
        logInfo("End user ChatDetailController not registered");
        return false;
      }

      final chatController = Get.find<ChatDetailController>();
      final currentConversation = chatController.conversation;

      // Check if current chat is with the same user
      final isSameUser =
          currentConversation.value!.userId == senderId ||
              currentConversation.value!.id == roomId;

      logInfo("End user current chat user ID: ${currentConversation.value!.userId}");
      logInfo("End user current chat room ID: ${currentConversation.value!.id}");
      logInfo("End user incoming sender ID: $senderId");
      logInfo("End user incoming room ID: $roomId");
      logInfo("End user is same user: $isSameUser");

      return isSameUser;
    } catch (e) {
      logError("Error checking end user chat detail status: $e");
      return false;
    }
  }

  /// Refresh end user messages inbox
  static void _refreshEndUserMessagesInbox() {
    try {
      if (Get.isRegistered<MessagesController>(tag: 'messages')) {
        final messagesController = Get.find<MessagesController>(tag: 'messages');
        messagesController.silentRefreshInbox();
        logInfo('End user messages inbox refresh triggered');
      } else {
        logInfo('End user MessagesController not registered, skipping inbox refresh');
      }
    } catch (e, stackTrace) {
      logError('Error refreshing end user messages inbox', error: e, stackTrace: stackTrace);
    }
  }

  /// Refresh end user notification count
  static void _refreshEndUserNotificationCount() {
    try {
      if (Get.isRegistered<HomeMainController>(tag: 'home')) {
        Get.find<HomeMainController>(tag: 'home').fetchNotificationCount();
        logInfo('End user notification count refresh triggered');
      } else {
        logInfo('End user HomeMainController not registered, skipping notification count refresh');
      }
    } catch (e, stackTrace) {
      logError('Error refreshing end user notification count', error: e, stackTrace: stackTrace);
    }
  }

  /// Refresh end user bookings
  static void _refreshEndUserBookings() {
    try {
      if (Get.isRegistered<BookingsController>(tag: 'bookings')) {
        final bookingsController = Get.find<BookingsController>(tag: 'bookings');
        bookingsController.refreshData();
        logInfo('End user bookings refresh triggered');
      } else {
        logInfo('End user BookingsController not registered, skipping bookings refresh');
      }
    } catch (e, stackTrace) {
      logError('Error refreshing end user bookings', error: e, stackTrace: stackTrace);
    }
  }

  /// Open the Bookings tab for end users
  static void _openEndUserBookingsTab() {
    try {
      if (Get.isRegistered<MainTabController>()) {
        final controller = Get.find<MainTabController>();
        controller.setTab(1); // 0: home, 1: bookings, 2: messages
        logInfo("End user switched to Bookings tab via MainTabController");
        // Also refresh bookings data if controller is available
        if (Get.isRegistered<BookingsController>(tag: 'bookings')) {
          try {
            final bookingsController = Get.find<BookingsController>(tag: 'bookings');
            bookingsController.refreshData();
            logInfo("End user refreshed bookings data after switching tab");
          } catch (e) {
            logError("Error refreshing end user bookings after switching tab: $e");
          }
        }
      } else {
        Get.toNamed(enduser_routes.AppRoutes.main, arguments: {'openTab': 1});
        logInfo("End user navigated to MainScreen with Bookings tab open");
      }
    } catch (e) {
      logError("Error opening end user Bookings tab: $e");
    }
  }

  /// Open review dialog for end users
  static Future<void> _openEndUserReviewDialog(Map<String, dynamic> data) async {
    try {
      // Extract required data from notification
      final professionalId = data['professional_id']?.toString() ?? '';
      final bookingId = data['booking_id']?.toString() ?? '';
      final professionalName =
          data['professional_name']?.toString() ??
              data['full_name']?.toString() ??
              'Professional';

      if (professionalId.isEmpty || bookingId.isEmpty) {
        logError("Missing professional_id or booking_id in notification data");
        // Fallback to bookings tab if required data is missing
        _openEndUserBookingsTab();
        return;
      }

      logInfo(
        "Opening end user review dialog for professional: $professionalName, ID: $professionalId, Booking: $bookingId",
      );

      // Navigate to home screen first, then show dialog
      final navigationResult = await Get.toNamed(
        enduser_routes.AppRoutes.main,
        arguments: {'openTab': 0}, // Home tab
      );

      // Show dialog after navigation completes with retry logic
      _showEndUserReviewDialogWithRetry(professionalName, professionalId, bookingId);
    } catch (e) {
      logError("Error opening end user review dialog: $e");
      // Fallback to bookings tab
      _openEndUserBookingsTab();
    }
  }

  /// Show review dialog with retry logic for end users
  static void _showEndUserReviewDialogWithRetry(
      String professionalName,
      String professionalId,
      String bookingId,
      ) {
    int retryCount = 0;
    const maxRetries = 10;

    void tryShowDialog() {
      retryCount++;
      logInfo("Attempting to show end user review dialog (attempt $retryCount/$maxRetries)");

      if (Get.isRegistered<HomeMainController>()) {
        logInfo("End user HomeMainController found, showing dialog");
        final homeController = Get.find<HomeMainController>();
        homeController.showReviewDialog(
          professionalName,
          professionalId,
          bookingId,
        );
      } else if (retryCount < maxRetries) {
        logInfo("End user HomeMainController not yet registered, retrying in 500ms...");
        Future.delayed(Duration(milliseconds: 500), () {
          tryShowDialog();
        });
      } else {
        logInfo(
          "End user HomeMainController not registered after $maxRetries attempts, showing fallback dialog",
        );
        _showEndUserFallbackReviewDialog(professionalName, professionalId, bookingId);
      }
    }

    tryShowDialog();
  }

  /// Show fallback review dialog directly for end users
  static void _showEndUserFallbackReviewDialog(
      String professionalName,
      String professionalId,
      String bookingId,
      ) {
    logInfo("Showing end user fallback review dialog for: $professionalName");

    // Create the dialog directly without relying on HomeMainController
    final TextEditingController reviewController = TextEditingController();
    final RxInt rating = 0.obs;
    final RxBool isSubmitting = false.obs;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main content container
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 24),
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

                  SizedBox(height: 24),

                  // Star Rating
                  Obx(
                        () => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () => rating.value = index + 1,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: SvgPicture.asset(
                              AppAssets.rating_selected,
                              color: index < rating.value
                                  ? AppColors.ratingSelectedColor
                                  : AppColors.unselectedTabColor,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Review Text Field
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
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
                        contentPadding: EdgeInsets.all(16),
                        counterStyle: AppTextStyles.regularTextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
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

            // Submit Button - Attached at bottom
            Obx(
                  () => Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: isSubmitting.value
                      ? Colors.grey
                      : AppColors.primaryColor,
                  borderRadius: BorderRadius.only(
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
                          duration: Duration(seconds: 2),
                        );
                        return;
                      }

                      // Submit review with API call
                      isSubmitting.value = true;

                      try {
                        await _submitEndUserReviewFallback(
                          professionalId: professionalId,
                          bookingId: bookingId,
                          rating: rating.value,
                          review: reviewController.text.trim(),
                        );

                        Get.back(); // Close dialog
                        Get.snackbar(
                          'Review Submitted',
                          'Thank you for your feedback!',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.primaryColor
                              .withOpacity(0.2),
                          duration: Duration(seconds: 2),
                        );
                      } catch (e) {
                        String errorMessage =
                            "Failed to submit review. Please try again.";

                        // Handle different exception types to extract proper error messages
                        if (e is NotFoundException) {
                          errorMessage = e.message;
                        } else if (e is ApiException) {
                          errorMessage = e.message;
                        } else if (e is Exception) {
                          String exceptionString = e.toString();
                          if (exceptionString.startsWith('Exception: ')) {
                            errorMessage = exceptionString.replaceFirst(
                              'Exception: ',
                              '',
                            );
                          } else {
                            errorMessage = exceptionString;
                          }
                        }

                        Get.snackbar(
                          'Error',
                          errorMessage,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red.shade100,
                          duration: Duration(seconds: 3),
                        );
                      } finally {
                        isSubmitting.value = false;
                      }
                    },
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: Center(
                      child: isSubmitting.value
                          ? SizedBox(
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

  /// Submit review fallback for end users
  static Future<void> _submitEndUserReviewFallback({
    required String professionalId,
    required String bookingId,
    required int rating,
    required String review,
  }) async {
    logInfo(
      "Submitting end user review (fallback): professionalId=$professionalId, bookingId=$bookingId, rating=$rating, review=$review",
    );

    if (!Get.isRegistered<ProjectRepository>(
      tag: (ProjectRepository).toString(),
    )) {
      throw Exception('Repository not available');
    }

    final repository = Get.find<ProjectRepository>(
      tag: (ProjectRepository).toString(),
    );

    final requestData = {
      "professional_id": professionalId,
      "booking_id": bookingId,
      "rating": rating,
      "review": review.isEmpty ? "" : review,
    };

    var service = repository.sendPostApiRequest(
          () => requestData,
      professionals_rate_review,
      true,
    );

    var response = await service;

    // Parse the response
    Map<String, dynamic> responseData;
    if (response != null && response.data != null) {
      responseData = response.data is Map<String, dynamic>
          ? response.data
          : response.data as Map<String, dynamic>;
    } else if (response is Map<String, dynamic>) {
      responseData = response;
    } else {
      throw Exception('Invalid response format');
    }

    bool success = responseData['success'] ?? false;

    if (!success) {
      String message = responseData['message'] ?? 'Failed to submit review';
      throw Exception(message);
    }

    logInfo("End user review submitted successfully (fallback): ${responseData['message']}");
  }

  /// Navigate to end user chat
  static void _navigateToEndUserChat(RemoteMessage message) {
    try {
      final data = message.data;

      // Extract chat room information from notification data
      final chatRoomId =
          data['room_id']?.toString() ??
              data['room_id']?.toString();
      final receiverId =
          data['sender_id']?.toString() ??
              data['sender_id']?.toString();
      final senderName =
          data['full_name']?.toString() ??
              data['full_name']?.toString() ??
              'Unknown';
      final profilePicture =
          data['profile_picture']?.toString() ??
              data['profile_picture']?.toString() ??
              '';
      final lastMessage =
          data['body']?.toString() ?? 'New message';
      final title =
          data['title']?.toString() ?? 'New Message';

      logInfo("=== END USER NAVIGATION FROM MESSAGE TAP DEBUG ===");
      logInfo("chatRoomId: $chatRoomId");
      logInfo("receiverId: $receiverId");
      logInfo("senderName: $senderName");
      logInfo("profilePicture: $profilePicture");

      final conversation = Conversation(
        id: chatRoomId ?? '',
        name: senderName,
        lastMessage: lastMessage,
        lastMessageTime: DateTime.now(),
        userId: receiverId,
        isOnline: false,
        profileImageUrl: profilePicture,
      );

      Get.to(
            () => ChatDetailScreen(),
        binding: ChatDetailBinding(),
        arguments: {
          'conversation': conversation,
          'notificationData': {
            'title': title,
            'body': lastMessage,
            'sender_id': receiverId,
            'room_id': chatRoomId,
            'full_name': senderName,
            'profile_picture': profilePicture,
            'timestamp': data['timestamp'],
            'click_action': data['click_action'],
          },
        },
      );

      /*    Get.toNamed(
        enduser_routes.AppRoutes.chat_detail,
        arguments: {
          'conversation': conversation,
          'notificationData': {
            'title': title,
            'body': lastMessage,
            'sender_id': receiverId,
            'room_id': chatRoomId,
            'full_name': senderName,
            'profile_picture': profilePicture,
            'timestamp': data['timestamp'],
            'click_action': data['click_action'],
          },
        },
      );*/

      logInfo("End user navigated to chat detail from FCM notification tap");
    } catch (e, stackTrace) {
      logError('Error navigating end user to chat from notification',
          error: e, stackTrace: stackTrace);
    }
  }

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
}
