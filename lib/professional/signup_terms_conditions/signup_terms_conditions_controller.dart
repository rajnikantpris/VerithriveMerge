import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../api/api_response.dart';
import '../../api/user_api_service.dart';
import '../../common/base_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/storage_service.dart';

class SignupTermsConditionsController extends BaseController {
  /// Personal details passed from previous screen
  late final String fullName;
  late final String dob;
  late final String gender;
  late final String postcode;
  late final String address;
  late final double? latitude;
  late final double? longitude;
  late final String? profileImagePath;
  late final String? socialProfileImageUrl;
  late final String? promoCode;

  /// Loaded terms & conditions text
  final termsText = ''.obs;
  final isContentLoading = true.obs;
  late final WebViewController webViewController;

  final marketingOptIn = false.obs;
  final termsAndConditionsAccepted = false.obs;
  final _userApi = Get.find<UserApiService>();
  final StorageService? _storageService =
      Get.isRegistered<StorageService>() ? Get.find<StorageService>() : null;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    fullName = (args['fullName'] ?? '') as String;
    dob = (args['dob'] ?? '') as String;
    gender = (args['gender'] ?? '') as String;
    postcode = (args['postcode'] ?? '') as String;
    address = (args['address'] ?? '') as String;
    latitude = args['latitude'] as double?;
    longitude = args['longitude'] as double?;
    profileImagePath = args['profileImagePath'] as String?;
    final socialUrl = args['socialProfileImageUrl'] as String?;
    socialProfileImageUrl =
        (socialUrl != null && socialUrl.isNotEmpty) ? socialUrl : null;
    promoCode = args['promoCode'] as String?;

    _initializeWebViewController();
  }

  void _initializeWebViewController() {
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            isContentLoading.value = true;
          },
          onPageFinished: (String url) {
            isContentLoading.value = false;
          },
        ),
      )
      ..loadRequest(Uri.parse('${UserApiService.baseUrl}get-static-page/webview?type=professional_terms_and_conditions'));
  }

  void toggleMarketingOptIn(bool? value) {
    marketingOptIn.value = value ?? false;
  }

  void toggleTermsAndConditions(bool? value) {
    termsAndConditionsAccepted.value = value ?? false;
  }

  Future<void> onAccept() async {
    await callDataService<ApiResponse<dynamic>>(
      _userApi.updatePersonalDetails(
        fullName: fullName,
        dob: dob,
        gender: gender,
        postcode: postcode,
        address: address,
        isTermCondition: true,
        latitude: latitude,
        longitude: longitude,
        optStatus: marketingOptIn.value ? 1 : 0,
        // Prefer manually selected image; fall back to social URL if available
        profileImagePath: profileImagePath ?? socialProfileImageUrl,
        promoCode: (promoCode != null && promoCode!.isNotEmpty) ? promoCode : null,
      ),
      showLoader: true,
      onSuccess: (response) async {
        if (response.success) {
          // Extract and save user data from response
          // Response structure: {success: true, data: {user: {...}}}
          final storage = _storageService;
          if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;

            // Extract user object
            if (data['user'] is Map<String, dynamic>) {
              final user = data['user'] as Map<String, dynamic>;

              // Extract and save is_personal_details
              final isPersonalDetails = user['is_personal_details'] as bool?;
              if (isPersonalDetails != null && storage != null) {
                await storage.writeBool(
                    'is_personal_details', isPersonalDetails);
              }

              // Extract and save is_term_condition
              final isTermCondition = user['is_term_condition'] as bool?;
              if (isTermCondition != null && storage != null) {
                await storage.writeBool('is_term_condition', isTermCondition);
              }

              // Extract and save is_profile_created
              final isProfileCreated = user['is_profile_created'] as bool?;
              if (isProfileCreated != null && storage != null) {
                await storage.writeBool('is_profile_created', isProfileCreated);
              }
            }
          }

          Get.toNamed(Routes.signupProfileWizard, arguments: {
            'fullName': fullName,
            'dob': dob,
            'gender': gender,
            'postcode': postcode,
            'address': address,
            'latitude': latitude,
            'longitude': longitude,
            'profileImagePath': profileImagePath,
            'marketingOptIn': marketingOptIn.value,
            'promoCode': (promoCode != null && promoCode!.isNotEmpty) ? promoCode : null,
          });
        } else {
          Get.snackbar(
            'Error',
            response.errorMessage,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      },
    );
  }
}
