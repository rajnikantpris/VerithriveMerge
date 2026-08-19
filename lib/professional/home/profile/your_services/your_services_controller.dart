import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../api/api_response.dart';
import '../../../../api/user_api_service.dart';
import '../../../../common/base_controller.dart';
import '../../../../models/profile_details_model.dart';
import '../../../../models/service_model.dart';
import '../../../../widgets/response_dialog.dart';
import '../../../../services/analytics_service.dart';

class YourServicesController extends BaseController {
  final UserApiService _userApiService;

  static const int _visibleThreshold = 10;

  // Services data
  final RxList<ServiceModel> services = <ServiceModel>[].obs;
  final selectedServices = <String>{}
      .obs; // Stores selected service names or sub-service names (for UI)
  final selectedServiceIds = <String>{}.obs; // Stores selected service IDs
  final selectedSubServiceIds = <String, List<String>>{}
      .obs; // Maps service_id to list of sub_service_ids
  final expandedServices = <String>{}.obs; // Tracks which services are expanded
  final isLoadingServices = false.obs;
  final hasLoadedServices =
      false.obs; // Track if services API has been called and completed
  final hasUserMadeManualSelection =
      false.obs; // Track if user has manually selected services
  final hasLoadedOldServices =
      false.obs; // Track if old services have been loaded from API

  // Profile data
  final professionTypeId = Rxn<String>();
  final professionSubTypeId = Rxn<String>();

  YourServicesController(this._userApiService);

  @override
  void onInit() {
    super.onInit();
    AnalyticsService.instance.logScreenView(
      screenName: 'ProfessionalYourServicesScreen',
      screenClass: 'YourServicesView',
      pageCategory: 'profile',
      elementLocation: 'view',
    );
    // Reset flags to allow loading old services if user hasn't made manual selections
    hasLoadedOldServices.value = false;
    hasUserMadeManualSelection.value = false;
    _loadProfileAndServices();
  }

  /// Load profile details and services in parallel where possible
  Future<void> _loadProfileAndServices() async {
    // Show a single loader for the entire process
    showLoading();
    isLoadingServices.value = true;
    hasLoadedServices.value = false;

    try {
      // Start loading profile details and already selected services in parallel
      // They don't depend on each other.
      await Future.wait([
        _loadProfileDetails(),
        _loadProfessionServices(),
      ]);

      // If we have professionSubTypeId, load all available services
      if (professionSubTypeId.value != null &&
          professionSubTypeId.value!.isNotEmpty) {
        await _loadServices();
        _initializeVisibleCounts();
      }
    } catch (e) {
      debugPrint('Error in _loadProfileAndServices: $e');
    } finally {
      isLoadingServices.value = false;
      hasLoadedServices.value = true;
      resetState(); // Dismiss the single loader
      debugPrint('Initial data loading completed. Services: ${services.length}');
    }
  }

  /// Load profile details from API to get profession_sub_type_id
  Future<void> _loadProfileDetails() async {
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.getCreateProfileDetails(),
      showLoader: false, // Managed by _loadProfileAndServices
      onSuccess: (response) {
        if (response.success && response.data != null) {
          try {
            final data = response.data as Map<String, dynamic>?;
            if (data != null) {
              final profileDetails = ProfileDetailsModel.fromJson(data);
              professionTypeId.value = profileDetails.professionTypeId;
              professionSubTypeId.value = profileDetails.professionSubTypeId;
              debugPrint(
                  'Loaded profession_sub_type_id: ${professionSubTypeId.value}');
            }
          } catch (e) {
            debugPrint('Error parsing profile details: $e');
          }
        }
      },
    );
  }

  /// Load services from API based on profession_sub_type_id
  Future<void> _loadServices() async {
    final professionSubTypeIdValue = professionSubTypeId.value;
    if (professionSubTypeIdValue == null || professionSubTypeIdValue.isEmpty) {
      debugPrint('No profession_sub_type_id available to load services');
      return;
    }

    debugPrint(
        'Loading services with profession_sub_type_id: $professionSubTypeIdValue');

    await callDataService<ApiResponse<dynamic>>(
      _userApiService.getAllServices(
        professionSubTypeId: professionSubTypeIdValue,
      ),
      showLoader: false, // Managed by _loadProfileAndServices
      onSuccess: (response) {
        // Handle "no services available" as a valid empty list, not an error
        if (!response.success) {
          final errorMsg = response.errorMessage.toLowerCase();
          if (errorMsg.contains('no services available') ||
              errorMsg.contains('there are no services')) {
            // Clear services list and treat as valid empty response
            services.clear();
            debugPrint('No services available for this profession sub-type');
            return;
          }
          // For other errors, log but don't show error dialog
          debugPrint('Error loading services: ${response.errorMessage}');
          return;
        }

        if (response.data != null) {
          // Extract services from response
          List<dynamic>? list;
          if (response.data is List) {
            list = response.data as List;
          } else if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            if (data['data'] is List) {
              list = data['data'] as List;
            }
          }

          if (list != null) {
            final serviceList = <ServiceModel>[];
            for (final item in list) {
              try {
                if (item is Map<String, dynamic>) {
                  final service = ServiceModel.fromJson(item);
                  if (service.serviceName != null &&
                      service.serviceName!.isNotEmpty) {
                    serviceList.add(service);
                  }
                }
              } catch (e) {
                debugPrint('Error parsing service: $e');
                continue;
              }
            }
            services.clear();
            services.addAll(serviceList);
          }
        } else {
          // No data in response, clear services list
          services.clear();
        }
      },
    );
  }

  /// Load profession services (selected services) from API
  Future<void> _loadProfessionServices() async {
    debugPrint('_loadProfessionServices called');
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.getProfessionServices(),
      showLoader: false, // Managed by _loadProfileAndServices
      onSuccess: (response) {
        debugPrint('Profession services API response received');
        if (response.success && response.data != null) {
          try {
            final data = response.data as Map<String, dynamic>?;
            if (data != null) {
              // Parse services array from response
              List<dynamic>? servicesList;
              if (data['services'] is List) {
                servicesList = data['services'] as List;
              } else if (data['data'] is Map<String, dynamic>) {
                final nestedData = data['data'] as Map<String, dynamic>;
                if (nestedData['services'] is List) {
                  servicesList = nestedData['services'] as List;
                }
              }

              if (servicesList != null && servicesList.isNotEmpty) {
                // Only load old services if user hasn't made any manual selections yet
                if (!hasUserMadeManualSelection.value) {
                  debugPrint(
                      'Clearing existing selections before loading old services');
                  // Clear existing selections only when loading old services
                  selectedServices.clear();
                  selectedServiceIds.clear();
                  selectedSubServiceIds.clear();
                  for (final serviceItem in servicesList) {
                    if (serviceItem is Map<String, dynamic>) {
                      final serviceId = serviceItem['_id']?.toString();
                      final serviceName =
                          serviceItem['service_name']?.toString();
                      final subServicesList =
                          serviceItem['sub_services'] as List?;

                      if (serviceId != null && serviceId.isNotEmpty) {
                        // Check if this service has sub-services
                        if (subServicesList != null &&
                            subServicesList.isNotEmpty) {
                          // Service has sub-services selected
                          final existingSubServiceIds =
                              selectedSubServiceIds[serviceId] ?? <String>[];
                          final subServiceIdList =
                              existingSubServiceIds.toSet().toList();

                          for (final subServiceItem in subServicesList) {
                            if (subServiceItem is Map<String, dynamic>) {
                              final subServiceId =
                                  subServiceItem['_id']?.toString();
                              final subServiceName =
                                  subServiceItem['sub_service_name']
                                      ?.toString();

                              if (subServiceId != null &&
                                  subServiceId.isNotEmpty) {
                                if (!subServiceIdList.contains(subServiceId)) {
                                  subServiceIdList.add(subServiceId);
                                }
                                if (subServiceName != null &&
                                    subServiceName.isNotEmpty) {
                                  selectedServices.add(subServiceName);
                                }
                              }
                            }
                          }

                          if (subServiceIdList.isNotEmpty) {
                            selectedSubServiceIds[serviceId] = subServiceIdList;
                          }
                        } else {
                          // Service without sub-services (simple service)
                          selectedServiceIds.add(serviceId);
                          if (serviceName != null && serviceName.isNotEmpty) {
                            selectedServices.add(serviceName);
                          }
                        }
                      }
                    }
                  }
                  // Mark that old services have been loaded
                  hasLoadedOldServices.value = true;
                  debugPrint(
                      'Selected services count: ${selectedServices.length}');
                  selectedServices.refresh();
                  selectedServiceIds.refresh();
                  selectedSubServiceIds.refresh();
                  debugPrint('UI refreshed with selected services');
                } else {
                  debugPrint(
                      'Skipping loading old services - user has made manual selections');
                }
              } else {
                debugPrint('No services found in profession services response');
              }
            } else {
              debugPrint('Profession services data is null');
            }
          } catch (e) {
            debugPrint('Error parsing profession services: $e');
          }
        } else {
          debugPrint('Profession services API response was not successful');
        }
      },
      onError: (error, stackTrace) {
        debugPrint('Error loading profession services: $error');
      },
    );
  }
  
  // Show more/show less functionality
  final showMoreServices = <String, bool>{}.obs; // Tracks which services have "show more" clicked
  final visibleServicesCount = <String, int>{}.obs; // Tracks visible count for each service

  /// Initialize visible counts for all services (limit to 10 initially)
  void _initializeVisibleCounts() {
    visibleServicesCount.clear();
    
    // For services without sub-services, limit to 10 initially
    final servicesWithoutSubServices = services.where((service) => 
        service.subServices == null || service.subServices!.isEmpty).toList();
    
    for (int i = 0; i < servicesWithoutSubServices.length; i++) {
      final service = servicesWithoutSubServices[i];
      final serviceId = service.id ?? '';
      
      // Show only first 10 services initially
      if (i < _visibleThreshold) {
        visibleServicesCount[serviceId] = 1; // Show this service
      } else {
        visibleServicesCount[serviceId] = 0; // Hide this service initially
      }
    }
    
    // For services with sub-services, show all sub-services initially
    for (final service in services) {
      final serviceId = service.id ?? '';
      if (service.subServices != null && service.subServices!.isNotEmpty) {
        visibleServicesCount[serviceId] = service.subServices!.length;
      }
    }
    visibleServicesCount.refresh();
  }

  /// Toggle show more/less for services list
  void toggleShowMore() {
    final servicesWithoutSubServices = services.where((service) => 
        service.subServices == null || service.subServices!.isEmpty).toList();
    
    // Check if currently showing more than threshold
    final visibleCount = servicesWithoutSubServices.where((service) => 
        (visibleServicesCount[service.id ?? 0] ?? 0) > 0).length;
    
    if (visibleCount > _visibleThreshold) {
      // Currently showing all, so show less (limit to threshold)
      _showLessServices();
    } else {
      // Currently showing limited, so show all
      _showAllServices();
    }
  }

  /// Show only first N services
  void _showLessServices() {
    final servicesWithoutSubServices = services.where((service) => 
        service.subServices == null || service.subServices!.isEmpty).toList();
    
    for (int i = 0; i < servicesWithoutSubServices.length; i++) {
      final service = servicesWithoutSubServices[i];
      final serviceId = service.id ?? '';
      
      if (i < _visibleThreshold) {
        visibleServicesCount[serviceId] = 1; // Show this service
      } else {
        visibleServicesCount[serviceId] = 0; // Hide this service
      }
    }
    visibleServicesCount.refresh();
  }

  /// Show all services
  void _showAllServices() {
    final servicesWithoutSubServices = services.where((service) => 
        service.subServices == null || service.subServices!.isEmpty).toList();
    
    for (final service in servicesWithoutSubServices) {
      final serviceId = service.id ?? '';
      visibleServicesCount[serviceId] = 1; // Show all services
    }
    visibleServicesCount.refresh();
  }

  /// Check if service should be visible
  bool isServiceVisible(String serviceId) {
    return (visibleServicesCount[serviceId] ?? 0) > 0;
  }

  /// Check if showing more than threshold
  bool get isShowingMoreServices {
    final servicesWithoutSubServices = services.where((service) => 
        service.subServices == null || service.subServices!.isEmpty).toList();
    
    final visibleCount = servicesWithoutSubServices.where((service) => 
        isServiceVisible(service.id ?? '')).length;
    
    return visibleCount > _visibleThreshold;
  }

  /// Check if the "Show more/less" button should be displayed
  bool get shouldShowMoreButton {
    final servicesWithoutSubServices = services.where((service) => 
        service.subServices == null || service.subServices!.isEmpty).toList();
    return servicesWithoutSubServices.length > _visibleThreshold;
  }

  void toggleService(String serviceName, String serviceId) {
    // Mark that user has made manual selection
    hasUserMadeManualSelection.value = true;

    if (selectedServices.contains(serviceName)) {
      selectedServices.remove(serviceName);
      selectedServiceIds.remove(serviceId);
    } else {
      selectedServices.add(serviceName);
      selectedServiceIds.add(serviceId);
    }
    selectedServices.refresh();
    selectedServiceIds.refresh();
  }

  void toggleServiceExpansion(String serviceId) {
    if (expandedServices.contains(serviceId)) {
      expandedServices.remove(serviceId);
    } else {
      expandedServices.add(serviceId);
    }
    expandedServices.refresh();
  }

  bool isServiceExpanded(String serviceId) {
    return expandedServices.contains(serviceId);
  }

  void toggleSubService(
      String subServiceName, String subServiceId, String serviceId) {
    // Mark that user has made manual selection
    hasUserMadeManualSelection.value = true;

    // Toggle UI selection
    if (selectedServices.contains(subServiceName)) {
      selectedServices.remove(subServiceName);
      // Remove from sub-service IDs map
      if (selectedSubServiceIds.containsKey(serviceId)) {
        selectedSubServiceIds[serviceId]!.remove(subServiceId);
        if (selectedSubServiceIds[serviceId]!.isEmpty) {
          selectedSubServiceIds.remove(serviceId);
        }
      }
    } else {
      selectedServices.add(subServiceName);
      // Add to sub-service IDs map
      if (!selectedSubServiceIds.containsKey(serviceId)) {
        selectedSubServiceIds[serviceId] = [];
      }
      if (!selectedSubServiceIds[serviceId]!.contains(subServiceId)) {
        selectedSubServiceIds[serviceId]!.add(subServiceId);
      }
    }
    selectedServices.refresh();
    selectedSubServiceIds.refresh();
  }

  bool get hasSelectedServices =>
      selectedServiceIds.isNotEmpty || selectedSubServiceIds.isNotEmpty;

  /// Save updated services
  Future<void> onUpdateDetails() async {
    if (!hasSelectedServices) {
      showResponseDialog(
        title: 'Error',
        message: 'Please select at least one service',
        isError: true,
        showButton: true,
      );
      return;
    }

    final professionTypeIdValue = professionTypeId.value;
    final professionSubTypeIdValue = professionSubTypeId.value;

    if (professionTypeIdValue == null || professionTypeIdValue.isEmpty) {
      showResponseDialog(
        title: 'Error',
        message: 'Profession type is required',
        isError: true,
        showButton: true,
      );
      return;
    }

    if (professionSubTypeIdValue == null || professionSubTypeIdValue.isEmpty) {
      showResponseDialog(
        title: 'Error',
        message: 'Profession sub-type is required',
        isError: true,
        showButton: true,
      );
      return;
    }

    // Build services array for API
    final servicesList = <Map<String, dynamic>>[];

    // Add services without sub-services (simple services)
    for (final serviceId in selectedServiceIds) {
      // Only add if this service doesn't have sub-services selected
      if (!selectedSubServiceIds.containsKey(serviceId)) {
        servicesList.add({
          'service_id': serviceId,
          'sub_service_ids': <String>[],
        });
      }
    }

    // Add services with sub-services
    for (final entry in selectedSubServiceIds.entries) {
      if (entry.value.isNotEmpty) {
        servicesList.add({
          'service_id': entry.key,
          'sub_service_ids': entry.value,
        });
      }
    }

    await callDataService<ApiResponse<dynamic>>(
      _userApiService.saveProfessionServices(
        professionTypeId: professionTypeIdValue,
        professionSubTypeId: professionSubTypeIdValue,
        services: servicesList,
      ),
      showLoader: true,
      onSuccess: (response) {
        if (response.success) {
          // Reset manual selection flag after successful save
          // This allows old services to be loaded next time user visits this page
          hasUserMadeManualSelection.value = false;
          hasLoadedOldServices.value = false;

          showResponseDialog(
            title: 'Success',
            message: 'Services updated successfully',
            isError: false,
            showButton: true,
            onOkPressed: () {
              Get.back();
            },
          );
        } else {
          showResponseDialog(
            title: 'Error',
            message: response.errorMessage,
            isError: true,
            showButton: true,
          );
        }
      },
      onError: (error, stack) {
        final errorMsg = errorMessage.value.isNotEmpty
            ? errorMessage.value
            : 'Failed to update services. Please try again.';
        showResponseDialog(
          title: 'Error',
          message: errorMsg,
          isError: true,
          showButton: true,
        );
      },
    );
  }
}
