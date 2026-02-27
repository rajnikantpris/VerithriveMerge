import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../api/api_response.dart';
import '../../../../api/user_api_service.dart';
import '../../../../common/base_controller.dart';
import '../../../../routes/app_routes.dart';
import '../../../../services/storage_service.dart';
import '../../../../widgets/response_dialog.dart';

class AccountController extends BaseController {
  final UserApiService _userApiService;
  final StorageService? _storageService =
      Get.isRegistered<StorageService>() ? Get.find<StorageService>() : null;

  AccountController(this._userApiService);

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  late final GlobalKey<FormState> formKey;
  final obscurePassword = true.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize formKey to ensure a new key is created each time
    formKey = GlobalKey<FormState>();
    // Load user email from storage
    _loadUserEmail();
    passwordController.text = '********';
  }

  void _loadUserEmail() {
    final storage = _storageService;
    if (storage != null) {
      final savedEmail = storage.readString('user_email');
      if (savedEmail != null && savedEmail.isNotEmpty) {
        emailController.text = savedEmail;
      }
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void onChangePassword() {
    Get.toNamed(Routes.changePassword);
  }

  void onDeleteAccount() {
    // Show confirmation dialog and handle account deletion
    debugPrint('Delete account tapped');
    // Dialog will be shown from the view
  }

  Future<void> onConfirmDeactivate() async {
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.deleteAccount(),
      showLoader: true,
      onComplete: () {
        resetState();
      },
      mapErrorMessage: (error) {
        if (error is ApiResponse) {
          final statusCode = error.statusCode;

          if (statusCode == 401) {
            return 'Session expired. Please log in again.';
          }

          if (statusCode != null && statusCode >= 500) {
            return 'Server error. Please try again later.';
          }

          return error.errorMessage;
        }
        return mapErrorToMessage(error);
      },
      onError: (error, stack) {
        // Show error dialog to user
        final errorMsg = errorMessage.value.isNotEmpty
            ? errorMessage.value
            : 'Failed to delete account. Please try again.';
        showResponseDialog(
          message: errorMsg,
          title: 'Error',
          isError: true,
          showButton: true,
          onOkPressed: () {
            // Even if delete API fails, clear local storage and navigate
            _clearLocalDataAndNavigate();
          },
        );
      },
      onSuccess: (response) async {
        if (response.success) {
          // Clear local storage and navigate
          await _clearLocalDataAndNavigate();
          showResponseDialog(
            message: 'Your account has been deactivated successfully.',
            title: 'Success',
            isError: false,
            showButton: true,
            onOkPressed: () {
              // Navigation already handled
            },
          );
        } else {
          // API returned error but still clear local data
          await _clearLocalDataAndNavigate();
          showResponseDialog(
            message: response.errorMessage,
            title: 'Error',
            isError: true,
            showButton: true,
            onOkPressed: () {
              // Navigation already handled
            },
          );
        }
      },
    );
  }

  Future<void> _clearLocalDataAndNavigate() async {
    // Clear stored token if available
    final storage = _storageService;
    if (storage != null) {
      await storage.writeString('access_token', '');
    }

    // Navigate to login page
    Get.offAllNamed(Routes.selectUser);
  }

  void onUpdateInformation() {
    if (formKey.currentState?.validate() ?? false) {
      // Handle update account information
      debugPrint('Update information: ${emailController.text}');
      // TODO: Implement update account API call
      Get.snackbar(
        'Success',
        'Account information updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
}
