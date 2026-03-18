import 'dart:io';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:verithrive_dev/enduser/core/base/base_controller.dart';
import 'package:verithrive_dev/enduser/screens/main/MainScreen.dart';
import 'package:verithrive_dev/enduser/utils/common_dialog.dart';
import '../../routes/app_routes.dart';
import '../../data/repository/project_repository.dart';
import '../../network/exceptions/base_exception.dart';
import '../../utils/api_services.dart';
import '../../core/values/sharePrefrenceConst.dart';
import '../profile/ProfileController.dart';
import 'package:verithrive_dev/services/storage_service.dart';

class TermsController extends BaseController {
  final ProjectRepository _repository = Get.find(tag: (ProjectRepository).toString());
  final StorageService _storageService = Get.find<StorageService>();
  
  final isAccepted = false.obs;
  final termsAndConditionsAccepted = false.obs;
  final isLoading = false.obs;
  final isContentLoading = true.obs;
  late final WebViewController webViewController;

  @override
  void onInit() {
    super.onInit();
    // fetchTermsAndConditions(); // We'll use WebView instead
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
      ..loadRequest(Uri.parse('${baseURL}get-static-page/webview?type=normal_terms_and_conditions'));
  }

  void toggleAcceptance(bool? value) {
    isAccepted.value = value ?? false;
  }

  void toggleTermsAndConditions(bool? value) {
    termsAndConditionsAccepted.value = value ?? false;
  }

  void acceptAndContinue() {
    if (!termsAndConditionsAccepted.value) {
      showResponseDialog(
        message: 'Please accept the terms and conditions to continue',
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
      return;
    }

    // Get profile data from arguments passed from Profile screen
    Map<String, dynamic>? profileData;
    File? profileImageFile;
    
    try {
      final arguments = Get.arguments as Map<String, dynamic>?;
      if (arguments != null) {
        profileData = Map<String, dynamic>.from(arguments);
        profileImageFile = arguments['profileImageFile'] as File?;
        print("Terms screen - Received profileImageFile: ${profileImageFile?.path}");
      }
    } catch (e) {
      print('Error parsing arguments: $e');
    }

    // Fallback to ProfileController if no arguments passed
    if (profileData == null) {
      ProfileController? profileController;
      try {
        profileController = Get.find<ProfileController>();
        profileData = profileController.getProfileData();
        profileImageFile = profileController.profileImage.value;
      } catch (e) {
        showResponseDialog(
          message: 'Profile data not found. Please go back and fill the profile form.',
          title: 'Error',
          isError: true,
          showButton: true,
          onOkPressed: () {
            Get.back();
          },
        );
        return;
      }
    }

    // Validate profile data
    if (profileData['full_name'] == null || profileData['full_name'].toString().isEmpty) {
      showResponseDialog(
        message: 'Please fill all required fields in profile',
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {
          Get.back();
        },
      );
      return;
    }

    isLoading.value = true;
    callPersonalDetailsService(profileData, profileImageFile);
  }

  void callPersonalDetailsService(Map<String, dynamic> profileData, File? profileImage) {
    Map<String, dynamic> toJson() {
      final Map<String, dynamic> data = <String, dynamic>{};
      data['full_name'] = profileData['full_name'] ?? '';
      data['dob'] = profileData['dob'] ?? '';
      data['gender'] = profileData['gender'] ?? '';
      data['postcode'] = profileData['postcode'] ?? '';
      data['address'] = profileData['address'] ?? '';
      data['latitude'] = profileData['latitude'] ?? 0.0;
      data['longitude'] = profileData['longitude'] ?? 0.0;
      //data['is_term_condition'] = isAccepted.value ? true : false;
      data['marketingOptIn'] = isAccepted.value ? true : false;
      // Note: profile_picture will be added as file in multipart
      return data;
    }
    
    var service = _repository.sendPutMultipartApiRequest(
      toJson,
      update_personal_details,
      true, // isToken = true
      imageFile: profileImage,
      imageFieldName: 'profile_picture',
    );

    callDataService(
      service,
      onSuccess: _handlePersonalDetailsResponseSuccess,
      onError: handleOnError,
      isShowLoading: true,
    );
  }

  Future<void> _handlePersonalDetailsResponseSuccess(dynamic baseResponse) async {
    isLoading.value = false;

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
      String message = responseData['message'] ?? 'Profile saved successfully';
      
      if (success == true) {
        // Update preferences
        await _storageService.writeBool(SharePreferenceConst.isTermCondition, true);
        await _storageService.writeBool(SharePreferenceConst.isPersonalDetails, true);
        await _storageService.writeBool(SharePreferenceConst.isNotification, isAccepted.value);
        
        showResponseDialog(
          message: message,
          title: 'Success',
          isError: false,
          showButton: true,
          onOkPressed: () {
            // Navigate to main screen after accepting terms
            Get.offAll(
              () => MainScreen(),
            );
          },
        );
      } else {
        showResponseDialog(
          message: message,
          title: 'Error',
          isError: true,
          showButton: true,
          onOkPressed: () {},
        );
      }
    } catch (e) {
      showResponseDialog(
        message: "Error processing response: $e",
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    }
  }

  void handleOnError(dynamic e) {
    isLoading.value = false;

    if (e is BaseException) {
      showResponseDialog(
        message: e.message,
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    } else {
      showResponseDialog(
        message: "An error occurred. Please try again.",
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    }
  }
}
