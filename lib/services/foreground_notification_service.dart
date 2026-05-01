import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../enduser/screens/message/ChatDetailBinding.dart';
import '../enduser/screens/message/ChatDetailScreen.dart';
import '../utils/logger.dart';
import '../routes/app_routes.dart';
import '../professional/home/messages_controller.dart' as professional_messages;
import '../professional/home/home_controller.dart';
import '../professional/home/calendar_controller.dart';
import '../professional/home/chat/chat_controller.dart';
import '../enduser/screens/message/MessagesController.dart' as enduser_messages;
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
import '../api/user_api_service.dart';
import '../enduser/screens/message/socket_service.dart';
import '../professional/home/messages_controller.dart';
import '../services/socket_service.dart';
import '../services/social_auth_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'storage_service.dart';
import 'analytics_service.dart';

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

/// Notification types that should refresh booking data for professional users
const List<String> _professionalBookingNotificationTypes = [
  'new_booking',
  'booking_cancelled',
  'booking_updated',
  'booking_ended',
  'booking_started',
  'booking_start_reminder',
  'booking_end_reminder',
  'booking_one_hour_reminder',
  'booking_one_day_reminder',
  'booking_three_day_reminder',
];

/// Service to handle foreground notifications for both user types
class ForegroundNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  /// Stores pending notification data when app is opened from terminated state
  static RemoteMessage? _pendingNotification;
//New Code
  /// Stores pending booking tab navigation when app is at splash screen
  static int? _pendingBookingNavigation;
//New Code
  /// Stores pending review dialog data when app is at splash screen
  static Map<String, String>? _pendingReviewDialogData;

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
    return userType == 'normal';
  }

  /// Check if notification type is booking-related for end users
  static bool _isEndUserBookingNotificationType(String? type) {
    if (type == null) return false;
    return _endUserBookingNotificationTypes.contains(type);
  }

  /// Check if notification type is booking-related for professional users
  static bool _isProfessionalBookingNotificationType(String? type) {
    if (type == null) return false;
    return _professionalBookingNotificationTypes.contains(type);
  }

  /// Handle pending notification - call this from Home after it's ready
  static void handlePendingNotificationIfAny() {
    if (_pendingNotification != null) {
      final message = _pendingNotification!;
      _pendingNotification = null;
      logInfo(
          'Handling pending notification after Home loaded: ${message.messageId}');
      _handleNotificationTap(message);
    }
  }
//New Code
  /// Handle pending booking navigation - call this from Main after it's ready
  static void handlePendingBookingNavigationIfAny() {
    if (_pendingBookingNavigation != null) {
      final tabIndex = _pendingBookingNavigation!;
      _pendingBookingNavigation = null;
      logInfo(
          'Handling pending booking navigation after Main loaded: tab $tabIndex');
      if (Get.isRegistered<MainTabController>()) {
        final controller = Get.find<MainTabController>();
        controller.setTab(tabIndex);
        logInfo(
            'End user switched to tab $tabIndex via MainTabController (pending)');
        if (tabIndex == 1 &&
            Get.isRegistered<BookingsController>(tag: 'bookings')) {
          try {
            final bookingsController =
                Get.find<BookingsController>(tag: 'bookings');
            bookingsController.refreshData();
            logInfo(
                'End user refreshed bookings data after pending navigation');
          } catch (e) {
            logError(
                'Error refreshing end user bookings after pending navigation: $e');
          }
        }
      }
    }
  }
//New Code
  /// Handle pending review dialog - call this from Main after it's ready
  static void handlePendingReviewDialogIfAny() {
    if (_pendingReviewDialogData != null) {
      final data = _pendingReviewDialogData!;
      _pendingReviewDialogData = null;
      logInfo(
          'Handling pending review dialog after Main loaded: ${data['professionalName']}');
      _showEndUserReviewDialogWithRetry(
        data['professionalName'] ?? 'Professional',
        data['professionalId'] ?? '',
        data['bookingId'] ?? '',
      );
    }
  }

  /// Initialize local notifications
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
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }

    logInfo('Foreground notification service initialized');
  }

  /// Create notification channel for Android
  static Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'notification_id',
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

  /// Handle notification tap from local notification
  static void _onNotificationTapped(NotificationResponse response) {
    logInfo('Notification tapped: ${response.payload}');
    _handleNotificationTapFromPayload(response.payload ?? '');
  }

  // ---------------------------------------------------------------------------
  // SHOW FOREGROUND NOTIFICATION
  // ---------------------------------------------------------------------------
  //
  // FIX SUMMARY:
  //   • setupForegroundMessageHandler now ALWAYS calls showForegroundNotification
  //     on every platform so that data-refresh logic (calendar, profile, etc.)
  //     is never skipped.
  //   • Inside showForegroundNotification the refresh / controller-update code
  //     runs FIRST (unconditionally).
  //   • After the refresh block, on iOS we return early when the message already
  //     has a notification payload — APNs has already shown the banner, so we
  //     must NOT call _localNotifications.show() or the user sees two banners.
  //   • On Android (and iOS data-only messages) we fall through to
  //     _localNotifications.show() as before.
  //
  // ---------------------------------------------------------------------------
  static Future<void> showForegroundNotification(
      RemoteMessage message) async {
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

      final notificationType = message.data['type']?.toString();
      logInfo('Notification type: $notificationType');

      // -----------------------------------------------------------------------
      // STEP 1 — Always run data-refresh / controller-update logic.
      //
      // This block intentionally has NO platform guard.  Previously the iOS
      // path inside setupForegroundMessageHandler skipped calling this method
      // entirely when message.notification != null, which meant calendar /
      // profile refreshes were silently dropped on iOS.
      // -----------------------------------------------------------------------
      _refreshNotificationCount();

      bool shouldShowBanner = true;

      if (_isProfessionalUser()) {
        shouldShowBanner = await _handleProfessionalForegroundNotification(
            message, notificationType);
      } else if (_isEndUser()) {
        shouldShowBanner =
            await _handleEndUserForegroundNotification(message, notificationType);
      } else {
        logInfo('Unknown user type, using default notification handling');
        shouldShowBanner =
            await _handleDefaultForegroundNotification(message, notificationType);
      }

      if (!shouldShowBanner) {
        logInfo('Suppression rule matched — skipping local notification banner');
        return;
      }

      // -----------------------------------------------------------------------
      // STEP 2 — Decide whether to show a local notification banner.
      //
      // iOS:  When the FCM message carries a notification payload, APNs has
      //       already displayed the system banner.  Calling
      //       _localNotifications.show() here would produce a SECOND banner.
      //       We return early to prevent that duplicate.
      //
      // iOS data-only (notification == null):  APNs shows nothing, so we fall
      //       through and call _localNotifications.show() ourselves.
      //
      // Android: Always fall through — flutter_local_notifications is always
      //       responsible for the foreground banner on Android.
      // -----------------------------------------------------------------------
      if (Platform.isIOS && message.notification != null) {
        logInfo(
            'iOS: notification payload present — APNs already showed banner, skipping local notification to prevent duplicate.');
        return;
      }

      // Guard: nothing to show if notification has no meaningful content
      bool hasMeaningfulContent = false;
      
      // Check if title is not just the default placeholder
      if (title != 'Notification' && title.isNotEmpty) {
        hasMeaningfulContent = true;
      }
      
      // Check if body has actual content
      if (body.isNotEmpty) {
        hasMeaningfulContent = true;
      }
      
      if (!hasMeaningfulContent) {
        logInfo('Skipping notification: no meaningful content (title: "$title", body: "$body")');
        return;
      }

      logInfo('Preparing local notification banner — Title: $title, Body: $body');

      // -----------------------------------------------------------------------
      // STEP 3 — Show local notification banner.
      //   • Reached on Android always.
      //   • Reached on iOS only for data-only messages (notification == null).
      // -----------------------------------------------------------------------
      final androidDetails = AndroidNotificationDetails(
        'notification_id',
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

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId = message.messageId != null
          ? message.messageId.hashCode
          : DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _localNotifications.show(
        notificationId,
        title,
        body,
        details,
        payload: message.data.toString(),
      );

      logInfo(
          'Local notification banner shown — ID: $notificationId, Title: $title');
    } catch (e, stackTrace) {
      logError('Error showing foreground notification',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Handle foreground notifications for professional users
  static Future<bool> _handleProfessionalForegroundNotification(
      RemoteMessage message,
      String? notificationType,
      ) async {
    if (notificationType == 'chat_message') {
      logInfo(
          'Professional chat message notification received - refreshing inbox');
      _refreshProfessionalChatInbox();

      if (_shouldHideChatNotification(message)) {
        logInfo('Chat is open for same user - hiding notification');
        return false;
      }
      return true;
    } else if (_isProfessionalBookingNotificationType(notificationType)) {
      logInfo(
          'Professional booking notification received (type: $notificationType) - refreshing calendar');
      _refreshCalendar();
      return true;
    } else if (notificationType == 'application_approved') {
      logInfo(
          'Professional profile approval notification received - refreshing profile data');
      _refreshProfile();
      _refreshCalendar();
      return true;
    } else if (notificationType == 'session_timeout') {
      logInfo('Professional session timeout notification received - logging out');
      await _handleSessionTimeout();
      return false; // Don't show notification banner for session timeout
    }
    return true;
  }

  /// Handle foreground notifications for end users
  static Future<bool> _handleEndUserForegroundNotification(
      RemoteMessage message,
      String? notificationType,
      ) async {
    final data = message.data;

    if (notificationType == 'chat_message') {
      logInfo(
          'End user chat message notification received - refreshing inbox');
      _refreshEndUserMessagesInbox();

      // Robust extraction of sender and room IDs
      final senderId = _extractSenderIdFromNotification(data);
      final roomId = _extractRoomIdFromNotification(data);

      if (_isEndUserChatDetailActiveWithUser(senderId, roomId)) {
        logInfo(
            'End user chat detail screen is active with same user/room - skipping notification');
        return false;
      }
      return true;
    } else if (_isEndUserBookingNotificationType(notificationType)) {
      logInfo(
          'End user booking notification received (type: $notificationType) - refreshing bookings');
      _refreshEndUserBookings();

      if (notificationType == 'booking_completed_review' ||
          notificationType == 'review_reminder' ||
          notificationType == 'final_review_reminder') {
        logInfo('Handling $notificationType in foreground for end user');
        _openEndUserReviewDialog(data);
      }
      return true;
    } else if (notificationType == 'session_timeout') {
      logInfo('End user session timeout notification received - logging out');
      await _handleSessionTimeout();
      return false; // Don't show notification banner for session timeout
    } else {
      logInfo(
          'End user notification received (type: $notificationType) - refreshing notification count');
      _refreshEndUserNotificationCount();
    }
    return true;
  }

  /// Handle default foreground notifica tions when user type is unknown
  static Future<bool> _handleDefaultForegroundNotification(
      RemoteMessage message,
      String? notificationType,
      ) async {
    _refreshNotificationCount();
    logInfo('Default notification handling for type: $notificationType');
    return true;
  }

  /// Handle session timeout by logging out user and navigating to select user screen
  static Future<void> _handleSessionTimeout() async {
    try {
      logInfo('Handling session timeout - logging out user');
      
      // Call logout API
      await _callLogoutApi();
      
      // Perform comprehensive cleanup matching ProfileController pattern
      await _clearLocalDataAndNavigate();
      
      logInfo('Session timeout handled - user logged out and redirected to select user');
    } catch (e, stackTrace) {
      logError('Error handling session timeout: $e');
      // Even if logout API fails, proceed with local cleanup and navigation
      try {
        await _clearLocalDataAndNavigate();
      } catch (navError) {
        logError('Error navigating after session timeout failure: $navError');
      }
    }
  }

  /// Clear local data and navigate - matching ProfileController pattern
  static Future<void> _clearLocalDataAndNavigate() async {
    try {
      // 1. Reset socket services first (IMPORTANT: Disconnect before deleting)
      if (Get.isRegistered<EndUserSocketService>()) {
        final endUserSocket = Get.find<EndUserSocketService>();
        endUserSocket.disconnect();
        Get.delete<EndUserSocketService>();
        logInfo('EndUserSocketService disconnected and removed');
      }

      if (Get.isRegistered<SocketService>()) {
        final socketService = Get.find<SocketService>();
        socketService.disconnect();
        Get.delete<SocketService>();
        logInfo('Professional SocketService disconnected and removed');
      }

      // 2. Explicitly delete ALL professional controllers to clear their memory state
      if (Get.isRegistered<MessagesController>()) {
        Get.delete<MessagesController>();
        logInfo('MessagesController deleted');
      }

      if (Get.isRegistered<HomeController>()) {
        Get.delete<HomeController>();
        logInfo('HomeController deleted');
      }

      if (Get.isRegistered<CalendarController>()) {
        Get.delete<CalendarController>();
        logInfo('CalendarController deleted');
      }

      if (Get.isRegistered<ChatController>()) {
        Get.delete<ChatController>();
        logInfo('ChatController deleted');
      }

      // 3. Sign out from social providers
      try {
        final socialAuthService = SocialAuthService();
        await socialAuthService.signOutSocialProviders();
        logInfo('Social providers signed out');
      } catch (e) {
        logError('Error signing out from social providers: $e');
      }

      // 4. Clear stored data except remember me credentials
      if (Get.isRegistered<StorageService>()) {
        final storage = Get.find<StorageService>();

        // Define keys to keep (all remember me data)
        final keysToKeep = [
          'savedEmail', // Professional key
          'savedPassword', // Professional key
          'email', // End-user key
          'password', // End-user key
          'rememberMe', // End-user key
          'savedPassword', // End-user key
        ];

        await storage.clearAllExcept(keysToKeep);
        logInfo('Storage cleared except remember me data');
      }

      // 5. Final cleanup: reset current route and navigate
      Get.offAllNamed('/select_user');
      logInfo('Navigation to select user completed');
    } catch (e) {
      logError('Error in _clearLocalDataAndNavigate: $e');
      // Fallback: basic cleanup and navigation
      try {
        if (Get.isRegistered<StorageService>()) {
          final storage = Get.find<StorageService>();
          storage.clear();
        }
        Get.offAllNamed('/select_user');
      } catch (fallbackError) {
        logError('Fallback cleanup failed: $fallbackError');
      }
    }
  }

  /// Call logout API
  static Future<void> _callLogoutApi() async {
    if (!Get.isRegistered<UserApiService>()) return;
    try {
      await AnalyticsService.instance.clearUser();
      await Get.find<UserApiService>().logout();
    } catch (e) {
      logError('Logout API failed: $e');
      // Ignore logout failures; we still proceed with local cleanup
    }
  }

  // ---------------------------------------------------------------------------
  // SETUP FOREGROUND MESSAGE HANDLER
  // ---------------------------------------------------------------------------
  //
  // FIX: Always call showForegroundNotification regardless of platform.
  //      Previously iOS only called it when message.notification == null,
  //      which silently skipped all data-refresh logic for regular push
  //      notifications that carry a notification payload.
  //
  // The showForegroundNotification method itself now handles the iOS
  // duplicate-banner prevention internally (Step 2 above).
  //
  // ---------------------------------------------------------------------------
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

        // Always call showForegroundNotification on every platform.
        // The method decides internally whether to show a local banner
        // (skips banner on iOS when APNs already showed one).
        showForegroundNotification(message);
      });

      // Handle message opened app (when user taps notification while app is in background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        logInfo(
            'Notification opened app (from background): ${message.messageId}');

        if (_pendingNotification != null) {
          logInfo(
              'Skipping onMessageOpenedApp - pending notification exists, will be handled by Home');
          return;
        }

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
  static Future<void> checkInitialMessage() async {
    try {
      final initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        logInfo(
            'App opened from terminated state via notification: ${initialMessage.messageId}');
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

  /// Check if current route is a public route
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
  static void refreshAllDataOnAppResume() {
    try {
      logInfo('App resumed from background - refreshing all data');

      if (!_isAuthenticated() || _isPublicRoute()) {
        logInfo(
            'User not authenticated or on public route, skipping data refresh');
        return;
      }

      _refreshNotificationCount();
      
      // Refresh user-specific chat inbox
      if (_isProfessionalUser()) {
        _refreshProfessionalChatInbox();
      } else if (_isEndUser()) {
        _refreshEndUserMessagesInbox();
      }
      
      _refreshCalendar();
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
        logInfo(
            'NotificationService not registered, skipping count refresh');
      }
    } catch (e, stackTrace) {
      logError('Error refreshing notification count',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Refresh professional chat inbox if MessagesController is available
  static void _refreshProfessionalChatInbox() {
    try {
      if (Get.isRegistered<professional_messages.MessagesController>()) {
        final messagesController = Get.find<professional_messages.MessagesController>();
        messagesController.checkAndReconnectSocket();
        logInfo('Professional chat inbox refresh triggered');
      } else {
        logInfo(
            'Professional MessagesController not registered, skipping inbox refresh');
      }
    } catch (e, stackTrace) {
      logError('Error refreshing professional chat inbox',
          error: e, stackTrace: stackTrace);
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
        logInfo(
            'HomeController not registered, skipping profile refresh');
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
      logInfo(
          'Handling notification tap - Type: $notificationType, ID: $messageId, User Type: ${_getUserType()}');

      if (messageId != null && messageId == _lastHandledNotificationId) {
        logInfo(
            'Notification already handled, skipping duplicate: $messageId');
        return;
      }

      if (messageId != null) {
        _lastHandledNotificationId = messageId;
      }

      _refreshNotificationCount();

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
  static void _handleProfessionalNotificationTap(
      RemoteMessage message, String? notificationType) {
    if (notificationType == 'chat_message') {
      _refreshProfessionalChatInbox();
      _navigateToChat(message);
    } else if (_isProfessionalBookingNotificationType(notificationType)) {
      _refreshCalendar();
      if (Get.currentRoute != Routes.home) {
        Get.toNamed(Routes.home);
        Future.delayed(const Duration(milliseconds: 300), () {
          _selectCalendarTab();
        });
        logInfo(
            'Navigated to home (calendar tab) for $notificationType');
      } else {
        _selectCalendarTab();
        logInfo(
            'Already on home screen, selected Calendar tab for $notificationType');
      }
    } else if (notificationType == 'application_approved') {
      _refreshProfile();
      Get.toNamed(Routes.notifications);
      logInfo(
          'Navigated to notifications screen for application approval');
    } else if (notificationType == 'settlement_payout' ||
        notificationType == 'subscription_renewed' ||
        notificationType == 'subscription_expired' ||
        notificationType == 'subscription_activated') {
      Get.toNamed(Routes.transactionSummary);
      logInfo(
          'Navigated to transaction summary screen for $notificationType');
    } else {
      logInfo(
          'Unknown notification type for professional: $notificationType');
    }
  }

  /// Handle notification tap for end users
  static void _handleEndUserNotificationTap(
      RemoteMessage message, String? notificationType) {
    final data = message.data;

    if (_isEndUserBookingNotificationType(notificationType)) {
      if (notificationType == 'booking_completed_review' ||
          notificationType == 'review_reminder' ||
          notificationType == 'final_review_reminder') {
        _openEndUserReviewDialog(data);
        logInfo(
            'Opened review dialog from $notificationType notification (FCM tap)');
      } else {
        _openEndUserBookingsTab();
        logInfo(
            'Navigated to Bookings tab from booking notification (FCM tap)');
      }
      return;
    }

    if (notificationType == 'chat_message') {
      _refreshEndUserMessagesInbox();
      _navigateToEndUserChat(message);
      return;
    }

    if (notificationType == 'settlement_refund') {
      Get.toNamed(enduser_routes.AppRoutes.transaction_summary);
      logInfo(
          'Navigated to transaction summary screen for settlement_refund');
      return;
    }

    logInfo(
        'Unknown notification type for end user: $notificationType');
  }

  /// Handle default notification tap when user type is unknown
  static void _handleDefaultNotificationTap(
      RemoteMessage message, String? notificationType) {
    logInfo(
        'Default notification handling for type: $notificationType');
  }

  /// Select Messages tab (index 2) in HomeController
  static void _selectMessagesTab() {
    try {
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        homeController.onTabSelected(2);
        logInfo('Messages tab selected');
      } else {
        logInfo(
            'HomeController not registered, cannot select Messages tab');
      }
    } catch (e, stackTrace) {
      logError('Error selecting Messages tab',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Select Calendar tab in HomeController
  static void _selectCalendarTab() {
    try {
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        homeController.onTabSelected(0);
        logInfo('Calendar tab selected');
      } else {
        logInfo(
            'HomeController not registered, cannot select Calendar tab');
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
        logInfo(
            'CalendarController not registered, skipping calendar refresh');
      }

      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        homeController.loadBookingsList();
        logInfo('Bookings list refresh triggered');
      }
    } catch (e, stackTrace) {
      logError('Error refreshing calendar',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Handle notification tap from local notification payload
  static void _handleNotificationTapFromPayload(String payload) {
    try {
      logInfo(
          'Parsing payload: $payload, User Type: ${_getUserType()}');

      _refreshNotificationCount();

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
  static void _handleProfessionalNotificationTapFromPayload(
      String payload) {
    if (payload.contains('type: chat_message') ||
        payload.contains("'type': 'chat_message'")) {
      _refreshProfessionalChatInbox();
      _navigateToChatFromPayload(payload);
    } else if (payload.contains('type: new_booking') ||
        payload.contains("'type': 'new_booking'") ||
        payload.contains('type: booking_cancelled') ||
        payload.contains("'type': 'booking_cancelled'") ||
        payload.contains('type: booking_updated') ||
        payload.contains("'type': 'booking_updated'") ||
        payload.contains('type: booking_ended') ||
        payload.contains("'type': 'booking_ended'") ||
        payload.contains('type: booking_started') ||
        payload.contains("'type': 'booking_started'") ||
        payload.contains('type: booking_start_reminder') ||
        payload.contains("'type': 'booking_start_reminder'") ||
        payload.contains('type: booking_end_reminder') ||
        payload.contains("'type': 'booking_end_reminder'") ||
        payload.contains('type: booking_one_hour_reminder') ||
        payload.contains("'type': 'booking_one_hour_reminder'") ||
        payload.contains('type: booking_one_day_reminder') ||
        payload.contains("'type': 'booking_one_day_reminder'") ||
        payload.contains('type: booking_three_day_reminder') ||
        payload.contains("'type': 'booking_three_day_reminder'")) {
      _refreshCalendar();
      if (Get.currentRoute != Routes.home) {
        Get.toNamed(Routes.home);
        Future.delayed(const Duration(milliseconds: 300), () {
          _selectCalendarTab();
        });
        logInfo(
            'Professional navigated to home (calendar tab) from payload');
      } else {
        _selectCalendarTab();
        logInfo(
            'Professional already on home screen, selected Calendar tab from payload');
      }
    } else if (payload.contains('type: application_approved') ||
        payload.contains("'type': 'application_approved'")) {
      _refreshProfile();
      Get.toNamed(Routes.notifications);
      logInfo(
          'Professional navigated to notifications screen from payload for application approval');
    } else if (payload.contains('type: settlement_payout') ||
        payload.contains("'type': 'settlement_payout'") ||
        payload.contains('type: subscription_renewed') ||
        payload.contains("'type': 'subscription_renewed'") ||
        payload.contains('type: subscription_expired') ||
        payload.contains("'type': 'subscription_expired'") ||
        payload.contains('type: subscription_activated') ||
        payload.contains("'type': 'subscription_activated'")) {
      Get.toNamed(Routes.transactionSummary);
      logInfo(
          'Professional navigated to transaction summary screen from payload');
    }
  }

  /// Handle notification tap from payload for end users
  static void _handleEndUserNotificationTapFromPayload(String payload) {
    if (payload.contains('type: booking_rescheduled_by_professional') ||
        payload.contains(
            "'type': 'booking_rescheduled_by_professional'") ||
        payload.contains('type: booking_cancelled_by_professional') ||
        payload.contains(
            "'type': 'booking_cancelled_by_professional'") ||
        payload.contains('type: booking_three_day_reminder') ||
        payload.contains("'type': 'booking_three_day_reminder'") ||
        payload.contains('type: booking_one_day_reminder') ||
        payload.contains("'type': 'booking_one_day_reminder'") ||
        payload.contains('type: booking_one_hour_reminder') ||
        payload.contains("'type': 'booking_one_hour_reminder'") ||
        payload.contains('type: booking_end_reminder') ||
        payload.contains("'type': 'booking_end_reminder'") ||
        payload.contains('type: booking_ended') ||
        payload.contains("'type': 'booking_ended'") ||
        payload.contains('type: booking_started') ||
        payload.contains("'type': 'booking_started'") ||
        payload.contains('type: booking_start_reminder') ||
        payload.contains("'type': 'booking_start_reminder'")) {
      _openEndUserBookingsTab();
      logInfo(
          'End user navigated to Bookings tab from booking notification (local tap)');
      return;
    }

    if (payload.contains('type: booking_completed_review') ||
        payload.contains("'type': 'booking_completed_review'") ||
        payload.contains('type: review_reminder') ||
        payload.contains("'type': 'review_reminder'") ||
        payload.contains('type: final_review_reminder') ||
        payload.contains("'type': 'final_review_reminder'")) {
      Map<String, dynamic> data = _parsePayloadToMap(payload);
      _openEndUserReviewDialog(data);
      logInfo(
          "End user opened review dialog from ${data['type']} notification (local tap)");
      return;
    }

    if (payload.contains('type: chat_message') ||
        payload.contains("'type': 'chat_message'")) {
      _refreshEndUserMessagesInbox();
      _navigateToEndUserChatFromPayload(payload);
      logInfo(
          'End user navigated to chat from chat message notification (local tap)');
      return;
    }

    if (payload.contains('type: settlement_refund') ||
        payload.contains("'type': 'settlement_refund'")) {
      Get.toNamed(enduser_routes.AppRoutes.transaction_summary);
      logInfo(
          'End user navigated to transaction summary screen from settlement_refund notification (local tap)');
      return;
    }

    logInfo(
        'End user unknown notification type in payload: $payload');
  }

  /// Handle default notification tap from payload when user type is unknown
  static void _handleDefaultNotificationTapFromPayload(String payload) {
    logInfo('Default payload handling for: $payload');
  }

  /// Parse payload string to Map
  static Map<String, dynamic> _parsePayloadToMap(String payload) {
    try {
      if (payload.startsWith('{') && payload.endsWith('}')) {
        payload = payload.substring(1, payload.length - 1);
      }

      Map<String, dynamic> mapped = {};
      List<String> keyValuePairs = payload.split(',');
      for (String keyValuePair in keyValuePairs) {
        List<String> keyValue = keyValuePair.split(':');
        if (keyValue.length == 2) {
          String key =
          keyValue[0].trim().replaceAll(RegExp(r'[{}"]'), '');
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
      logError('Error parsing payload to map: $e');
      return {};
    }
  }

  /// Navigate to end user chat from payload
  static void _navigateToEndUserChatFromPayload(String payload) {
    try {
      Map<String, dynamic> valueMap = _parsePayloadToMap(payload);

      final chatRoomId = valueMap['room_id']?.toString();
      final receiverId = valueMap['sender_id']?.toString();
      final senderName =
          valueMap['full_name']?.toString() ?? 'Unknown';
      final profilePicture =
          valueMap['profile_picture']?.toString() ?? '';
      final lastMessage =
          valueMap['body']?.toString() ?? 'New message';
      final title = valueMap['title']?.toString() ?? 'New Message';

      logInfo('=== END USER NOTIFICATION EXTRACTION DEBUG ===');
      logInfo('Extracted chatRoomId: $chatRoomId');
      logInfo('Extracted receiverId: $receiverId');
      logInfo('Extracted senderName: $senderName');
      logInfo('Extracted profilePicture: $profilePicture');

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

      logInfo('End user navigated to chat detail from notification');
    } catch (e, stackTrace) {
      logError(
          'Error navigating end user to chat from payload',
          error: e,
          stackTrace: stackTrace);
    }
  }

  /// Check if chat notification should be hidden (professional)
  static bool _shouldHideChatNotification(RemoteMessage message) {
    try {
      if (!Get.isRegistered<ChatController>()) {
        return false;
      }

      final chatController = Get.find<ChatController>();
      final peerUserId = chatController.peer.value.userId;
      final currentChatId = chatController.peer.value.chatId;

      final senderId = _extractSenderIdFromNotification(message.data);
      final roomId = _extractRoomIdFromNotification(message.data);

      // Hide if either sender matches OR room matches
      bool matchesUser = false;
      if (senderId != null && senderId.isNotEmpty && 
          peerUserId != null && peerUserId.isNotEmpty) {
        matchesUser = senderId == peerUserId;
      }

      bool matchesRoom = false;
      if (roomId != null && roomId.isNotEmpty && 
          currentChatId != null && currentChatId.isNotEmpty) {
        matchesRoom = roomId == currentChatId;
      }

      final shouldHide = matchesUser || matchesRoom;
      
      logInfo(
          'Professional chat notification check - Peer: $peerUserId, Room: $currentChatId');
      logInfo(
          'Incoming Sender: $senderId, Incoming Room: $roomId, Hide: $shouldHide');
      
      return shouldHide;
    } catch (e) {
      logError(
          'Error checking if chat notification should be hidden',
          error: e);
      return false;
    }
  }

  /// Extract sender ID from notification data
  static String? _extractSenderIdFromNotification(
      Map<String, dynamic> data) {
    try {
      final senderIdData = data['sender_id'] ??
          data['senderId'] ??
          data['user_id'] ??
          data['userId'] ??
          data['from_id'] ??
          data['fromId'];

      if (senderIdData == null) return null;

      if (senderIdData is String) {
        return senderIdData;
      }

      if (senderIdData is Map<String, dynamic>) {
        return senderIdData['_id']?.toString() ??
            senderIdData['id']?.toString() ??
            senderIdData['userId']?.toString() ??
            senderIdData['user_id']?.toString();
      }

      return senderIdData.toString();
    } catch (e) {
      logError('Error extracting sender ID from notification',
          error: e);
      return null;
    }
  }

  /// Extract room ID from notification data
  static String? _extractRoomIdFromNotification(
      Map<String, dynamic> data) {
    try {
      final roomIdData = data['room_id'] ??
          data['roomId'] ??
          data['chat_id'] ??
          data['chatId'] ??
          data['conversation_id'] ??
          data['conversationId'] ??
          data['id'] ??
          data['_id'];

      if (roomIdData == null) return null;

      if (roomIdData is String) {
        return roomIdData;
      }

      if (roomIdData is Map<String, dynamic>) {
        return roomIdData['_id']?.toString() ??
            roomIdData['id']?.toString() ??
            roomIdData['room_id']?.toString() ??
            roomIdData['chat_id']?.toString();
      }

      return roomIdData.toString();
    } catch (e) {
      logError('Error extracting room ID from notification',
          error: e);
      return null;
    }
  }

  /// Navigate to specific chat from notification (professional)
  static void _navigateToChat(RemoteMessage message) {
    try {
      if (Get.currentRoute == Routes.chat) {
        logInfo('Already on chat screen, skipping navigation');
        return;
      }

      final data = message.data;

      final userId =
          _extractSenderIdFromNotification(data) ??
              data['user_id']?.toString() ??
              data['userId']?.toString();

      final chatId = data['chat_id']?.toString() ??
          data['chatId']?.toString() ??
          data['room_id']?.toString() ??
          data['roomId']?.toString();

      String? name;
      bool isOnline = false;
      String? avatarAsset;

      final senderIdData =
          data['sender_id'] ?? data['senderId'];
      if (senderIdData is Map<String, dynamic>) {
        name = senderIdData['full_name']?.toString() ??
            senderIdData['fullName']?.toString() ??
            senderIdData['name']?.toString();
        isOnline = senderIdData['is_online'] as bool? ??
            senderIdData['isOnline'] as bool? ??
            false;
        avatarAsset =
            senderIdData['profile_picture']?.toString() ??
                senderIdData['profilePicture']?.toString() ??
                senderIdData['avatar']?.toString();
      }

      name ??= message.notification?.title ??
          data['name']?.toString() ??
          data['full_name']?.toString() ??
          data['sender_name']?.toString() ??
          data['senderName']?.toString() ??
          'User';

      if (!isOnline) {
        isOnline = data['is_online'] as bool? ??
            data['isOnline'] as bool? ??
            false;
      }

      final arguments = <String, dynamic>{
        'userId': userId,
        'name': name,
        'isOnline': isOnline,
        if (avatarAsset != null && avatarAsset.isNotEmpty)
          'avatarAsset': avatarAsset,
        if (chatId != null && chatId.isNotEmpty) 'chatId': chatId,
      };

      logInfo(
          'Navigating to chat - UserId: $userId, Name: $name, isOnline: $isOnline, ChatId: $chatId');

      Get.toNamed(Routes.chat, arguments: arguments);
    } catch (e, stackTrace) {
      logError('Error navigating to chat from notification',
          error: e, stackTrace: stackTrace);
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

  /// Navigate to specific chat from payload string (professional)
  static void _navigateToChatFromPayload(String payload) {
    try {
      if (Get.currentRoute == Routes.chat) {
        logInfo(
            'Already on chat screen, skipping navigation from payload');
        return;
      }

      String? userId;
      String? chatId;
      String? name;
      bool isOnline = false;

      final senderIdObjectPattern =
      RegExp(r'sender_id\s*:\s*\{([^}]+)\}');
      final senderIdObjectMatch =
      senderIdObjectPattern.firstMatch(payload);
      if (senderIdObjectMatch != null) {
        final senderIdContent =
            senderIdObjectMatch.group(1) ?? '';
        final idPattern = RegExp(r'_id\s*:\s*([^,}]+)');
        final idMatch = idPattern.firstMatch(senderIdContent);
        if (idMatch != null) {
          userId = idMatch
              .group(1)
              ?.trim()
              .replaceAll("'", '')
              .replaceAll('"', '');
        }
        final nameInSenderPattern =
        RegExp(r'full_name\s*:\s*([^,}]+)');
        final nameInSenderMatch =
        nameInSenderPattern.firstMatch(senderIdContent);
        if (nameInSenderMatch != null) {
          name = nameInSenderMatch
              .group(1)
              ?.trim()
              .replaceAll("'", '')
              .replaceAll('"', '');
        }
        final onlinePattern =
        RegExp(r'is_online\s*:\s*(true|false)');
        final onlineMatch =
        onlinePattern.firstMatch(senderIdContent);
        if (onlineMatch != null) {
          isOnline = onlineMatch.group(1) == 'true';
        }
      }

      if (userId == null || userId.isEmpty) {
        final userIdPatterns = [
          RegExp(r'user_id\s*:\s*([^,}]+)'),
          RegExp(r'userId\s*:\s*([^,}]+)'),
        ];
        for (final pattern in userIdPatterns) {
          final match = pattern.firstMatch(payload);
          if (match != null) {
            final extracted =
                match.group(1)?.trim() ?? '';
            userId = extracted
                .replaceAll("'", '')
                .replaceAll('"', '');
            if (!userId.startsWith('{')) {
              break;
            }
            userId = null;
          }
        }
      }

      final chatIdPatterns = [
        RegExp(r'chat_id\s*:\s*([^,}]+)'),
        RegExp(r'chatId\s*:\s*([^,}]+)'),
        RegExp(r'room_id\s*:\s*([^,}]+)'),
        RegExp(r'roomId\s*:\s*([^,}]+)'),
      ];
      for (final pattern in chatIdPatterns) {
        final match = pattern.firstMatch(payload);
        if (match != null) {
          final extracted = match.group(1)?.trim() ?? '';
          chatId = extracted
              .replaceAll("'", '')
              .replaceAll('"', '');
          break;
        }
      }

      if (name == null || name.isEmpty) {
        final namePatterns = [
          RegExp(r'full_name\s*:\s*([^,}]+)'),
          RegExp(r'fullName\s*:\s*([^,}]+)'),
          RegExp(r'sender_name\s*:\s*([^,}]+)'),
          RegExp(r'senderName\s*:\s*([^,}]+)'),
        ];
        for (final pattern in namePatterns) {
          final match = pattern.firstMatch(payload);
          if (match != null) {
            final extracted =
                match.group(1)?.trim() ?? '';
            name = extracted
                .replaceAll("'", '')
                .replaceAll('"', '');
            break;
          }
        }
      }

      if (!isOnline) {
        final onlinePatterns = [
          RegExp(r'is_online\s*:\s*(true|false)'),
          RegExp(r'isOnline\s*:\s*(true|false)'),
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
        final arguments = <String, dynamic>{
          'userId': userId,
          'name': name ?? 'User',
          'isOnline': isOnline,
          if (chatId != null && chatId.isNotEmpty) 'chatId': chatId,
        };

        logInfo(
            'Navigating to chat from payload - UserId: $userId, Name: $name, isOnline: $isOnline, ChatId: $chatId');

        Get.toNamed(Routes.chat, arguments: arguments);
        return;
      }

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
  static bool _isEndUserChatDetailActiveWithUser(
      String? senderId, String? roomId) {
    try {
      if (!Get.isRegistered<ChatDetailController>()) {
        logInfo('End user ChatDetailController not registered');
        return false;
      }

      final chatController = Get.find<ChatDetailController>();
      final currentConversation = chatController.conversation.value;

      if (currentConversation == null) {
        logInfo('End user current conversation is null');
        return false;
      }

      final currentUserId = currentConversation.userId;
      final currentRoomId = currentConversation.id;

      // Logic: Hide if either sender matches OR room matches,
      // but only if both values are not null/empty
      bool matchesUser = false;
      if (senderId != null && senderId.isNotEmpty && 
          currentUserId != null && currentUserId.isNotEmpty) {
        matchesUser = senderId == currentUserId;
      }

      bool matchesRoom = false;
      if (roomId != null && roomId.isNotEmpty && 
          currentRoomId != null && currentRoomId.isNotEmpty) {
        matchesRoom = roomId == currentRoomId;
      }

      final isSameUser = matchesUser || matchesRoom;

      logInfo('End user chat check - Current User: $currentUserId, Current Room: $currentRoomId');
      logInfo('Incoming sender ID: $senderId, Incoming room ID: $roomId');
      logInfo('End user is same user: $isSameUser');

      return isSameUser;
    } catch (e) {
      logError('Error checking end user chat detail status: $e');
      return false;
    }
  }

  /// Refresh end user messages inbox
  static void _refreshEndUserMessagesInbox() {
    try {
      if (Get.isRegistered<enduser_messages.MessagesController>(tag: 'messages')) {
        final messagesController =
        Get.find<enduser_messages.MessagesController>(tag: 'messages');
        messagesController.silentRefreshInbox();
        logInfo('End user messages inbox refresh triggered');
      } else {
        logInfo(
            'End user MessagesController not registered, skipping inbox refresh');
      }
    } catch (e, stackTrace) {
      logError('Error refreshing end user messages inbox',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Refresh end user notification count
  static void _refreshEndUserNotificationCount() {
    try {
      if (Get.isRegistered<HomeMainController>(tag: 'home')) {
        Get.find<HomeMainController>(tag: 'home')
            .fetchNotificationCount();
        logInfo(
            'End user notification count refresh triggered');
      } else {
        logInfo(
            'End user HomeMainController not registered, skipping notification count refresh');
      }
    } catch (e, stackTrace) {
      logError(
          'Error refreshing end user notification count',
          error: e,
          stackTrace: stackTrace);
    }
  }

  /// Refresh end user bookings
  static void _refreshEndUserBookings() {
    try {
      if (Get.isRegistered<BookingsController>(
          tag: 'bookings')) {
        final bookingsController =
        Get.find<BookingsController>(tag: 'bookings');
        bookingsController.refreshData();
        logInfo('End user bookings refresh triggered');
      } else {
        logInfo(
            'End user BookingsController not registered, skipping bookings refresh');
      }
    } catch (e, stackTrace) {
      logError('Error refreshing end user bookings',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Open the Bookings tab for end users
  static void _openEndUserBookingsTab() {
    try {
      if (Get.isRegistered<MainTabController>()) {
        final controller = Get.find<MainTabController>();
        controller.setTab(1);
        logInfo(
            'End user switched to Bookings tab via MainTabController');
        if (Get.isRegistered<BookingsController>(
            tag: 'bookings')) {
          try {
            final bookingsController =
            Get.find<BookingsController>(tag: 'bookings');
            bookingsController.refreshData();
            logInfo(
                'End user refreshed bookings data after switching tab');
          } catch (e) {
            logError(
                'Error refreshing end user bookings after switching tab: $e');
          }
        }
      } else if (Get.currentRoute == enduser_routes.AppRoutes.splash) {
        logInfo(
            'App still at splash screen, storing pending navigation to Bookings tab');
        _pendingBookingNavigation = 1;
      } else {
        Get.toNamed(enduser_routes.AppRoutes.main,
            arguments: {'openTab': 1});
        logInfo(
            'End user navigated to MainScreen with Bookings tab open');
      }
    } catch (e) {
      logError('Error opening end user Bookings tab: $e');
    }
  }

  /// Open review dialog for end users
  static Future<void> _openEndUserReviewDialog(
      Map<String, dynamic> data) async {
    try {
      final professionalId =
          data['professional_id']?.toString() ?? '';
      final bookingId = data['booking_id']?.toString() ?? '';
      final professionalName =
          data['professional_name']?.toString() ??
              data['full_name']?.toString() ??
              'Professional';

      if (professionalId.isEmpty || bookingId.isEmpty) {
        logError(
            'Missing professional_id or booking_id in notification data');
        _openEndUserBookingsTab();
        return;
      }

      logInfo(
          'Opening end user review dialog for professional: $professionalName, ID: $professionalId, Booking: $bookingId');
//New Code
      if (Get.currentRoute == enduser_routes.AppRoutes.splash) {
        logInfo(
            'App still at splash screen, storing pending review dialog');
        _pendingReviewDialogData = {
          'professionalName': professionalName,
          'professionalId': professionalId,
          'bookingId': bookingId,
        };
        return;
      }

      if (Get.isRegistered<MainTabController>()) {
        final controller = Get.find<MainTabController>();
        controller.setTab(0);
        logInfo(
            'End user switched to Home tab via MainTabController');
      } else {
        await Get.toNamed(
          enduser_routes.AppRoutes.main,
          arguments: {'openTab': 0},
        );
      }

      _showEndUserReviewDialogWithRetry(
          professionalName, professionalId, bookingId);
    } catch (e) {
      logError('Error opening end user review dialog: $e');
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
      logInfo(
          'Attempting to show end user review dialog (attempt $retryCount/$maxRetries)');

      if (Get.isRegistered<HomeMainController>()) {
        logInfo(
            'End user HomeMainController found, showing dialog');
        final homeController =
        Get.find<HomeMainController>();
        homeController.showReviewDialog(
          professionalName,
          professionalId,
          bookingId,
        );
      } else if (retryCount < maxRetries) {
        logInfo(
            'End user HomeMainController not yet registered, retrying in 500ms...');
        Future.delayed(const Duration(milliseconds: 500), () {
          tryShowDialog();
        });
      } else {
        logInfo(
            'End user HomeMainController not registered after $maxRetries attempts, showing fallback dialog');
        _showEndUserFallbackReviewDialog(
            professionalName, professionalId, bookingId);
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
    logInfo(
        'Showing end user fallback review dialog for: $professionalName');

    final TextEditingController reviewController =
    TextEditingController();
    final RxInt rating = 0.obs;
    final RxBool isSubmitting = false.obs;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        insetPadding:
        const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 24),
                      Expanded(
                        child: Text(
                          'Rate your recent session with\n"$professionalName"',
                          textAlign: TextAlign.center,
                          style: AppTextStyles
                              .popinMediumTextStyle(),
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
                  Obx(
                        () => Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children:
                      List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () =>
                          rating.value = index + 1,
                          child: Padding(
                            padding:
                            const EdgeInsets.symmetric(
                                horizontal: 4),
                            child: SvgPicture.asset(
                              AppAssets.rating_selected,
                              color: index < rating.value
                                  ? AppColors
                                  .ratingSelectedColor
                                  : AppColors
                                  .unselectedTabColor,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius:
                      BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1),
                    ),
                    child: TextField(
                      controller: reviewController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Write a review',
                        hintStyle: AppTextStyles
                            .popinRegularTextStyle(
                          fontSize: 14,
                          color: AppColors.color919191,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                        const EdgeInsets.all(16),
                        counterStyle: AppTextStyles
                            .regularTextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      style:
                      AppTextStyles.regularTextStyle(
                        fontSize: 14,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                          snackPosition:
                          SnackPosition.BOTTOM,
                          backgroundColor:
                          Colors.orange.shade100,
                          duration: const Duration(
                              seconds: 2),
                        );
                        return;
                      }

                      isSubmitting.value = true;

                      try {
                        await _submitEndUserReviewFallback(
                          professionalId:
                          professionalId,
                          bookingId: bookingId,
                          rating: rating.value,
                          review: reviewController
                              .text
                              .trim(),
                        );

                        Get.back();
                        Get.snackbar(
                          'Review Submitted',
                          'Thank you for your feedback!',
                          snackPosition:
                          SnackPosition.BOTTOM,
                          backgroundColor: AppColors
                              .primaryColor
                              .withOpacity(0.2),
                          duration: const Duration(
                              seconds: 2),
                        );
                      } catch (e) {
                        String errorMessage =
                            'Failed to submit review. Please try again.';

                        if (e is NotFoundException) {
                          errorMessage = e.message;
                        } else if (e is ApiException) {
                          errorMessage = e.message;
                        } else if (e is Exception) {
                          String exceptionString =
                          e.toString();
                          if (exceptionString
                              .startsWith(
                              'Exception: ')) {
                            errorMessage =
                                exceptionString
                                    .replaceFirst(
                                    'Exception: ',
                                    '');
                          } else {
                            errorMessage =
                                exceptionString;
                          }
                        }

                        Get.snackbar(
                          'Error',
                          errorMessage,
                          snackPosition:
                          SnackPosition.BOTTOM,
                          backgroundColor:
                          Colors.red.shade100,
                          duration: const Duration(
                              seconds: 3),
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
                          valueColor:
                          AlwaysStoppedAnimation<
                              Color>(Colors.white),
                        ),
                      )
                          : Text(
                        'Add review',
                        style: AppTextStyles
                            .buttonTextStyle(),
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
        'Submitting end user review (fallback): professionalId=$professionalId, bookingId=$bookingId, rating=$rating');

    if (!Get.isRegistered<ProjectRepository>(
      tag: (ProjectRepository).toString(),
    )) {
      throw Exception('Repository not available');
    }

    final repository = Get.find<ProjectRepository>(
      tag: (ProjectRepository).toString(),
    );

    final requestData = {
      'professional_id': professionalId,
      'booking_id': bookingId,
      'rating': rating,
      'review': review.isEmpty ? '' : review,
    };

    var service = repository.sendPostApiRequest(
          () => requestData,
      professionals_rate_review,
      true,
    );

    var response = await service;

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

    if (success) {
      // Analytics: Log review submission
      AnalyticsService.instance.logEvent(
        name: 'review_submit',
        parameters: {
          'screen_name': 'NotificationDialog',
          'screen_class': 'NotificationDialog',
          'element_text': review.toString(),
          'element_location': 'notification_review_dialog',
          'page_category': 'notification',
          'element_class': rating.toString(),
        },
      );
    }

    if (!success) {
      String message =
          responseData['message'] ?? 'Failed to submit review';
      throw Exception(message);
    }

    logInfo(
        'End user review submitted successfully (fallback): ${responseData['message']}');
  }

  /// Navigate to end user chat from FCM message tap
  static void _navigateToEndUserChat(RemoteMessage message) {
    try {
      final data = message.data;

      final chatRoomId = data['room_id']?.toString();
      final receiverId = data['sender_id']?.toString();
      final senderName =
          data['full_name']?.toString() ?? 'Unknown';
      final profilePicture =
          data['profile_picture']?.toString() ?? '';
      final lastMessage =
          data['body']?.toString() ?? 'New message';
      final title =
          data['title']?.toString() ?? 'New Message';

      logInfo(
          '=== END USER NAVIGATION FROM MESSAGE TAP DEBUG ===');
      logInfo('chatRoomId: $chatRoomId');
      logInfo('receiverId: $receiverId');
      logInfo('senderName: $senderName');
      logInfo('profilePicture: $profilePicture');

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

      logInfo(
          'End user navigated to chat detail from FCM notification tap');
    } catch (e, stackTrace) {
      logError(
          'Error navigating end user to chat from notification',
          error: e,
          stackTrace: stackTrace);
    }
  }

  static Future<void> backgroundMessageHandler(
      RemoteMessage message) async {
    if (message.notification == null) {
      await showForegroundNotification(message);
    } else {
      final type =
          message.data['type']?.toString() ?? '';
      logInfo(
          'Background FCM message (type: $type) – FCM handles display automatically');
    }
  }
}
