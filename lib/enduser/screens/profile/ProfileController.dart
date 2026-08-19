import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:verithrive_dev/enduser/screens/select_address/SelectAddressMapBinding.dart';
import 'package:verithrive_dev/enduser/screens/select_address/SelectAddressMapView.dart';
import 'package:verithrive_dev/enduser/screens/term_condition/TermsConditionBinding.dart';
import 'package:verithrive_dev/enduser/screens/term_condition/TermsView.dart';
import 'package:verithrive_dev/enduser/utils/common_dialog.dart';
import 'package:verithrive_dev/enduser/utils/camera_storage_permission_service.dart';
import 'package:verithrive_dev/enduser/utils/location_permission_service.dart';
import 'package:verithrive_dev/enduser/core/values/sharePrefrenceConst.dart';
import 'package:verithrive_dev/enduser/screens/message/socket_service.dart';
import 'package:verithrive_dev/select_user/select_user_binding.dart';
import 'package:verithrive_dev/select_user/select_user_view.dart';
import 'package:verithrive_dev/services/social_auth_service.dart';
import 'package:verithrive_dev/services/socket_service.dart' as prof_socket;
import 'package:verithrive_dev/services/notification_permission_service.dart';
import 'package:verithrive_dev/services/storage_service.dart';
import 'package:verithrive_dev/services/analytics_service.dart';

class ProfileController extends GetxController {
  final NotificationPermissionService _notificationPermissionService =
      NotificationPermissionService();
  StorageService? get _storageService =>
      Get.isRegistered<StorageService>() ? Get.find<StorageService>() : null;
  final formKey = GlobalKey<FormState>();
  final dobFieldKey = GlobalKey<FormFieldState<String>>();

  final fullNameController = TextEditingController();
  final dobController = TextEditingController();
  final postcodeController = TextEditingController();
  final addressController = TextEditingController();
  final postcodeFocusNode = FocusNode();
  final addressFocusNode = FocusNode();

  final selectedGender = ''.obs;
  final selectedAddress = ''.obs;
  final selectedPostcode = ''.obs;
  final selectedDob = Rxn<DateTime>();
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
  final SocialAuthService _socialAuthService = SocialAuthService();

  // Selected address data
  final selectedLatitude = Rxn<double>();
  final selectedLongitude = Rxn<double>();

  // Gender options
  final List<String> genderOptions = ['Male', 'Female', 'Prefer not to say'];

  // Validation error messages
  final genderError = RxString('');
  final addressError = RxString('');
  final postcodeError = RxString('');

  // Track if user clicked "enter manually" for postcode
  final isManualEntry = false.obs;
  final isManualAddress = false.obs;
  final isSocialLogin = false.obs;

  @override
  void onInit() {
    super.onInit();
    AnalyticsService.instance.logScreenView(
      screenName: 'ProfileView',
      screenClass: 'ProfileView',
      pageCategory: 'profile',
      elementLocation: 'view',
    );

    // Add text change listener to automatically capitalize first letter
    fullNameController.addListener(_capitalizeFullName);

    // Get current location and auto-fill address and postcode
    // getCurrentLocationAndFillAddress();

    _loadIsSocialLogin();
    _applySocialDataFromArguments(Get.arguments as Map<String, dynamic>?);
    _loadPersistedSocialData();
    _persistSocialFieldsToStorage();
  }

  @override
  void onReady() {
    super.onReady();
    _notificationPermissionService.ensurePermissionAfterFirstScreen();
  }

  void _loadIsSocialLogin() {
    final storage = _storageService;
    if (storage == null) return;
    isSocialLogin.value =
        storage.readBool(SharePreferenceConst.isSocialLogin) ?? false;
  }

  /// Social login: hide full name when pre-filled; show when empty (e.g. Apple hide email).
  bool get shouldShowFullNameField =>
      !isSocialLogin.value || fullNameController.text.trim().isEmpty;

  Future<void> onBackPressed() async {
    try {
      if (Get.isRegistered<EndUserSocketService>()) {
        final endUserSocket = Get.find<EndUserSocketService>();
        endUserSocket.disconnect();
        Get.delete<EndUserSocketService>();
      }

      if (Get.isRegistered<prof_socket.SocketService>()) {
        final professionalSocket = Get.find<prof_socket.SocketService>();
        professionalSocket.disconnect();
        Get.delete<prof_socket.SocketService>();
      }

      await _socialAuthService.signOutSocialProviders();

      final storage = _storageService;
      if (storage != null) {
        await storage.clearAllExcept(const [
          'professional_remember_me',
          'professional_saved_email',
          'professional_saved_password',
          SharePreferenceConst.rememberMe,
          SharePreferenceConst.savedEmail,
          SharePreferenceConst.savedPassword,
        ]);
      }
    } catch (_) {
      // Still navigate even if cleanup fails
    }

    Get.offAll(
      () => const SelectUserView(),
      binding: SelectUserBinding(),
    );
  }

  void _applySocialDataFromArguments(Map<String, dynamic>? arguments) {
    if (arguments == null || arguments.isEmpty) return;

    final fullName = arguments['fullName']?.toString().trim() ?? '';
    if (fullName.isNotEmpty) {
      fullNameController.text = fullName;
    }

    String profilePic = arguments['profilePicture']?.toString().trim() ?? '';
    if (profilePic.isEmpty) {
      profilePic = arguments['googleProfilePicture']?.toString().trim() ?? '';
    }
    if (profilePic.isNotEmpty) {
      profileImageUrl.value = profilePic;
    }

    if (arguments['profileImageFile'] is File) {
      profileImage.value = arguments['profileImageFile'] as File;
    }
  }

  /// Restore social pre-fill after app restart (splash opens profile without arguments).
  void _loadPersistedSocialData() {
    final storage = _storageService;
    if (storage == null) return;

    if (fullNameController.text.trim().isEmpty) {
      String fullName =
          storage.readString(SharePreferenceConst.socialFullName)?.trim() ?? '';
      if (fullName.isEmpty) {
        fullName = storage.readString('apple_user_name')?.trim() ?? '';
      }
      if (fullName.isEmpty) {
        fullName = _readFullNameFromStoredUserData(storage);
      }
      if (fullName.isNotEmpty) {
        fullNameController.text = fullName;
      }
    }

    if (profileImage.value == null && profileImageUrl.value.isEmpty) {
      String profilePic = storage
              .readString(SharePreferenceConst.socialProfilePicture)
              ?.trim() ??
          '';
      if (profilePic.isEmpty) {
        profilePic = _readProfilePictureFromStoredUserData(storage);
      }
      if (profilePic.isNotEmpty) {
        profileImageUrl.value = profilePic;
      }
    }
  }

  String _readFullNameFromStoredUserData(StorageService storage) {
    final userDataJson = storage.readString(SharePreferenceConst.userData);
    if (userDataJson == null || userDataJson.isEmpty) return '';
    try {
      final userData = jsonDecode(userDataJson) as Map<String, dynamic>;
      return userData['full_name']?.toString().trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  String _readProfilePictureFromStoredUserData(StorageService storage) {
    final userDataJson = storage.readString(SharePreferenceConst.userData);
    if (userDataJson == null || userDataJson.isEmpty) return '';
    try {
      final userData = jsonDecode(userDataJson) as Map<String, dynamic>;
      return userData['profile_picture']?.toString().trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _persistSocialFieldsToStorage() async {
    final storage = _storageService;
    if (storage == null) return;

    final isSocialLogin =
        storage.readBool(SharePreferenceConst.isSocialLogin) ?? false;
    if (!isSocialLogin) return;

    final fullName = fullNameController.text.trim();
    if (fullName.isNotEmpty) {
      await storage.writeString(SharePreferenceConst.socialFullName, fullName);
    }

    final profilePic = profileImageUrl.value.trim();
    if (profilePic.isNotEmpty) {
      await storage.writeString(
        SharePreferenceConst.socialProfilePicture,
        profilePic,
      );
    }
  }

  void _capitalizeFullName() {
    String text = fullNameController.text;
    if (text.isNotEmpty) {
      // Capitalize first letter and keep the rest as is (don't force lowercase)
      String capitalized =
          text.substring(0, 1).toUpperCase() + text.substring(1);

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
    if (isSocialLogin.value && !shouldShowFullNameField) return null;
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
    // FormField value can lag behind controller when date is set programmatically
    final dobText = (value == null || value.trim().isEmpty)
        ? dobController.text.trim()
        : value.trim();
    if (dobText.isEmpty) {
      return 'Please select your Date of Birth';
    }
    // Validate date format DD/MM/YYYY
    if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(dobText)) {
      return 'Please enter date in DD/MM/YYYY format';
    }

    // Check if user is 18+ years old
    if (selectedDob.value == null) {
      // Parse the date from the controller if selectedDob is not set
      try {
        List<String> parts = dobText.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          selectedDob.value = DateTime(year, month, day);
        }
      } catch (e) {
        return 'Invalid date format';
      }
    }

    if (selectedDob.value != null) {
      final now = DateTime.now();
      final age = now.year - selectedDob.value!.year;
      final monthDiff = now.month - selectedDob.value!.month;
      final dayDiff = now.day - selectedDob.value!.day;

      final actualAge =
          monthDiff < 0 || (monthDiff == 0 && dayDiff < 0) ? age - 1 : age;

      if (actualAge < 18) {
        return 'You must be 18 years old to use this app.';
      }
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

  String? validatePostcodeField() {
    final postcode = postcodeController.text.trim().isNotEmpty
        ? postcodeController.text.trim()
        : selectedPostcode.value.trim();
    return validatePostcode(postcode.isEmpty ? null : postcode);
  }

  Future<void> selectDateOfBirth(BuildContext context) async {
    // Use selected DOB if available, otherwise use current date minus 18 years
    final now = DateTime.now();
    final DateTime initialDate = selectedDob.value ??
        DateTime(now.year, now.month, now.day); // 18 years ago

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 0)), // Yesterday
      locale: const Locale('en', 'GB'), // UK locale for date picker
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
      selectedDob.value = picked;
      final formattedDob =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      dobController.text = formattedDob;
      // Sync FormField state — controller.text alone does not update the field value
      WidgetsBinding.instance.addPostFrameCallback((_) {
        dobFieldKey.currentState?.didChange(formattedDob);
        dobFieldKey.currentState?.validate();
      });
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
    postcodeError.value = '';

    // Validate all fields so every error is shown on Next
    final formValid = formKey.currentState!.validate();

    final genderValidationError = validateGender();
    if (genderValidationError != null) {
      genderError.value = genderValidationError;
    }

    final postcodeValidationError = validatePostcodeField();
    if (postcodeValidationError != null && !isManualEntry.value) {
      postcodeError.value = postcodeValidationError;
    }

    final addressValidationError = validateAddressField();
    if (addressValidationError != null) {
      addressError.value = addressValidationError;
    }

    if (!formValid ||
        genderError.value.isNotEmpty ||
        postcodeError.value.isNotEmpty ||
        addressError.value.isNotEmpty) {
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
    addressFocusNode.dispose();
    super.onClose();
  }

  Future<void> navigateToMapScreen() async {
    // First check if location permission is already granted
    // bool hasPermission =
    //     await _locationPermissionService.checkLocationPermissionStatus();

    // // If not granted, request permission
    // if (!hasPermission) {
    //   hasPermission =
    //       await _locationPermissionService.requestLocationPermission();
    // }

    // if (!hasPermission) {
    //   // Permission service already shows appropriate message/dialog
    //   return;
    // }

    // Prepare arguments for map screen
    final Map<String, dynamic> arguments = {
      'hideSelectButton': true
    }; // Hide Select Address button initially

    // If we have existing coordinates, pass them to map
    if (latitude.value != 0.0 && longitude.value != 0.0) {
      arguments['latitude'] = latitude.value;
      arguments['longitude'] = longitude.value;
      debugPrint(
          'Passing existing coordinates to map: lat=${latitude.value}, lng=${longitude.value}');
    }

    // If we have existing address, pass it to map
    if (selectedAddress.value.isNotEmpty) {
      arguments['existingAddress'] = selectedAddress.value;
      debugPrint('Passing existing address to map: ${selectedAddress.value}');
    }

    final result = await Get.to(
      () => SelectAddressMapView(),
      arguments: arguments,
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
        postcodeError.value = '';
      }
    }
  }

  /// Get current location and auto-fill address and postcode
  Future<void> getCurrentLocationAndFillAddress() async {
    try {
      // First check if permission is already granted
      // bool hasPermission =
      //     await _locationPermissionService.checkLocationPermissionStatus();

      // // If not granted, request permission
      // if (!hasPermission) {
      //   hasPermission =
      //       await _locationPermissionService.requestLocationPermission();
      // }

      // if (!hasPermission) {
      //   debugPrint('Location permission not granted');
      //   return;
      // }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        Get.snackbar(
          'Location Services',
          'Please enable location services to get your address automatically',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Get current position with timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Location request timed out');
        },
      );

      // Store coordinates
      selectedLatitude.value = position.latitude;
      selectedLongitude.value = position.longitude;
      latitude.value = position.latitude;
      longitude.value = position.longitude;

      // Reverse geocode to get address and postcode
      await reverseGeocodeAndFillFields(
        position.latitude,
        position.longitude,
      );
    } on TimeoutException catch (e) {
      debugPrint('Timeout getting current location: $e');
      Get.snackbar(
        'Location Timeout',
        'Getting location took too long. Please try selecting address manually.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      // Silently fail - user can manually select address
    }
  }

  /// Reverse geocode coordinates and fill address and postcode fields
  Future<void> reverseGeocodeAndFillFields(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final addressParts = <String>[];

        if (placemark.street != null && placemark.street!.isNotEmpty) {
          addressParts.add(placemark.street!);
        }
        if (placemark.subThoroughfare != null &&
            placemark.subThoroughfare!.isNotEmpty) {
          addressParts.insert(0, placemark.subThoroughfare!);
        }
        if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          addressParts.add(placemark.locality!);
        }
        if (placemark.postalCode != null && placemark.postalCode!.isNotEmpty) {
          // Auto-fill postcode only if not manually entered
          if (!isManualEntry.value) {
            // postcodeController.text = placemark.postalCode!;
            // selectedPostcode.value = placemark.postalCode!;
          }
          addressParts.add(placemark.postalCode!);
        }
        if (placemark.country != null && placemark.country!.isNotEmpty) {
          addressParts.add(placemark.country!);
        }

        // Auto-fill address
        final fullAddress = addressParts.join(', ');
        // addressController.text = fullAddress;
        // selectedAddress.value = fullAddress;
        addressError.value = ''; // Clear error when address is filled
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
    }
  }

  void enterManually() {
    // Toggle manual entry mode for postcode
    isManualEntry.value = !isManualEntry.value;
    // Also enable manual address when manual entry is enabled
    if (isManualEntry.value) {
      isManualAddress.value = true;
      // Focus address field when manual mode is enabled
      Future.delayed(Duration(milliseconds: 100), () {
        addressFocusNode.requestFocus();
      });
    }
    // If toggling back to non-editable mode, sync selectedPostcode with controller text
    if (!isManualEntry.value && postcodeController.text.isNotEmpty) {
      selectedPostcode.value = postcodeController.text;
    }
  }
}
