import 'dart:convert';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:verithrive_dev/services/analytics_service.dart';
import '../../core/base/base_controller.dart';
import '../../data/repository/project_repository.dart';
import '../../utils/api_services.dart';
import 'Therapist.dart';

class TherapistController extends BaseController {
  final ProjectRepository _repository = Get.find(tag: (ProjectRepository).toString());
  
  var therapists = <Therapist>[].obs;
  var filteredTherapists = <Therapist>[].obs;
  var isLoading = false.obs;
  var searchQuery = ''.obs;
  var screenTitle = 'Sport therapists'.obs;

  // Store received parameters
  String? category;
  String? subTypeId;
  String? label;
  String? type;
  List<Map<String, dynamic>>? subTypesArray;
  String? availability;
  double? distance;
  double? latitude;
  double? longitude;
  List<String>? goals;
  String? trainerPreference;
  dynamic arguments; // Store arguments for API call

  // Filter and sort parameters - make filter parameters observable for Obx
  final RxString selectedProfessionalSubType = ''.obs;
  final RxString selectedGender = ''.obs;
  final RxDouble minPrice = 0.0.obs;
  final RxDouble maxPrice = 1000.0.obs;
  final RxString selectedAvailabilityFilter = ''.obs;
  final RxDouble selectedDistance = 0.0.obs;
  final RxString sortBy = ''.obs; // Only set when user selects a sort option - made observable
  int page = 0;
  int limit = 20;

  // Check if any filter is applied
  bool get hasFilter {
    // Professional filter applied (not empty)
    if (selectedProfessionalSubType.value.isNotEmpty) {
      return true;
    }

    // Distance filter applied (not default 13.0)
    if (selectedDistance.value > 0.0 && selectedDistance.value != 13.0) {
      return true;
    }

    // Price filter applied (min > 0 or max < 1000)
    if (minPrice.value > 0.0 || maxPrice.value < 1000.0) {
      return true;
    }

    // Availability filter applied (any value means it was manually selected)
    if (selectedAvailabilityFilter.value.isNotEmpty) {
      return true;
    }

    // Gender filter applied (any value means it was manually selected)
    if (selectedGender.value.isNotEmpty) {
      return true;
    }

    // No filters applied
    return false;
  }

  @override
  void onInit() {
    super.onInit();
    _receiveAndLogArguments();
    initializeTitle();
    loadTherapists();
  }

  void _receiveAndLogArguments() {
    final receivedArguments = Get.arguments;
    arguments = receivedArguments;
    
    print('========================================');
    print('THERAPY LIST SCREEN - RECEIVED ARGUMENTS');
    print('========================================');
    
    if (arguments != null && arguments is Map<String, dynamic>) {
      // Category
      category = arguments['category'] as String?;
      print('Category: ${category ?? "null"}');
      
      // Type
      type = arguments['type'] as String?;
      print('Type: ${type ?? "null"}');
      
      // Sub Type ID
      subTypeId = arguments['sub_type_id'] as String?;
      print('Sub Type ID: ${subTypeId ?? "null"}');
      
      // Label
      label = arguments['label'] as String?;
      print('Label: ${label ?? "null"}');
      
      // Sub Types Array
      if (arguments['sub_types'] != null) {
        subTypesArray = List<Map<String, dynamic>>.from(
          arguments['sub_types'] as List,
        );
        print('Sub Types Array: $subTypesArray');
        print('Sub Types Count: ${subTypesArray!.length}');
        // Print each sub_type in the array
        for (int i = 0; i < subTypesArray!.length; i++) {
          print('  Sub Type ${i + 1}:');
          print('    - ID: ${subTypesArray![i]['id'] ?? "null"}');
          print('    - Sub Type: ${subTypesArray![i]['sub_type'] ?? "null"}');
          print('    - Image: ${subTypesArray![i]['image'] ?? "null"}');
        }
      } else {
        print('Sub Types Array: null');
      }
      
      // Availability (converted to API format)
      availability = arguments['availability'] as String?;
      print('Availability: ${availability ?? "null"}');
      
      // Distance
      if (arguments['distance'] != null) {
        distance = arguments['distance'] is double 
            ? arguments['distance'] as double
            : (arguments['distance'] as num).toDouble();
        print('Distance: $distance miles');
      } else {
        print('Distance: null');
      }
      
      // Latitude
      if (arguments['latitude'] != null) {
        latitude = arguments['latitude'] is double 
            ? arguments['latitude'] as double
            : (arguments['latitude'] as num).toDouble();
        print('Latitude: $latitude');
      } else {
        print('Latitude: null');
      }
      
      // Longitude
      if (arguments['longitude'] != null) {
        longitude = arguments['longitude'] is double 
            ? arguments['longitude'] as double
            : (arguments['longitude'] as num).toDouble();
        print('Longitude: $longitude');
      } else {
        print('Longitude: null');
      }
      
      // Goals (for fitness/nutrition goals)
      if (arguments['goals'] != null) {
        goals = List<String>.from(arguments['goals'] as List);
        print('Goals: $goals');
      } else {
        print('Goals: null');
      }
      
      // Service IDs (from fitness goal screen)
      if (arguments['service_id'] != null) {
        List<dynamic> serviceIds = arguments['service_id'] as List<dynamic>;
        print('Service IDs: $serviceIds');
      } else {
        print('Service IDs: null');
      }
      
      // Sub Service IDs (from fitness goal screen)
      if (arguments['sub_service_id'] != null) {
        List<dynamic> subServiceIds = arguments['sub_service_id'] as List<dynamic>;
        print('Sub Service IDs: $subServiceIds');
      } else {
        print('Sub Service IDs: null');
      }
      
      // Trainer Preference (for fitness goal)
      trainerPreference = arguments['trainerPreference'] as String?;
      print('Trainer Preference: ${trainerPreference ?? "null"}');
      
      // Gender (converted from trainer preference)
      if (arguments['gender'] != null) {
        String genderValue = arguments['gender'] as String;
        print('Gender: $genderValue');
        // Set gender for API call
        selectedGender.value = genderValue;
      } else {
        print('Gender: null (no preference)');
        // Don't set gender if not provided
        selectedGender.value = '';
      }
      
      print('========================================');
      print('END OF ARGUMENTS LOG');
      print('========================================');
    } else {
      print('No arguments received or arguments is not a Map');
      print('Arguments type: ${arguments.runtimeType}');
      print('Arguments value: $arguments');
      print('========================================');
    }
  }

  void initializeTitle() {
    // First, try to get the sub_type from the sub_types array using subTypeId
    if (subTypeId != null && subTypeId!.isNotEmpty && subTypesArray != null && subTypesArray!.isNotEmpty) {
      // Find the matching sub_type in the array
      for (var subType in subTypesArray!) {
        if (subType['id']?.toString() == subTypeId) {
          String? subTypeName = subType['sub_type']?.toString();
          if (subTypeName != null && subTypeName.isNotEmpty) {
            screenTitle.value = subTypeName;
            print('Title set from sub_type: $subTypeName');
            return;
          }
        }
      }
    }
    
    // Fallback to category-based titles if sub_type not found
    if (category != null) {
      switch (category) {
        case 'wellness':
          screenTitle.value = 'Sport therapists';
          break;
        case 'fitness':
          screenTitle.value = 'Personal Trainer';
          break;
        case 'food_nutrition':
          screenTitle.value = 'Nutritionists';
          break;
        default:
          screenTitle.value = 'Sport therapists';
      }
    }
  }

  String? _getCategoryForAnalytics() {
    // Return the category for analytics purposes
    return category;
  }

  void loadTherapists() {
    callProfessionalsListAPI();
  }

  void callProfessionalsListAPI() {
    Map<String, dynamic> toJson() {
      final Map<String, dynamic> data = <String, dynamic>{};
      
      // Required: profession_sub_type (use subTypeId from arguments)
      if (selectedProfessionalSubType.value.isNotEmpty) {
        data['profession_sub_type'] = selectedProfessionalSubType.value;
      } else if (subTypeId != null && subTypeId!.isNotEmpty) {
        data['profession_sub_type'] = subTypeId;
      }
      
      // Service IDs (from fitness goal screen)
      if (arguments != null && arguments is Map<String, dynamic>) {
        if (arguments!['service_id'] != null) {
          try {
            dynamic serviceIdsValue = arguments!['service_id'];
            if (serviceIdsValue is List) {
              // Convert to List<String> to ensure proper type
              List<String> serviceIds = serviceIdsValue.map((id) => id.toString()).toList();
              data['service_id'] = serviceIds;
            }
          } catch (e) {
            print('Error processing service_id: $e');
          }
        }
        
        // Sub Service IDs (from fitness goal screen)
        if (arguments!['sub_service_id'] != null) {
          try {
            dynamic subServiceIdsValue = arguments!['sub_service_id'];
            if (subServiceIdsValue is List) {
              // Convert to List<String> to ensure proper type
              List<String> subServiceIds = subServiceIdsValue.map((id) => id.toString()).toList();
              data['sub_service_id'] = subServiceIds;
            }
          } catch (e) {
            print('Error processing sub_service_id: $e');
          }
        }
      }
      
      // Optional parameters
      // Only pass gender if it's explicitly set (from trainer preference)
      if (selectedGender.value.isNotEmpty) {
        data['gender'] = selectedGender.value.toLowerCase();
      }
      
      if (minPrice.value > 0.0) {
        data['price_min'] = minPrice.value.toInt();
      }
      
      if (maxPrice.value < 1000.0) {
        data['price_max'] = maxPrice.value.toInt();
      }
      
      // Availability - convert from UI format to API format
      if (selectedAvailabilityFilter.value.isNotEmpty) {
        String availabilityApiFormat = _convertAvailabilityToApiFormat(selectedAvailabilityFilter.value);
        data['availability'] = availabilityApiFormat;
      } else if (availability != null && availability!.isNotEmpty) {
        data['availability'] = availability;
      }
      
      if (latitude != null && longitude != null) {
        data['latitude'] = latitude;
        data['longitude'] = longitude;
      }
      
      if (selectedDistance.value > 0.0) {
        data['distance'] = selectedDistance.value.toInt();
      } else if (distance != null) {
        data['distance'] = distance!.toInt();
      }
      
      // Only pass sort_by if it's explicitly set (user selected a sort option)
      if (sortBy.value.isNotEmpty) {
        data['sort_by'] = sortBy.value;
      }
      
      // Add current_date parameter in DD/MM/YYYY format
      DateTime now = DateTime.now();
      String currentDate = DateFormat('dd/MM/yyyy').format(now);
      data['current_date'] = currentDate;
      
      data['page'] = page;
      data['limit'] = limit;
      
      print('========================================');
      print('Professionals List API Request:');
      print(data);
      print('========================================');
      
      return data;
    }
    
    var service = _repository.sendPostApiRequest(toJson, professionals_list, true);
    callDataService(
      service,
      onSuccess: _handleProfessionalsListSuccess,
      onError: _handleProfessionalsListError,
      isShowLoading: true,
    );
  }

  String _convertAvailabilityToApiFormat(String uiFormat) {
    // Convert UI format to API format
    if (uiFormat == 'Available in next 3 days') {
      return '3_days';
    } else if (uiFormat == 'Available in next 7 days') {
      return '7_days';
    } else if (uiFormat == 'Available in next 10 days') {
      return '10_days';
    } else if (uiFormat == 'Available in next 14 days') {
      return '14_days';
    } else if (uiFormat == 'Available in next 30 days') {
      return '30_days';
    } else if (uiFormat == 'Available anytime') {
      return 'anytime';
    }
    // If already in API format, return as is
    return uiFormat;
  }

  Future<void> _handleProfessionalsListSuccess(dynamic baseResponse) async {
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
        Map<String, dynamic> dataMap = responseData['data'] as Map<String, dynamic>;

        // Analytics: Log search results
        

        List<dynamic>? itemsList = dataMap['items'] as List<dynamic>?;
        
        if (itemsList != null && itemsList.isNotEmpty) {
          therapists.value = itemsList.map((json) {
            // Helper function to safely parse numeric values
            double? _parseDouble(dynamic value) {
              if (value == null) return null;
              if (value is num) return value.toDouble();
              if (value is String) {
                if (value.isEmpty) return null;
                return double.tryParse(value);
              }
              return null;
            }
            
            int? _parseInt(dynamic value) {
              if (value == null) return null;
              if (value is num) return value.toInt();
              if (value is String) {
                if (value.isEmpty) return null;
                return int.tryParse(value);
              }
              return null;
            }
            
            // Parse according to updated API response structure
            final therapist = Therapist(
              id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
              name: json['full_name']?.toString() ?? 'Unknown',
              imageUrl: json['profile_picture']?.toString() ?? 
                        json['image']?.toString() ?? 
                        json['imageUrl']?.toString() ?? 
                        json['profile_image']?.toString() ?? '',
              specialty: json['specialty']?.toString() ?? 
                        json['profession_sub_type']?.toString() ?? 
                        json['sub_type']?.toString() ?? 
                        json['profession']?.toString() ?? '',
              distance: _parseDouble(json['distance_miles']) ?? 
                       _parseDouble(json['distance']) ?? 0.0,
              rating: _parseDouble(json['rating']) ?? 0.0,
              reviewCount: _parseInt(json['review_count']) ?? 0,
              price: _parseDouble(json['price']) ?? 0.0,
              isFavorite: json['is_saved'] as bool? ?? false,
              services: (json['services'] as List?)?.map((e) => e.toString()).toList() ?? [],
              packages: (json['packages'] as List?)?.map((pkg) {
                return ServicePackage(
                  title: pkg['title']?.toString() ?? '',
                  duration: pkg['duration']?.toString() ?? '',
                  price: _parseDouble(pkg['price']) ?? 0.0,
                  discount: pkg['discount']?.toString(),
                  service_format_date: pkg['service_format_date']?.toString(),
                );
              }).toList() ?? [],
            );
            
            // Log parsed data for debugging
            print('Parsed Therapist:');
            print('  ID: ${therapist.id}');
            print('  Name: ${therapist.name}');
            print('  Rating: ${therapist.rating}');
            print('  Review Count: ${therapist.reviewCount}');
            print('  Price: ${therapist.price}');
            print('  Is Saved: ${therapist.isFavorite}');
            print('  Distance: ${therapist.distance}');
            
            return therapist;
          }).toList();
        } else {
          // Empty list - no professionals found
          therapists.value = [];
        }
        
        filteredTherapists.value = therapists;
        
        // Log view_item_list analytics when therapist list is loaded
        if (filteredTherapists.isNotEmpty) {
          final category = _getCategoryForAnalytics() ?? 'wellness';
          final items = filteredTherapists.map((therapist) => {
            'item_id': therapist.id,
            'item_name': therapist.name,
            'item_category': category,
            'item_variant': therapist.specialty,
            'item_brand': therapist.services.isNotEmpty ? therapist.services.first : '',
            'price': therapist.price,
            'quantity': 1,
            'currency': 'GBP',
          }).toList();
          
          AnalyticsService.instance.logEvent(
            name: 'view_item_list',
            parameters: {
              'screen_name': 'TherapistListingScreen',
              'screen_class': 'TherapistListingScreen',
              'page_category': category,
              'items': jsonEncode(items),
            },
          );
        }
        
        print('========================================');
        print('Professionals List API Success:');
        print('Loaded ${therapists.length} professionals');
        if (dataMap['pagination'] != null) {
          print('Pagination: ${dataMap['pagination']}');
        }
        print('========================================');
      } else {
        print('Professionals List API Error: $message');
        therapists.value = [];
        filteredTherapists.value = [];
      }
    } catch (e) {
      print('Error parsing professionals list response: $e');
      therapists.value = [];
      filteredTherapists.value = [];
    }
  }

  void _handleProfessionalsListError(Exception exception) {
    print('Professionals List API Error: $exception');
    therapists.value = [];
    filteredTherapists.value = [];
  }

  // Method to update title based on selected professional
  void _updateTitleFromProfessional() {
    if (selectedProfessionalSubType.value.isNotEmpty && 
        subTypesArray != null && 
        subTypesArray!.isNotEmpty) {
      // Find the matching sub_type in the array
      for (var subType in subTypesArray!) {
        if (subType['id']?.toString() == selectedProfessionalSubType.value) {
          String? subTypeName = subType['sub_type']?.toString();
          if (subTypeName != null && subTypeName.isNotEmpty) {
            screenTitle.value = subTypeName;
            print('Title updated from selected professional: $subTypeName');
            return;
          }
        }
      }
    }
    
    // If no professional selected or not found, use default title logic
    initializeTitle();
  }

  // Method to apply filters from FilterController
  void applyFilters(Map<String, dynamic> filterData) {
    // Save all filter values so they persist when filter screen is reopened
    selectedProfessionalSubType.value = filterData['profession_sub_type'] as String? ?? '';
    selectedGender.value = filterData['gender'] as String? ?? '';
    minPrice.value = filterData['minPrice'] as double? ?? 0.0;
    maxPrice.value = filterData['maxPrice'] as double? ?? 1000.0;
    selectedAvailabilityFilter.value = filterData['availability'] as String? ?? '';
    selectedDistance.value = filterData['distance'] as double? ?? 0.0;
    
    print('========================================');
    print('TherapistController: Applied filters:');
    print('Professional Sub Type: ${selectedProfessionalSubType.value}');
    print('Gender: ${selectedGender.value}');
    print('Min Price: ${minPrice.value}');
    print('Max Price: ${maxPrice.value}');
    print('Availability: ${selectedAvailabilityFilter.value}');
    print('Distance: ${selectedDistance.value}');
    print('========================================');
    
    // Update title based on selected professional
    _updateTitleFromProfessional();
    
    // Reload therapists with new filters
    callProfessionalsListAPI();
  }

  // Method to apply sort
  void applySort(String sortValue) {
    // Convert UI sort value to API format
    if (sortValue == 'price_low_to_high') {
      sortBy.value = 'price_low';
    } else if (sortValue == 'price_high_to_low') {
      sortBy.value = 'price_high';
    } else if (sortValue == 'distance_nearest') {
      sortBy.value = 'distance';
    } else {
      sortBy.value = sortValue;
    }
    
    // Reload therapists with new sort
    callProfessionalsListAPI();
  }

  void searchTherapists(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      filteredTherapists.value = therapists;
    } else {
      filteredTherapists.value = therapists
          .where((t) => t.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  void toggleFavorite(String id) {
    // Find the therapist in the list
    final therapistIndex = therapists.indexWhere((t) => t.id == id);
    if (therapistIndex == -1) return;
    
    final therapist = therapists[therapistIndex];
    final currentFavoriteStatus = therapist.isFavorite;
    
    // Analytics: Log favorite toggle
    

    // Optimistically update UI (will revert if API fails)
    _updateTherapistFavoriteStatus(id, !currentFavoriteStatus);
    
    // Call API to save/unsave
    callSaveUnsaveAPI(id);
  }

  void callSaveUnsaveAPI(String therapistId) {
    // POST request with parameter: {"professional_id": "string"}
    Map<String, dynamic> toJson() {
      final Map<String, dynamic> data = <String, dynamic>{};
      data['professional_id'] = therapistId;
      
      print('========================================');
      print('Save/Unsave API Request (POST):');
      print(data);
      print('========================================');
      
      return data;
    }
    
    // Using POST method via sendPostApiRequest
    var service = _repository.sendPostApiRequest(toJson, save_unsave, true);
    callDataService(
      service,
      onSuccess: (response) => _handleSaveUnsaveSuccess(response, therapistId),
      onError: (exception) => _handleSaveUnsaveError(exception, therapistId),
      isShowLoading: false, // Don't show loading for wishlist toggle
    );
  }

  Future<void> _handleSaveUnsaveSuccess(dynamic baseResponse, String therapistId) async {
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
      
      if (success == true) {
        // Find the therapist and get the updated status from response
        final therapistIndex = therapists.indexWhere((t) => t.id == therapistId);
        if (therapistIndex != -1) {
          final therapist = therapists[therapistIndex];
          // Check if response contains updated is_saved status
          bool? updatedStatus = responseData['data']?['is_saved'] as bool?;
          if (updatedStatus != null) {
            _updateTherapistFavoriteStatus(therapistId, updatedStatus);
          }
          // Otherwise, the optimistic update is already applied
        }
        
        print('Save/Unsave API Success: $message');
      } else {
        // Revert optimistic update on failure
        final therapistIndex = therapists.indexWhere((t) => t.id == therapistId);
        if (therapistIndex != -1) {
          final therapist = therapists[therapistIndex];
          _updateTherapistFavoriteStatus(therapistId, !therapist.isFavorite);
        }
        print('Save/Unsave API Error: $message');
      }
    } catch (e) {
      // Revert optimistic update on error
      final therapistIndex = therapists.indexWhere((t) => t.id == therapistId);
      if (therapistIndex != -1) {
        final therapist = therapists[therapistIndex];
        _updateTherapistFavoriteStatus(therapistId, !therapist.isFavorite);
      }
      print('Error parsing save/unsave response: $e');
    }
  }

  void _handleSaveUnsaveError(Exception exception, String therapistId) {
    // Revert optimistic update on error
    final therapistIndex = therapists.indexWhere((t) => t.id == therapistId);
    if (therapistIndex != -1) {
      final therapist = therapists[therapistIndex];
      _updateTherapistFavoriteStatus(therapistId, !therapist.isFavorite);
    }
    print('Save/Unsave API Error: $exception');
  }

  void _updateTherapistFavoriteStatus(String id, bool isFavorite) {
    // Update in therapists list
    final therapistIndex = therapists.indexWhere((t) => t.id == id);
    if (therapistIndex != -1) {
      final therapist = therapists[therapistIndex];
      therapists[therapistIndex] = Therapist(
        id: therapist.id,
        name: therapist.name,
        imageUrl: therapist.imageUrl,
        specialty: therapist.specialty,
        distance: therapist.distance,
        rating: therapist.rating,
        reviewCount: therapist.reviewCount,
        price: therapist.price,
        isFavorite: isFavorite,
        availability: therapist.availability,
        ratingsCount: therapist.ratingsCount,
        yearsExperience: therapist.yearsExperience,
        bookingsCount: therapist.bookingsCount,
        services: therapist.services,
        packages: therapist.packages,
      );
    }
    
    // Update in filteredTherapists list
    final filteredIndex = filteredTherapists.indexWhere((t) => t.id == id);
    if (filteredIndex != -1) {
      final therapist = filteredTherapists[filteredIndex];
      filteredTherapists[filteredIndex] = Therapist(
        id: therapist.id,
        name: therapist.name,
        imageUrl: therapist.imageUrl,
        specialty: therapist.specialty,
        distance: therapist.distance,
        rating: therapist.rating,
        reviewCount: therapist.reviewCount,
        price: therapist.price,
        isFavorite: isFavorite,
        availability: therapist.availability,
        ratingsCount: therapist.ratingsCount,
        yearsExperience: therapist.yearsExperience,
        bookingsCount: therapist.bookingsCount,
        services: therapist.services,
        packages: therapist.packages,
      );
    }
  }
}
