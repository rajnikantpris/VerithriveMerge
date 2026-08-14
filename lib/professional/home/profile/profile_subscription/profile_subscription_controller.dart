import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';

import '../../../../api/api_response.dart';
import '../../../../api/user_api_service.dart';
import '../../../../common/base_controller.dart';
import '../../../../models/subscription_plan_model.dart';
import '../../../../routes/app_routes.dart';
import '../../../../services/analytics_service.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/fonts.dart';
import '../../../../theme/font_sizes.dart';
import '../../../../theme/hight_width_sizes.dart';
import '../../home_controller.dart';

class ProfileSubscriptionController extends BaseController {
  ProfileSubscriptionController(this._userApiService);

  final UserApiService _userApiService;
  final carouselController = CarouselSliderController();
  final currentPageIndex = 0.obs;
  final plans = <SubscriptionPlan>[].obs;
  final isInitialFetchDone = false.obs;
  final activeUntilDate = ''.obs;
  final isCancelled = false.obs;

  int get initialPage {
    final currentPlanIndex = plans.indexWhere((plan) => plan.isCurrentPlan);
    return currentPlanIndex >= 0 ? currentPlanIndex : 0;
  }

  /// Get the current active subscription plan
  SubscriptionPlan? get currentPlan =>
      plans.firstWhereOrNull((plan) => plan.isCurrentPlan);

  /// Get the weight of a plan for downgrade comparison
  /// Yearly (3) > Quarterly (2) > Monthly (1)
  int _getPlanWeight(SubscriptionPlan plan) {
    final cycle = plan.billingCycle.toLowerCase();
    final name = plan.name.toLowerCase();

    if (cycle.contains('year') || name.contains('year')) return 3;
    if (cycle.contains('quarter') || name.contains('quarter')) return 2;
    if (cycle.contains('month') || name.contains('month')) return 1;
    return 0; // Unknown
  }

  String? _currentSubscriptionPlanId;
  String? _currentSubscriptionPlanKey;
  String? _activeSubscriptionId;
  final Set<String> _upcomingSubscriptionPlanIds = <String>{};
  final Map<String, String> _upcomingPlanStartDateByPlanId = {};
  String? _selectedSubscriptionStatus;

  bool isPlanUpcoming(String? planId) {
    if (planId == null || planId.isEmpty) return false;
    return _upcomingSubscriptionPlanIds.contains(planId);
  }

  String upcomingPlanMessage(String? planId) {
    if (!isPlanUpcoming(planId)) return '';
    final startDate =
        planId == null ? null : _upcomingPlanStartDateByPlanId[planId];
    if (startDate != null && startDate.isNotEmpty) {
      return 'Next plan starts on $startDate';
    }
    return 'This plan will start in the next billing cycle';
  }

  @override
  void onInit() {
    super.onInit();
    AnalyticsService.instance.logScreenView(
      screenName: 'ProfessionalProfileSubscriptionScreen',
      screenClass: 'ProfileSubscriptionView',
      pageCategory: 'profile',
      elementLocation: 'view',
    );
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

  /// Parse subscription details to extract current plan ID and expiry date
  void _parseSubscriptionDetails(dynamic data) {
    try {
      String? planId;
      String? expiryDate;
      String? cancelDate;
      String? selectedStatus;

      if (data is Map<String, dynamic>) {
        Map<String, dynamic>? selectedSubscription;
        _upcomingSubscriptionPlanIds.clear();
        _upcomingPlanStartDateByPlanId.clear();

        // API may return a list of subscriptions; pick the best one.
        if (data['subscriptions'] is List) {
          final subscriptions = (data['subscriptions'] as List)
              .whereType<Map<String, dynamic>>()
              .toList();

          for (final subscription in subscriptions) {
            final status =
                (subscription['status'] as String? ?? '').toLowerCase().trim();
            if (status == 'upcoming' || status == 'pending') {
              final upcomingPlanId = subscription['subscription_id'] as String?;
              if (upcomingPlanId != null && upcomingPlanId.isNotEmpty) {
                _upcomingSubscriptionPlanIds.add(upcomingPlanId);
                final rawUpcomingStartDate =
                    subscription['start_date'] as String? ??
                        subscription['starts_at'] as String? ??
                        subscription['next_billing_date'] as String? ??
                        subscription['activation_date'] as String?;
                if (rawUpcomingStartDate != null &&
                    rawUpcomingStartDate.isNotEmpty) {
                  try {
                    final parsedDate = DateTime.parse(rawUpcomingStartDate);
                    _upcomingPlanStartDateByPlanId[upcomingPlanId] =
                        DateFormat('dd MMM yyyy').format(parsedDate);
                  } catch (_) {}
                }
              }
            }
          }
          selectedSubscription = _selectCurrentSubscription(subscriptions);
        }

        // Check for subscription object first
        if (selectedSubscription == null &&
            data['subscription'] is Map<String, dynamic>) {
          selectedSubscription = data['subscription'] as Map<String, dynamic>;
        }

        if (selectedSubscription != null) {
          // Get active subscription record ID (_id) for cancellation
          _activeSubscriptionId = selectedSubscription['_id'] as String?;
          // Get subscription_id for plan highlighting in UI
          planId = selectedSubscription['subscription_id'] as String?;
          // Get plan_key for proper plan matching
          _currentSubscriptionPlanKey =
              selectedSubscription['plan_key_snapshot'] as String?;
          selectedStatus = selectedSubscription['status'] as String?;

          expiryDate = selectedSubscription['expiry_date'] as String? ??
              selectedSubscription['end_date'] as String? ??
              selectedSubscription['expires_at'] as String?;

          cancelDate = selectedSubscription['cancel_date'] as String?;
        }

        // If not found, try plan object
        if (planId == null && data['plan'] is Map<String, dynamic>) {
          final planObj = data['plan'] as Map<String, dynamic>;
          planId = planObj['_id'] as String? ?? planObj['id'] as String?;

          if (_activeSubscriptionId == null) {
            _activeSubscriptionId = planId;
          }
        }

        // Fallback: try direct fields
        if (planId == null) {
          planId = data['plan_id'] as String? ??
              data['planId'] as String? ??
              data['subscription_plan_id'] as String? ??
              data['subscriptionPlanId'] as String?;

          if (_activeSubscriptionId == null) {
            _activeSubscriptionId = planId;
          }
        }

        if (expiryDate == null) {
          expiryDate = data['expiry_date'] as String? ??
              data['end_date'] as String? ??
              data['expires_at'] as String?;
        }

        if (cancelDate == null) {
          cancelDate = data['cancel_date'] as String?;
        }
      }

      _currentSubscriptionPlanId = planId;
      final normalizedStatus = selectedStatus?.toLowerCase().trim();
      _selectedSubscriptionStatus = normalizedStatus;
      if ((normalizedStatus == 'upcoming' || normalizedStatus == 'pending') &&
          planId != null &&
          planId.isNotEmpty) {
        _upcomingSubscriptionPlanIds.add(planId);
      }
      final isStatusCancelled =
          normalizedStatus == 'cancelled' || normalizedStatus == 'canceled';
      isCancelled.value =
          (cancelDate != null && cancelDate.isNotEmpty) || isStatusCancelled;

      if (expiryDate != null && expiryDate.isNotEmpty) {
        try {
          final date = DateTime.parse(expiryDate);
          activeUntilDate.value = DateFormat('dd MMM yyyy').format(date);
        } catch (e) {
          debugPrint('Error formatting expiry date: $e');
          activeUntilDate.value = '';
        }
      } else {
        activeUntilDate.value = '';
      }

      debugPrint('Active subscription ID (_id): $_activeSubscriptionId');
      debugPrint('Current plan ID: $_currentSubscriptionPlanId');
      debugPrint('Selected subscription status: $selectedStatus');
      debugPrint('Upcoming plan IDs: $_upcomingSubscriptionPlanIds');
      debugPrint('Upcoming plan dates: $_upcomingPlanStartDateByPlanId');
      debugPrint('Active until date: ${activeUntilDate.value}');
    } catch (e) {
      debugPrint('Error parsing subscription details: $e');
    }
  }

  /// Pick the most relevant subscription for current-state UI:
  /// active/trialing > upcoming/pending > latest record fallback.
  Map<String, dynamic>? _selectCurrentSubscription(
      List<Map<String, dynamic>> subscriptions) {
    if (subscriptions.isEmpty) return null;

    int score(Map<String, dynamic> sub) {
      final status = (sub['status'] as String? ?? '').toLowerCase().trim();
      switch (status) {
        case 'active':
        case 'trialing':
          return 3;
        case 'upcoming':
        case 'pending':
          return 2;
        case 'cancelled':
        case 'canceled':
        case 'expired':
          return 1;
        default:
          return 0;
      }
    }

    int compareDateDesc(Map<String, dynamic> a, Map<String, dynamic> b) {
      final aDateRaw =
          a['updatedAt'] ?? a['createdAt'] ?? a['start_date'] ?? a['end_date'];
      final bDateRaw =
          b['updatedAt'] ?? b['createdAt'] ?? b['start_date'] ?? b['end_date'];
      final aDate = DateTime.tryParse(aDateRaw?.toString() ?? '');
      final bDate = DateTime.tryParse(bDateRaw?.toString() ?? '');
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    }

    final sorted = [...subscriptions];
    sorted.sort((a, b) {
      final scoreCompare = score(b).compareTo(score(a));
      if (scoreCompare != 0) return scoreCompare;
      return compareDateDesc(a, b);
    });

    return sorted.first;
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
        // Mark active/trialing plan as current based on subscription details.
        final shouldMarkAsCurrentPlan =
            _selectedSubscriptionStatus == 'active' ||
                _selectedSubscriptionStatus == 'trialing';
        if (shouldMarkAsCurrentPlan && _currentSubscriptionPlanKey != null) {
          for (var plan in parsedPlans) {
            bool isMatch = false;

            // Primary match: exact plan_key comparison
            if (plan.planKey == _currentSubscriptionPlanKey) {
              isMatch = true;
            }
            // Fallback match: partial key matching (e.g., 'yearly' matches 'yearly_plan')
            else if (plan.planKey != null &&
                _currentSubscriptionPlanKey != null) {
              final planKeyLower = plan.planKey!.toLowerCase();
              final currentKeyLower =
                  _currentSubscriptionPlanKey!.toLowerCase();

              // Check if current key is contained in plan key or vice versa
              if (planKeyLower.contains(currentKeyLower) ||
                  currentKeyLower.contains(planKeyLower)) {
                isMatch = true;
              }
              // Check for common patterns
              else if ((planKeyLower.contains('year') &&
                      currentKeyLower.contains('year')) ||
                  (planKeyLower.contains('quarter') &&
                      currentKeyLower.contains('quarter')) ||
                  (planKeyLower.contains('month') &&
                      currentKeyLower.contains('month')) ||
                  (planKeyLower.contains('day') &&
                      currentKeyLower.contains('day'))) {
                isMatch = true;
              }
            }

            if (isMatch) {
              // Create a new plan with isCurrentPlan = true
              final index = parsedPlans.indexOf(plan);
              parsedPlans[index] = SubscriptionPlan(
                id: plan.id,
                planKey: plan.planKey,
                name: plan.name,
                price: plan.price,
                equivalentMonthlyPrice: plan.equivalentMonthlyPrice,
                highlightLabel: plan.highlightLabel,
                features: plan.features,
                billingCycle: plan.billingCycle,
                billingCycleCount: plan.billingCycleCount,
                isCurrentPlan: true,
                isFeatured: plan.isFeatured,
                description: plan.description,
                cutPriceLabel: plan.cutPriceLabel,
                perMonthLabel: plan.perMonthLabel,
                promoLabel: plan.promoLabel,
                stripePriceId: plan.stripePriceId,
                stripeProductId: plan.stripeProductId,
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
        _logViewItemForPlans(parsedPlans);

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

  void _logViewItemForPlans(List<SubscriptionPlan> parsedPlans) {
    if (parsedPlans.isEmpty) return;

    String? professionName;
    if (Get.isRegistered<HomeController>()) {
      professionName =
          Get.find<HomeController>().profileDetails.value?.profession_name;
    }
    final pageCategory =
        AnalyticsService.pageCategoryFromProfession(professionName);

    final analyticsItems = parsedPlans
        .map(
          (plan) => AnalyticsEventItem(
            itemId: (plan.stripeProductId != null &&
                    plan.stripeProductId!.isNotEmpty)
                ? plan.stripeProductId!
                : '',
            itemName: plan.name.isNotEmpty ? plan.name : 'subscription',
            itemCategory: pageCategory,
            itemCategory2: plan.billingCycle,
            itemVariant: plan.billingCycle.isNotEmpty
                ? plan.billingCycle
                : plan.name.toLowerCase(),
            itemBrand: 'verithrive',
            price: AnalyticsService.validatePrice(plan.price),
            quantity: 1,
          ),
        )
        .toList();

    AnalyticsService.instance.logViewItemEvent(
      items: analyticsItems,
      screenName: 'ProfileSubscriptionView',
      screenClass: 'ProfileSubscriptionView',
      pageCategory: pageCategory,
    );
  }

  /// Navigate to payment method screen to buy subscription
  void onBuyNow(SubscriptionPlan plan) {
    if (plan.id == null || plan.id!.isEmpty) {
      debugPrint('Plan ID is missing');
      return;
    }

    // Do not allow buying a plan that is already marked as upcoming.
    if (isPlanUpcoming(plan.id)) {
      debugPrint('Plan is already upcoming');
      return;
    }

    // Check for downgrade restriction
    final current = currentPlan;
    if (current != null) {
      final currentWeight = _getPlanWeight(current);
      final newWeight = _getPlanWeight(plan);

      // If user is trying to buy a plan with a lower weight (Monthly < Quarterly < Yearly)
      if (currentWeight > newWeight) {
        showDowngradeRestrictionDialog(
            currentPlanName: current.name, newPlanName: plan.name);
        return;
      }

      // Check if user is trying to buy the same plan
      if (plan.id == current.id) {
        // User already has this plan active
        debugPrint('Plan is already active');
        return;
      }
    }

    String? professionName;
    if (Get.isRegistered<HomeController>()) {
      professionName =
          Get.find<HomeController>().profileDetails.value?.profession_name;
    }
    final pageCategory =
        AnalyticsService.pageCategoryFromProfession(professionName);

    AnalyticsService.instance.logSelectItemEvent(
      item: AnalyticsEventItem(
        itemId: (plan.stripeProductId != null &&
                plan.stripeProductId!.isNotEmpty)
            ? plan.stripeProductId!
            : '',
        itemName: plan.name.isNotEmpty ? plan.name : 'subscription',
        itemCategory: pageCategory,
        itemVariant: plan.billingCycle.isNotEmpty
            ? plan.billingCycle
            : plan.name.toLowerCase(),
        itemBrand: 'verithrive',
        price: AnalyticsService.validatePrice(plan.price),
        quantity: 1,
      ),
      currency: 'GBP',
      screenName: 'ProfileSubscriptionView',
      screenClass: 'ProfileSubscriptionView',
      pageCategory: pageCategory,
    );

    // Navigate to payment method screen with plan ID, name, price, and stripe price ID
    Get.toNamed(
      Routes.paymentMethod,
      arguments: {
        'planId': plan.id!,
        'planName': plan.name,
        'planPrice': plan.price,
        'stripePriceId': plan.stripePriceId,
        'stripeProductId': plan.stripeProductId,
        'isFromSignup': false,
      },
    );
  }

  /// Show a dialog informing the user they cannot downgrade to a lower plan until their current plan expires
  void showDowngradeRestrictionDialog(
      {required String currentPlanName, required String newPlanName}) {
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
                    'Plan Restriction',
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
                    'You are currently on a $currentPlanName. You cannot downgrade to a $newPlanName until your current plan expires.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.rubikRegular,
                      fontWeight: FontWeight.w400,
                      fontSize: FontSizes.setFontValue_14,
                      color: AppColor.color_2D2D2D,
                    ),
                  ),
                  SizedBox(height: HightWidthSizes.setValue_24),

                  // OK button
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
                        'OK',
                        style: TextStyle(
                          fontFamily: AppFonts.rubikMedium,
                          fontWeight: FontWeight.w500,
                          fontSize: FontSizes.setFontValue_16,
                          color: AppColor.white,
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
                        cancelSubscription();
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

  /// Cancel subscription API call
  Future<void> cancelSubscription() async {
    if (_activeSubscriptionId == null || _activeSubscriptionId!.isEmpty) {
      showStatusDialog(
        title: 'Error',
        message: 'No active subscription found to cancel.',
        isError: true,
      );
      return;
    }

    await callDataService<ApiResponse<dynamic>>(
      _userApiService.cancelSubscription(
        subscriptionId: _activeSubscriptionId!,
      ),
      showLoader: true,
      onSuccess: (response) {
        if (response.success) {
          showStatusDialog(
            title: 'Success',
            message: response.message ?? 'Subscription cancelled successfully.',
            isError: false,
          );
          // Refresh plans and details
          fetchSubscriptionPlans();
        } else {
          showStatusDialog(
            title: 'Error',
            message: response.errorMessage,
            isError: true,
          );
        }
      },
      onError: (error, stack) {
        showStatusDialog(
          title: 'Error',
          message: 'Failed to cancel subscription. Please try again.',
          isError: true,
        );
      },
    );
  }

  /// Show a success or error dialog
  void showStatusDialog({
    required String title,
    required String message,
    required bool isError,
  }) {
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
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.rubikMedium,
                      fontWeight: FontWeight.w500,
                      fontSize: FontSizes.setFontValue_20,
                      color: isError
                          ? AppColor.color_E64646
                          : AppColor.color_2FC4B2,
                    ),
                  ),
                  SizedBox(height: HightWidthSizes.setValue_16),

                  // Body text
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.rubikRegular,
                      fontWeight: FontWeight.w400,
                      fontSize: FontSizes.setFontValue_14,
                      color: AppColor.color_2D2D2D,
                    ),
                  ),
                  SizedBox(height: HightWidthSizes.setValue_24),

                  // OK button
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
                        'OK',
                        style: TextStyle(
                          fontFamily: AppFonts.rubikMedium,
                          fontWeight: FontWeight.w500,
                          fontSize: FontSizes.setFontValue_16,
                          color: AppColor.white,
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
