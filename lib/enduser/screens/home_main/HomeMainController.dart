import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/screens/appointment/AppointmentBinding.dart';
import 'package:verithrive_dev/enduser/screens/appointment/AppointmentBookingScreen.dart';
import 'package:verithrive_dev/enduser/screens/fitness_goal/FitnessGoalBinding.dart';
import 'package:verithrive_dev/enduser/screens/fitness_goal/FitnessGoalScreen.dart';
import 'package:verithrive_dev/enduser/screens/nutrition_goal/NutritionGoalBinding.dart';
import 'package:verithrive_dev/enduser/screens/nutrition_goal/NutritionGoalScreen.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../BaseController.dart';
import '../../data/repository/project_repository.dart';
import '../../core/values/sharePrefrenceConst.dart';
import '../../utils/api_services.dart';
import 'models/ProfessionTypeModel.dart';
import 'package:verithrive_dev/services/storage_service.dart';

// Holds one category (type + ordered sub_types) exactly as returned by the API
class ProfessionCategory {
  final String id;
  final String type;
  final List<SubTypeModel> subTypes;

  ProfessionCategory({
    required this.id,
    required this.type,
    required this.subTypes,
  });
}

class HomeMainController extends BaseController with WidgetsBindingObserver {
  ProjectRepository? _repository;
  StorageService? _storageService;
  bool _hasFetchedPersonalDetails = false;
  RxBool isGuest = false.obs;

  ProjectRepository get repository {
    _repository ??= Get.find<ProjectRepository>(tag: (ProjectRepository).toString());
    return _repository!;
  }

  StorageService get storageService {
    _storageService ??= Get.find<StorageService>();
    return _storageService!;
  }

  // ── Fully dynamic: preserves the exact order returned by the API ──────────
  var professionCategories = <ProfessionCategory>[].obs;

  // Notification count variables
  var totalCount = 0.obs;
  var unreadCount = 0.obs;
  var readCount = 0.obs;

  @override
  void fetchData() async {
    print("API Called: Home Data Loaded");
    isLoading.value = true;
    fetchProfessionTypes();
    fetchNotificationCount();
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    if (!_hasFetchedPersonalDetails) {
      _hasFetchedPersonalDetails = true;
      fetchPersonalDetails();
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      fetchNotificationCount();
    }
  }

  // ── Personal Details ───────────────────────────────────────────────────────
  Future<void> fetchPersonalDetails() async {
    try {
      if (!Get.isRegistered<ProjectRepository>(tag: (ProjectRepository).toString())) return;

      bool isLoggedIn = storageService.readBool(SharePreferenceConst.isLogin) ?? false;
      isGuest.value = storageService.readBool(SharePreferenceConst.isGuest) ?? false;
      if (!isLoggedIn) return;

      var response = await repository.sendGetApiNoParamRequest(get_personal_details);

      Map<String, dynamic> responseData;
      if (response != null && response.data != null) {
        responseData = response.data is Map<String, dynamic>
            ? response.data
            : response.data as Map<String, dynamic>;
      } else if (response is Map<String, dynamic>) {
        responseData = response;
      } else {
        return;
      }

      bool success = responseData['success'] ?? false;
      if (success == true && responseData['data'] != null) {
        Map<String, dynamic> data = responseData['data'] as Map<String, dynamic>;
        if (data['is_notification'] != null) {
          bool isNotification = data['is_notification'] is bool
              ? data['is_notification'] as bool
              : data['is_notification'].toString().toLowerCase() == 'true';
          await storageService.writeBool(SharePreferenceConst.isNotification, isNotification);
        }
      }
    } catch (e) {
      print('Error fetching personal details in home: $e');
    }
  }

  // ── Profession Types (fully dynamic) ──────────────────────────────────────
  void fetchProfessionTypes() {
    if (!Get.isRegistered<ProjectRepository>(tag: (ProjectRepository).toString())) {
      isLoading.value = false;
      return;
    }

    isLoading.value = true;

    repository.sendGetApiNoParamRequest(profession_types_all).then((response) {
      _handleProfessionTypesSuccess(response);
    }).catchError((error) {
      print('Error fetching profession types: $error');
      isLoading.value = false;
    });
  }

  Future<void> _handleProfessionTypesSuccess(dynamic baseResponse) async {
    try {
      Map<String, dynamic> responseData;
      if (baseResponse != null && baseResponse.data != null) {
        responseData = baseResponse.data is Map<String, dynamic>
            ? baseResponse.data
            : baseResponse.data as Map<String, dynamic>;
      } else if (baseResponse is Map<String, dynamic>) {
        responseData = baseResponse;
      } else {
        isLoading.value = false;
        return;
      }

      bool success = responseData['success'] ?? false;

      if (success == true && responseData['data'] != null) {
        List<dynamic> dataList = responseData['data'] as List<dynamic>;

        // Parse into ProfessionCategory list preserving API order exactly
        final List<ProfessionCategory> categories = dataList.map((item) {
          final model = ProfessionTypeModel.fromJson(item as Map<String, dynamic>);
          return ProfessionCategory(
            id: model.id,
            type: model.type,
            subTypes: model.subTypes, // order from API
          );
        }).toList();

        professionCategories.value = categories;
      }

      isLoading.value = false;
    } catch (e) {
      print('Error parsing profession types: $e');
      isLoading.value = false;
    }
  }

  // ── Notification Count ─────────────────────────────────────────────────────
  Future<void> fetchNotificationCount() async {
    try {
      if (!Get.isRegistered<ProjectRepository>(tag: (ProjectRepository).toString())) return;

      bool isLoggedIn = storageService.readBool(SharePreferenceConst.isLogin) ?? false;
      if (!isLoggedIn) return;

      var response = await repository.sendGetApiNoParamRequest(notifications_count);

      Map<String, dynamic> responseData;
      if (response != null && response.data != null) {
        responseData = response.data is Map<String, dynamic>
            ? response.data
            : response.data as Map<String, dynamic>;
      } else if (response is Map<String, dynamic>) {
        responseData = response;
      } else {
        return;
      }

      bool success = responseData['success'] ?? false;
      if (success == true && responseData['data'] != null) {
        Map<String, dynamic> data = responseData['data'] as Map<String, dynamic>;
        totalCount.value = data['total_count'] ?? 0;
        unreadCount.value = data['unread_count'] ?? 0;
        readCount.value = data['readed_count'] ?? 0;
      }
    } catch (e) {
      print('Error fetching notification count: $e');
    }
  }

  // ── Card Tap ───────────────────────────────────────────────────────────────
  void onCardTap(String category, String label, String? subTypeId) {
    // Find the matching category from the dynamic list
    final matchedCategory = professionCategories.firstWhereOrNull(
          (c) => c.type.toLowerCase() == category.toLowerCase(),
    );

    List<Map<String, dynamic>> subTypesArray = matchedCategory?.subTypes.map((subType) => {
      'id': subType.id,
      'sub_type': subType.subType,
      'image': subType.image ?? '',
    }).toList() ?? [];

    final args = {
      'category': category,
      'label': label,
      'sub_type_id': subTypeId ?? '',
      'sub_types': subTypesArray,
      'type': category,
    };

    print('========================================');
    print('HOME MAIN CONTROLLER - PASSING ARGUMENTS');
    print('========================================');
    print('Category: $category | Label: $label | Sub Type ID: ${subTypeId ?? "null"}');
    print('Sub Types Count: ${subTypesArray.length}');
    print('========================================');

    final categoryLower = category.toLowerCase();
    if (categoryLower.contains('wellness')) {
      Get.to(() => AppointmentBookingScreen(), binding: AppointmentBinding(), arguments: args);
    } else if (categoryLower.contains('fitness')) {
      Get.to(() => const FitnessGoalScreen(), binding: FitnessGoalBinding(), arguments: args);
    } else if (categoryLower.contains('food') || categoryLower.contains('nutrition')) {
      Get.to(() => const NutritionGoalScreen(), binding: NutritionGoalBinding(), arguments: args);
    } else {
      Get.to(() => AppointmentBookingScreen(), binding: AppointmentBinding(), arguments: args);
    }
  }

  // ── Review Dialog ──────────────────────────────────────────────────────────
  void showReviewDialog(String professionalName, String professionalId, String bookingId) {
    final TextEditingController reviewController = TextEditingController();
    final RxInt rating = 0.obs;
    final RxBool isSubmitting = false.obs;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 24),
                      Expanded(
                        child: Text(
                          'Rate your recent session with\n"$professionalName"',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.popinMediumTextStyle(),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Icon(Icons.close, color: Colors.grey.shade600, size: 24),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Obx(() => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => rating.value = index + 1,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: SvgPicture.asset(
                            AppAssets.rating_selected,
                            color: index < rating.value
                                ? AppColors.ratingSelectedColor
                                : AppColors.unselectedTabColor,
                          ),
                        ),
                      );
                    }),
                  )),
                  SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: TextField(
                      controller: reviewController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Write a review',
                        hintStyle: AppTextStyles.popinRegularTextStyle(
                          fontSize: 14,
                          color: AppColors.color919191,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      style: AppTextStyles.regularTextStyle(fontSize: 14, color: AppColors.black),
                    ),
                  ),
                ],
              ),
            ),
            Obx(() => Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: isSubmitting.value ? Colors.grey : AppColors.primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isSubmitting.value
                      ? null
                      : () async {
                    if (rating.value == 0) {
                      Get.snackbar('Rating Required', 'Please select a rating before submitting',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.orange.shade100,
                          duration: Duration(seconds: 2));
                      return;
                    }
                    isSubmitting.value = true;
                    try {
                      await _submitReview(
                        professionalId: professionalId,
                        bookingId: bookingId,
                        rating: rating.value,
                        review: reviewController.text.trim(),
                      );
                      Get.back();
                      Get.snackbar('Review Submitted', 'Thank you for your feedback!',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                          duration: Duration(seconds: 2));
                    } catch (e) {
                      Get.snackbar('Error', 'Failed to submit review. Please try again.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red.shade100,
                          duration: Duration(seconds: 3));
                    } finally {
                      isSubmitting.value = false;
                    }
                  },
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: Center(
                    child: isSubmitting.value
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                        : Text('Add review', style: AppTextStyles.buttonTextStyle()),
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _submitReview({
    required String professionalId,
    required String bookingId,
    required int rating,
    required String review,
  }) async {
    final requestData = {
      "professional_id": professionalId,
      "booking_id": bookingId,
      "rating": rating,
      "review": review.isEmpty ? "" : review,
    };

    var response = await repository.sendPostApiRequest(() => requestData, professionals_rate_review, true);

    Map<String, dynamic> responseData;
    if (response != null && response.data != null) {
      responseData = response.data is Map<String, dynamic> ? response.data : response.data as Map<String, dynamic>;
    } else if (response is Map<String, dynamic>) {
      responseData = response;
    } else {
      throw Exception('Invalid response format');
    }

    bool success = responseData['success'] ?? false;
    if (!success) throw Exception(responseData['message'] ?? 'Failed to submit review');
  }
}