import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../api/api_response.dart';
import '../../../../api/user_api_service.dart';
import '../../../../common/base_controller.dart';
import '../../../../widgets/response_dialog.dart';

class BankAccountController extends BaseController {
  final UserApiService _userApiService;

  BankAccountController(this._userApiService);

  late final GlobalKey<FormState> formKey;

  final accountHolderNameController = TextEditingController();
  final accountNumberController = TextEditingController();
  final sortCodeController = TextEditingController();

  // Track if form has been submitted to show validation errors
  final hasAttemptedSubmit = false.obs;

  // Track if bank details already exist
  final hasBankDetails = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize formKey to ensure a new key is created each time
    formKey = GlobalKey<FormState>();
    // Load bank details if available
    _loadBankDetails();
  }

  @override
  void onClose() {
    accountHolderNameController.dispose();
    accountNumberController.dispose();
    sortCodeController.dispose();
    super.onClose();
  }

  Future<void> onAddAccount() async {
    // Mark that user has attempted to submit
    hasAttemptedSubmit.value = true;

    if (!(formKey.currentState?.validate() ?? false)) return;

    await callDataService<ApiResponse<dynamic>>(
      _userApiService.addBankDetails(
        accountHolderName: accountHolderNameController.text.trim(),
        accountNumber: accountNumberController.text.trim(),
        sortCode: sortCodeController.text.trim(),
      ),
      showLoader: true,
      onSuccess: (response) {
        if (response.success) {
          final successMessage = response.message ??
              (hasBankDetails.value
                  ? 'Bank account updated successfully'
                  : 'Bank account added successfully');
          showResponseDialog(
            message: successMessage,
            title: 'Success',
            isError: false,
            showButton: false,
            onOkPressed: () {
              Get.back();
            },
          );
        } else {
          showResponseDialog(
            message: response.errorMessage,
            title: 'Error',
            isError: true,
            showButton: true,
          );
        }
      },
      onError: (error, stack) {
        final errorMsg = errorMessage.value.isNotEmpty
            ? errorMessage.value
            : 'Failed to add bank account. Please try again.';
        showResponseDialog(
          message: errorMsg,
          title: 'Error',
          isError: true,
          showButton: true,
        );
      },
    );
  }

  String? validateNotEmpty(String? value, String label) {
    // Only show validation errors after first submit attempt
    if (!hasAttemptedSubmit.value) return null;

    if (value == null || value.trim().isEmpty) {
      return 'Please enter $label';
    }
    return null;
  }

  String? validateSortCode(String? value) {
    // Only show validation errors after first submit attempt
    if (!hasAttemptedSubmit.value) return null;

    if (value == null || value.trim().isEmpty) {
      return 'Please enter sort code';
    }
    // Validate format: 00-00-00
    final sortCodePattern = RegExp(r'^\d{2}-\d{2}-\d{2}$');
    if (!sortCodePattern.hasMatch(value.trim())) {
      return 'Sort code must be in format 00-00-00';
    }
    return null;
  }

  // Clear validation errors when user starts typing
  void onFieldChanged() {
    if (hasAttemptedSubmit.value) {
      formKey.currentState?.validate();
    }
  }

  /// Load bank details from API
  Future<void> _loadBankDetails() async {
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.getBankDetails(),
      showLoader: true,
      onSuccess: (response) {
        if (response.success && response.data != null) {
          try {
            final data = response.data as Map<String, dynamic>?;
            if (data != null) {
              bool hasData = false;

              // Populate account holder name
              if (data['account_holder_name'] != null &&
                  data['account_holder_name'].toString().isNotEmpty) {
                accountHolderNameController.text =
                    data['account_holder_name'].toString();
                hasData = true;
              }

              // Populate account number
              if (data['account_number'] != null &&
                  data['account_number'].toString().isNotEmpty) {
                accountNumberController.text =
                    data['account_number'].toString();
                hasData = true;
              }

              // Populate sort code
              if (data['sort_code'] != null &&
                  data['sort_code'].toString().isNotEmpty) {
                sortCodeController.text = data['sort_code'].toString();
                hasData = true;
              }

              // Update flag based on whether data exists
              hasBankDetails.value = hasData;
            } else {
              hasBankDetails.value = false;
            }
          } catch (e) {
            debugPrint('Error parsing bank details: $e');
            hasBankDetails.value = false;
          }
        } else {
          hasBankDetails.value = false;
        }
      },
    );
  }
}
