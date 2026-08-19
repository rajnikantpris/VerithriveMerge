import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/screens/login/LoginBinding.dart';
import 'package:verithrive_dev/enduser/screens/login/LoginView.dart';
import '../../../select_user/select_user_binding.dart';
import '../../../select_user/select_user_view.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../core/base/base_controller.dart';
import '../../data/repository/project_repository.dart';
import '../../core/values/sharePrefrenceConst.dart';
import '../../routes/app_routes.dart';
import '../../utils/api_services.dart';
import '../../utils/common_dialog.dart';
import '../../network/exceptions/base_exception.dart';
import 'package:verithrive_dev/services/storage_service.dart';
import 'package:verithrive_dev/services/analytics_service.dart';

class AccountController extends BaseController {
  final ProjectRepository _repository =
      Get.find(tag: (ProjectRepository).toString());
  final StorageService _storageService = Get.find<StorageService>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController(text: '**************');
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserEmail();
    AnalyticsService.instance.logScreenView(
      screenName: 'AccountScreen',
      screenClass: 'AccountScreen',
      pageCategory: 'profile',
      elementLocation: 'view',
    );
  }

  Future<void> _loadUserEmail() async {
    try {
      String email =
          _storageService.readString(SharePreferenceConst.email) ?? '';
      if (email.isNotEmpty) {
        emailController.text = email;
      }
    } catch (e) {
      print('Error loading email: $e');
    }
  }

  void updateInformation() {
    isLoading.value = true;
    // Simulate API call
    Future.delayed(Duration(seconds: 2), () {
      isLoading.value = false;
      Get.snackbar(
        'Success',
        'Information updated successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
      );
    });
  }

  void showDeleteAccountDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Delete account',
                style: AppTextStyles.mediumTextStyle(
                  fontSize: 24,
                  color: AppColors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Taking a break? You\'re welcome back anytime - but you\'ll lose all your saved data.',
                style: AppTextStyles.regularTextStyle(
                  fontSize: 16,
                  color: AppColors.color2D2D2D,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    AnalyticsService.instance.logButtonTap(
                      eventName: 'delete_account_tap',
                      screenName: 'AccountScreen',
                      screenClass: 'AccountScreen',
                      elementText: 'Yes, delete',
                      elementLocation: 'button_tap_cta',
                      pageCategory: 'profile',
                    );
                    Get.back();
                    deleteAccount();
                  },
                  child: Text(
                    'Yes, delete',
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.colorEB001B,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'No, go back',
                    style: AppTextStyles.regularTextStyle(
                        fontSize: 16, color: AppColors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void deleteAccount() {
    var service = _repository.sendDeleteApiRequest(delete_account, true);

    callDataService(
      service,
      onSuccess: _handleDeleteAccountSuccess,
      onError: _handleDeleteAccountError,
      isShowLoading: true,
    );
  }

  Future<void> _handleDeleteAccountSuccess(dynamic baseResponse) async {
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
      String message =
          responseData['message'] ?? 'Account deleted successfully';

      if (success == true) {
        // Show success dialog with API message
        showResponseDialog(
          message: message,
          title: 'Success',
          isError: false,
          showButton: true,
          onOkPressed: () async {
            // Clear all preferences
            await _storageService.clear();

            // Navigate to login screen
            Get.offAll(
              () => SelectUserView(),
              binding: SelectUserBinding(),
            );
          },
        );
      } else {
        // Show error dialog if API returns success: false
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
        message: "Error processing delete account response: ${e.toString()}",
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    }
  }

  void _handleDeleteAccountError(dynamic e) {
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
        message: "An error occurred while deleting your account",
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
