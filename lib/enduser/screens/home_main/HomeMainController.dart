import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/routes/app_routes.dart';
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
  
  // Profession types from API
  var wellnessTypes = <SubTypeModel>[].obs;
  var fitnessTypes = <SubTypeModel>[].obs;
  var foodNutritionTypes = <SubTypeModel>[].obs;

  // Notification count variables
  var totalCount = 0.obs;
  var unreadCount = 0.obs;
  var readCount = 0.obs;

  @override
  void fetchData() async {
    print("API Called: Home Data Loaded");
    // Set loading to true when starting to fetch data
    isLoading.value = true;
    // Fetch profession types (this will handle setting isLoading to false when done)
    fetchProfessionTypes();
    // Fetch notification count
    fetchNotificationCount();
  }

  @override
  void onInit() {
    super.onInit();
    // Register app lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    // Fetch personal details only once when app opens
    if (!_hasFetchedPersonalDetails) {
      _hasFetchedPersonalDetails = true;
      fetchPersonalDetails();
    }
/*    Future.delayed(Duration(seconds: 1),() {
      showReviewDialog("Test Professional");
    },);*/
  }

  @override
  void onClose() {
    // Unregister app lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('App lifecycle state changed: $state');
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground from background
        print('App resumed from background - refreshing notification count');
        fetchNotificationCount();
        break;
      case AppLifecycleState.paused:
        // App went to background
        print('App went to background');
        break;
      case AppLifecycleState.detached:
        // App is about to be terminated
        print('App is being terminated');
        break;
      case AppLifecycleState.inactive:
        // App is inactive
        print('App is inactive');
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        print('App is hidden');
        break;
    }
  }

  // Fetch personal details from API
  Future<void> fetchPersonalDetails() async {
    try {
      // Ensure repository is available
      if (!Get.isRegistered<ProjectRepository>(tag: (ProjectRepository).toString())) {
        return; // Repository not available yet
      }
      
      // Check if user is logged in
      bool isLoggedIn =
          storageService.readBool(SharePreferenceConst.isLogin) ?? false;
      isGuest.value =
          storageService.readBool(SharePreferenceConst.isGuest) ?? false;
      if (!isLoggedIn) {
        return; // Don't call API if user is not logged in
      }

      var service = repository.sendGetApiNoParamRequest(get_personal_details);
      
      var response = await service;
      
      // Parse the response
      Map<String, dynamic> responseData;
      if (response != null && response.data != null) {
        responseData = response.data is Map<String, dynamic> 
            ? response.data 
            : response.data as Map<String, dynamic>;
      } else if (response is Map<String, dynamic>) {
        responseData = response;
      } else {
        return; // Invalid response format, skip
      }

      bool success = responseData['success'] ?? false;
      
      if (success == true && responseData['data'] != null) {
        Map<String, dynamic> data = responseData['data'] as Map<String, dynamic>;
        
        // Save is_notification to shared preferences
        if (data['is_notification'] != null) {
          bool isNotification = data['is_notification'] is bool 
              ? data['is_notification'] as bool
              : data['is_notification'].toString().toLowerCase() == 'true';
          await storageService
              .writeBool(SharePreferenceConst.isNotification, isNotification);
        }
      }
    } catch (e) {
      // Silently handle errors - don't block app functionality
      print('Error fetching personal details in home: $e');
    }
  }

  // Fetch profession types from API
  void fetchProfessionTypes() {
    // Ensure repository is available
    if (!Get.isRegistered<ProjectRepository>(tag: (ProjectRepository).toString())) {
      isLoading.value = false; // Set loading to false if repository not available
      return; // Repository not available yet
    }
    
    // Set loading to true when starting to fetch
    isLoading.value = true;
    
    // This API might not require authentication, but let's check the repository method
    // If it requires auth, we'll need to use sendGetApiNoParamRequest with isToken parameter
    var service = repository.sendGetApiNoParamRequest(profession_types_all);
    
    service.then((response) {
      _handleProfessionTypesSuccess(response);
    }).catchError((error) {
      print('Error fetching profession types: $error');
      isLoading.value = false; // Set loading to false on error
      // Keep default empty lists on error
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
        isLoading.value = false; // Set loading to false on invalid response
        return; // Invalid response format
      }

      bool success = responseData['success'] ?? false;
      
      if (success == true && responseData['data'] != null) {
        List<dynamic> dataList = responseData['data'] as List<dynamic>;
        
        // Clear existing lists
        wellnessTypes.clear();
        fitnessTypes.clear();
        foodNutritionTypes.clear();
        
        // Parse and categorize profession types
        for (var item in dataList) {
          ProfessionTypeModel professionType = ProfessionTypeModel.fromJson(item as Map<String, dynamic>);
          
          String type = professionType.type.toLowerCase();
          if (type.contains('wellness')) {
            wellnessTypes.value = professionType.subTypes;
          } else if (type.contains('fitness')) {
            fitnessTypes.value = professionType.subTypes;
          } else if (type.contains('food') || type.contains('nutrition')) {
            foodNutritionTypes.value = professionType.subTypes;
          }
        }
      }
      
      // Set loading to false after processing response
      isLoading.value = false;
    } catch (e) {
      print('Error parsing profession types: $e');
      isLoading.value = false; // Set loading to false on error
    }
  }

  // Fetch notification count from API
  Future<void> fetchNotificationCount() async {
    try {
      // Ensure repository is available
      if (!Get.isRegistered<ProjectRepository>(tag: (ProjectRepository).toString())) {
        return; // Repository not available yet
      }
      
      // Check if user is logged in
      bool isLoggedIn =
          storageService.readBool(SharePreferenceConst.isLogin) ?? false;
      if (!isLoggedIn) {
        return; // Don't call API if user is not logged in
      }

      var service = repository.sendGetApiNoParamRequest(notifications_count);
      
      var response = await service;
      
      // Parse the response
      Map<String, dynamic> responseData;
      if (response != null && response.data != null) {
        responseData = response.data is Map<String, dynamic> 
            ? response.data 
            : response.data as Map<String, dynamic>;
      } else if (response is Map<String, dynamic>) {
        responseData = response;
      } else {
        return; // Invalid response format, skip
      }

      bool success = responseData['success'] ?? false;
      
      if (success == true && responseData['data'] != null) {
        Map<String, dynamic> data = responseData['data'] as Map<String, dynamic>;
        
        // Update notification counts
        totalCount.value = data['total_count'] ?? 0;
        unreadCount.value = data['unread_count'] ?? 0;
        readCount.value = data['readed_count'] ?? 0;
        
        print('Notification counts updated: Total=${totalCount.value}, Unread=${unreadCount.value}, Read=${readCount.value}');
      }
    } catch (e) {
      // Silently handle errors - don't block app functionality
      print('Error fetching notification count: $e');
    }
  }

  void onCardTap(String category, String label, String? subTypeId) {
    // Get the full sub_types array for the selected category
    List<Map<String, dynamic>> subTypesArray = [];
    
    String categoryLower = category.toLowerCase();
    if (categoryLower.contains('wellness')) {
      subTypesArray = wellnessTypes.map((subType) => {
        'id': subType.id,
        'sub_type': subType.subType,
        'image': subType.image,
      }).toList();
    } else if (categoryLower.contains('fitness')) {
      subTypesArray = fitnessTypes.map((subType) => {
        'id': subType.id,
        'sub_type': subType.subType,
        'image': subType.image,
      }).toList();
    } else if (categoryLower.contains('food') || categoryLower.contains('nutrition')) {
      subTypesArray = foodNutritionTypes.map((subType) => {
        'id': subType.id,
        'sub_type': subType.subType,
        'image': subType.image,
      }).toList();
    }
    
    final args = {
      'category': category, 
      'label': label,
      'sub_type_id': subTypeId ?? '',
      'sub_types': subTypesArray, // Pass full array
      'type': category, // Pass the type name (Fitness, Wellness, Food & Nutrition)
    };
    
    // Log what we're passing
    print('========================================');
    print('HOME MAIN CONTROLLER - PASSING ARGUMENTS');
    print('========================================');
    print('Category: $category');
    print('Label: $label');
    print('Sub Type ID: ${subTypeId ?? "null"}');
    print('Type: $category');
    print('Sub Types Array: $subTypesArray');
    print('Sub Types Count: ${subTypesArray.length}');
    print('========================================');
    
    switch (category.toLowerCase()) {
      case 'wellness':
        print('Navigating to: Appointment Screen');
        Get.to(
          () => AppointmentBookingScreen(),
          binding: AppointmentBinding(),
          arguments: args,
        );
        break;
      case 'fitness':
        print('Navigating to: Fitness Goal Screen');
        Get.to(
          () => const FitnessGoalScreen(),
          binding: FitnessGoalBinding(),
          arguments: args,
        );
        break;
      case 'food_nutrition':
      case 'food & nutrition':
        print('Navigating to: Nutrition Goal Screen');
        Get.to(
          () => const NutritionGoalScreen(),
          binding: NutritionGoalBinding(),
          arguments: args,
        );
        break;
      default:
        print('Navigating to: Appointment Screen (default)');
        Get.to(
          () => AppointmentBookingScreen(),
          binding: AppointmentBinding(),
          arguments: args,
        );
    }
    print('========================================');
  }


  void showReviewDialog(String professionalName, String professionalId, String bookingId) {
    final TextEditingController reviewController = TextEditingController();
    final RxInt rating = 0.obs;
    final RxBool isSubmitting = false.obs;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main content container
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
                        child: Icon(
                          Icons.close,
                          color: Colors.grey.shade600,
                          size: 24,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Star Rating
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

                  // Review Text Field
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: reviewController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Write a review',
                        hintStyle: AppTextStyles.popinRegularTextStyle(
                          fontSize: 14,
                          color: AppColors.color919191
                          ,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                        counterStyle: AppTextStyles.regularTextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      style: AppTextStyles.regularTextStyle(
                        fontSize: 14,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Submit Button - Attached at bottom
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
                  onTap: isSubmitting.value ? null : () async {
                    if (rating.value == 0) {
                      Get.snackbar(
                        'Rating Required',
                        'Please select a rating before submitting',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.orange.shade100,
                        duration: Duration(seconds: 2),
                      );
                      return;
                    }

                    // Submit review with API call
                    isSubmitting.value = true;
                    
                    try {
                      await _submitReview(
                        professionalId: professionalId,
                        bookingId: bookingId,
                        rating: rating.value,
                        review: reviewController.text.trim(),
                      );
                      
                      Get.back(); // Close dialog
                      Get.snackbar(
                        'Review Submitted',
                        'Thank you for your feedback!',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.primaryColor.withOpacity(0.2),
                        duration: Duration(seconds: 2),
                      );
                    } catch (e) {
                      Get.snackbar(
                        'Error',
                        'Failed to submit review. Please try again.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red.shade100,
                        duration: Duration(seconds: 3),
                      );
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
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Add review',
                            style: AppTextStyles.buttonTextStyle(),
                          ),
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
    print("Submitting review: professionalId=$professionalId, bookingId=$bookingId, rating=$rating, review=$review");
    
    final requestData = {
      "professional_id": professionalId,
      "booking_id": bookingId,
      "rating": rating,
      "review": review.isEmpty ? "" : review,
    };

    var service = repository.sendPostApiRequest(() => requestData, professionals_rate_review, true);
    
    var response = await service;
    
    // Parse the response
    Map<String, dynamic> responseData;
    if (response != null && response.data != null) {
      responseData = response.data is Map<String, dynamic> 
          ? response.data 
          : response.data as Map<String, dynamic>;
    } else if (response is Map<String, dynamic>) {
      responseData = response;
    } else {
      throw Exception('Invalid response format');
    }

    bool success = responseData['success'] ?? false;
    
    if (!success) {
      String message = responseData['message'] ?? 'Failed to submit review';
      throw Exception(message);
    }
    
    print("Review submitted successfully: ${responseData['message']}");
  }
}
