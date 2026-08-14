import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../api/api_response.dart';
import '../../../../api/user_api_service.dart';
import '../../../../common/base_controller.dart';
import '../../../../services/analytics_service.dart';
import '../../../../services/storage_service.dart';
import '../../../../widgets/response_dialog.dart';

class AboutYouController extends BaseController {
  final UserApiService _userApiService;
  final StorageService? _storageService =
      Get.isRegistered<StorageService>() ? Get.find<StorageService>() : null;

  AboutYouController(this._userApiService);

  late final GlobalKey<FormState> formKey;

  final aboutYouController = TextEditingController();
  final aboutYouWordCount = 0.obs;
  final hasValidData = false.obs;

  @override
  void onInit() {
    super.onInit();
    AnalyticsService.instance.logScreenView(
      screenName: 'ProfessionalAboutYouScreen',
      screenClass: 'AboutYouView',
      pageCategory: 'profile',
      elementLocation: 'view',
    );
    // Initialize formKey to ensure a new key is created each time
    formKey = GlobalKey<FormState>();
    // Load existing data from API
    _loadAboutYouDetails();
  }

  @override
  void onClose() {
    aboutYouController.dispose();
    super.onClose();
  }

  void onAboutYouChanged(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      aboutYouWordCount.value = 0;
      hasValidData.value = false;
      return;
    }
    final words = trimmed.split(RegExp(r'\s+'));
    aboutYouWordCount.value = words.length;
    hasValidData.value = true;
  }

  void onUpdateDetails() {
    if (formKey.currentState?.validate() ?? false) {
      _saveAboutYou();
    }
  }

  /// Load about you details from API
  Future<void> _loadAboutYouDetails() async {
    debugPrint('Loading about you details...');
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.getAboutYouDetails(),
      showLoader: true,
      onSuccess: (response) {
        if (response.success && response.data != null) {
          try {
            final data = response.data as Map<String, dynamic>?;
            if (data != null) {
              // The response might have description directly or nested in data
              String? description;
              if (data['description'] != null) {
                description = data['description'].toString();
              } else if (data['data'] is Map<String, dynamic>) {
                final nestedData = data['data'] as Map<String, dynamic>;
                if (nestedData['description'] != null) {
                  description = nestedData['description'].toString();
                }
              }

              if (description != null && description.isNotEmpty) {
                aboutYouController.text = description;
                // Update word count and valid data
                onAboutYouChanged(description);
                debugPrint(
                    'Loaded about you description: ${description.length} characters');
              } else {
                debugPrint('No description found in API response');
                hasValidData.value = false;
              }
            }
          } catch (e) {
            debugPrint('Error parsing about you details: $e');
          }
        }
      },
      onError: (error, stackTrace) {
        debugPrint('Error loading about you details: $error');
      },
    );
  }

  /// Save about you API call
  Future<void> _saveAboutYou() async {
    debugPrint('=== Starting Save About You ===');

    final description = aboutYouController.text.trim();

    debugPrint('Description: $description');
    debugPrint('Word Count: ${aboutYouWordCount.value}');

    await callDataService<ApiResponse<dynamic>>(
      _userApiService.saveAboutYou(
        description: description,
        is_update:true
      ),
      showLoader: true,
      onSuccess: (response) async {
        debugPrint('=== API Response Success ===');
        debugPrint('Success: ${response.success}');
        debugPrint('Error Message: ${response.errorMessage}');
        if (response.success) {
          // Extract and save user flags from response
          final storage = _storageService;
          if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            if (data['user'] is Map<String, dynamic>) {
              final user = data['user'] as Map<String, dynamic>;

              // Extract and save all user flags
              if (storage != null) {
                final flags = [
                  'is_personal_details',
                  'is_term_condition',
                  'is_profile_created',
                  'is_work_full',
                  'is_professional_services',
                  'is_qualification',
                  'is_personal_identification',
                  'is_about_you',
                  'is_payment',
                  'is_notification',
                ];

                for (final flag in flags) {
                  final value = user[flag] as bool?;
                  if (value != null) {
                    await storage.writeBool(flag, value);
                    debugPrint('Saved flag $flag = $value');
                  }
                }
              }
            }
          }

          showResponseDialog(
            title: 'Success',
            message: 'About you updated successfully',
            isError: false,
            showButton: true,
            onOkPressed: () {
              Get.back();
            },
          );
        } else {
          debugPrint('=== API Response Failed ===');
          debugPrint('Error: ${response.errorMessage}');
          showResponseDialog(
            title: 'Error',
            message: response.errorMessage,
            isError: true,
            showButton: true,
          );
        }
      },
      onError: (error, stack) {
        debugPrint('=== API Call Error ===');
        debugPrint('Error: $error');
        debugPrint('Stack: $stack');
        final errorMsg = errorMessage.value.isNotEmpty
            ? errorMessage.value
            : 'Failed to save about you. Please try again.';
        debugPrint('Error Message: $errorMsg');
        showResponseDialog(
          title: 'Error',
          message: errorMsg,
          isError: true,
          showButton: true,
        );
      },
    );
  }

  String? validateAboutYou(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter about you';
    }
    final trimmed = value.trim();
    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length > 500) {
      return 'Maximum 500 words allowed';
    }
    return null;
  }
}
