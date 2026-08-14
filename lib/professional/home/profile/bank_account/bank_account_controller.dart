import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../api/api_response.dart';
import '../../../../api/user_api_service.dart';
import '../../../../common/base_controller.dart';
import '../../../../services/analytics_service.dart';
import '../../../../widgets/response_dialog.dart';
import '../../../signup_terms_conditions/professional_webview_screen.dart';

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
  final bankName = RxnString();
  final last4 = RxnString();
  final routingNumber = RxnString();
  final status = RxnString();
  final currency = RxnString();
  final country = RxnString();
  final loginLink = RxnString();

  @override
  void onInit() {
    super.onInit();
    AnalyticsService.instance.logScreenView(
      screenName: 'ProfessionalBankAccountScreen',
      screenClass: 'BankAccountView',
      pageCategory: 'profile',
      elementLocation: 'view',
    );
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
              if (data['last4'] != null &&
                  data['last4'].toString().isNotEmpty) {
                accountNumberController.text =
                    '•••• •••• ${data['last4']}';
                hasData = true;
              }

              // Populate sort code
              if (data['routing_number'] != null &&
                  data['routing_number'].toString().isNotEmpty) {
                sortCodeController.text = data['routing_number'].toString();
                hasData = true;
              }

              bankName.value = data['bank_name']?.toString();
              last4.value = data['last4']?.toString();
              routingNumber.value = data['routing_number']?.toString();
              status.value = data['status']?.toString();
              currency.value = data['currency']?.toString();
              country.value = data['country']?.toString();
              loginLink.value = data['loginLink']?.toString();
              if (bankName.value != null ||
                  last4.value != null ||
                  routingNumber.value != null ||
                  status.value != null ||
                  currency.value != null ||
                  country.value != null ||
                  loginLink.value != null) {
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

  void openStripeDashboard() {
    final url = loginLink.value;
    if (url == null || url.isEmpty) return;
    Get.to(() => ProfessionalWebViewScreen(url: url));
  }
}
