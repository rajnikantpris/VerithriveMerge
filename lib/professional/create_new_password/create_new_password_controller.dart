import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/api_response.dart';
import '../../api/user_api_service.dart';
import '../../common/base_controller.dart';
import '../../routes/app_routes.dart';
import '../../widgets/response_dialog.dart';

class CreateNewPasswordController extends BaseController {
  CreateNewPasswordController(this._userApiService);

  final UserApiService _userApiService;

  late final GlobalKey<FormState> formKey;
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final isButtonEnabled = false.obs;

  late final String email;
  late final String otp;
  late final String userType;

  @override
  void onInit() {
    super.onInit();
    // Initialize formKey to ensure a new key is created each time
    formKey = GlobalKey<FormState>();
    final args = Get.arguments as Map<String, dynamic>?;
    email = (args?['email'] as String?) ?? '';
    otp = (args?['otp'] as String?) ?? '';
    userType = (args?['user_type'] as String?) ?? 'professional';

    // Add listeners to track text changes
    passwordController.addListener(_updateButtonState);
    confirmPasswordController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    isButtonEnabled.value = passwordController.text.trim().isNotEmpty &&
        confirmPasswordController.text.trim().isNotEmpty;
  }

  @override
  void onClose() {
    // Remove listeners before disposing
    passwordController.removeListener(_updateButtonState);
    confirmPasswordController.removeListener(_updateButtonState);
    // Clear controllers before disposing to prevent access after disposal
    passwordController.clear();
    confirmPasswordController.clear();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8 || value.length > 12) {
      return 'Password must be at least 8-12 characters long';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must include at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must include at least one lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must include at least one number';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (!isClosed &&
        passwordController.text.isNotEmpty &&
        value != passwordController.text) {
      return 'Oops! Those passwords don’t quite match. One more go?';
    }
    return null;
  }

  Future<void> submit() async {
    if (isClosed) return;
    if (!(formKey.currentState?.validate() ?? false)) return;

    // Capture password value early to avoid accessing disposed controller
    final newPassword = passwordController.text.trim();
    if (isClosed) return;

    await callDataService<ApiResponse<dynamic>>(
      _userApiService.resetPassword(
        email: email,
        userType: userType,
        newPassword: newPassword,
      ),
      showLoader: true,
      onComplete: () {
        resetState();
      },
      mapErrorMessage: (error) {
        if (error is ApiResponse) {
          final statusCode = error.statusCode;

          if (statusCode == 400) {
            return 'Invalid request. Please check your information and try again.';
          }

          if (statusCode == 401) {
            return 'Unauthorized. Please verify your OTP again.';
          }

          if (statusCode == 404) {
            return 'Service not found. Please try again later.';
          }

          if (statusCode == 429) {
            return 'Too many attempts. Please wait and try again.';
          }

          if (statusCode != null && statusCode >= 500) {
            return 'Server error. Please try again later.';
          }

          return error.errorMessage;
        }
        return mapErrorToMessage(error);
      },
      onSuccess: (response) {
        if (!isClosed) {
          if (response.success) {
            final messageText =
                response.message ?? 'Password reset successfully';
            if (!isClosed) {
              // Small delay to ensure UI operations complete before navigation
              Future.delayed(const Duration(milliseconds: 100), () {
                if (!isClosed) {
                  Get.offAllNamed(Routes.login);
                }
              });
            }

            // showResponseDialog(
            //   message: messageText,
            //   title: 'Success',
            //   isError: false,
            //   showButton: true,
            //   onOkPressed: () {
            //     if (!isClosed) {
            //       // Small delay to ensure UI operations complete before navigation
            //       Future.delayed(const Duration(milliseconds: 100), () {
            //         if (!isClosed) {
            //           Get.offAllNamed(Routes.login);
            //         }
            //       });
            //     }
            //   },
            // );
          } else {
            showResponseDialog(
              title: 'Error',
              message: response.errorMessage,
              isError: true,
              showButton: true,
            );
          }
        }
      },
      onError: (error, stack) {
        if (!isClosed) {
          final errorMsg = errorMessage.value.isNotEmpty
              ? errorMessage.value
              : 'Failed to reset password. Please try again.';
          showResponseDialog(
            title: 'Error',
            message: errorMsg,
            isError: true,
            showButton: true,
          );
        }
      },
    );
  }
}
