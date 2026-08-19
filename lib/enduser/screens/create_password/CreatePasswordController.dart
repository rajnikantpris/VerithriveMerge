import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/core/base/base_controller.dart';
import 'package:verithrive_dev/enduser/routes/app_routes.dart';
import 'package:verithrive_dev/enduser/screens/login/LoginBinding.dart';
import 'package:verithrive_dev/enduser/screens/login/LoginView.dart';
import 'package:verithrive_dev/enduser/utils/common_dialog.dart';
import '../../data/repository/project_repository.dart';
import '../../network/exceptions/base_exception.dart';
import '../../utils/api_services.dart';
import 'package:verithrive_dev/services/analytics_service.dart';

class CreatePasswordController extends BaseController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final ProjectRepository _repository =
      Get.find(tag: (ProjectRepository).toString());

  final isLoading = false.obs;

  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final _isPasswordComplete = false.obs;

  String? userEmail;
  String type = "";
  bool _isDisposed = false;

  CreatePasswordController();

  @override
  void onInit() {
    super.onInit();
    AnalyticsService.instance.logScreenView(
      screenName: 'CreatePasswordView',
      screenClass: 'CreatePasswordView',
      pageCategory: 'register',
      elementLocation: 'view',
    );
    // Get email and type from arguments
    if (Get.arguments is Map) {
      userEmail = Get.arguments['email'];
      type = Get.arguments['type'] ?? "";
    }
  }

  void updatePasswordState() {
    // Update reactive state when text changes
    try {
      final password = passwordController.text.trim();
      final confirmPassword = confirmPasswordController.text.trim();

      // Check if both fields are not empty
      final bothFieldsNotEmpty =
          password.isNotEmpty && confirmPassword.isNotEmpty;

      // Check if passwords match
      final passwordsMatch = password == confirmPassword;

      // Check if password meets validation criteria
      final passwordValid = validatePassword(password) == null;

      // Enable continue button only if all conditions are met
      _isPasswordComplete.value =
          bothFieldsNotEmpty && passwordsMatch && passwordValid;
    } catch (e) {
      // Ignore any errors
    }
  }

  bool get isPasswordComplete => _isPasswordComplete.value;

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  Future<void> clickContinueBtn() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    // Validate that passwords match
    if (passwordController.text != confirmPasswordController.text) {
      showResponseDialog(
        message: 'Passwords do not match',
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
      return;
    }

    // Get email from arguments or show error
    String emailToUse = userEmail ?? '';
    if (emailToUse.isEmpty) {
      showResponseDialog(
        message: 'Email not found. Please try again.',
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {
          Get.back();
        },
      );
      return;
    }

    isLoading.value = true;
    callForgotPasswordResetService(emailToUse);
  }

  void callForgotPasswordResetService(String email) {
    Map<String, dynamic> toJson() {
      final Map<String, dynamic> data = <String, dynamic>{};
      data['email'] = email;
      data['new_password'] = passwordController.text.trim();
      data['user_type'] = 'normal';
      return data;
    }

    var service =
        _repository.sendPostApiRequest(toJson, forgot_password_reset, false);

    callDataService(
      service,
      onSuccess: _handleForgotPasswordResetResponseSuccess,
      onError: handleOnError,
      isShowLoading: true,
    );
  }

  Future<void> _handleForgotPasswordResetResponseSuccess(
      dynamic baseResponse) async {
    isLoading.value = false;

    try {
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
      String message = responseData['message'] ?? 'Password reset successfully';

      if (success == true) {
        showResponseDialog(
          message: message,
          title: 'Success',
          isError: false,
          showButton: true,
          onOkPressed: () {
            // Close the dialog first
            Navigator.of(Get.context!, rootNavigator: true).pop();

            // Wait for dialog to close, then navigate
            // Use post-frame callback to ensure dialog is fully closed
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Navigate to login screen
              // offAllNamed will remove all previous routes and their controllers
              Get.offAll(
                () => LoginView(),
                binding: LoginBinding(),
              );
            });
          },
        );
      } else {
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
        message: "Error processing response: $e",
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    }
  }

  void handleOnError(dynamic e) {
    isLoading.value = false;

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
        message: "An error occurred. Please try again.",
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8 || value.length > 12) {
      return 'Password must be at least 8-12 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain an uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain a lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a number';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }
}
