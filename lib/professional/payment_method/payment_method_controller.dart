import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/api_response.dart';
import '../../api/user_api_service.dart';
import '../../common/base_controller.dart';
import '../../models/login_response_model.dart';
import '../../routes/app_routes.dart';
import '../../services/storage_service.dart';
import '../../services/analytics_service.dart';
import '../../theme/image_paths.dart';
import '../../widgets/response_dialog.dart';
import '../home/home_controller.dart';
import '../payment_view/payment_webview_screen.dart';

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
  ];

  final selectedMethodId = ''.obs;
  final isConfirming = false.obs;
  String selectedPlanId = '';
  String selectedPlanName = '';
  double selectedPlanPrice = 0.0;
  String selectedStripePriceId = '';
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
      if (args['planPrice'] is num) {
        selectedPlanPrice = (args['planPrice'] as num).toDouble();
      }
      if (args['stripePriceId'] is String) {
        selectedStripePriceId = args['stripePriceId'] as String;
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
    // Get professional details from HomeController
    final homeController =
        Get.isRegistered<HomeController>() ? Get.find<HomeController>() : null;
    final profile = homeController?.profileDetails.value;
    final professionName = profile?.profession_name ?? '';
    final stripeAccountId = profile?.stripeConnectAccountId ?? '';

    // await AnalyticsService.instance.logPurchaseEvent(
    //   item: AnalyticsService.instance.buildItem(
    //     itemId: selectedPlanId.isNotEmpty ? selectedPlanId : '',
    //     itemName:
    //         selectedPlanName.isNotEmpty ? selectedPlanName : 'subscription',
    //     itemCategory:
    //         professionName.isNotEmpty ? professionName : 'subscription',
    //     itemVariant: selectedPlanName.toLowerCase(),
    //     itemBrand: 'subscription',
    //     price: selectedPlanPrice,
    //     quantity: 1,
    //   ),
    //   transactionId: selectedStripePriceId.isNotEmpty
    //       ? selectedStripePriceId
    //       : stripeAccountId.isNotEmpty
    //           ? stripeAccountId
    //           : selectedPlanId.isNotEmpty
    //               ? '${selectedPlanId}_${DateTime.now().millisecondsSinceEpoch}'
    //               : DateTime.now().millisecondsSinceEpoch.toString(),
    //   value: selectedPlanPrice,
    //   currency: 'GBP',
    // );

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
          final data = response.rawResponse?.data;
          if (data is Map<String, dynamic> && data['data'] != null) {
            final paymentData = data['data'] as Map<String, dynamic>;
            final checkoutUrl = paymentData['checkout_url']?.toString();

            if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
              // Open Stripe Checkout in WebView
              final result =
                  await Get.to(() => PaymentWebViewScreen(url: checkoutUrl));

              // When returning from WebView, check result and navigate if successful
              if (result == 'success') {
                await AnalyticsService.instance.logPurchaseEvent(
                  item: AnalyticsService.instance.buildItem(
                    itemId: selectedPlanId.isNotEmpty ? selectedPlanId : '',
                    itemName: selectedPlanName.isNotEmpty
                        ? selectedPlanName
                        : 'subscription',
                    itemCategory: professionName.isNotEmpty
                        ? professionName
                        : 'subscription',
                    itemVariant: selectedPlanName.toLowerCase(),
                    itemBrand: 'subscription',
                    price: selectedPlanPrice,
                    quantity: 1,
                  ),
                  transactionId: selectedStripePriceId.isNotEmpty
                      ? selectedStripePriceId
                      : stripeAccountId.isNotEmpty
                          ? stripeAccountId
                          : selectedPlanId.isNotEmpty
                              ? '${selectedPlanId}_${DateTime.now().millisecondsSinceEpoch}'
                              : DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString(),
                  value: selectedPlanPrice,
                  currency: 'GBP',
                );

                await _checkPaymentStatusAndNavigate(response.data?.user);
              } else if (result == 'failed') {
                showResponseDialog(
                  message: 'Payment failed. Please try again.',
                  title: 'Payment Failed',
                  isError: true,
                  showButton: true,
                  onOkPressed: () {},
                );
              }
            } else {
              await _handleLegacySuccess(response);
            }
          } else {
            await _handleLegacySuccess(response);
          }
        } else {
          showResponseDialog(
            message: response.errorMessage,
            title: 'Payment Failed',
            isError: true,
            showButton: true,
            onOkPressed: () {},
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
          onOkPressed: () {},
        );
      },
      onComplete: () {
        isConfirming.value = false;
        setSuccess(); // Explicitly set state to success (or idle) to hide loader
      },
    );
  }

  Future<void> _checkPaymentStatusAndNavigate(UserModel? user) async {
    // Extract user flags and ensure is_payment is true
    final userFlags = _extractUserFlagsFromModel(user);
    userFlags['is_payment'] = true;

    // Save flags to storage
    final storage = _storageService;
    if (storage != null) {
      for (final entry in userFlags.entries) {
        await storage.writeBool(entry.key, entry.value);
      }
    }

    // Navigate to processing payment screen
    Get.offAllNamed(
      Routes.processingPayment,
      arguments: {
        'planId': selectedPlanId,
        'planTitle': selectedPlanName,
        'isFromSignup': isFromSignup,
      },
    );
  }

  Future<void> _handleLegacySuccess(
      ApiResponse<LoginResponseModel> response) async {
    if (response.data != null) {
      final loginData = response.data!;
      final token = loginData.token;
      if (token != null && token.isNotEmpty) {
        await _storageService?.writeString('access_token', token);
      }
    }

    await _checkPaymentStatusAndNavigate(response.data?.user);
  }

  Map<String, bool> _extractUserFlagsFromModel(UserModel? user) {
    final flags = <String, bool>{};
    if (user == null) return flags;

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
