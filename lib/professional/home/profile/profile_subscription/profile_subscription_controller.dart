import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../../../../api/api_response.dart';
import '../../../../api/user_api_service.dart';
import '../../../../common/base_controller.dart';
import '../../../../models/subscription_plan_model.dart';
import '../../../../routes/app_routes.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/fonts.dart';
import '../../../../theme/font_sizes.dart';
import '../../../../theme/hight_width_sizes.dart';

class ProfileSubscriptionController extends BaseController {
  ProfileSubscriptionController(this._userApiService);

  final UserApiService _userApiService;
  final carouselController = CarouselSliderController();
  final currentPageIndex = 0.obs;
  final plans = <SubscriptionPlan>[].obs;
  final isInitialFetchDone = false.obs;

  int get initialPage {
    final currentPlanIndex = plans.indexWhere((plan) => plan.isCurrentPlan);
    return currentPlanIndex >= 0 ? currentPlanIndex : 0;
  }

  String? _currentSubscriptionPlanId;

  @override
  void onInit() {
    super.onInit();
    fetchSubscriptionPlans();
  }

  /// Fetch subscription plans from API
  Future<void> fetchSubscriptionPlans() async {
    // First fetch subscription details to get current plan
    await fetchSubscriptionDetails();

    // Then fetch all plans
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.getSubscriptionsList(),
      showLoader: true,
      onSuccess: (response) {
        if (response.success && response.data != null) {
          _parseSubscriptionPlans(response.data);
        } else {
          setError(response.errorMessage);
        }
      },
      onError: (error, stack) {
        final errorMsg = errorMessage.value.isNotEmpty
            ? errorMessage.value
            : 'Failed to load subscription plans. Please try again.';
        setError(errorMsg);
      },
      onComplete: () {
        isInitialFetchDone.value = true;
        resetState();
      },
    );
  }

  /// Fetch subscription details to determine current plan
  Future<void> fetchSubscriptionDetails() async {
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.getSubscriptionDetails(),
      showLoader: true, // Don't show loader for details, plans will show it
      onSuccess: (response) {
        if (response.success && response.data != null) {
          _parseSubscriptionDetails(response.data);
        }
      },
      onError: (error, stack) {
        // Silently fail - user might not have a subscription
        debugPrint('Could not fetch subscription details: $error');
      },
    );
  }

  /// Parse subscription details to extract current plan ID
  void _parseSubscriptionDetails(dynamic data) {
    try {
      String? planId;

      if (data is Map<String, dynamic>) {
        // Check for subscription object first
        if (data['subscription'] is Map<String, dynamic>) {
          final subscription = data['subscription'] as Map<String, dynamic>;
          // Get subscription_id from subscription object
          planId = subscription['subscription_id'] as String?;
        }

        // If not found, try plan object
        if (planId == null && data['plan'] is Map<String, dynamic>) {
          final planObj = data['plan'] as Map<String, dynamic>;
          planId = planObj['_id'] as String? ?? planObj['id'] as String?;
        }

        // Fallback: try direct fields
        if (planId == null) {
          planId = data['plan_id'] as String? ??
              data['planId'] as String? ??
              data['subscription_plan_id'] as String? ??
              data['subscriptionPlanId'] as String?;
        }
      }

      _currentSubscriptionPlanId = planId;
      debugPrint('Current subscription plan ID: $_currentSubscriptionPlanId');
    } catch (e) {
      debugPrint('Error parsing subscription details: $e');
    }
  }

  /// Parse subscription plans from API response
  void _parseSubscriptionPlans(dynamic data) {
    try {
      List<SubscriptionPlan> parsedPlans = [];

      // Handle different response structures
      if (data is List) {
        // Direct list response
        parsedPlans = data
            .map((item) =>
                SubscriptionPlan.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (data is Map<String, dynamic>) {
        // Check if data contains a list field
        if (data['plans'] is List) {
          parsedPlans = (data['plans'] as List)
              .map((item) =>
                  SubscriptionPlan.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (data['subscriptions'] is List) {
          parsedPlans = (data['subscriptions'] as List)
              .map((item) =>
                  SubscriptionPlan.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (data['data'] is List) {
          parsedPlans = (data['data'] as List)
              .map((item) =>
                  SubscriptionPlan.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }

      if (parsedPlans.isNotEmpty) {
        // Mark current plan based on subscription details
        if (_currentSubscriptionPlanId != null) {
          for (var plan in parsedPlans) {
            if (plan.id == _currentSubscriptionPlanId) {
              // Create a new plan with isCurrentPlan = true
              final index = parsedPlans.indexOf(plan);
              parsedPlans[index] = SubscriptionPlan(
                id: plan.id,
                name: plan.name,
                price: plan.price,
                equivalentMonthlyPrice: plan.equivalentMonthlyPrice,
                highlightLabel: plan.highlightLabel,
                features: plan.features,
                billingCycle: plan.billingCycle,
                isCurrentPlan: true,
                isFeatured: plan.isFeatured,
                description: plan.description,
              );
              break;
            }
          }
        }

        plans.value = parsedPlans;
        // Find the index of the current plan and initialize with it
        final currentPlanIndex =
            parsedPlans.indexWhere((plan) => plan.isCurrentPlan);
        final initialPageIndex = currentPlanIndex >= 0 ? currentPlanIndex : 0;
        currentPageIndex.value = initialPageIndex;

        // Navigate to initial page after a short delay to ensure carousel is built
        Future.delayed(const Duration(milliseconds: 100), () {
          try {
            carouselController.animateToPage(initialPageIndex);
          } catch (e) {
            // Carousel might not be ready yet, ignore
            debugPrint('Could not navigate to initial page: $e');
          }
        });
      } else {
        // Fallback to empty list or show error
        plans.value = [];
        setError('No subscription plans available');
      }
    } catch (e) {
      debugPrint('Error parsing subscription plans: $e');
      setError('Failed to parse subscription plans');
    }
  }

  void onPageChanged(int index) {
    currentPageIndex.value = index;
  }

  /// Navigate to payment method screen to buy subscription
  void onBuyNow(SubscriptionPlan plan) {
    if (plan.id == null || plan.id!.isEmpty) {
      debugPrint('Plan ID is missing');
      return;
    }

    // Navigate to payment method screen with plan ID and name
    Get.toNamed(
      Routes.paymentMethod,
      arguments: {
        'planId': plan.id!,
        'planName': plan.name ?? '',
        'isFromSignup': false,
      },
    );
  }

  void onCancelSubscription() {
    // Show confirmation dialog
    showCancelSubscriptionDialog();
  }

  void showCancelSubscriptionDialog() {
    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: HightWidthSizes.setValue_16,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius:
                    BorderRadius.circular(HightWidthSizes.setValue_10),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: HightWidthSizes.setValue_10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.all(HightWidthSizes.setValue_24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Title
                  Text(
                    'Cancel subscription?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.rubikMedium,
                      fontWeight: FontWeight.w500,
                      fontSize: FontSizes.setFontValue_20,
                      color: AppColor.color_2D3648,
                    ),
                  ),
                  SizedBox(height: HightWidthSizes.setValue_16),

                  // Body text
                  Text(
                    'Are you sure you want to cancel your subscription? You\'ll lose access to premium features.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.rubikRegular,
                      fontWeight: FontWeight.w400,
                      fontSize: FontSizes.setFontValue_14,
                      color: AppColor.color_2D2D2D,
                    ),
                  ),
                  SizedBox(height: HightWidthSizes.setValue_24),

                  // No, go back button (Primary)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.color_2FC4B2,
                        foregroundColor: AppColor.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          vertical: HightWidthSizes.setValue_14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            HightWidthSizes.setValue_10,
                          ),
                        ),
                      ),
                      child: Text(
                        'No, go back',
                        style: TextStyle(
                          fontFamily: AppFonts.rubikMedium,
                          fontWeight: FontWeight.w500,
                          fontSize: FontSizes.setFontValue_16,
                          color: AppColor.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: HightWidthSizes.setValue_12),

                  // Yes, cancel button (Destructive)
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Handle cancellation logic here
                        debugPrint('Subscription cancelled');
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: HightWidthSizes.setValue_14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            HightWidthSizes.setValue_10,
                          ),
                        ),
                      ),
                      child: Text(
                        'Yes, cancel',
                        style: TextStyle(
                          fontFamily: AppFonts.rubikRegular,
                          fontWeight: FontWeight.w400,
                          fontSize: FontSizes.setFontValue_16,
                          color: AppColor.color_B53232,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
