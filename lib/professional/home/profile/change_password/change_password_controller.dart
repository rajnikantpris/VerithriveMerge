import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../api/api_response.dart';
import '../../../../api/user_api_service.dart';
import '../../../../common/base_controller.dart';
import '../../../../services/analytics_service.dart';
import '../../../../widgets/response_dialog.dart';

class ChangePasswordController extends BaseController {
  final UserApiService _userApiService;

  ChangePasswordController(this._userApiService);

  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  late final GlobalKey<FormState> formKey;
  final obscureNewPassword = true.obs;
  final obscureConfirmPassword = true.obs;

  @override
  void onInit() {
    super.onInit();
    AnalyticsService.instance.logScreenView(
      screenName: 'ProfessionalChangePasswordScreen',
      screenClass: 'ChangePasswordView',
      pageCategory: 'profile',
      elementLocation: 'view',
    );
    // Initialize formKey to ensure a new key is created each time
    formKey = GlobalKey<FormState>();
  }

  @override
  void onClose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void toggleNewPasswordVisibility() {
    obscureNewPassword.value = !obscureNewPassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

  Future<void> onContinue() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    await callDataService<ApiResponse<dynamic>>(
      _userApiService.changePassword(
        newPassword: newPasswordController.text.trim(),
      ),
      showLoader: true,
      onSuccess: (response) {
        if (response.success) {
          // Analytics: Log password change
          

          showResponseDialog(
            message: response.message ?? 'Password changed successfully',
            title: 'Success',
            isError: false,
            onOkPressed: () {
              Get.back();
            },
          );
        } else {
          showResponseDialog(
            message: response.errorMessage,
            title: 'Error',
            isError: true,
          );
        }
      },
      onError: (error, stack) {
        final errorMsg = errorMessage.value.isNotEmpty
            ? errorMessage.value
            : 'Failed to change password. Please try again.';
        showResponseDialog(
          message: errorMsg,
          title: 'Error',
          isError: true,
        );
      },
    );
  }

  String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a new password';
    }

    // Check minimum length
    if (value.length < 8 || value.length > 12) {
      return 'Password must be at least 8-12 characters long';
    }

    // Check for uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must include at least one uppercase letter';
    }

    // Check for lowercase letter
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must include at least one lowercase letter';
    }

    // Check for number
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must include at least one number';
    }

    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != newPasswordController.text) {
      return 'Oops! Those passwords don’t quite match. One more go?';
    }

    return null;
  }
}
