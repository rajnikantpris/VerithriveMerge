import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_colors.dart';
import '../../core/base/base_controller.dart';
import '../../data/repository/project_repository.dart';
import '../../network/exceptions/base_exception.dart';
import '../../utils/api_services.dart';
import '../../utils/common_dialog.dart';

class ChangePasswordController extends BaseController {
  final ProjectRepository _repository = Get.find(tag: (ProjectRepository).toString());
  
  final formKey = GlobalKey<FormState>();
  final isLoading = false.obs;
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;

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
    if (value.length < 12) {
      return 'Password must be at least 12 characters';
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

  void changePassword() {
    if (formKey.currentState!.validate()) {
      isLoading.value = true;
      callChangePasswordService();
    }
  }

  void callChangePasswordService() {
    Map<String, dynamic> toJson() {
      final Map<String, dynamic> data = <String, dynamic>{};
      data['new_password'] = passwordController.text.trim();
      return data;
    }
    
    var service = _repository.sendPostApiRequest(
      toJson,
      change_password,
      true, // isToken = true (requires authentication)
    );

    callDataService(
      service,
      onSuccess: _handleChangePasswordResponseSuccess,
      onError: handleOnError,
      isShowLoading: true,
    );
  }

  Future<void> _handleChangePasswordResponseSuccess(dynamic baseResponse) async {
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
      String message = responseData['message'] ?? 'Password changed successfully';

      if (success == true) {
        showResponseDialog(
          message: message,
          title: 'Success',
          isError: false,
          showButton: true,
          onOkPressed: () {
            Get.back();
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
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}

