import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/routes/app_routes.dart';
import 'package:verithrive_dev/enduser/screens/therapy_list/TherapistListingScreen.dart';
import 'package:verithrive_dev/enduser/screens/therapy_list/TherapyBinding.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_text_styles.dart';

import '../../network/exceptions/not_found_exception.dart';
import '../../utils/app_colors.dart';
import '../../core/widget/animated_loader.dart';
import '../../core/base/base_controller.dart';
import '../../data/repository/project_repository.dart';
import '../../utils/api_services.dart';
import 'package:verithrive_dev/services/analytics_service.dart';

class FitnessGoalController extends BaseController {
  ProjectRepository? _repository; // Changed to nullable
  
  ProjectRepository get repository { // Lazy getter
    _repository ??= Get.find<ProjectRepository>(tag: (ProjectRepository).toString());
    return _repository!;
  }
  
  final RxSet<String> selectedGoals = <String>{}.obs;
  final RxBool onTrainerStep = false.obs;
  final RxString selectedPreference = ''.obs;
  String? category;
  String? subTypeId;
  String? label;
  List<Map<String, dynamic>>? subTypesArray;
  String? type;
  
  // API Data
  var services = <ServiceModel>[].obs;
  var isLoadingServices = false.obs;
  var expandedServiceIds = <String>{}.obs;
  var selectedSubServiceIds = <String>{}.obs;
  var selectedServiceIds = <String>{}.obs; // Track parent service IDs
  var apiMessage = ''.obs; // API message for display

  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments;
    if (arguments != null && arguments is Map<String, dynamic>) {
      category = arguments['category'] as String?;
      subTypeId = arguments['sub_type_id'] as String?;
      label = arguments['label'] as String?;
      type = arguments['type'] as String?;
      
      // Get sub_types array
      if (arguments['sub_types'] != null) {
        subTypesArray = List<Map<String, dynamic>>.from(
          arguments['sub_types'] as List,
        );
      }
      
      // Call API to fetch services
      if (subTypeId != null && subTypeId!.isNotEmpty) {
        fetchServices();
      }
    }
  }
  
  // Fetch services from API
  void fetchServices() {
    isLoadingServices.value = true;
    apiMessage.value = ''; // Clear previous message
    
    Map<String, dynamic> toJson() {
      final Map<String, dynamic> data = <String, dynamic>{};
      data['profession_sub_type_id'] = subTypeId;
      return data;
    }
    
    // Remove leading slash if present
    String apiEndpoint = get_services_all.startsWith('/') 
        ? get_services_all.substring(1) 
        : get_services_all;
    var service = repository.sendGetApiWithParamRequest(toJson, apiEndpoint, false);
    callDataService(
      service,
      onSuccess: _handleServicesSuccess,
      onError: _handleServicesError,
      isShowLoading: false,
    );
  }
  
  Future<void> _handleServicesSuccess(dynamic baseResponse) async {
    try {
      Map<String, dynamic> responseData;
      if (baseResponse != null && baseResponse.data != null) {
        responseData = baseResponse.data is Map<String, dynamic>
            ? baseResponse.data
            : baseResponse.data as Map<String, dynamic>;
      } else if (baseResponse is Map<String, dynamic>) {
        responseData = baseResponse;
      } else {
        throw Exception('Invalid response format');
      }

      bool success = responseData['success'] ?? false;
      String message = responseData['message'] ?? '';
      
      if (success == true && responseData['data'] != null) {
        List<dynamic> servicesList = responseData['data'] as List<dynamic>;
        if (servicesList.isNotEmpty) {
          services.value = servicesList.map((json) {
            return ServiceModel.fromJson(json as Map<String, dynamic>);
          }).toList();
          apiMessage.value = ''; // Clear message if data is loaded
          
          print('========================================');
          print('Services loaded: ${services.length}');
          print('========================================');
        } else {
          // No services in the data array
          services.value = [];
          apiMessage.value = message.isNotEmpty ? message : 'No services available';
        }
      } else {
        // API returned success=false or no data
        services.value = [];
        apiMessage.value = message.isNotEmpty ? message : 'No services available';
        print('Services API returned success=false or no data');
      }
      
      isLoadingServices.value = false;
    } catch (e) {
      print('Error parsing services response: $e');
      print('Response: $baseResponse');
      isLoadingServices.value = false;
    }
  }
  


  void _handleServicesError(dynamic e) {
    print('Availability API Error: $e');

    if (e is NotFoundException) {
      services.value = [];
      isLoadingServices.value = false;
      apiMessage.value = e.message.toString();
    }
  }


  // Toggle service expansion
  void toggleServiceExpansion(String serviceId) {
    if (expandedServiceIds.contains(serviceId)) {
      expandedServiceIds.remove(serviceId);
    } else {
      expandedServiceIds.add(serviceId);
    }
  }
  
  // Toggle sub-service selection
  void toggleSubServiceSelection(String subServiceId, String serviceId) {
    if (selectedSubServiceIds.contains(subServiceId)) {
      selectedSubServiceIds.remove(subServiceId);
      // Check if any other sub-services from this service are selected
      bool hasOtherSubServices = services.any((service) {
        if (service.id == serviceId) {
          return service.subServices.any((sub) => 
            sub.id != subServiceId && selectedSubServiceIds.contains(sub.id));
        }
        return false;
      });
      // If no other sub-services from this service are selected, remove service ID
      if (!hasOtherSubServices) {
        selectedServiceIds.remove(serviceId);
      }
    } else {
      selectedSubServiceIds.add(subServiceId);
      // Add parent service ID if not already added
      selectedServiceIds.add(serviceId);
      
      // Log analytics when goal is selected
      String subServiceName = '';
      for (var service in services) {
        for (var subService in service.subServices) {
          if (subService.id == subServiceId) {
            subServiceName = subService.subServiceName;
            break;
          }
        }
        if (subServiceName.isNotEmpty) break;
      }
      
      if (subServiceName.isNotEmpty) {
        AnalyticsService.instance.logEvent(
          name: 'select_goal_tap',
          parameters: {
            'screen_name': 'FitnessGoalScreen',
            'screen_class': 'FitnessGoalScreen',
            'element_text': subServiceName,
            'element_location': 'option_tap',
            'page_category': 'fitness',
          },
        );
      }
    }
  }
  
  // Toggle parent service selection (for services with no children)
  void toggleServiceSelection(String serviceId) {
    if (selectedServiceIds.contains(serviceId)) {
      selectedServiceIds.remove(serviceId);
    } else {
      selectedServiceIds.add(serviceId);
    }
  }
  
  // Check if service has no children
  bool serviceHasNoChildren(String serviceId) {
    ServiceModel? service = services.firstWhereOrNull((s) => s.id == serviceId);
    return service?.subServices.isEmpty ?? true;
  }
  
  // Check if service is selected (for services with no children)
  bool isServiceSelected(String serviceId) {
    return selectedServiceIds.contains(serviceId);
  }
  
  // Check if sub-service is selected
  bool isSubServiceSelected(String subServiceId) {
    return selectedSubServiceIds.contains(subServiceId);
  }
  
  // Check if service is expanded
  bool isServiceExpanded(String serviceId) {
    return expandedServiceIds.contains(serviceId);
  }
  
  // Get button text based on state
  String getButtonText() {
    if (onTrainerStep.value) {
      return selectedPreference.value.isNotEmpty ? 'Done' : 'Skip';
    } else {
      bool hasSelections = selectedSubServiceIds.isNotEmpty || 
                           services.any((service) => service.subServices.isEmpty && selectedServiceIds.contains(service.id));
      return hasSelections ? 'Next' : 'Skip';
    }
  }

  final List<String> preferences = const [
    'Male only',
    'Female only',
    'No preference',
  ];

  void onSkip() {
    if (onTrainerStep.value) {
      // On trainer step, skip means proceed without preference
      onSubmit();
    } else {
      // On goals step, check if any selections exist
      bool hasSelections = selectedSubServiceIds.isNotEmpty || 
                           services.any((service) => service.subServices.isEmpty && selectedServiceIds.contains(service.id));
      if (hasSelections) {
        // If selections exist, go to trainer step
        goToTrainerStep();
      } else {
        // If no selections, proceed to trainer step (same as original logic)
        goToTrainerStep();
      }
    }
  }
  
  void onNext() {
    if (onTrainerStep.value) {
      // On trainer step, next means submit
      onSubmit();
    } else {
      // On goals step, next means go to trainer step
      goToTrainerStep();
    }
  }

  void goToTrainerStep() {
    onTrainerStep.value = true;
  }

  void selectPreference(String pref) {
    if (selectedPreference.value == pref) {
      // Deselect if already selected
      selectedPreference.value = '';
    } else {
      selectedPreference.value = pref;
    }
  }
  
  bool isPreferenceSelected(String pref) {
    return selectedPreference.value == pref;
  }

  void onBackFromTrainer() {
    onTrainerStep.value = false;
  }

  void onSubmit() {
    final Map<String, dynamic> result = <String, dynamic>{
      'category': category ?? 'fitness',
    };
    
    // Pass service IDs if any are selected
    if (selectedServiceIds.isNotEmpty) {
      List<String> serviceIdList = selectedServiceIds.toList();
      result['service_id'] = serviceIdList;
    }
    
    // Pass sub-service IDs if any are selected
    if (selectedSubServiceIds.isNotEmpty) {
      List<String> subServiceIdList = selectedSubServiceIds.toList();
      result['sub_service_id'] = subServiceIdList;
    }
    
    // Pass trainer preference and convert to gender
    if (selectedPreference.value.isNotEmpty) {
      result['trainerPreference'] = selectedPreference.value;
      
      // Convert trainer preference to gender for API
      if (selectedPreference.value == 'Male only') {
        result['gender'] = 'male';
      } else if (selectedPreference.value == 'Female only') {
        result['gender'] = 'female';
      }
      // "No preference" - don't pass gender key
    }
    
    if (subTypeId != null && subTypeId!.isNotEmpty) {
      result['sub_type_id'] = subTypeId!;
    }
    
    if (label != null) {
      result['label'] = label!;
    }
    
    // Pass type and sub_types array
    if (type != null) {
      result['type'] = type!;
    }
    
    if (subTypesArray != null && subTypesArray!.isNotEmpty) {
      result['sub_types'] = subTypesArray!;
    }
    
    // Log what we're passing
    print('========================================');
    print('FITNESS GOAL CONTROLLER - PASSING ARGUMENTS');
    print('========================================');
    print('Category: ${result['category']}');
    print('Type: ${result['type'] ?? "null"}');
    print('Sub Type ID: ${result['sub_type_id'] ?? "null"}');
    print('Label: ${result['label'] ?? "null"}');
    print('Sub Types Array: ${result['sub_types'] ?? "null"}');
    print('Sub Types Count: ${subTypesArray != null ? subTypesArray!.length : 0}');
    print('Service IDs: ${result['service_id'] ?? "null"}');
    print('Sub Service IDs: ${result['sub_service_id'] ?? "null"}');
    print('Trainer Preference: ${result['trainerPreference'] ?? "null"}');
    print('Gender: ${result['gender'] ?? "null (no preference)"}');
    print('========================================');
    print('Navigating to therapy_list...');
    print('========================================');
    
    _showLoadingAndNavigate(result);
  }

  Future<void> _showLoadingAndNavigate(Map<String, dynamic> result) async {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: Container(
          color: AppColors.white,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedLoader(
                  assetPath: AppAssets.loader1,
                  width: 60,
                  height: 60,
                  duration: const Duration(seconds: 2),
                ),
                 SizedBox(height: 16),
                 Text(
                  'Lining up the pros for you...',
                  style:  AppTextStyles.regularTextStyle(
                    fontSize: 16,
                    color: AppColors.color454545
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
    await Future.delayed(const Duration(seconds: 2));
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
    Get.off(
      () => TherapistListingScreen(),
      binding: TherapyBinding(),
      arguments: result,
    );
  }
}

// Models for API response
class ServiceModel {
  final String id;
  final String subTypeId;
  final String serviceName;
  final bool isActive;
  final bool isDeleted;
  final List<SubServiceModel> subServices;

  ServiceModel({
    required this.id,
    required this.subTypeId,
    required this.serviceName,
    required this.isActive,
    required this.isDeleted,
    required this.subServices,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['_id']?.toString() ?? '',
      subTypeId: json['sub_type_id']?.toString() ?? '',
      serviceName: json['service_name']?.toString() ?? '',
      isActive: json['is_active'] as bool? ?? true,
      isDeleted: json['is_deleted'] as bool? ?? false,
      subServices: (json['sub_services'] as List<dynamic>?)
              ?.map((e) => SubServiceModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SubServiceModel {
  final String id;
  final String subServiceName;
  final String createdAt;

  SubServiceModel({
    required this.id,
    required this.subServiceName,
    required this.createdAt,
  });

  factory SubServiceModel.fromJson(Map<String, dynamic> json) {
    return SubServiceModel(
      id: json['_id']?.toString() ?? '',
      subServiceName: json['sub_service_name']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
