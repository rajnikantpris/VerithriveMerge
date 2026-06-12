import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/storage_service.dart';
import '../../core/base/base_controller.dart';
import '../../core/values/sharePrefrenceConst.dart';
import '../../data/local/preference/preference_manager.dart';
import '../../data/repository/project_repository.dart';
import '../../utils/api_services.dart';
import '../therapy_list/Therapist.dart';
import 'package:verithrive_dev/services/analytics_service.dart';

class TherapistDetailController extends BaseController
    with GetSingleTickerProviderStateMixin {
  final ProjectRepository _repository = Get.find(tag: (ProjectRepository).toString());
 final StorageService? _storageService =
      Get.isRegistered<StorageService>() ? Get.find<StorageService>() : null;
  // Store initial therapist from arguments (for fallback)
  Therapist? initialTherapist;
  String? category;
  String? professionalId; // Store professional ID for API call

  // API Response Data - Observable
  var therapist = Therapist(
    id: '',
    name: 'Loading...',
    imageUrl: '',
    specialty: '',
    distance: 0.0,
    rating: 0.0,
    reviewCount: 0,
    price: 0.0,
    services: [],
    packages: [],
  ).obs;

  var description = ''.obs;
  var availability_text = ''.obs;
  var experience = 0.obs;
  var totalExperience = 0.obs;
  var booking_count = 0.obs;
  var email = ''.obs;
  var mobileNumber = ''.obs;
  var gender = ''.obs;
  var professionType = ''.obs;
  var professionSubType = ''.obs;
  var address = ''.obs;
  var postcode = ''.obs;
  var latitude = ''.obs;
  var longitude = ''.obs;

  // Services from API
  var services = <ServiceItem>[].obs;

  // Qualifications from API
  var qualifications = <Qualification>[].obs;

  // Personal Identifications from API
  var personalIdentifications = <PersonalIdentification>[].obs;

  // Professional Service Format (packages)
  var packages = <ServicePackage>[].obs;

  // Rating details
  var averageRating = 0.0.obs;
  var ratingCount = 0.obs;

  late final TabController tabController;
  var selectedTabIndex = 0.obs;
  var isLoading = true.obs;

  RxBool isGuest = false.obs;


  @override
  void onInit() {
    super.onInit();

    // Receive the therapist and category passed from the previous screen
    final arguments = Get.arguments;
    print('========================================');
    print('TherapistDetailController onInit:');
    print('Arguments type: ${arguments.runtimeType}');
    print('Arguments: $arguments');
    print('========================================');

    getPreferenceDetails();
    
    if (arguments is Map<String, dynamic>) {
      initialTherapist = arguments['therapist'] as Therapist?;
      category = arguments['category'] as String?;

      // Get professional ID from therapist
      if (initialTherapist != null) {
        professionalId = initialTherapist!.id;
        // Set initial therapist data while loading
        therapist.value = initialTherapist!;
        print('Professional ID from Map: $professionalId');
      }
    } else if (arguments is Therapist) {
      initialTherapist = arguments;
      professionalId = initialTherapist!.id;
      therapist.value = initialTherapist!;
      print('Professional ID from Therapist: $professionalId');
    }

    // Initialize TabController (3 tabs: Services, About, Qualifications)
    tabController = TabController(length: 3, vsync: this);

    // Sync selected index with tab controller (update immediately for IndexedStack)
    tabController.addListener(() {
      selectedTabIndex.value = tabController.index;
      
      // Analytics: Log secondary navigation tap event
      String elementText = '';
      switch (tabController.index) {
        case 0:
          elementText = 'Services';
          break;
        case 1:
          elementText = 'About';
          break;
        case 2:
          elementText = 'Qualifications';
          break;
        default:
          elementText = 'Unknown';
          break;
      }
      
      // Get dynamic page category from navigation arguments
      String pageCategory = 'wellness';
      try {
        final args = Get.arguments as Map<String, dynamic>?;
        pageCategory = args?['category'] as String? ?? 'wellness';
      } catch (e) {
        // Fallback to wellness if arguments are not available
        pageCategory = 'wellness';
      }
      
      AnalyticsService.instance.logEvent(
        name: 'secondary_nav_tap',
        parameters: {
          'screen_name': 'TherapistDetailScreen',
          'screen_class': 'TherapistDetailScreen',
          'element_text': elementText,
          'element_location': 'nav',
          'page_category': pageCategory,
        },
      );
    });

    // Call API to fetch professional details
    if (professionalId != null && professionalId!.isNotEmpty) {
      print('Calling fetchProfessionalDetails with ID: $professionalId');
      fetchProfessionalDetails();
    } else {
      print('ERROR: Professional ID is null or empty!');
      print('Initial Therapist: $initialTherapist');
      print('Professional ID: $professionalId');
      isLoading.value = false;
    }
  }

  void fetchProfessionalDetails() {
    // Append the ID to the endpoint URL path
    String endpointWithId = "$professionals_details/$professionalId";
    
    Map<String, dynamic> toJson() {
      // Return empty map since ID is in the URL path
      return <String, dynamic>{};
    }

    print('========================================');
    print('Professional Details API Request:');
    print('Professional ID: $professionalId');
    print('Endpoint: $endpointWithId');
    print('Full URL: http://192.168.0.21:4142/api/v1/user/$endpointWithId');
    print('========================================');

    // Use GET request with id in URL path and authorization token
    var service = _repository.sendGetApiWithParamRequest(toJson, endpointWithId, true);
    callDataService(
      service,
      onSuccess: _handleProfessionalDetailsSuccess,
      onError: _handleProfessionalDetailsError,
      isShowLoading: true,
    );
  }

  Future<void> _handleProfessionalDetailsSuccess(dynamic baseResponse) async {
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

        // Analytics: Log professional profile view
        
        
        // Parse professional data
        if (dataMap['professional'] != null) {
          Map<String, dynamic> professional = dataMap['professional'] as Map<String, dynamic>;

          // Update therapist observable
          therapist.value = Therapist(
            id: professional['_id']?.toString() ?? professionalId ?? '',
            name: professional['full_name']?.toString() ?? initialTherapist?.name ?? 'Unknown',
            imageUrl: professional['image']?.toString() ??
                     professional['profile_image']?.toString() ??
                     initialTherapist?.imageUrl ?? '',
            specialty: professional['profession_sub_type_details']?['sub_type']?.toString() ??
                      professional['profession_sub_type']?.toString() ??
                      initialTherapist?.specialty ?? '',
            distance: initialTherapist?.distance ?? 0.0,
            rating: (professional['rating']?['average'] as num?)?.toDouble() ??
                   professional['rating'] as double? ??
                   initialTherapist?.rating ?? 0.0,
            reviewCount: (professional['rating']?['count'] as num?)?.toInt() ??
                        professional['review_count'] as int? ??
                        initialTherapist?.reviewCount ?? 0,
            price: initialTherapist?.price ?? 0.0,
            isFavorite: professional['is_saved'] as bool? ?? initialTherapist?.isFavorite ?? false,
            availability: 'Available for next 7 days',
            ratingsCount: (professional['rating']?['count'] as num?)?.toInt() ?? 0,
            yearsExperience: (professional['total_experience'] as num?)?.toInt() ??
                            (professional['experience'] as num?)?.toInt() ?? 0,
            bookingsCount: 0, // Not in API response
            services: [],
            packages: [],
          );

          // Store other professional details
          description.value = professional['description']?.toString() ?? '';
          availability_text.value = professional['availability_text']?.toString() ?? '';
          experience.value = (professional['experience'] as num?)?.toInt() ?? 0;
          totalExperience.value = (professional['total_experience'] as num?)?.toInt() ?? 0;
          booking_count.value = (professional['booking_count'] as num?)?.toInt() ?? 0;
          email.value = professional['email']?.toString() ?? '';
          mobileNumber.value = professional['mobile_number']?.toString() ?? '';
          gender.value = professional['gender']?.toString() ?? '';
          professionType.value = professional['profession_type_details']?['type']?.toString() ?? '';
          professionSubType.value = professional['profession_sub_type_details']?['sub_type']?.toString() ?? '';

          // Parse rating
          if (professional['rating'] != null && professional['rating'] is Map) {
            Map<String, dynamic> ratingData = professional['rating'] as Map<String, dynamic>;
            averageRating.value = (ratingData['average'] as num?)?.toDouble() ?? 0.0;
            ratingCount.value = (ratingData['count'] as num?)?.toInt() ?? 0;
          }
        }

        // Parse address (full_address is at the same level as professional in dataMap)
        if (dataMap['full_address'] != null) {
          Map<String, dynamic>? fullAddress = dataMap['full_address'] as Map<String, dynamic>?;
          if (fullAddress != null) {
            address.value = fullAddress['address']?.toString() ?? '';
            postcode.value = fullAddress['postcode']?.toString() ?? '';
            latitude.value = fullAddress['latitude']?.toString() ?? '';
            longitude.value = fullAddress['longitude']?.toString() ?? '';
            
            print('========================================');
            print('Address Parsed:');
            print('Address: ${address.value}');
            print('Postcode: ${postcode.value}');
            print('Latitude: ${latitude.value}');
            print('Longitude: ${longitude.value}');
            print('========================================');
          }
        }

        // Parse services
        if (dataMap['services'] != null) {
          List<dynamic> servicesList = dataMap['services'] as List<dynamic>;
          services.value = servicesList.map((json) {
            return ServiceItem(
              serviceId: json['service_id']?.toString() ?? '',
              serviceName: json['service_name']?.toString() ?? '',
              subServices: (json['sub_services'] as List?)?.map((e) => e.toString()).toList() ?? [],
            );
          }).toList();

          // Also update therapist services for compatibility
          therapist.value = Therapist(
            id: therapist.value.id,
            name: therapist.value.name,
            imageUrl: therapist.value.imageUrl,
            specialty: therapist.value.specialty,
            distance: therapist.value.distance,
            rating: therapist.value.rating,
            reviewCount: therapist.value.reviewCount,
            price: therapist.value.price,
            isFavorite: therapist.value.isFavorite,
            availability: therapist.value.availability,
            ratingsCount: therapist.value.ratingsCount,
            yearsExperience: therapist.value.yearsExperience,
            bookingsCount: therapist.value.bookingsCount,
            services: services.map((s) => s.serviceName).toList(),
            packages: packages,
          );
        }

        // Parse qualifications
        if (dataMap['qualifications'] != null) {
          List<dynamic> qualificationsList = dataMap['qualifications'] as List<dynamic>;
          qualifications.value = qualificationsList.map((json) {
            return Qualification(
              id: json['_id']?.toString() ?? '',
              schoolOrUniversity: json['school_or_university']?.toString() ?? '',
              degreeOrCertificate: json['degree_or_certificate']?.toString() ?? '',
              expiryDate: json['expiry_date']?.toString() ?? '',
              certificateFile: json['certificate_file']?.toString() ?? '',
              createdAt: json['created_at']?.toString() ?? '',
              updatedAt: json['updated_at']?.toString() ?? '',
            );
          }).toList();
        }

        // Parse personal identifications
        if (dataMap['personal_identifications'] != null) {
          List<dynamic> identificationsList = dataMap['personal_identifications'] as List<dynamic>;
          personalIdentifications.value = identificationsList.map((json) {
            return PersonalIdentification(
              id: json['_id']?.toString() ?? '',
              idType: json['id_type']?.toString() ?? '',
              expiryDate: json['expiry_date']?.toString() ?? '',
              documentFile: json['document_file']?.toString() ?? '',
              createdAt: json['created_at']?.toString() ?? '',
              updatedAt: json['updated_at']?.toString() ?? '',
            );
          }).toList();
        }

        // Parse professional service format (packages)
        if (dataMap['professional_service_format'] != null) {
          List<dynamic> packagesList = dataMap['professional_service_format'] as List<dynamic>;
          packages.value = packagesList.map((json) {
            // Extract both _id and service_format_id
            String? professionalServiceFormatIdValue = json['_id']?.toString() ?? json['id']?.toString();
            String? serviceFormatIdValue = json['service_format_id']?.toString() ?? json['_id']?.toString();

            final parsedPrice = _parsePackagePrice(json['price']);
            final isFree = parsedPrice == null;

            print('Service Format - _id: ${json['_id']}, service_format_id: ${json['service_format_id']}');
            print('  -> professional_service_format_id (_id): $professionalServiceFormatIdValue');
            print('  -> service_format_id: $serviceFormatIdValue');
            print('  -> price: ${json['price']}, isFree: $isFree');

            return ServicePackage(
              title: json['service_format_name']?.toString() ?? json['service_name']?.toString() ?? '',
              duration: json['duration_minutes']?.toString() ?? '',
              price: parsedPrice ?? 0.0,
              isFree: isFree,
              discount: json['offer_text']?.toString() ?? json['discount']?.toString(),
              service_format_date: json['service_format_date']?.toString(),
              serviceFormatId: serviceFormatIdValue, // service_format_id for summary screen
              professionalServiceFormatId: professionalServiceFormatIdValue, // _id for create-booking API
            );
          }).toList();

          // Also update therapist packages for compatibility
          therapist.value = Therapist(
            id: therapist.value.id,
            name: therapist.value.name,
            imageUrl: therapist.value.imageUrl,
            specialty: therapist.value.specialty,
            distance: therapist.value.distance,
            rating: therapist.value.rating,
            reviewCount: therapist.value.reviewCount,
            price: therapist.value.price,
            isFavorite: therapist.value.isFavorite,
            availability: therapist.value.availability,
            ratingsCount: therapist.value.ratingsCount,
            yearsExperience: therapist.value.yearsExperience,
            bookingsCount: therapist.value.bookingsCount,
            services: therapist.value.services,
            packages: packages,
          );
        }

        isLoading.value = false;

        print('========================================');
        print('Professional Details API Success:');
        print('Name: ${therapist.value.name}');
        print('Specialty: ${therapist.value.specialty}');
        print('Rating: ${therapist.value.rating}');
        print('Services Count: ${services.length}');
        print('Qualifications Count: ${qualifications.length}');
        print('Packages Count: ${packages.length}');
        print('========================================');
      } else {
        print('Professional Details API Error: $message');
        isLoading.value = false;
      }
    } catch (e) {
      print('Error parsing professional details response: $e');
      isLoading.value = false;
    }
  }

  void _handleProfessionalDetailsError(Exception exception) {
    print('Professional Details API Error: $exception');
    isLoading.value = false;
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  // Helper to change tab programmatically (if needed)
  void changeTab(int index) {
    tabController.animateTo(index);
  }

  Future<void> getPreferenceDetails() async {
    isGuest.value = _storageService?.readBool(SharePreferenceConst.isGuest) ?? false;
  }

  double? _parsePackagePrice(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return double.tryParse(trimmed);
    }
    return null;
  }
}

mixin z {
}

// Models for API response
class ServiceItem {
  final String serviceId;
  final String serviceName;
  final List<String> subServices;

  ServiceItem({
    required this.serviceId,
    required this.serviceName,
    required this.subServices,
  });
}

class Qualification {
  final String id;
  final String schoolOrUniversity;
  final String degreeOrCertificate;
  final String expiryDate;
  final String certificateFile;
  final String createdAt;
  final String updatedAt;

  Qualification({
    required this.id,
    required this.schoolOrUniversity,
    required this.degreeOrCertificate,
    required this.expiryDate,
    required this.certificateFile,
    required this.createdAt,
    required this.updatedAt,
  });
}

class PersonalIdentification {
  final String id;
  final String idType;
  final String expiryDate;
  final String documentFile;
  final String createdAt;
  final String updatedAt;

  PersonalIdentification({
    required this.id,
    required this.idType,
    required this.expiryDate,
    required this.documentFile,
    required this.createdAt,
    required this.updatedAt,
  });
}
