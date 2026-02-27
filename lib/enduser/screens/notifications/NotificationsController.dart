import 'package:get/get.dart';
import '../../core/base/base_controller.dart';
import '../../data/repository/project_repository.dart';
import '../../core/values/sharePrefrenceConst.dart';
import '../../network/exceptions/base_exception.dart';
import '../../utils/api_services.dart';
import '../../utils/common_dialog.dart';
import 'package:verithrive_dev/services/storage_service.dart';

class NotificationsController extends BaseController {
  final ProjectRepository _repository = Get.find(tag: (ProjectRepository).toString());
  final StorageService _storageService = Get.find<StorageService>();
  
  var notificationsEnabled = true.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    try {
      bool isNotification =
          _storageService.readBool(SharePreferenceConst.isNotification) ??
              true; // Default to true if not set
      notificationsEnabled.value = isNotification;
    } catch (e) {
      print('Error loading notification preference: $e');
      // Keep default value (true)
    }
  }

  void toggleNotifications(bool value) {
    notificationsEnabled.value = value;
    // Call API to update notification preference
    updateNotificationPreference(value);
  }

  void updateNotificationPreference(bool isEnabled) {
    Map<String, dynamic> toJson() {
      final Map<String, dynamic> data = <String, dynamic>{};
      data['is_notification'] = isEnabled;
      return data;
    }
    
    var service = _repository.sendPostApiRequest(
      toJson,
      notification,
      true, // isToken = true (requires authentication)
    );

    callDataService(
      service,
      onSuccess: _handleNotificationUpdateSuccess,
      onError: _handleNotificationUpdateError,
      isShowLoading: false, // Don't show loading for toggle
    );
  }

  Future<void> _handleNotificationUpdateSuccess(dynamic baseResponse) async {
    try {
      // Parse the response - baseResponse is a Dio Response object
      Map<String, dynamic> responseData;
      if (baseResponse != null && baseResponse.data != null) {
        responseData = baseResponse.data is Map<String, dynamic> 
            ? baseResponse.data 
            : baseResponse.data as Map<String, dynamic>;
      } else if (baseResponse is Map<String, dynamic>) {
        responseData = baseResponse;
      } else {
        throw Exception('Invalid response format');
      }

      bool success = responseData['success'] ?? false;
      String message = responseData['message'] ?? 'Notification preference updated successfully';

      if (success == true) {
        // Success - notification preference updated
        // Save to shared preferences
        await _storageService.writeBool(
            SharePreferenceConst.isNotification, notificationsEnabled.value);
        // The toggle value is already updated in the UI
      } else {
        // Revert toggle if API call failed
        notificationsEnabled.value = !notificationsEnabled.value;
        showResponseDialog(
          message: message,
          title: 'Error',
          isError: true,
          showButton: true,
          onOkPressed: () {},
        );
      }
    } catch (e) {
      // Revert toggle on error
      notificationsEnabled.value = !notificationsEnabled.value;
      showResponseDialog(
        message: "Error processing response: $e",
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    }
  }

  void _handleNotificationUpdateError(dynamic e) {
    // Revert toggle on error
    notificationsEnabled.value = !notificationsEnabled.value;
    
    if (e is BaseException) {
      showResponseDialog(
        message: e.message,
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    } else {
      showResponseDialog(
        message: "An error occurred while updating notification preference",
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    }
  }
}
