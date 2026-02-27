import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/api_response.dart';
import '../../api/user_api_service.dart';
import '../../common/base_controller.dart';
import '../../routes/app_routes.dart';
import '../../widgets/response_dialog.dart';

class ForgotPasswordController extends BaseController {
  ForgotPasswordController(this._userApiService);

  final UserApiService _userApiService;

  late final GlobalKey<FormState> formKey;
  final emailController = TextEditingController();
  final isEmailValid = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize formKey to ensure a new key is created each time
    formKey = GlobalKey<FormState>();
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      isEmailValid.value = false;
      return 'Please enter your email';
    }
    if (!GetUtils.isEmail(value.trim())) {
      isEmailValid.value = false;
      return 'Please enter a valid email';
    }
    isEmailValid.value = true;
    return null;
  }

  void onEmailChanged(String value) {
    if (value.trim().isEmpty) {
      isEmailValid.value = false;
    } else {
      isEmailValid.value = GetUtils.isEmail(value.trim());
    }
  }

  Future<void> sendResetCode() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    final email = emailController.text.trim();
    const userType = 'professional';

    await callDataService<ApiResponse<dynamic>>(
      _userApiService.forgotPasswordSendOtp(
        email: email,
        userType: userType,
      ),
      showLoader: true,
      onComplete: () {
        resetState();
      },
      mapErrorMessage: (error) {
        if (error is ApiResponse) {
          final statusCode = error.statusCode;

          if (statusCode == 400) {
            return 'Invalid email address. Please check and try again.';
          }

          if (statusCode == 404) {
            return 'Email not found. Please check your email address.';
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
        if (response.success) {
          // Extract OTP from response data if available
          String? otp;
          if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            final otpValue = data['otp'];
            if (otpValue != null) {
              otp = otpValue.toString();
            }
          }

          Get.toNamed(
            Routes.verifyEmail,
            arguments: {
              'email': email,
              'nextRoute': Routes.createNewPassword,
              'user_type': userType,
              if (otp != null) 'otp': otp,
            },
          );
        } else {
          showResponseDialog(
            title: 'Error',
            message: response.errorMessage,
            isError: true,
            showButton: true,
          );
        }
      },
      onError: (error, stack) {
        final errorMsg = errorMessage.value.isNotEmpty
            ? errorMessage.value
            : 'Failed to send reset code. Please try again.';
        showResponseDialog(
          title: 'Error',
          message: errorMsg,
          isError: true,
          showButton: true,
        );
      },
    );
  }
}
