import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/api_response.dart';
import '../../api/user_api_service.dart';
import '../../common/base_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/analytics_service.dart';
import '../../theme/image_paths.dart';
import '../home/home_controller.dart';
import '../signup_profile_wizard/signup_profile_wizard_controller.dart';

class PlanOption {
  PlanOption({
    required this.id,
    required this.title,
    required this.priceLabel,
    this.cutPriceLabel,
    this.perMonthLabel,
    this.promoLabel,
    this.assetPath,
    required this.accentColor,
    this.stripeProductId,
  });

  final String id;
  final String title;
  final String priceLabel;
  final String? cutPriceLabel;
  final String? perMonthLabel;
  final String? promoLabel;
  final String? assetPath;
  final Color accentColor;
  final String? stripeProductId;
}

class SubscriptionController extends BaseController {
  SubscriptionController(this._userApiService);

  final UserApiService _userApiService;

  final plans = <PlanOption>[].obs;
  final selectedPlanId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadSubscriptions();
  }

  /// Load subscriptions from API
  Future<void> loadSubscriptions() async {
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.getSubscriptionsList(),
      showLoader: true,
      onSuccess: (response) {
        if (response.success && response.data != null) {
          _parseSubscriptions(response.data);
        }
      },
    );
  }

  /// Parse subscriptions from API response
  void _parseSubscriptions(dynamic data) {
    try {
      final List<PlanOption> parsedPlans = [];

      // Handle API response structure: {success: true, data: {plans: [...]}}
      // Based on logs, 'data' passed here is the Map containing 'plans'
      List<dynamic>? subscriptionsList;
      if (data is Map<String, dynamic>) {
        if (data['plans'] is List) {
          subscriptionsList = data['plans'] as List;
        } else if (data['data'] is List) {
          subscriptionsList = data['data'] as List;
        } else if (data['items'] is List) {
          subscriptionsList = data['items'] as List;
        }
      } else if (data is List) {
        subscriptionsList = data;
      }

      if (subscriptionsList != null && subscriptionsList.isNotEmpty) {
        for (final item in subscriptionsList) {
          if (item is Map<String, dynamic>) {
            final plan = _mapToPlanOption(item);
            if (plan != null) {
              parsedPlans.add(plan);
            }
          }
        }
      }

      // If no plans from API, use fallback hardcoded plans
      if (parsedPlans.isEmpty) {
        // plans.value = _getDefaultPlans();
      } else {
        plans.value = parsedPlans;
      }

      // Auto-select first plan by default if nothing selected
      if (selectedPlanId.value.isEmpty && plans.isNotEmpty) {
        selectedPlanId.value = plans.first.id;
      }
    } catch (e) {
      // On error, use fallback plans
      // plans.value = _getDefaultPlans();
      if (selectedPlanId.value.isEmpty && plans.isNotEmpty) {
        selectedPlanId.value = plans.first.id;
      }
    }
  }

  /// Map API response item to PlanOption
  PlanOption? _mapToPlanOption(Map<String, dynamic> item) {
    try {
      final id = item['_id']?.toString() ?? item['id']?.toString() ?? '';
      final planName = item['plan_name']?.toString() ?? '';
      final billingCycle = item['billing_cycle']?.toString() ?? '';
      final currency = item['currency_code']?.toString() == 'GBP' ? '£' : '£';

      if (id.isEmpty || planName.isEmpty) return null;

      // New pricing logic based on user request:
      // Main Price: price_amount/billing_cycle
      // Cut Price: equivalent_monthly_price/billing_cycle
      final priceAmount = item['price_amount'];
      final equivalentPrice = item['equivalent_monthly_price'];

      final priceLabel = '$currency$priceAmount/$billingCycle';
      String? cutPriceLabel;
      if (equivalentPrice != null && equivalentPrice != priceAmount) {
        cutPriceLabel = '$currency$equivalentPrice/$billingCycle';
      }

      // Determine plan type
      final planNameLower = planName.toLowerCase();
      final billingCycleLower = billingCycle.toLowerCase();

      final isYearly = planNameLower.contains('year') ||
          billingCycleLower.contains('yearly') ||
          billingCycleLower.contains('year');
      final isQuarterly = planNameLower.contains('quarter') ||
          (billingCycleLower.contains('quarterly') && !isYearly);
      final isMonthly = planNameLower.contains('month') ||
          (billingCycleLower.contains('monthly') && !isYearly && !isQuarterly);

      // Determine perMonthLabel (e.g., "£41/month", "£45/month")
      String? perMonthLabel;
      String? promoLabel;

      final billingCycleCount =
          int.tryParse(item['billing_cycle_count']?.toString() ?? '1') ?? 1;
      int months;
      if (billingCycleLower == 'monthly') {
        months = billingCycleCount;
      } else if (billingCycleLower == 'quarterly') {
        months = billingCycleCount * 3;
      } else if (billingCycleLower == 'yearly') {
        months = billingCycleCount * 12;
      } else {
        // Fallback to previous logic if billing_cycle is something else
        months = isYearly ? 12 : (isQuarterly ? 3 : 1);
      }

      if (months > 1) {
        final amount = double.tryParse(priceAmount?.toString() ?? '');
        if (amount != null) {
          final monthlyPrice = (amount / months).round();
          perMonthLabel = '$currency$monthlyPrice/month';
        }
      }

      if (isYearly) {
        promoLabel = 'or one month free!';
      }

      // Determine accent color based on plan type
      Color accentColor;
      if (isMonthly) {
        accentColor = const Color(0xFF2FC4B2);
      } else if (isQuarterly) {
        accentColor = const Color(0xFFFF9100);
      } else {
        accentColor = const Color(0xFFA2A2A2);
      }

      // Determine asset path based on plan type
      String? assetPath;
      if (isYearly) {
        assetPath = AppImages.yearly;
      } else if (isQuarterly) {
        assetPath = AppImages.quarterly;
      } else if (isMonthly) {
        assetPath = AppImages.monthly;
      }

      return PlanOption(
        id: id,
        title: planName,
        priceLabel: priceLabel,
        cutPriceLabel: cutPriceLabel,
        perMonthLabel: perMonthLabel,
        promoLabel: promoLabel,
        assetPath: assetPath,
        accentColor: accentColor,
        stripeProductId: item['stripe_product_id']?.toString(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get default hardcoded plans as fallback
  List<PlanOption> _getDefaultPlans() {
    return [
      PlanOption(
        id: 'monthly',
        title: 'Monthly plan',
        priceLabel: '£49/monthly',
        cutPriceLabel: '£59/monthly',
        perMonthLabel: null,
        assetPath: AppImages.monthly,
        accentColor: const Color(0xFF2FC4B2),
      ),
      PlanOption(
        id: 'quarterly',
        title: 'Quarterly plan',
        priceLabel: '£137/quarterly',
        cutPriceLabel: '£159/quarterly',
        perMonthLabel: '£45/month',
        assetPath: AppImages.quarterly,
        accentColor: const Color(0xFFFF9100),
      ),
      PlanOption(
        id: 'yearly',
        title: 'Yearly plan',
        priceLabel: '£539/monthly',
        cutPriceLabel: '£565/monthly',
        perMonthLabel: '£44/month',
        assetPath: AppImages.yearly,
        accentColor: const Color(0xFFA2A2A2),
      ),
    ];
  }

  void selectPlan(String planId) {
    selectedPlanId.value = planId;
  }

  void continueToPayment() {
    if (selectedPlanId.value.isEmpty) return;

    final selectedPlan = plans.firstWhere(
      (plan) => plan.id == selectedPlanId.value,
      orElse: () => PlanOption(
        id: '',
        title: '',
        priceLabel: '',
        accentColor: Colors.transparent,
      ),
    );

    String? professionName;
    if (Get.isRegistered<HomeController>()) {
      professionName =
          Get.find<HomeController>().profileDetails.value?.profession_name;
    }
    if ((professionName == null || professionName.isEmpty) &&
        Get.isRegistered<SignupProfileWizardController>()) {
      professionName = Get.find<SignupProfileWizardController>()
          .selectedProfessionType
          .value;
    }
    final pageCategory =
        AnalyticsService.pageCategoryFromProfession(professionName);

    // Analytics: Log professional subscription plan selected / begin_checkout
    AnalyticsService.instance.logBeginCheckoutEvent(
      item: AnalyticsService.instance.buildItem(
        itemId: (selectedPlan.stripeProductId != null &&
                selectedPlan.stripeProductId!.isNotEmpty)
            ? selectedPlan.stripeProductId!
            : '',
        itemName:
            selectedPlan.title.isNotEmpty ? selectedPlan.title : 'subscription',
        itemCategory: 'professional',
        itemVariant: selectedPlan.title.toLowerCase(),
        itemBrand: 'verithrive',
        price: 0.0,
        quantity: 1,
      ),
      value: 0.0,
      currency: 'GBP',
      screenName: 'SubscriptionView',
      screenClass: 'SubscriptionView',
      pageCategory: pageCategory,
    );

    Get.toNamed(
      Routes.paymentMethod,
      arguments: {
        'planId': selectedPlanId.value,
        'planName': selectedPlan.title,
        'stripeProductId': selectedPlan.stripeProductId,
        'isFromSignup': true,
      },
    );
  }
}
