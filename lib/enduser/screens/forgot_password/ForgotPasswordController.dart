import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/core/base/base_controller.dart';
import 'package:verithrive_dev/enduser/routes/app_routes.dart';
import 'package:verithrive_dev/enduser/screens/otp/OTPBinding.dart';
import 'package:verithrive_dev/enduser/screens/otp/OTPView.dart';
import 'package:verithrive_dev/enduser/utils/common_dialog.dart';
import '../../data/repository/project_repository.dart';
import '../../network/exceptions/base_exception.dart';
import '../../utils/api_services.dart';

class ForgotPasswordController extends BaseController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final ProjectRepository _repository = Get.find(tag: (ProjectRepository).toString());

  final isLoading = false.obs;
  final String? email;
  final emailController = TextEditingController();

  ForgotPasswordController({this.email});

  @override
  void onInit() {
    super.onInit();
    if (email != null && email!.isNotEmpty) {
      emailController.text = email!;
    }
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  Future<void> openOTPScreen() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final email = emailController.text.trim();
    if (email.isEmpty) {
      showResponseDialog(
        message: 'Please enter your email address',
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
      return;
    }

    isLoading.value = true;
    callForgotPasswordSendOTPService(email);
  }

  void callForgotPasswordSendOTPService(String email) {
    Map<String, dynamic> toJson() {
      final Map<String, dynamic> data = <String, dynamic>{};
      data['email'] = email;
      data['user_type'] = 'normal';
      return data;
    }
    
    var service = _repository.sendPostApiRequest(toJson, forgot_password_send_otp, false);

    callDataService(
      service,
      onSuccess: _handleForgotPasswordSendOTPResponseSuccess,
      onError: handleOnError,
      isShowLoading: true,
    );
  }

  Future<void> _handleForgotPasswordSendOTPResponseSuccess(dynamic baseResponse) async {
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
      String message = responseData['message'] ?? 'OTP sent successfully';
      
      // Extract OTP from response data if available
      String? receivedOtp;
      if (responseData['data'] != null && responseData['data'] is Map) {
        receivedOtp = responseData['data']['otp']?.toString();
      }

      if (success == true) {
        final email = emailController.text.trim();
        
        showResponseDialog(
          message: message,
          title: 'Success',
          isError: false,
          showButton: true,
          onOkPressed: () {
            // Navigate to OTP screen with email and type
            Map<String, dynamic> arguments = {
              'type': 'forgot_password',
              'email': email,
            };
            if (receivedOtp != null && receivedOtp.isNotEmpty) {
              arguments['otp'] = receivedOtp;
            }
            Get.to(
              () => OTPView(),
              binding: OTPBinding(),
              arguments: arguments,
            );
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

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }
}
