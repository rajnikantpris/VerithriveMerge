import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/logger.dart';
import '../routes/app_routes.dart';
import '../professional/home/messages_controller.dart';
import '../professional/home/home_controller.dart';
import '../professional/home/calendar_controller.dart';
import '../professional/home/chat/chat_controller.dart';
import 'notification_service.dart';
import 'storage_service.dart';

/// Service to handle foreground notifications
class ForegroundNotificationServiceOld {
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

      if (notificationType == 'chat_message') {
        logInfo('Chat message notification received - refreshing inbox');
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
            'Booking notification received (type: $notificationType) - refreshing calendar');
        _refreshCalendar();
      } else if (notificationType == 'application_approved') {
        logInfo(
            'Profile approval notification received - refreshing profile data');
        _refreshProfile();
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

        // Show the notification
        showForegroundNotification(message);
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
      logInfo('Handling notification tap - Type: $notificationType, ID: $messageId');

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
        logInfo('Unknown notification type: $notificationType');
      }
    } catch (e, stackTrace) {
      logError('Error handling notification tap',
          error: e, stackTrace: stackTrace);
    }
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
      logInfo('Parsing payload: $payload');

      // Always refresh notification count when notification is tapped
      _refreshNotificationCount();

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
          logInfo('Navigated to home (calendar tab) from payload');
        } else {
          // Already on home screen, just select Calendar tab
          _selectCalendarTab();
          logInfo('Already on home screen, selected Calendar tab from payload');
        }
      } else if (payload.contains("type: application_approved") ||
          payload.contains("'type': 'application_approved'")) {
        // Refresh profile data and navigate to notifications screen
        _refreshProfile();
        Get.toNamed(Routes.notifications);
        logInfo(
            'Navigated to notifications screen from payload for application approval');
      }
    } catch (e, stackTrace) {
      logError('Error handling notification tap from payload',
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
}
