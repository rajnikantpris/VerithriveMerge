import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/base/base_controller.dart';
import '../../data/repository/project_repository.dart';
import '../../utils/api_services.dart';
import '../../utils/auth_service.dart';
import '../therapy_list/Therapist.dart';

class SavedController extends BaseController {
  final ProjectRepository _repository = Get.find(tag: (ProjectRepository).toString());
  
  // Observable list of saved therapists
  var savedTherapists = <Therapist>[].obs;
  var isLoading = false.obs;
  int page = 0;
  int limit = 20;

  @override
  void onInit() {
    super.onInit();
    // Don't check authentication on init - let user navigate first
    // Authentication will be checked when data is actually loaded
  }

  @override
  void fetchData() async {
    print("API Called: Saved Items Loaded");
    _checkAuthAndLoadSavedTherapists();
  }

  // Refresh data method called by MainScreen when tab is tapped
  void refreshData() {
    isLoading.value = false;
    // Check authentication before refreshing saved therapists
    _checkAuthAndRefreshData();
  }

  // Check authentication and load saved therapists
  Future<void> _checkAuthAndLoadSavedTherapists() async {
    bool canAccess = await AuthService.requireAuth();
    if (canAccess) {
      loadSavedTherapists();
    }
  }

  // Check authentication and refresh data
  Future<void> _checkAuthAndRefreshData() async {
    bool canAccess = await AuthService.requireAuth();
    if (canAccess) {
      loadSavedTherapists();
    }
  }

  void loadSavedTherapists() {
    callProfessionalsListAPI();
  }

  void callProfessionalsListAPI() {
    isLoading.value = true;
    
    Map<String, dynamic> toJson() {
      final Map<String, dynamic> data = <String, dynamic>{};
      
      // Add current_date parameter in DD/MM/YYYY format
      DateTime now = DateTime.now();
      String currentDate = DateFormat('dd/MM/yyyy').format(now);
      data['current_date'] = currentDate;
      
      data['page'] = page;
      data['limit'] = limit;
      
      // Note: We'll filter for saved items (is_saved: true) in the response handler
      // If the API supports filtering saved items directly, add: data['is_saved'] = true;
      
      print('========================================');
      print('Saved Professionals List API Request:');
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
        List<dynamic>? itemsList = dataMap['items'] as List<dynamic>?;
        
        if (itemsList != null && itemsList.isNotEmpty) {
          // Filter only saved items (is_saved: true)
          List<dynamic> savedItems = itemsList.where((item) {
            bool isSaved = item['is_saved'] as bool? ?? false;
            return isSaved;
          }).toList();
          
          savedTherapists.value = savedItems.map((json) {
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
                );
              }).toList() ?? [],
            );
            
            // Log parsed data for debugging
            print('Parsed Saved Therapist:');
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
          // Empty list - no saved professionals found
          savedTherapists.value = [];
        }
        
        print('========================================');
        print('Saved Professionals List API Success:');
        print('Loaded ${savedTherapists.length} saved professionals');
        if (dataMap['pagination'] != null) {
          print('Pagination: ${dataMap['pagination']}');
        }
        print('========================================');
      } else {
        print('Saved Professionals List API Error: $message');
        savedTherapists.value = [];
      }
      isLoading.value = false;
    } catch (e) {
      print('Error parsing saved professionals list response: $e');
      savedTherapists.value = [];
      isLoading.value = false;
    }
  }

  void _handleProfessionalsListError(Exception exception) {
    print('Saved Professionals List API Error: $exception');
    savedTherapists.value = [];
    isLoading.value = false;
  }

  void toggleFavorite(String therapistId) {
    // Find the therapist in the list
    final therapistIndex = savedTherapists.indexWhere((t) => t.id == therapistId);
    if (therapistIndex == -1) return;
    
    final therapist = savedTherapists[therapistIndex];
    final currentFavoriteStatus = therapist.isFavorite;
    
    // Optimistically update UI (will revert if API fails)
    // Since we're removing from saved list, remove it immediately
    if (currentFavoriteStatus) {
      savedTherapists.removeAt(therapistIndex);
    }

    callSaveUnsaveAPI(therapistId);
  }

  void callSaveUnsaveAPI(String therapistId) {
    // POST request with parameter: {"professional_id": "string"}
    Map<String, dynamic> toJson() {
      final Map<String, dynamic> data = <String, dynamic>{};
      data['professional_id'] = therapistId;
      
      print('========================================');
      print('Save/Unsave API Request (POST) from Saved Screen:');
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
        // Item was unsaved successfully, it's already removed from list optimistically
        print('Save/Unsave API Success: $message');
        // Optionally reload the list to ensure consistency
        // loadSavedTherapists();
      } else {
        // Revert optimistic update on failure - reload the list
        print('Save/Unsave API Error: $message');
        loadSavedTherapists();
      }
    } catch (e) {
      // Revert optimistic update on error - reload the list
      print('Error parsing save/unsave response: $e');
      loadSavedTherapists();
    }
  }

  void _handleSaveUnsaveError(Exception exception, String therapistId) {
    // Revert optimistic update on error - reload the list
    print('Save/Unsave API Error: $exception');
    loadSavedTherapists();
  }
}