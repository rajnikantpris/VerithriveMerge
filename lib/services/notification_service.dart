import 'package:get/get.dart';
import '../api/user_api_service.dart';
import '../services/storage_service.dart';
import '../utils/logger.dart';

/// Shared notification service to manage notification count across all screens
class NotificationService extends GetxService {
  // Shared notification count observable
  final notificationCount = 0.obs;

  /// Get UserApiService if available
  UserApiService? get _userApiService =>
      Get.isRegistered<UserApiService>() ? Get.find<UserApiService>() : null;

  /// Check if user is authenticated
  bool _isAuthenticated() {
    if (!Get.isRegistered<StorageService>()) {
      return false;
    }
    final storage = Get.find<StorageService>();
    final token = storage.readString('access_token');
    final userType = storage.readString('userType');
    if (userType != 'professional') {
      return false;
    }
    return token != null && token.isNotEmpty;
  }

  /// Fetch notification count from API
  Future<void> fetchNotificationCount() async {
    // Check if user is authenticated before making API call
    if (!_isAuthenticated()) {
      logInfo('User not authenticated, skipping notification count fetch');
      notificationCount.value = 0;
      return;
    }

    final apiService = _userApiService;
    if (apiService == null) {
      logError('UserApiService not available');
      return;
    }

    try {
      final response = await apiService.getNotificationsCount();

      try {
        if (response.success && response.data != null) {
          // Handle different response structures
          int count = 0;
          if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            // Try different possible keys for count
            // Priority: unread_count > total_count > count > notification_count
            if (data['unread_count'] != null) {
              count = (data['unread_count'] is int)
                  ? data['unread_count'] as int
                  : int.tryParse(data['unread_count'].toString()) ?? 0;
            } else if (data['total_count'] != null) {
              count = (data['total_count'] is int)
                  ? data['total_count'] as int
                  : int.tryParse(data['total_count'].toString()) ?? 0;
            } else if (data['count'] != null) {
              count = (data['count'] is int)
                  ? data['count'] as int
                  : int.tryParse(data['count'].toString()) ?? 0;
            } else if (data['notification_count'] != null) {
              count = (data['notification_count'] is int)
                  ? data['notification_count'] as int
                  : int.tryParse(data['notification_count'].toString()) ?? 0;
            } else if (data['data'] != null && data['data'] is Map) {
              final nestedData = data['data'] as Map<String, dynamic>;
              if (nestedData['unread_count'] != null) {
                count = (nestedData['unread_count'] is int)
                    ? nestedData['unread_count'] as int
                    : int.tryParse(nestedData['unread_count'].toString()) ?? 0;
              } else if (nestedData['total_count'] != null) {
                count = (nestedData['total_count'] is int)
                    ? nestedData['total_count'] as int
                    : int.tryParse(nestedData['total_count'].toString()) ?? 0;
              } else if (nestedData['count'] != null) {
                count = (nestedData['count'] is int)
                    ? nestedData['count'] as int
                    : int.tryParse(nestedData['count'].toString()) ?? 0;
              }
            }
          } else if (response.data is int) {
            count = response.data as int;
          }
          notificationCount.value = count;
          logInfo('Notification count updated: $count');
        } else {
          notificationCount.value = 0;
        }
      } catch (e, stackTrace) {
        logError('Error parsing notification count',
            error: e, stackTrace: stackTrace);
        notificationCount.value = 0;
      }
    } catch (error, stack) {
      logError('Failed to fetch notification count',
          error: error, stackTrace: stack);
      // Don't reset count on error, keep previous value
    }
  }
}
