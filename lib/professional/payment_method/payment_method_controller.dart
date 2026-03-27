import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/api_response.dart';
import '../../api/user_api_service.dart';
import '../../common/base_controller.dart';
import '../../models/login_response_model.dart';
import '../../routes/app_routes.dart';
import '../../services/storage_service.dart';
import '../../theme/image_paths.dart';
import '../../widgets/response_dialog.dart';

class PaymentMethodOption {
  PaymentMethodOption({
    required this.id,
    required this.title,
    this.assetPath,
    this.icon,
    this.accentColor = const Color(0xFF000000),
  });

  final String id;
  final String title;
  final String? assetPath;
  final IconData? icon;
  final Color? accentColor;
}

class PaymentMethodController extends BaseController {
  PaymentMethodController(
    this._userApiService, [
    StorageService? storageService,
  ]) : _storageService = storageService ??
            (Get.isRegistered<StorageService>()
                ? Get.find<StorageService>()
                : null);

  final UserApiService _userApiService;
  final StorageService? _storageService;

  final methods = <PaymentMethodOption>[
    PaymentMethodOption(
      id: 'card',
      title: 'Credit /Debit Card',
      assetPath: AppImages.mastercard,
      accentColor: const Color(0xFFE64A19),
    ),
    PaymentMethodOption(
      id: 'google_pay',
      title: 'Google Pay',
      assetPath: AppImages.googlepayPng,
    ),
    PaymentMethodOption(
      id: 'apple_pay',
      title: 'Apple Pay',
      assetPath: AppImages.iphonepayPng,
    ),
/*    PaymentMethodOption(
      id: 'paypal',
      title: 'PayPal',
      assetPath: AppImages.paypal,
      accentColor: const Color(0xFF003087),
    ),*/
  ];

  final selectedMethodId = ''.obs;
  final isConfirming = false.obs;
  String selectedPlanId = '';
  String selectedPlanName = '';
  bool isFromSignup = false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      if (args['planId'] is String) {
        selectedPlanId = args['planId'] as String;
      }
      if (args['planName'] is String) {
        selectedPlanName = args['planName'] as String;
      }
      if (args['isFromSignup'] is bool) {
        isFromSignup = args['isFromSignup'] as bool;
      }
    }
  }

  void selectMethod(String methodId) {
    selectedMethodId.value = methodId;
  }

  Future<void> confirmPayment() async {
    if (selectedMethodId.value.isEmpty ||
        selectedPlanId.isEmpty ||
        isConfirming.value) {
      return;
    }

    isConfirming.value = true;
    await callDataService<ApiResponse<LoginResponseModel>>(
      _userApiService.buySubscription(
        subscriptionId: selectedPlanId,
        paymentMethod: selectedMethodId.value,
      ),
      showLoader: true,
      onSuccess: (response) async {
        if (response.success) {
          // Extract and save user data from LoginResponseModel
          if (response.data != null) {
            final loginData = response.data!;

            // Extract and save token if present
            final token = loginData.token;
            if (token != null && token.isNotEmpty) {
              await _storageService?.writeString('access_token', token);
            }

            // Extract user flags from user model
            final userFlags = _extractUserFlagsFromModel(loginData.user);

            // Save flags to storage
            final storage = _storageService;
            if (storage != null) {
              for (final entry in userFlags.entries) {
                await storage.writeBool(entry.key, entry.value);
              }
            }
          }

          // Navigate to processing payment screen, which will auto-navigate to verification after 5 seconds
          Get.offAllNamed(
            Routes.processingPayment,
            arguments: {
              'planId': selectedPlanId,
              'planTitle': selectedPlanName,
              'isFromSignup': isFromSignup,
            },
          );
        } else {
          showResponseDialog(
            message: response.errorMessage,
            title: 'Payment Failed',
            isError: true,
            showButton: true,
            onOkPressed: () {
              // Stay on payment page to retry
            },
          );
        }
      },
      onError: (error, stack) {
        final errorMsg = errorMessage.value.isNotEmpty
            ? errorMessage.value
            : 'Payment failed. Please try again.';
        showResponseDialog(
          message: errorMsg,
          title: 'Error',
          isError: true,
          showButton: true,
          onOkPressed: () {
            // Stay on payment page to retry
          },
        );
      },
      onComplete: () {
        isConfirming.value = false;
      },
    );
  }

  /// Extract user flags from UserModel
  Map<String, bool> _extractUserFlagsFromModel(UserModel? user) {
    final flags = <String, bool>{};

    if (user == null) {
      return flags;
    }

    // Extract all user flags from model with default value false
    flags['is_personal_details'] = user.isPersonalDetails ?? false;
    flags['is_term_condition'] = user.isTermCondition ?? false;
    flags['is_profile_created'] = user.isProfileCreated ?? false;
    flags['is_work_full'] = user.isWorkFull ?? false;
    flags['is_professional_services'] = user.isProfessionalServices ?? false;
    flags['is_qualification'] = user.isQualification ?? false;
    flags['is_personal_identification'] =
        user.isPersonalIdentification ?? false;
    flags['is_about_you'] = user.isAboutYou ?? false;
    flags['is_payment'] = user.isPayment ?? false;

    return flags;
  }
}
