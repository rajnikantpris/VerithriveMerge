import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../api/api_response.dart';
import '../../../../api/user_api_service.dart';
import '../../../../common/base_controller.dart';
import '../../../../services/storage_service.dart';
import '../../../../widgets/response_dialog.dart';
import '../../profile_controller.dart';

class NotificationSettingsController extends BaseController {
  final UserApiService _userApiService;
  final StorageService? _storageService =
      Get.isRegistered<StorageService>() ? Get.find<StorageService>() : null;

  final notificationsEnabled = false.obs;

  NotificationSettingsController(this._userApiService);

  @override
  void onInit() {
    super.onInit();
    _loadNotificationStatus();
  }

  /// Load notification status from storage
  Future<void> _loadNotificationStatus() async {
    final status = _storageService?.readBool('is_notification') ?? false;
    notificationsEnabled.value = status;
    debugPrint('Loaded notification status: $status');
  }

  /// Toggle notification settings and update via API
  Future<void> toggleNotifications(bool value) async {
    // Optimistically update UI
    notificationsEnabled.value = value;

    // Call API to update notification status
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.updateNotification(isNotification: value),
      showLoader: false,
      onSuccess: (response) {
        if (response.success) {
          // Update storage with new value
          // if (_storageService != null) {
          //   _storageService!.writeBool('is_notification', value);
          // }
          //
          // // Extract and save user data from response if available
          // if (response.data is Map<String, dynamic>) {
          //   final data = response.data as Map<String, dynamic>;
          //   if (data['user'] is Map<String, dynamic>) {
          //     final user = data['user'] as Map<String, dynamic>;
          //     final isNotification = user['is_notification'] as bool?;
          //     if (isNotification != null && _storageService != null) {
          //       _storageService!.writeBool('is_notification', isNotification);
          //       notificationsEnabled.value = isNotification;
          //     }
          //   }
          // }

          // Call profile API to refresh profile details
          if (Get.isRegistered<ProfileController>()) {
            Get.find<ProfileController>().fetchProfileDetails();
          }

          debugPrint(
              'Notifications ${value ? "enabled" : "disabled"} successfully');
        } else {
          // Revert on failure
          final previousValue = !value;
          notificationsEnabled.value = previousValue;
          showResponseDialog(
            title: 'Error',
            message:
                response.message ?? 'Failed to update notification settings',
            isError: true,
          );
        }
      },
      onError: (error, stack) {
        // Revert on error
        final previousValue = !value;
        notificationsEnabled.value = previousValue;
        showResponseDialog(
          title: 'Error',
          message: 'Failed to update notification settings. Please try again.',
          isError: true,
        );
      },
    );
  }
}
