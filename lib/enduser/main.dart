import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verithrive_dev/enduser/routes/app_routes.dart';
import 'package:verithrive_dev/enduser/screens/message/MessagesController.dart';
import 'package:verithrive_dev/enduser/screens/message/ChatDetailController.dart';
import 'package:verithrive_dev/enduser/screens/booking/BookingsController.dart';
import 'package:verithrive_dev/enduser/screens/home_main/HomeMainController.dart';
import 'package:verithrive_dev/enduser/models/Conversation.dart';
import 'package:verithrive_dev/enduser/data/repository/project_repository.dart';
import 'package:verithrive_dev/enduser/utils/FirebaseTokenManager.dart';
import 'package:verithrive_dev/enduser/utils/api_services.dart';
import 'package:verithrive_dev/enduser/network/exceptions/not_found_exception.dart';
import 'package:verithrive_dev/enduser/network/exceptions/api_exception.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import 'package:verithrive_dev/enduser/utils/app_text_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'flavors/build_config.dart';
import 'flavors/env_config.dart';
import 'flavors/environment.dart';
import 'core/utils/DefaultFirebaseOptions.dart';
import 'app/modules/notification/model/NotificationPayloadModel.dart';
import 'screens/main/MainTabController.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart' as routes;
import 'bindings/initial_binding.dart';
// import '../services/analytics_service.dart';

// end user main.dart file

final Routes = routes.Routes;

//String channelId = "";
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const String CUSTOM_CHANNEL_ID = 'custom_notification_channel';

/// Notification types that should open the Bookings tab
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

/// Open review dialog for review-related notifications
Future<void> _openReviewDialog(Map<String, dynamic> data) async {
  try {
    // Extract required data from notification
    final professionalId = data['professional_id']?.toString() ?? '';
    final bookingId = data['booking_id']?.toString() ?? '';
    final professionalName = data['professional_name']?.toString() ??
        data['full_name']?.toString() ??
        'Professional';

    if (professionalId.isEmpty || bookingId.isEmpty) {
      print("Missing professional_id or booking_id in notification data");
      // Fallback to bookings tab if required data is missing
      _openBookingsTab();
      return;
    }

    print(
      "Opening review dialog for professional: $professionalName, ID: $professionalId, Booking: $bookingId",
    );

    // Navigate to home screen first, then show dialog
    final navigationResult = await Get.toNamed(
      AppRoutes.main,
      arguments: {'openTab': 0}, // Home tab
    );

    // Show dialog after navigation completes with retry logic
    _showReviewDialogWithRetry(professionalName, professionalId, bookingId);
  } catch (e) {
    print("Error opening review dialog: $e");
    // Fallback to bookings tab
    _openBookingsTab();
  }
}

/// Show review dialog with retry logic for controller registration
void _showReviewDialogWithRetry(
  String professionalName,
  String professionalId,
  String bookingId,
) {
  int retryCount = 0;
  const maxRetries = 10;

  void tryShowDialog() {
    retryCount++;
    print("Attempting to show review dialog (attempt $retryCount/$maxRetries)");

    if (Get.isRegistered<HomeMainController>()) {
      print("HomeMainController found, showing dialog");
      final homeController = Get.find<HomeMainController>();
      homeController.showReviewDialog(
        professionalName,
        professionalId,
        bookingId,
      );
    } else if (retryCount < maxRetries) {
      print("HomeMainController not yet registered, retrying in 500ms...");
      Future.delayed(Duration(milliseconds: 500), () {
        tryShowDialog();
      });
    } else {
      print(
        "HomeMainController not registered after $maxRetries attempts, showing fallback dialog",
      );
      _showFallbackReviewDialog(professionalName, professionalId, bookingId);
    }
  }

  tryShowDialog();
}

/// Show fallback review dialog directly without relying on HomeMainController
void _showFallbackReviewDialog(
  String professionalName,
  String professionalId,
  String bookingId,
) {
  print("Showing fallback review dialog for: $professionalName");

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
                color:
                    isSubmitting.value ? Colors.grey : AppColors.primaryColor,
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
                            await _submitReviewFallback(
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
                              backgroundColor:
                                  AppColors.primaryColor.withOpacity(0.2),
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

Future<void> _submitReviewFallback({
  required String professionalId,
  required String bookingId,
  required int rating,
  required String review,
}) async {
  print(
    "Submitting review (fallback): professionalId=$professionalId, bookingId=$bookingId, rating=$rating, review=$review",
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

  print("Review submitted successfully (fallback): ${responseData['message']}");
}

bool _isBookingNotificationType(String? type) {
  if (type == null) return false;
  return _bookingNotificationTypes.contains(type);
}

/// Open the Bookings tab (index 1) either by switching the existing
/// MainTabController or by navigating to MainScreen with the correct tab.
void _openBookingsTab() {
  try {
    if (Get.isRegistered<MainTabController>()) {
      final controller = Get.find<MainTabController>();
      controller.setTab(1); // 0: home, 1: bookings, 2: messages
      print("Switched to Bookings tab via MainTabController");
      // Also refresh bookings data if controller is available
      if (Get.isRegistered<BookingsController>(tag: 'bookings')) {
        try {
          final bookingsController = Get.find<BookingsController>(
            tag: 'bookings',
          );
          bookingsController.refreshData();
          print("Refreshed bookings data after switching tab");
        } catch (e) {
          print("Error refreshing bookings after switching tab: $e");
        }
      }
    } else {
      Get.toNamed(AppRoutes.main, arguments: {'openTab': 1});
      print("Navigated to MainScreen with Bookings tab open");
    }
  } catch (e) {
    print("Error opening Bookings tab: $e");
  }
}

Future<void> main() async {
  EnvConfig prodConfig = EnvConfig(
    appName: "VeriThrive",
    baseUrl: "",
    shouldCollectCrashLog: true,
  );

  BuildConfig.instantiate(
    envType: Environment.DEVELOPMENT,
    envConfig: prodConfig,
  );

  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isIOS) {
    await Firebase.initializeApp();
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  FirebaseTokenManager.initializeInBackground();

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    // User tapped a notification while app was in background
    _handleNotificationNavigationFromMessage(message);
  });

  FirebaseMessaging.onBackgroundMessage(_messageHandler);

  await FirebaseMessaging.instance.getInitialMessage();

  if (!kIsWeb) {
    await setupFlutterNotifications();
  }

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MyApp());

  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      // App was opened from a terminated state by tapping a notification.
      // Defer navigation until after the first frame so Get's navigator is ready.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationNavigationFromMessage(message);
      });
    }
  });

  FirebaseMessaging.onMessage.listen((event) {
    print("Foreground message received: ${event.data}");
    showNotification(event);

    // Handle review-related notifications in foreground - show dialog immediately
    final data = event.data;
    if (data['type'] == "booking_completed_review" ||
        data['type'] == "review_reminder" ||
        data['type'] == "final_review_reminder") {
      print("Handling ${data['type']} in foreground");
      _openReviewDialog(data);
    }
  });

  // var initializationSettingsAndroid =
  //     const AndroidInitializationSettings('@mipmap/ic_launcher');
  // var initializationSettings =
  //     InitializationSettings(android: initializationSettingsAndroid);
  // await flutterLocalNotificationsPlugin.initialize(
  //   initializationSettings,
  //   onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
  //   onDidReceiveBackgroundNotificationResponse:
  //       onDidReceiveNotificationResponse,
  // );

  const AndroidInitializationSettings androidInitializationSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosInitializationSettings =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: androidInitializationSettings,
    iOS: iosInitializationSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    onDidReceiveBackgroundNotificationResponse:
        onDidReceiveNotificationResponse,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel!);
}

Map<String, dynamic> convertPayload(String payload) {
  try {
    payload = payload.replaceAll("{", "").replaceAll("}", "");
    List<String> keyValuePairs = payload.split(",");
    Map<String, dynamic> mapped = {};
    for (String keyValuePair in keyValuePairs) {
      List<String> keyValue = keyValuePair.split(":");
      if (keyValue.length == 2) {
        String key = keyValue[0].trim();
        String value = keyValue[1].trim();
        mapped[key] = value;
      }
    }
    return mapped;
  } catch (e) {
    print("Error converting payload to map: $e");
    return {};
  }
}

/// Check if chat detail screen is active with the same user
bool _isChatDetailActiveWithUser(String? senderId, String? roomId) {
  try {
    // Check if ChatDetailController is registered and active
    if (!Get.isRegistered<ChatDetailController>()) {
      print("ChatDetailController not registered");
      return false;
    }

    final chatController = Get.find<ChatDetailController>();
    final currentConversation = chatController.conversation;

    // Check if current chat is with the same user
    final isSameUser = currentConversation.value!.userId == senderId ||
        currentConversation.value!.id == roomId;

    print("Current chat user ID: ${currentConversation.value!.userId}");
    print("Current chat room ID: ${currentConversation.value!.id}");
    print("Incoming sender ID: $senderId");
    print("Incoming room ID: $roomId");
    print("Is same user: $isSameUser");

    return isSameUser;
  } catch (e) {
    print("Error checking chat detail status: $e");
    return false;
  }
}

/// Handle navigation when a push notification is tapped (foreground/background/terminated)
void _handleNotificationNavigationFromMessage(RemoteMessage message) {
  try {
    final data = message.data;
    if (data.isEmpty) {
      print("Notification tap with empty data payload");
      // Fallback: open main screen on Messages tab so user
      // still lands in the messaging area when app was killed.
      try {
        Get.toNamed(
          AppRoutes.main,
          arguments: {'openTab': 2}, // 0: home, 1: bookings, 2: messages
        );
        print(
          "Navigated to main screen (Messages tab) from empty notification data",
        );
      } catch (e) {
        print("Error navigating to main/messages from empty data: $e");
      }
      return;
    }

    print("Handling notification tap from RemoteMessage. Data: $data");

    final notificationModel = NotificationPayloadModel.fromJson(data);
    print(
      "Notification type from message: ${notificationModel.notificationType}",
    );

    // If this is a booking-related notification, handle accordingly
    if (_isBookingNotificationType(notificationModel.notificationType)) {
      if (notificationModel.notificationType == "booking_completed_review" ||
          notificationModel.notificationType == "review_reminder" ||
          notificationModel.notificationType == "final_review_reminder") {
        _openReviewDialog(data);
        print(
          "Opened review dialog from ${notificationModel.notificationType} notification (FCM tap)",
        );
      } else {
        _openBookingsTab();
        print("Navigated to Bookings tab from booking notification (FCM tap)");
      }
      return;
    }

    // Handle chat message notification - navigate to chat detail
    if (notificationModel.notificationType == "chat_message") {
      final chatRoomId =
          notificationModel.roomId ?? data['room_id']?.toString();
      final receiverId =
          notificationModel.senderId ?? data['sender_id']?.toString();
      final senderName = notificationModel.fullName ??
          data['full_name']?.toString() ??
          'Unknown';
      final profilePicture = notificationModel.profilePicture ??
          data['profile_picture']?.toString() ??
          '';
      final lastMessage =
          notificationModel.body ?? data['body']?.toString() ?? 'New message';
      final title =
          notificationModel.title ?? data['title']?.toString() ?? 'New Message';

      print("=== NAVIGATION FROM MESSAGE TAP DEBUG ===");
      print("chatRoomId: $chatRoomId");
      print("receiverId: $receiverId");
      print("senderName: $senderName");
      print("profilePicture: $profilePicture");

      final conversation = Conversation(
        id: chatRoomId ?? '',
        name: senderName,
        lastMessage: lastMessage,
        lastMessageTime: DateTime.now(),
        userId: receiverId,
        isOnline: false,
        profileImageUrl: profilePicture,
      );

      Get.toNamed(
        AppRoutes.chat_detail,
        arguments: {
          'conversation': conversation,
          'notificationData': {
            'title': title,
            'body': lastMessage,
            'sender_id': receiverId,
            'room_id': chatRoomId,
            'full_name': senderName,
            'profile_picture': profilePicture,
            'timestamp': notificationModel.timestamp ?? data['timestamp'],
            'click_action':
                notificationModel.clickAction ?? data['click_action'],
          },
        },
      );

      print("Navigated to chat detail from FCM notification tap");
    }
  } catch (e) {
    print("Error handling notification navigation from message: $e");
  }
}

void onDidReceiveNotificationResponse(
  NotificationResponse notificationResponse,
) async {
  print("onDidReceiveNotificationResponse");
  if (notificationResponse.payload != null &&
      notificationResponse.payload!.isNotEmpty) {
    print("Raw payload: ${notificationResponse.payload}");

    Map<String, dynamic> valueMap;
    try {
      // Try to parse the payload as a proper map
      String payloadStr = notificationResponse.payload!;

      // Remove outer braces if present
      if (payloadStr.startsWith('{') && payloadStr.endsWith('}')) {
        payloadStr = payloadStr.substring(1, payloadStr.length - 1);
      }

      valueMap = {};
      List<String> pairs = payloadStr.split(',');
      for (String pair in pairs) {
        List<String> keyValue = pair.split(':');
        if (keyValue.length >= 2) {
          String key = keyValue[0].trim().replaceAll(RegExp(r'[{}"]'), '');
          String value = keyValue
              .sublist(1)
              .join(':')
              .trim()
              .replaceAll(RegExp(r'["}]'), '');
          valueMap[key] = value;
        }
      }
    } catch (e) {
      print("Error parsing payload: $e");
      valueMap = convertPayload(notificationResponse.payload.toString());
    }

    print("Parsed valueMap: $valueMap");

    NotificationPayloadModel notificationModel =
        NotificationPayloadModel.fromJson(valueMap);

    print("Notification type: ${notificationModel.notificationType}");
    print("Notification data: ${notificationModel.orderData}");

    // Booking notifications: handle accordingly
    if (_isBookingNotificationType(notificationModel.notificationType)) {
      if (notificationModel.notificationType == "booking_completed_review" ||
          notificationModel.notificationType == "review_reminder" ||
          notificationModel.notificationType == "final_review_reminder") {
        _openReviewDialog(valueMap);
        print(
          "Opened review dialog from ${notificationModel.notificationType} notification (local tap)",
        );
      } else {
        _openBookingsTab();
        print(
          "Navigated to Bookings tab from booking notification (local tap)",
        );
      }
      return;
    }

    // Handle chat message notification - navigate to chat detail
    if (notificationModel.notificationType == "chat_message") {
      // Extract chat room information from notification model
      final chatRoomId =
          notificationModel.roomId ?? valueMap['room_id']?.toString();
      final receiverId =
          notificationModel.senderId ?? valueMap['sender_id']?.toString();
      final senderName = notificationModel.fullName ??
          valueMap['full_name']?.toString() ??
          'Unknown';
      final profilePicture = notificationModel.profilePicture ??
          valueMap['profile_picture']?.toString() ??
          '';
      final lastMessage = notificationModel.body ??
          valueMap['body']?.toString() ??
          'New message';
      final title = notificationModel.title ??
          valueMap['title']?.toString() ??
          'New Message';

      print("=== NOTIFICATION EXTRACTION DEBUG ===");
      print("Raw valueMap: $valueMap");
      print(
        "NotificationModel.profilePicture: ${notificationModel.profilePicture}",
      );
      print("valueMap['profile_picture']: ${valueMap['profile_picture']}");
      print("Extracted chatRoomId: $chatRoomId");
      print("Extracted receiverId: $receiverId");
      print("Extracted senderName: $senderName");
      print("Extracted profilePicture: $profilePicture");
      print("ProfilePicture isEmpty: ${profilePicture.isEmpty}");
      print("ProfilePicture length: ${profilePicture.length}");

      // Create conversation object for navigation with all payload data
      final conversation = Conversation(
        id: chatRoomId ?? '',
        name: senderName,
        lastMessage: lastMessage,
        lastMessageTime: DateTime.now(),
        userId: receiverId,
        isOnline: false,
        profileImageUrl: profilePicture, // Use correct field name
      );

      print("=== CONVERSATION CREATION DEBUG ===");
      print("Created conversation.id: ${conversation.id}");
      print("Created conversation.name: ${conversation.name}");
      print(
        "Created conversation.profileImageUrl: ${conversation.profileImageUrl}",
      );
      print("Created conversation.userId: ${conversation.userId}");
      print("Conversation toString(): ${conversation.toString()}");

      // Navigate to chat detail screen with conversation data
      Get.toNamed(
        AppRoutes.chat_detail,
        arguments: {
          'conversation': conversation,
          'notificationData': {
            'title': title,
            'body': lastMessage,
            'sender_id': receiverId,
            'room_id': chatRoomId,
            'full_name': senderName,
            'profile_picture': profilePicture,
            'timestamp': notificationModel.timestamp,
            'click_action': notificationModel.clickAction,
          },
        },
      );

      print("Navigated to chat detail from notification");
      return;
    }

    // Refresh messages list for other notification types
    if (Get.isRegistered<MessagesController>(tag: 'messages')) {
      print("MessagesController registered");
      final MessagesController ordersScreenController =
          Get.find<MessagesController>(tag: 'messages');
      if (notificationModel.notificationType != null) {
        if (notificationModel.notificationType.toString() == "chat_message") {
          // Use silent refresh to prevent blinking
          ordersScreenController.silentRefreshInbox();
        }
      }
    }
  }
}

@pragma('vm:entry-point')
Future<void> _messageHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Check if message has notification payload
  // If it does, FCM will automatically display it when app is killed
  // So we should only show local notification for data-only messages
  if (message.notification == null) {
    // Data-only message - show local notification
    showNotification(message);
  } else {
    // Message has notification payload - FCM will handle it automatically
    // Only process data if needed (e.g., refresh inbox for chat messages)
    var data = message.data;
    String notificationType = data['type']?.toString() ?? '';

    if (notificationType == "chat_message") {
      // Handle chat message data processing if needed
      // Note: Notification is already shown by FCM automatically
      print(
        "Background chat message received - skipping notification count refresh",
      );
    } else {
      // For non-chat messages, we could potentially refresh notification count
      // However, since app is in background, we'll rely on app lifecycle to refresh
      print("Background notification received (type: $notificationType)");
    }
  }
}

bool isFlutterLocalNotificationsInitialized = false;

AndroidNotificationChannel? channel;

Future<void> setupFlutterNotifications() async {
  int rand1 = Random().nextInt(10000);
  // channelId = rand1.toString();
  channel = AndroidNotificationChannel(
    //rand1.toString(),
    CUSTOM_CHANNEL_ID,
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
    playSound: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel!);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  isFlutterLocalNotificationsInitialized = true;
}

Future<void> showNotificationWorking(RemoteMessage message) async {
  var data = message.data;
  String soundFileName = data['sound'] ?? "default";
  String loop = data['loop']?.toString() ?? "0";
  bool isShowPopup = data['is_show_popup'] == '1';

  bool isLoopEnabled = data['loop'] != null && data['loop'].toString() == '1';

  if (isLoopEnabled && Platform.isIOS) {}

  bool isAppInForeground =
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  // Show dialog only in foreground if isShowPopup is true
  if (isAppInForeground && isShowPopup) {
    return; // Skip notification if dialog is shown
  }

  // Create notification channel if not already created
  if (channel == null) {
    int rand1 = Random().nextInt(10000);
    channel = AndroidNotificationChannel(
      rand1.toString(),
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
      sound: soundFileName.isNotEmpty
          ? RawResourceAndroidNotificationSound(soundFileName)
          : RawResourceAndroidNotificationSound("default"),
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel!);
  }

  // Define notification details with sound
  NotificationDetails notificationDetails = loop == "1"
      ? NotificationDetails(
          android: AndroidNotificationDetails(
            channel!.id,
            channel!.name,
            channelDescription: channel!.description,
            enableLights: true,
            playSound: true,
            //icon: '@mipmap/ic_launcher',
            importance: Importance.high,
            autoCancel: Platform.isAndroid,
            ongoing: Platform.isIOS,
            priority: Priority.high,
            enableVibration: false,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBanner: true,
            interruptionLevel: InterruptionLevel.critical,
          ),
        )
      : NotificationDetails(
          android: AndroidNotificationDetails(
            channel!.id,
            channel!.name,
            channelDescription: channel!.description,
            enableLights: true,
            playSound: true,
            // icon: '@mimap/ic_launcher',
            importance: Importance.high,
            autoCancel: Platform.isAndroid,
            ongoing: Platform.isIOS,
            priority: Priority.high,
            enableVibration: false,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBanner: true,
            interruptionLevel: InterruptionLevel.critical,
          ),
        );

  // Show notification
  await flutterLocalNotificationsPlugin.show(
    Random().nextInt(10000),
    data['title'] ?? '',
    data['body'] ?? '',
    notificationDetails,
    payload: data.toString(),
  );

  // Handle notification click immediately for chat messages
  if (data['type'] == "chat_message" && data['room_id'] != null) {
    // Check if chat detail screen is already active with same user
    final senderId = data['sender_id']?.toString();
    final roomId = data['room_id']?.toString();

    if (_isChatDetailActiveWithUser(senderId, roomId)) {
      print(
        "Chat detail screen is active with same user - skipping immediate navigation",
      );
      return;
    }

    print("Immediate navigation for chat message notification");

    // Extract chat room information from notification data using correct field names
    final chatRoomId = data['room_id']?.toString();
    final receiverId = data['sender_id']?.toString();
    final senderName = data['full_name']?.toString() ?? 'Unknown';
    final profilePicture = data['profile_picture']?.toString() ?? '';
    final lastMessage = data['body']?.toString() ?? 'New message';
    final title = data['title']?.toString() ?? 'New Message';

    print("=== IMMEDIATE NAVIGATION DEBUG ===");
    print("Raw data: $data");
    print("Extracted chatRoomId: $chatRoomId");
    print("Extracted receiverId: $receiverId");
    print("Extracted senderName: $senderName");
    print("Extracted profilePicture: $profilePicture");
    print("ProfilePicture isEmpty: ${profilePicture.isEmpty}");
    print("ProfilePicture length: ${profilePicture.length}");

    // Create conversation object for navigation with all payload data
    final conversation = Conversation(
      id: chatRoomId ?? '',
      name: senderName,
      lastMessage: lastMessage,
      lastMessageTime: DateTime.now(),
      userId: receiverId,
      isOnline: false,
      profileImageUrl: profilePicture, // Use correct field name
    );

    print("=== IMMEDIATE CONVERSATION CREATION DEBUG ===");
    print("Created conversation.id: ${conversation.id}");
    print("Created conversation.name: ${conversation.name}");
    print(
      "Created conversation.profileImageUrl: ${conversation.profileImageUrl}",
    );
    print("Created conversation.userId: ${conversation.userId}");

    // Navigate to chat detail screen with conversation data
    Get.toNamed(
      AppRoutes.chat_detail,
      arguments: {
        'conversation': conversation,
        'notificationData': {
          'title': title,
          'body': lastMessage,
          'sender_id': receiverId,
          'room_id': chatRoomId,
          'full_name': senderName,
          'profile_picture': profilePicture,
          'timestamp': data['timestamp']?.toString(),
          'click_action': data['click_action']?.toString(),
        },
      },
    );

    print("Immediately navigated to chat detail from notification");
  }
}

Future<void> showNotification(RemoteMessage message) async {
  var data = message.data;
  String loop = data['loop']?.toString() ?? "0";
  bool isShowPopup = data['is_show_popup'] == '1';
  bool isLoopEnabled = data['loop'] != null && data['loop'].toString() == '1';

  print("##showNotification data: $data");

  // Check if this is a chat message and if chat detail screen is active with same user
  if (data['type'] == "chat_message") {
    final senderId = data['sender_id']?.toString();
    final roomId = data['room_id']?.toString();

    if (_isChatDetailActiveWithUser(senderId, roomId)) {
      print(
        "Chat detail screen is active with same user - skipping notification",
      );
      // Still refresh messages but don't show notification
      if (Get.isRegistered<MessagesController>(tag: 'messages')) {
        final messagesController = Get.find<MessagesController>(
          tag: 'messages',
        );
        messagesController.silentRefreshInbox();
      }
      return;
    }
  }

  if (Get.isRegistered<MessagesController>(tag: 'messages')) {
    print("MessagesController registered");
    final MessagesController ordersScreenController =
        Get.find<MessagesController>(tag: 'messages');
    if (data['type'] != null) {
      if (data['type'].toString() == "chat_message") {
        // Use silent refresh to prevent blinking
        ordersScreenController.silentRefreshInbox();
      }
    }
  } else {
    print("MessagesController NOT registered");
  }

  // Call notification count API for all notification types except chat_message
  String notificationType = data['type']?.toString() ?? '';
  if (notificationType != "chat_message") {
    print(
      "New notification received (type: $notificationType) - refreshing notification count",
    );
    if (Get.isRegistered<HomeMainController>(tag: 'home')) {
      Get.find<HomeMainController>(tag: 'home').fetchNotificationCount();
    }
  } else {
    print("Chat message received - skipping notification count refresh");
  }

  // Create notification channel if not already created
  if (channel == null) {
    int rand1 = Random().nextInt(10000);
    channel = AndroidNotificationChannel(
      rand1.toString(),
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel!);
  }

  // Define notification details with sound
  NotificationDetails notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      channel!.id,
      channel!.name,
      channelDescription: channel!.description,
      enableLights: true,
      playSound: true,
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: Platform.isAndroid,
      ongoing: Platform.isIOS,
      enableVibration: false,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBanner: true,
      interruptionLevel: InterruptionLevel.critical,
    ),
  );

  // Show notification
  await flutterLocalNotificationsPlugin.show(
    Random().nextInt(10000),
    data['title'] ?? 'Notification',
    data['body'] ?? 'You have a new notification',
    notificationDetails,
    payload: data.toString(),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final EnvConfig _envConfig = BuildConfig.instance.config;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print('Firebase token refreshed: $newToken');

      // Update cached token
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('firebase_device_token', newToken);
      });

      // Update to server in background
      FirebaseTokenManager.updateTokenToServer();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return GetMaterialApp(
      title: _envConfig.appName,
      initialRoute: AppPages.initial,
      initialBinding: InitialBinding(),
      getPages: AppPages.routes,
      // localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: _getSupportedLocal(),
      builder: (context, child) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: child!,
        );
      },
      theme: ThemeData(
        primarySwatch: AppColors.colorPrimarySwatch,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.light,
        primaryColor: AppColors.primaryColor,
        textTheme: const TextTheme(
          labelLarge: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      // navigatorObservers: [
      //   AnalyticsService.instance.observer,
      // ],
    );
  }

  List<Locale> _getSupportedLocal() {
    return [const Locale('en', ''), const Locale('bn', '')];
  }
}

// booking_completed_review
// review_reminder
// final_review_reminder
