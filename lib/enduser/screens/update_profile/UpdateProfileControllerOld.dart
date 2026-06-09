import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:verithrive_dev/enduser/screens/select_address/SelectAddressMapBinding.dart';
import 'package:verithrive_dev/enduser/screens/select_address/SelectAddressMapView.dart';
import '../../utils/app_colors.dart';
import '../../core/base/base_controller.dart';
import '../../data/repository/project_repository.dart';
import '../../network/exceptions/base_exception.dart';
import '../../utils/api_services.dart';
import '../../utils/common_dialog.dart';
import '../../routes/app_routes.dart';
import '../../utils/camera_storage_permission_service.dart';
import '../../core/values/sharePrefrenceConst.dart';
import 'package:verithrive_dev/services/storage_service.dart';

class UpdateProfileController extends BaseController {
  final ProjectRepository _repository =
      Get.find(tag: (ProjectRepository).toString());
  final StorageService _storageService = Get.find<StorageService>();

  final formKey = GlobalKey<FormState>();

  final fullNameController = TextEditingController();
  final dobController = TextEditingController();
  final postcodeController = TextEditingController();
  final postcodeFocusNode = FocusNode();

  final selectedGender = ''.obs;
  final selectedAddress = ''.obs;
  final selectedPostcode = ''.obs;
  final profileImage = Rx<File?>(null);
  final profileImageUrl = RxString(''); // For network image URL
  final isProfilePictureRemoved =
      false.obs; // Track if user explicitly removed the picture
  final isLoading = false.obs;
  final latitude = 0.0.obs;
  final longitude = 0.0.obs;

  final ImagePicker _picker = ImagePicker();
  final CameraStoragePermissionService _cameraStoragePermissionService =
      CameraStoragePermissionService();

  // Selected address data
  final selectedLatitude = Rxn<double>();
  final selectedLongitude = Rxn<double>();

  // Gender options
  final List<String> genderOptions = ['Male', 'Female', 'Prefer not to say'];

  // Marketing preferences
  final marketingOptions = ['Yes', 'No'];
  final selectedMarketingPreference = ''.obs;

  // Validation error messages
  final genderError = RxString('');
  final addressError = RxString('');

  // Track if user clicked "enter manually" for postcode
  final isManualEntry = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPersonalDetails();
  }

  // Fetch personal details from API
  void fetchPersonalDetails() {
    var service = _repository.sendGetApiNoParamRequest(get_personal_details);

    callDataService(
      service,
      onSuccess: _handleGetPersonalDetailsSuccess,
      onError: handleOnError,
      isShowLoading: true,
    );
  }

  Future<void> _handleGetPersonalDetailsSuccess(dynamic baseResponse) async {
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

      if (success == true && responseData['data'] != null) {
        Map<String, dynamic> data =
            responseData['data'] as Map<String, dynamic>;

        // Check if user is from social login and use social data if API doesn't have full_name or profile_picture
        bool isSocialLogin =
            _storageService.readBool(SharePreferenceConst.isSocialLogin) ??
                false;

        // Populate form fields
        if (data['full_name'] != null &&
            data['full_name'].toString().isNotEmpty) {
          fullNameController.text = data['full_name'].toString();
        } else if (isSocialLogin) {
          // Use social full name if API doesn't have it
          String socialFullName =
              _storageService.readString(SharePreferenceConst.socialFullName) ??
                  '';
          if (socialFullName.isNotEmpty) {
            fullNameController.text = socialFullName;
          }
        }

        if (data['dob'] != null) {
          // Convert from YYYY-MM-DD to DD/MM/YYYY
          String dobString = data['dob'].toString();
          try {
            DateTime dobDate = DateTime.parse(dobString);
            dobController.text =
                '${dobDate.day.toString().padLeft(2, '0')}/${dobDate.month.toString().padLeft(2, '0')}/${dobDate.year}';
          } catch (e) {
            print('Error parsing DOB: $e');
          }
        }

        if (data['gender'] != null) {
          String gender = data['gender'].toString();
          // Handle special case for "prefer_not_to_say"
          if (gender.toLowerCase() == 'prefer_not_to_say') {
            selectedGender.value = 'Prefer not to say';
          } else if (gender.isNotEmpty) {
            // Capitalize first letter for other genders
            selectedGender.value =
                gender[0].toUpperCase() + gender.substring(1).toLowerCase();
          } else {
            selectedGender.value = '';
          }
        }

        // Populate marketing preference
        if (data['opt_status'] != null) {
          selectedMarketingPreference.value =
              (data['opt_status'] == 1 || data['opt_status'] == true)
                  ? 'Yes'
                  : 'No';
        }

        if (data['postcode'] != null) {
          postcodeController.text = data['postcode'].toString();
          selectedPostcode.value = data['postcode'].toString();
        }

        if (data['address'] != null) {
          selectedAddress.value = data['address'].toString();
        }

        if (data['latitude'] != null) {
          latitude.value = (data['latitude'] is num)
              ? (data['latitude'] as num).toDouble()
              : double.tryParse(data['latitude'].toString()) ?? 0.0;
          selectedLatitude.value = latitude.value;
        }

        if (data['longitude'] != null) {
          longitude.value = (data['longitude'] is num)
              ? (data['longitude'] as num).toDouble()
              : double.tryParse(data['longitude'].toString()) ?? 0.0;
          selectedLongitude.value = longitude.value;
        }

        if (data['profile_picture'] != null &&
            data['profile_picture'].toString().isNotEmpty) {
          profileImageUrl.value = data['profile_picture'].toString();
          isProfilePictureRemoved.value =
              false; // Reset removal flag when loading existing picture
        } else if (isSocialLogin) {
          // Use social profile picture if API doesn't have it or returns empty string
          String socialProfilePicture = _storageService
                  .readString(SharePreferenceConst.socialProfilePicture) ??
              '';
          if (socialProfilePicture.isNotEmpty) {
            profileImageUrl.value = socialProfilePicture;
            isProfilePictureRemoved.value = false;
          }
        } else {
          // If no picture in API response, reset the flag
          isProfilePictureRemoved.value = false;
        }
      }
    } catch (e) {
      showResponseDialog(
        message: "Error loading profile data: $e",
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    }
  }

  String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  String? validateDOB(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date of birth is required';
    }
    // Validate date format DD/MM/YYYY
    if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value)) {
      return 'Please enter date in DD/MM/YYYY format';
    }
    return null;
  }

  String? validatePostcode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Postcode is required';
    }
    if (value.length < 5) {
      return 'Postcode must be at least 5 characters';
    }
    return null;
  }

  String? validateGender() {
    if (selectedGender.value.isEmpty) {
      return 'Gender is required';
    }
    return null;
  }

  String? validateAddressField() {
    if (selectedAddress.value.isEmpty) {
      return 'Address is required';
    }
    if (selectedAddress.value.length < 10) {
      return 'Address must be at least 10 characters';
    }
    return null;
  }

  Future<void> selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      dobController.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  // Convert DOB from DD/MM/YYYY to YYYY-MM-DD format
  String? getFormattedDOB() {
    if (dobController.text.isEmpty) return null;
    try {
      List<String> parts = dobController.text.split('/');
      if (parts.length == 3) {
        return '${parts[2]}-${parts[1]}-${parts[0]}';
      }
    } catch (e) {
      print('Error formatting DOB: $e');
    }
    return null;
  }

  // Convert gender to lowercase for API
  String? getFormattedGender() {
    if (selectedGender.value.isEmpty) return null;
    return selectedGender.value.toLowerCase();
  }

  void selectGender(String gender) {
    selectedGender.value = gender;
    genderError.value = ''; // Clear error when gender is selected
    Get.back();
  }

  void setMarketingPreference(String preference) {
    selectedMarketingPreference.value = preference;
    Get.back();
  }

  void showMarketingInfo() {
    Get.dialog(
      AlertDialog(
        title: const Text('Marketing Preferences'),
        content: const Text(
          'Marketing emails from VERITHRIVE to keep you up to date about latest offers and trends.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void openMarketingBottomSheet() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Marketing Preference',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            ...marketingOptions.map((option) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(option, style: TextStyle(fontSize: 16)),
                trailing: Obx(() => selectedMarketingPreference.value == option
                    ? Icon(Icons.check, color: AppColors.primaryColor)
                    : SizedBox.shrink()),
                onTap: () => setMarketingPreference(option),
              );
            }).toList(),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void openGenderBottomSheet() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Gender',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            ...genderOptions.map((gender) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(gender, style: TextStyle(fontSize: 16)),
                trailing: Obx(() => selectedGender.value == gender
                    ? Icon(Icons.check, color: AppColors.primaryColor)
                    : SizedBox.shrink()),
                onTap: () => selectGender(gender),
              );
            }).toList(),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> selectAddress() async {
    // Navigate to map screen to select address
    await navigateToMapScreen();
  }

  Future<void> navigateToMapScreen() async {
    final result = await Get.to(
      () => SelectAddressMapView(),
      binding: SelectAddressMapBinding(),
    );
    if (result != null && result is Map<String, dynamic>) {
      // Update latitude and longitude
      selectedLatitude.value = result['latitude'] as double?;
      selectedLongitude.value = result['longitude'] as double?;

      // Update latitude and longitude for API calls
      if (result['latitude'] != null) {
        latitude.value = result['latitude'] as double;
      }
      if (result['longitude'] != null) {
        longitude.value = result['longitude'] as double;
      }

      // Set address from map selection
      final address = result['address'] as String? ?? '';
      if (address.isNotEmpty) {
        selectedAddress.value = address;
        addressError.value = ''; // Clear error when address is selected
      }

      // Set postcode from map selection
      if (result['postcode'] != null &&
          result['postcode'].toString().isNotEmpty) {
        final postcode = result['postcode'] as String;
        postcodeController.text = postcode;
        selectedPostcode.value = postcode;
      }
    }
  }

  void enterManually() {
    // Toggle manual entry mode for postcode
    isManualEntry.value = !isManualEntry.value;

    // If toggling back to non-editable mode, sync selectedPostcode with controller text
    if (!isManualEntry.value && postcodeController.text.isNotEmpty) {
      selectedPostcode.value = postcodeController.text;
    } else if (isManualEntry.value) {
      // When field becomes editable, focus it after a short delay to ensure widget is built
      Future.delayed(Duration(milliseconds: 100), () {
        postcodeFocusNode.requestFocus();
      });
    }
  }

  Future<void> pickProfileImage() async {
    // Request storage permission using CameraStoragePermissionService
    bool hasPermission =
        await _cameraStoragePermissionService.requestStoragePermission();
    if (!hasPermission) {
      return; // Permission service handles the error messages
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        profileImage.value = File(image.path);
        profileImageUrl.value = ''; // Clear URL when new image is selected
        isProfilePictureRemoved.value =
            false; // Reset removal flag when new image is selected
      }
    } catch (e) {
      showResponseDialog(
        message: 'Failed to pick image: $e',
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    }
  }

  Future<void> takePhoto() async {
    // Request camera permission using CameraStoragePermissionService
    bool hasPermission =
        await _cameraStoragePermissionService.requestCameraPermission();
    if (!hasPermission) {
      return; // Permission service handles the error messages
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        profileImage.value = File(image.path);
        profileImageUrl.value = ''; // Clear URL when new image is selected
        isProfilePictureRemoved.value =
            false; // Reset removal flag when new image is selected
      }
    } catch (e) {
      showResponseDialog(
        message: 'Failed to take photo: $e',
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    }
  }

  void showImagePickerOptions() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Upload Profile Picture',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColors.primaryColor),
              title: Text('Choose from gallery'),
              onTap: () {
                Get.back();
                pickProfileImage();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.primaryColor),
              title: Text('Take a photo'),
              onTap: () {
                Get.back();
                takePhoto();
              },
            ),
            if (profileImage.value != null || profileImageUrl.value.isNotEmpty)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Remove photo'),
                onTap: () {
                  Get.back();
                  profileImage.value = null;
                  profileImageUrl.value = '';
                  isProfilePictureRemoved.value =
                      true; // Mark that picture should be removed
                },
              ),
          ],
        ),
      ),
    );
  }

  void updateProfile() {
    // Clear previous errors
    genderError.value = '';
    addressError.value = '';

    // Validate form fields
    if (!formKey.currentState!.validate()) {
      return;
    }

    // Validate gender
    final genderValidationError = validateGender();
    if (genderValidationError != null) {
      genderError.value = genderValidationError;
      return;
    }

    // Validate address
    final addressValidationError = validateAddressField();
    if (addressValidationError != null) {
      addressError.value = addressValidationError;
      return;
    }

    isLoading.value = true;
    callUpdatePersonalDetailsService();
  }

  void callUpdatePersonalDetailsService() {
    Map<String, dynamic> toJson() {
      final Map<String, dynamic> data = <String, dynamic>{};
      data['full_name'] = fullNameController.text.trim();
      data['dob'] = getFormattedDOB() ?? '';
      //data['gender'] = getFormattedGender() ?? '';
      data['gender'] = (getFormattedGender() == "prefer not to say")
          ? "prefer_not_to_say"
          : getFormattedGender() ?? '';
      data['postcode'] = postcodeController.text.trim();
      data['address'] = selectedAddress.value;
      data['latitude'] = latitude.value;
      data['longitude'] = longitude.value;
      data['opt_status'] = selectedMarketingPreference.value == 'Yes' ? 1 : 0;
      data['is_term_condition'] = true;
      data['is_update'] = true;

      // If picture was explicitly removed, send empty string to remove it from API
      if (isProfilePictureRemoved.value) {
        data['profile_picture'] = '';
      }
      // Note: profile_picture will be added as file in multipart only if new image is selected
      return data;
    }

    // Check if a new image is selected
    // Only use multipart request if a new image file is selected
    // If profileImage.value is null, use regular PUT request without image
    if (profileImage.value != null) {
      // New image selected - use multipart request with image
      var service = _repository.sendPutMultipartApiRequest(
        toJson,
        update_personal_details,
        true, // isToken = true
        imageFile: profileImage.value,
        imageFieldName: 'profile_picture',
      );

      callDataService(
        service,
        onSuccess: _handleUpdatePersonalDetailsResponseSuccess,
        onError: handleOnError,
        isShowLoading: true,
      );
    } else {
      // No new image selected - use regular PUT request
      // If picture was removed, profile_picture: '' will be included in the request
      var service = _repository.sendPutApiRequest(
        toJson,
        update_personal_details,
        true, // isToken = true
      );

      callDataService(
        service,
        onSuccess: _handleUpdatePersonalDetailsResponseSuccess,
        onError: handleOnError,
        isShowLoading: true,
      );
    }
  }

  Future<void> _handleUpdatePersonalDetailsResponseSuccess(
      dynamic baseResponse) async {
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
      String message =
          responseData['message'] ?? 'Profile updated successfully';

      if (success == true) {
        // Reset removal flag after successful update
        if (isProfilePictureRemoved.value) {
          profileImageUrl.value = ''; // Clear the URL since picture was removed
          isProfilePictureRemoved.value = false; // Reset the flag
        }

        showResponseDialog(
          message: message,
          title: 'Success',
          isError: false,
          showButton: true,
          onOkPressed: () {
            Get.back();
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

  @override
  void onClose() {
    fullNameController.dispose();
    dobController.dispose();
    postcodeController.dispose();
    postcodeFocusNode.dispose();
    super.onClose();
  }
}
