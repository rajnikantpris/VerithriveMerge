import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:verithrive_dev/enduser/routes/app_routes.dart';
import 'package:verithrive_dev/enduser/screens/select_address/SelectAddressMapBinding.dart';
import 'package:verithrive_dev/enduser/screens/select_address/SelectAddressMapView.dart';
import 'package:verithrive_dev/enduser/screens/term_condition/TermsConditionBinding.dart';
import 'package:verithrive_dev/enduser/screens/term_condition/TermsView.dart';
import 'package:verithrive_dev/enduser/utils/common_dialog.dart';
import 'package:verithrive_dev/enduser/utils/camera_storage_permission_service.dart';
import 'package:verithrive_dev/enduser/utils/location_permission_service.dart';

class ProfileController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final fullNameController = TextEditingController();
  final dobController = TextEditingController();
  final postcodeController = TextEditingController();
  final addressController = TextEditingController();
  final postcodeFocusNode = FocusNode();

  final selectedGender = ''.obs;
  final selectedAddress = ''.obs;
  final selectedPostcode = ''.obs;
  final profileImage = Rx<File?>(null);
  final profileImageUrl = RxString(''); // For network images from social login
  final isLoading = false.obs;
  final latitude = 0.0.obs;
  final longitude = 0.0.obs;

  final ImagePicker _picker = ImagePicker();
  final CameraStoragePermissionService _cameraStoragePermissionService =
      CameraStoragePermissionService();
  final LocationPermissionService _locationPermissionService =
      LocationPermissionService();

  // Selected address data
  final selectedLatitude = Rxn<double>();
  final selectedLongitude = Rxn<double>();

  // Gender options
  final List<String> genderOptions = ['Male', 'Female', 'Prefer not to say'];

  // Validation error messages
  final genderError = RxString('');
  final addressError = RxString('');

  // Track if user clicked "enter manually" for postcode
  final isManualEntry = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Add text change listener to automatically capitalize first letter
    fullNameController.addListener(_capitalizeFullName);

    // Ask for location permission when profile screen opens
    // Fire and forget; dialog and system prompt are handled by the service
    _locationPermissionService.requestLocationPermission();

    // Check if social data was passed from login
    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments != null && arguments!.isNotEmpty) {
      // Use social data passed from login screen
      if (arguments!['fullName'] != null &&
          arguments!['fullName'].toString().isNotEmpty) {
        fullNameController.text = arguments!['fullName'].toString();
        print(
            "Profile screen - Social full name: ${arguments!['fullName'].toString()}");
      }

      // Set profile image from social data
      String profilePic = arguments!['profilePicture']?.toString() ?? '';
      if (profilePic.isEmpty && arguments!['googleProfilePicture'] != null) {
        profilePic = arguments!['googleProfilePicture'].toString();
      }
      if (profilePic.isNotEmpty) {
        // Set network image URL for social login
        profileImageUrl.value = profilePic;
        print("Profile screen - Social profile picture: $profilePic");
      }

      // Store the profileImageFile if passed from login
      if (arguments!['profileImageFile'] != null &&
          arguments!['profileImageFile'] is File) {
        profileImage.value = arguments!['profileImageFile'] as File;
        print(
            "Profile screen - Received profileImageFile: ${profileImage.value?.path}");
      }
    }
  }

  void _capitalizeFullName() {
    String text = fullNameController.text;
    if (text.isNotEmpty) {
      // Capitalize first letter and keep the rest as is (don't force lowercase)
      String capitalized = text.substring(0, 1).toUpperCase() + text.substring(1);
      
      // Only update if the text is different to prevent infinite loops
      if (text != capitalized) {
        // Remove listener temporarily to prevent infinite loop
        fullNameController.removeListener(_capitalizeFullName);
        fullNameController.text = capitalized;
        // Add listener back
        fullNameController.addListener(_capitalizeFullName);
        
        // Move cursor to the end
        fullNameController.selection = TextSelection.fromPosition(
          TextPosition(offset: capitalized.length),
        );
      }
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

  String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    if (value.length < 10) {
      return 'Address must be at least 10 characters';
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
    final address = selectedAddress.value.isNotEmpty
        ? selectedAddress.value
        : addressController.text.trim();
    if (address.isEmpty) {
      return 'Address is required';
    }
    if (address.length < 10) {
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
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00BFA5),
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

  void openGenderBottomSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
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
            const Text(
              'Select Gender',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            ...genderOptions.map((gender) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  gender,
                  style: const TextStyle(fontSize: 16),
                ),
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
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Upload Profile Picture',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: Color(0xFF00BFA5)),
              title: const Text('Choose from gallery'),
              onTap: () {
                Get.back();
                pickProfileImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF00BFA5)),
              title: const Text('Take a photo'),
              onTap: () {
                Get.back();
                takePhoto();
              },
            ),
            if (profileImage.value != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove photo'),
                onTap: () {
                  Get.back();
                  profileImage.value = null;
                },
              ),
          ],
        ),
      ),
    );
  }

  void saveProfile() {
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

    // Store address if entered manually
    if (addressController.text.isNotEmpty && selectedAddress.value.isEmpty) {
      selectedAddress.value = addressController.text;
    }

    // Prepare data to pass to terms screen including profileImageFile
    Map<String, dynamic> profileData = getProfileData();
    profileData['profileImageFile'] = profileImage.value; // Add the File object

    // Navigate to terms screen with profile data
    Get.to(
      () => TermsView(),
      binding: TermsConditionsBinding(),
      arguments: profileData,
    );
    // Note: Error dialogs should only be shown for API response errors/success
  }

  // Get profile data as Map for API call
  Map<String, dynamic> getProfileData() {
    return {
      'full_name': fullNameController.text.trim(),
      'dob': getFormattedDOB() ?? '',
      'gender': (getFormattedGender() == "prefer not to say")
          ? "prefer_not_to_say"
          : getFormattedGender() ?? '',
      'postcode': postcodeController.text.trim(),
      'address': selectedAddress.value.isNotEmpty
          ? selectedAddress.value
          : addressController.text.trim(),
      'latitude': latitude.value,
      'longitude': longitude.value,
      'profile_picture': profileImage.value?.path ?? '',
    };
  }

  /// Request location permission using the common service
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestLocationPermission() async {
    return await _locationPermissionService.requestLocationPermission();
  }

  /// Check location permission status using the common service
  /// Returns true if permission is granted, false otherwise
  Future<bool> checkLocationPermissionStatus() async {
    return await _locationPermissionService.checkLocationPermissionStatus();
  }

  @override
  void onClose() {
    fullNameController.dispose();
    dobController.dispose();
    postcodeController.dispose();
    addressController.dispose();
    postcodeFocusNode.dispose();
    super.onClose();
  }

  Future<void> navigateToMapScreen() async {
    // First check if location permission is already granted
    bool hasPermission =
        await _locationPermissionService.checkLocationPermissionStatus();

    // If not granted, request permission
    if (!hasPermission) {
      hasPermission =
          await _locationPermissionService.requestLocationPermission();
    }

    if (!hasPermission) {
      // Permission service already shows appropriate message/dialog
      return;
    }

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
        addressController.text = address;
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
}
