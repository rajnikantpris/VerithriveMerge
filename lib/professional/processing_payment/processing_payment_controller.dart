import 'dart:async';
import 'package:get/get.dart';

import '../../api/user_api_service.dart';
import '../../common/base_controller.dart';
import '../../models/profile_details_model.dart';
import '../../routes/app_routes.dart';
import '../../utils/logger.dart';
import 'package:geocoding/geocoding.dart';

class ProcessingPaymentController extends BaseController {
  Timer? _timer;
  final selectedPlanId = ''.obs;
  final selectedtitle = ''.obs;
  bool isFromSignup = false;

  /// Get UserApiService if available
  UserApiService? get _userApiService =>
      Get.isRegistered<UserApiService>() ? Get.find<UserApiService>() : null;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      if (args['planId'] is String) {
        selectedPlanId.value = args['planId'] as String;
      }
      if (args['planTitle'] is String) {
        selectedtitle.value = args['planTitle'] as String;
      }
      if (args['isFromSignup'] is bool) {
        isFromSignup = args['isFromSignup'] as bool;
      }
    }
    loadProfileDetails();
    _startTimer();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void _startTimer() {
    _timer = Timer(const Duration(seconds: 5), () {
      if (isFromSignup) {
        Get.offAllNamed(Routes.verification);
      } else {
        Get.offAllNamed(Routes.home);
      }
    });
  }

  /// Load user profile details
  ///
  /// Fetches user profile details from the API
  Future<void> loadProfileDetails() async {
    final apiService = _userApiService;
    if (apiService == null) {
      logError('UserApiService not available');
      return;
    }

    await callDataService(
      apiService.getProfileDetails(),
      showLoader: true,
      onSuccess: (response) async {
        if (response.success && response.data != null) {
          try {
            final data = response.data as Map<String, dynamic>?;
            if (data != null) {
              final profile = ProfileDetailsModel.fromJson(data);
              if (isFromSignup) {
                /*
                await AnalyticsService.instance.setUserProfile(
                  loginState: 'logged_in',
                  userId: profile.id,
                  city: await getCityFromAddress(profile.address.toString()),
                  persona: "professional_${profile.profession_name?.toLowerCase()}",
                  plan: _getTimePeriodFromPlan(selectedtitle.value),
                  registrationType: profile.userType ??
                      ((profile.isSocialLogin ?? false) ? 'social' : 'regular'),
                );
                */
              } else {
                /*
                await AnalyticsService.instance.setUserProfile(
                  plan: _getTimePeriodFromPlan(selectedtitle.value),
                );
                */
              }
            } else {
              logError('Profile data is null');
            }
          } catch (e, stackTrace) {
            logError('Error parsing profile details',
                error: e, stackTrace: stackTrace);
          }
        } else {
          logError('Failed to load profile details: ${response.message}');
        }
      },
      onError: (error, stack) {
        logError('Failed to load profile details',
            error: error, stackTrace: stack);
      },
    );
  }

  String _getTimePeriodFromPlan(String planTitle) {
    if (planTitle.toLowerCase().contains('monthly')) {
      return 'monthly';
    } else if (planTitle.toLowerCase().contains('quarterly')) {
      return 'quarterly';
    } else if (planTitle.toLowerCase().contains('yearly')) {
      return 'annually';
    }
    return planTitle.toLowerCase();
  }

  Future<String?> getCityFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        double lat = locations.first.latitude;
        double lng = locations.first.longitude;

        List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

        if (placemarks.isNotEmpty) {
          return placemarks.first.locality!.toLowerCase(); // return city
        }
      }
    } catch (e) {
      print("Error: $e");
    }

    return null;
  }
}
