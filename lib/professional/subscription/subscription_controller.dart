import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/api_response.dart';
import '../../api/user_api_service.dart';
import '../../common/base_controller.dart';
import '../../routes/app_routes.dart';
import '../../theme/image_paths.dart';

class PlanOption {
  PlanOption({
    required this.id,
    required this.title,
    required this.priceLabel,
    this.perMonthLabel,
    this.assetPath,
    required this.accentColor,
  });

  final String id;
  final String title;
  final String priceLabel;
  final String? perMonthLabel;
  final String? assetPath;
  final Color accentColor;
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
      final highlightLabel = item['highlight_label']?.toString() ?? '';
      final billingCycle = item['billing_cycle']?.toString() ?? '';

      if (id.isEmpty || planName.isEmpty) return null;

      // Use highlight_label as the main price label (e.g., "£565/year", "£159/quarter", "£59/month")
      final priceLabel = highlightLabel.isNotEmpty ? highlightLabel : '';

      // Determine plan type
      final planNameLower = planName.toLowerCase();
      final billingCycleLower = billingCycle.toLowerCase();

      final isYearly =
          planNameLower.contains('year') || billingCycleLower.contains('yearly') || billingCycleLower.contains('year');
      final isQuarterly = planNameLower.contains('quarter') ||
          (billingCycleLower.contains('quarterly') && !isYearly);
      final isMonthly = planNameLower.contains('month') ||
          (billingCycleLower.contains('monthly') && !isYearly && !isQuarterly);

      // Determine perMonthLabel (e.g., "£47/month", "£53/month")
      String? perMonthLabel;
      if (!isMonthly) {
        final priceAmount = double.tryParse(item['price_amount']?.toString() ?? '');
        if (priceAmount != null) {
          int months = isYearly ? 12 : (isQuarterly ? 3 : 1);
          if (months > 1) {
            final monthlyPrice = (priceAmount / months).round();
            // Default to GBP if not specified or different
            final currency = item['currency_code']?.toString() == 'GBP' ? '£' : '£';
            perMonthLabel = '$currency$monthlyPrice/month';
          }
        }
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
        perMonthLabel: perMonthLabel,
        assetPath: assetPath,
        accentColor: accentColor,
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
        priceLabel: '£59/month',
        perMonthLabel: null,
        assetPath: AppImages.monthly,
        accentColor: const Color(0xFF2FC4B2),
      ),
      PlanOption(
        id: 'quarterly',
        title: 'Quarterly plan',
        priceLabel: '£159/quarter',
        perMonthLabel: '£53/month',
        assetPath: AppImages.quarterly,
        accentColor: const Color(0xFFFF9100),
      ),
      PlanOption(
        id: 'yearly',
        title: 'Yearly plan',
        priceLabel: '£565/year',
        perMonthLabel: '£47/month',
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

    Get.toNamed(
      Routes.paymentMethod,
      arguments: {
        'planId': selectedPlanId.value,
        'planName': selectedPlan.title,
        'isFromSignup': true,
      },
    );
  }
}
