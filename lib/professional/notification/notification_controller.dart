import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../api/api_response.dart';
import '../../api/user_api_service.dart';
import '../../common/base_controller.dart';
import '../../services/notification_service.dart';

class NotificationItem {
  const NotificationItem({
    required this.title,
    required this.description,
    required this.dateLabel,
  });

  final String title;
  final String description;
  final String dateLabel;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    // Parse date from API response and format it
    String dateLabel = '';
    if (json['created_at'] != null ||
        json['date'] != null ||
        json['createdAt'] != null) {
      try {
        final dateStr = json['created_at'] ?? json['date'] ?? json['createdAt'];
        if (dateStr is String) {
          final date = DateTime.parse(dateStr);
          dateLabel = DateFormat('dd/MM/yyyy').format(date);
        }
      } catch (e) {
        // If parsing fails, use the string as is or empty
        dateLabel = json['date']?.toString() ?? '';
      }
    }

    return NotificationItem(
      title: json['title']?.toString() ?? json['heading']?.toString() ?? '',
      description: json['description']?.toString() ??
          json['message']?.toString() ??
          json['body']?.toString() ??
          '',
      dateLabel: dateLabel,
    );
  }
}

class NotificationController extends BaseController {
  NotificationController(this._userApiService);

  final UserApiService _userApiService;
  final notifications = <NotificationItem>[].obs;

  // Get NotificationService if available
  NotificationService? get _notificationService =>
      Get.isRegistered<NotificationService>()
          ? Get.find<NotificationService>()
          : null;

  @override
  void onInit() {
    super.onInit();
    // Refresh notification count when screen opens
    _notificationService?.fetchNotificationCount();
    fetchNotifications();
  }

  /// Fetch notifications from API
  /// [showLoader] - Whether to show the loading indicator (default: true)
  Future<void> fetchNotifications({bool showLoader = true}) async {
    await callDataService(
      _userApiService.getNotificationsList(),
      showLoader: showLoader,
      onSuccess: (ApiResponse<dynamic> response) {
        if (response.success && response.data != null) {
          _parseApiResponse(response.data);
        } else {
          // If API fails, clear list
          notifications.clear();
        }
      },
      onError: (error, stack) {
        // Error is already handled by callDataService
        // Clear list on error
        notifications.clear();
      },
    );
  }

  /// Parse API response and update notifications list
  void _parseApiResponse(dynamic data) {
    try {
      // Handle different response structures
      List<dynamic>? notificationsList;

      if (data is List) {
        notificationsList = data;
      } else if (data is Map<String, dynamic>) {
        // Check if data is nested under common keys
        if (data['data'] is List) {
          notificationsList = data['data'] as List;
        } else if (data['notifications'] is List) {
          notificationsList = data['notifications'] as List;
        } else if (data['list'] is List) {
          notificationsList = data['list'] as List;
        } else if (data['items'] is List) {
          notificationsList = data['items'] as List;
        }
      }

      if (notificationsList != null && notificationsList.isNotEmpty) {
        notifications.value = notificationsList
            .map((item) {
              if (item is Map<String, dynamic>) {
                return NotificationItem.fromJson(item);
              }
              return null;
            })
            .whereType<NotificationItem>()
            .toList();
      } else {
        // Empty list
        notifications.clear();
      }
    } catch (e) {
      // If parsing fails, clear list
      notifications.clear();
    }
  }
}
