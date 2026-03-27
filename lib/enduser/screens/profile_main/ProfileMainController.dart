import 'package:get/get.dart';
import 'package:verithrive_dev/select_user/select_user_binding.dart';
import 'package:verithrive_dev/select_user/select_user_view.dart';
import '../../core/values/sharePrefrenceConst.dart';
import '../../routes/app_routes.dart';
import '../../core/base/base_controller.dart';
import '../../data/repository/project_repository.dart';
import '../../network/exceptions/base_exception.dart';
import '../../utils/api_services.dart';
import '../../utils/common_dialog.dart';
import '../../utils/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verithrive_dev/services/storage_service.dart';
import 'package:verithrive_dev/services/social_auth_service.dart';
import 'package:verithrive_dev/services/socket_service.dart' as prof_socket;
import '../message/socket_service.dart';

class ProfileMainController extends BaseController {
  final StorageService _storageService = Get.find<StorageService>();
  final ProjectRepository _repository = Get.find(tag: (ProjectRepository).toString());
  final SocialAuthService _socialAuthService = SocialAuthService();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Don't check authentication on init - let user navigate first
    // Authentication will be checked when data is actually accessed
  }

  // Refresh data method called by MainScreen
  void refreshData() {
    print("ProfileMainController refreshData called");
    // Check authentication before accessing profile
    _checkAuthAndInit();
  }

  // Check authentication and initialize profile
  Future<void> _checkAuthAndInit() async {
    bool canAccess = await AuthService.requireAuth();
    if (canAccess) {
      print("ProfileMainController initialized - User authenticated");
    }
  }

  // Logout function that calls API and then clears all data except remember me data
  Future<void> logoutApiCall() async {
    // Call logout API
    callLogoutApi();
  }

  void callLogoutApi() {
    Map<String, dynamic> toJson() {
      final Map<String, dynamic> data = <String, dynamic>{};
      return data; // Empty object for logout API
    }
    
    var service = _repository.sendPostApiRequest(
      toJson,
      logout,
      true, // isToken = true (requires authentication)
    );

    callDataService(
      service,
      onSuccess: _handleLogoutSuccess,
      onError: _handleLogoutError,
      isShowLoading: true,
    );
  }

  Future<void> _handleLogoutSuccess(dynamic baseResponse) async {
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
      String message = responseData['message'] ?? 'Logout successful';

      if (success == true) {
        // Show success dialog with API message
        showResponseDialog(
          message: message,
          title: 'Success',
          isError: false,
          showButton: true,
          onOkPressed: () async {
            // Execute current logout code on OK button click
            await performLogout();
          },
        );
      } else {
        // Show error message if API returns success: false
        showResponseDialog(
          message: message,
          title: 'Error',
          isError: true,
          showButton: true,
          onOkPressed: () {},
        );
      }
    } catch (e) {
      showResponseDialog(
        message: "Error processing logout response: $e",
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    }
  }

  void _handleLogoutError(dynamic e) {
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
        message: "An error occurred while logging out",
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    }
  }

  // Current logout code - clears only end-user data, preserving all remember me credentials
  Future<void> performLogout() async {
    try {
      // Properly disconnect and remove socket services during logout
      if (Get.isRegistered<EndUserSocketService>()) {
        final endUserSocket = Get.find<EndUserSocketService>();
        endUserSocket.disconnect();
        Get.delete<EndUserSocketService>();
        print('EndUserSocketService disconnected and removed');
      }
      
      if (Get.isRegistered<prof_socket.SocketService>()) {
        final professionalSocket = Get.find<prof_socket.SocketService>();
        professionalSocket.disconnect();
        Get.delete<prof_socket.SocketService>();
        print('Professional SocketService disconnected and removed');
      }

      // Sign out from social providers first
      await _socialAuthService.signOutSocialProviders();

      // Define keys to keep (all remember me data)
      final keysToKeep = [
        // Professional keys
        'professional_remember_me',
        'professional_saved_email',
        'professional_saved_password',
        // End-user keys
        SharePreferenceConst.rememberMe,
        SharePreferenceConst.savedEmail,
        SharePreferenceConst.savedPassword,
      ];

      // Clear all stored data except the specified keys
      await _storageService.clearAllExcept(keysToKeep);

      // Navigate to select user screen
      Get.offAll(
        () => SelectUserView(),
        binding: SelectUserBinding(),
      );
    } catch (e) {
      print('Error during logout: $e');
      // Still navigate to select user screen even if there's an error
      Get.offAll(
        () => SelectUserView(),
        binding: SelectUserBinding(),
      );
    }
  }
}
