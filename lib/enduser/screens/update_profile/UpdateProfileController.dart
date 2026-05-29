import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:verithrive_dev/enduser/screens/select_address/SelectAddressMapBinding.dart';
import 'package:verithrive_dev/enduser/screens/select_address/SelectAddressMapView.dart';
import '../../utils/app_colors.dart';
import '../../core/base/base_controller.dart';
import '../../data/repository/project_repository.dart';
import '../../network/exceptions/base_exception.dart';
import '../../utils/api_services.dart';
import '../../utils/common_dialog.dart';
import 'package:verithrive_dev/services/analytics_service.dart';
import 'package:verithrive_dev/enduser/utils/camera_storage_permission_service.dart';
import 'package:verithrive_dev/enduser/utils/location_permission_service.dart';
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
  final addressController = TextEditingController();
  final postcodeFocusNode = FocusNode();
  final addressFocusNode = FocusNode();

  final selectedGender = ''.obs;
  final selectedAddress = ''.obs;
  final selectedPostcode = ''.obs;
  final selectedDob = Rxn<DateTime>();
  final profileImage = Rx<File?>(null);
  final profileImageUrl = RxString('');
  final isProfilePictureRemoved = false.obs;
  final isLoading = false.obs;
  final isDataLoading = true.obs;
  final latitude = 0.0.obs;
  final longitude = 0.0.obs;

  final ImagePicker _picker = ImagePicker();
  final CameraStoragePermissionService _cameraStoragePermissionService =
      CameraStoragePermissionService();
  final LocationPermissionService _locationPermissionService =
      LocationPermissionService();

  bool _isPicking = false; // Guard against double picker calls

  final selectedLatitude = Rxn<double>();
  final selectedLongitude = Rxn<double>();

  final List<String> genderOptions = ['Male', 'Female', 'Prefer not to say'];

  final marketingOptions = ['Opted In', 'Opted Out'];
  final selectedMarketingPreference = ''.obs;

  final genderError = RxString('');
  final addressError = RxString('');

  final isManualEntry = false.obs;
  final isManualAddress = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Add text change listener to automatically capitalize first letter
    fullNameController.addListener(_capitalizeFullName);

    // Fetch personal details first, then initialize location based on profile data
    fetchPersonalDetails();
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

        bool isSocialLogin =
            _storageService.readBool(SharePreferenceConst.isSocialLogin) ??
                false;

        if (data['full_name'] != null &&
            data['full_name'].toString().isNotEmpty) {
          fullNameController.text = data['full_name'].toString();
        } else if (isSocialLogin) {
          String socialFullName =
              _storageService.readString(SharePreferenceConst.socialFullName) ??
                  '';
          if (socialFullName.isNotEmpty) {
            fullNameController.text = socialFullName;
          }
        }

        if (data['dob'] != null) {
          String dobString = data['dob'].toString();
          try {
            DateTime dobDate = DateTime.parse(dobString);
            selectedDob.value = dobDate;
            dobController.text =
                '${dobDate.day.toString().padLeft(2, '0')}/${dobDate.month.toString().padLeft(2, '0')}/${dobDate.year}';
          } catch (e) {
            print('Error parsing DOB: $e');
          }
        }

        if (data['gender'] != null) {
          String gender = data['gender'].toString();
          if (gender.toLowerCase() == 'prefer_not_to_say') {
            selectedGender.value = 'Prefer not to say';
          } else if (gender.isNotEmpty) {
            selectedGender.value =
                gender[0].toUpperCase() + gender.substring(1).toLowerCase();
          } else {
            selectedGender.value = '';
          }
        }

        if (data['opt_status'] != null) {
          selectedMarketingPreference.value =
              (data['opt_status'] == 1 || data['opt_status'] == true)
                  ? 'Opted In'
                  : 'Opted Out';
        }

        if (data['postcode'] != null) {
          postcodeController.text = data['postcode'].toString();
          selectedPostcode.value = data['postcode'].toString();
        }

        if (data['address'] != null) {
          selectedAddress.value = data['address'].toString();
          addressController.text = data['address'].toString();
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
          isProfilePictureRemoved.value = false;
        } else if (isSocialLogin) {
          String socialProfilePicture = _storageService
                  .readString(SharePreferenceConst.socialProfilePicture) ??
              '';
          if (socialProfilePicture.isNotEmpty) {
            profileImageUrl.value = socialProfilePicture;
            isProfilePictureRemoved.value = false;
          }
        } else {
          isProfilePictureRemoved.value = false;
        }
      }

      // Initialize map with profile coordinates if available
      initializeMapWithProfileData();

      isDataLoading.value = false;
    } catch (e) {
      isDataLoading.value = false;
      showResponseDialog(
        message: "Error loading profile data: $e",
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    }
  }

  /// Initialize map with profile coordinates if available, otherwise get current location
  Future<void> initializeMapWithProfileData() async {
    try {
      debugPrint(
          'Profile coordinates: lat=${selectedLatitude.value}, lng=${selectedLongitude.value}');

      // Check if profile has valid latitude and longitude
      if (selectedLatitude.value != null &&
          selectedLongitude.value != null &&
          selectedLatitude.value != 0.0 &&
          selectedLongitude.value != 0.0) {
        // Use profile coordinates
        debugPrint(
            'Using profile coordinates: ${selectedLatitude.value}, ${selectedLongitude.value}');

        // Reverse geocode to get address and postcode for profile coordinates
        await reverseGeocodeAndFillFields(
          selectedLatitude.value!,
          selectedLongitude.value!,
        );
      } else {
        // Fallback to current location if no valid profile coordinates
        debugPrint('No valid profile coordinates, getting current location');
        await getCurrentLocationAndFillAddress();
      }
    } catch (e) {
      debugPrint('Error initializing map with profile data: $e');
      // Fallback to current location on error
      await getCurrentLocationAndFillAddress();
    }
  }

  String? validateFullName(String? value) {
    if (value == null || value.isEmpty) return 'Full name is required';
    if (value.length < 2) return 'Name must be at least 2 characters';
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  String? validateDOB(String? value) {
    if (value == null || value.isEmpty) return 'Date of birth is required';
    if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value)) {
      return 'Please enter date in DD/MM/YYYY format';
    }

    // Check if user is 18+ years old
    if (selectedDob.value == null) {
      // Parse date from controller if selectedDob is not set
      try {
        List<String> parts = value.split('/');
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
    if (value == null || value.isEmpty) return 'Postcode is required';
    if (value.length < 5) return 'Postcode must be at least 5 characters';
    return null;
  }

  String? validateAddress(String? value) {
    if (value == null || value.isEmpty) return 'Address is required';
    if (value.length < 10) return 'Address must be at least 10 characters';
    return null;
  }

  String? validateGender() {
    if (selectedGender.value.isEmpty) return 'Gender is required';
    return null;
  }

  String? validateAddressField() {
    if (selectedAddress.value.isEmpty) return 'Address is required';
    if (selectedAddress.value.length < 10) {
      return 'Address must be at least 10 characters';
    }
    return null;
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
      selectedDob.value = picked;
      dobController.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      // Trigger validation to show age error immediately if needed
      formKey.currentState?.validate();
    }
  }

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

  String? getFormattedGender() {
    if (selectedGender.value.isEmpty) return null;
    return selectedGender.value.toLowerCase();
  }

  void selectGender(String gender) {
    selectedGender.value = gender;
    genderError.value = '';
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
                  color: Colors.black),
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
                  color: Colors.black),
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
    await navigateToMapScreen();
  }

  Future<void> navigateToMapScreen() async {
    // Prepare arguments with current coordinates if available
    final Map<String, dynamic> arguments = {};

    debugPrint(
        'Current coordinates in UpdateProfile: lat=${selectedLatitude.value}, lng=${selectedLongitude.value}');

    if (selectedLatitude.value != null &&
        selectedLongitude.value != null &&
        selectedLatitude.value != 0.0 &&
        selectedLongitude.value != 0.0) {
      arguments['latitude'] = selectedLatitude.value;
      arguments['longitude'] = selectedLongitude.value;
      debugPrint('Passing coordinates to map: $arguments');
    } else {
      debugPrint('No valid coordinates to pass to map');
    }

    // Pass existing address from API if available
    if (selectedAddress.value.isNotEmpty) {
      arguments['existingAddress'] = selectedAddress.value;
      debugPrint('Passing existing address to map: ${selectedAddress.value}');
    }

    final result = await Get.to(
      () => SelectAddressMapView(),
      arguments: arguments.isNotEmpty ? arguments : null,
      binding: SelectAddressMapBinding(),
    );
    if (result != null && result is Map<String, dynamic>) {
      selectedLatitude.value = result['latitude'] as double?;
      selectedLongitude.value = result['longitude'] as double?;

      if (result['latitude'] != null) {
        latitude.value = result['latitude'] as double;
      }
      if (result['longitude'] != null) {
        longitude.value = result['longitude'] as double;
      }

      final address = result['address'] as String? ?? '';
      if (address.isNotEmpty) {
        selectedAddress.value = address;
        addressError.value = '';
      }

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

  // ─── CORE FIX ─────────────────────────────────────────────────────────────
  //
  // Android 13+ (API 33+): Calling Permission.storage.request() before
  // pickImage(gallery) triggers the system photo picker sheet via
  // READ_MEDIA_VISUAL_USER_SELECTED. Then pickImage() opens a SECOND picker.
  //
  // Fix per source:
  //   CAMERA  → Keep explicit permission check (no double-open risk).
  //   GALLERY (Android) → Skip all manual permission calls. image_picker
  //                        handles it internally — no double-open.
  //   GALLERY (iOS)     → Check status first; bail if .limited after request
  //                        (OS already showed its own picker).
  // ──────────────────────────────────────────────────────────────────────────

  /// Pick image from GALLERY
  Future<void> pickProfileImage() async {
    if (_isPicking) return;
    _isPicking = true;

    try {
      if (Platform.isAndroid) {
        // ── Android: Let image_picker handle permissions internally ────────
        // DO NOT call requestStoragePermission() before pickImage().
        // On Android 13+, permission_handler shows the system photo picker,
        // then pickImage() opens a SECOND one — causing the double-open bug.
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (image != null) {
          _applyPickedImage(image);
        }
      } else if (Platform.isIOS) {
        // ── iOS: Check current status WITHOUT triggering a prompt ──────────
        PermissionStatus status = await Permission.photos.status;
        debugPrint('iOS photo permission status (before): $status');

        if (status.isPermanentlyDenied) {
          _showPermissionSettingsSnackbar();
          return;
        }

        if (status.isDenied) {
          status = await Permission.photos.request();
          debugPrint('iOS photo permission status (after request): $status');

          if (status.isLimited) {
            // iOS already showed its own photo sheet during the request.
            // Do NOT call pickImage() — that opens a second picker.
            // User must tap again; second tap hits isLimited below → opens once.
            Get.snackbar(
              'Limited Access Granted',
              'Tap the photo icon again to select a photo.',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 3),
            );
            return; // ← KEY FIX
          }

          if (status.isDenied || status.isPermanentlyDenied) {
            _showPermissionSettingsSnackbar();
            return;
          }
        }

        // Status is .granted or .limited (second tap) — safe to open picker
        if (status.isGranted || status.isLimited) {
          final XFile? image = await _picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1024,
            maxHeight: 1024,
            imageQuality: 85,
          );

          if (image != null) {
            _applyPickedImage(image);
          }
        }
      }
    } catch (e) {
      showResponseDialog(
        message: 'Failed to pick image: $e',
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    } finally {
      _isPicking = false;
    }
  }

  /// Take photo from CAMERA
  /// Camera always requires an explicit runtime permission check —
  /// no double-open risk since the permission dialog and camera UI
  /// are completely separate system components.
  Future<void> takePhoto() async {
    if (_isPicking) return;
    _isPicking = true;

    try {
      final bool hasPermission =
          await _cameraStoragePermissionService.requestCameraPermission();
      if (!hasPermission) return;

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        _applyPickedImage(image);
      }
    } catch (e) {
      showResponseDialog(
        message: 'Failed to take photo: $e',
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    } finally {
      _isPicking = false;
    }
  }

  /// Shared logic after a file is picked — updates state
  void _applyPickedImage(XFile image) {
    profileImage.value = File(image.path);
    profileImageUrl.value = ''; // Clear URL when new image is selected
    isProfilePictureRemoved.value = false; // Reset removal flag
  }

  void _showPermissionSettingsSnackbar() {
    Get.snackbar(
      'Permission Required',
      'Photo access is required. Please enable it in Settings.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
      mainButton: TextButton(
        onPressed: () => openAppSettings(),
        child: const Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
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
                  color: Colors.black),
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
                  isProfilePictureRemoved.value = true;
                },
              ),
          ],
        ),
      ),
    );
  }

  void updateProfile() {
    genderError.value = '';
    addressError.value = '';

    if (!formKey.currentState!.validate()) return;

    final genderValidationError = validateGender();
    if (genderValidationError != null) {
      genderError.value = genderValidationError;
      return;
    }

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
      data['gender'] = (getFormattedGender() == "prefer not to say")
          ? "prefer_not_to_say"
          : getFormattedGender() ?? '';
      data['postcode'] = postcodeController.text.trim();
      data['address'] = selectedAddress.value;
      data['latitude'] = latitude.value;
      data['longitude'] = longitude.value;
      data['opt_status'] =
          selectedMarketingPreference.value == 'Opted In' ? 1 : 0;
      data['is_term_condition'] = true;
      data['is_update'] = true;

      if (isProfilePictureRemoved.value) {
        data['profile_picture'] = '';
      }
      return data;
    }

    if (profileImage.value != null) {
      var service = _repository.sendPutMultipartApiRequest(
        toJson,
        update_personal_details,
        true,
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
      var service = _repository.sendPutApiRequest(
        toJson,
        update_personal_details,
        true,
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
        // Analytics: Update user profile with address information
        if (selectedAddress.value.isNotEmpty) {
          await AnalyticsService.instance.setUserProfile(
            city: await getCityFromAddress(selectedAddress.value.toString()),
          );
        }

        if (isProfilePictureRemoved.value) {
          profileImageUrl.value = '';
          isProfilePictureRemoved.value = false;
        }

        showResponseDialog(
          message: message,
          title: 'Success',
          isError: false,
          showButton: true,
          onOkPressed: () => Get.back(),
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

  /// Get current location and auto-fill address and postcode
  Future<void> getCurrentLocationAndFillAddress() async {
    try {
      // First check if permission is already granted
      bool hasPermission =
          await _locationPermissionService.checkLocationPermissionStatus();

      // If not granted, request permission
      if (!hasPermission) {
        hasPermission =
            await _locationPermissionService.requestLocationPermission();
      }

      if (!hasPermission) {
        debugPrint('Location permission not granted');
        return;
      }

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

  Future<String?> getCityFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        double lat = locations.first.latitude;
        double lng = locations.first.longitude;

        List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

        if (placemarks.isNotEmpty) {
          return placemarks.first.locality!.toLowerCase(); // return city
        }
      }
    } catch (e) {
      print("Error: $e");
    }

    return null;
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
}
