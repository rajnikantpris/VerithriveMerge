import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../api/api_response.dart';
import '../../api/dio_client.dart';
import '../../api/user_api_service.dart';
import '../../common/base_controller.dart';
import '../../enduser/screens/message/socket_service.dart';
import '../../routes/app_routes.dart';
import '../../services/location_permission_service.dart';
import '../../services/camera_storage_permission_service.dart';
import '../../services/social_auth_service.dart';
import '../../services/socket_service.dart';
import 'package:verithrive_dev/enduser/core/values/sharePrefrenceConst.dart';
import 'package:verithrive_dev/select_user/select_user_binding.dart';
import 'package:verithrive_dev/select_user/select_user_view.dart';
import '../../theme/colors.dart';
import '../../theme/font_sizes.dart';
import '../../theme/fonts.dart';
import '../../theme/hight_width_sizes.dart';
import '../../services/notification_permission_service.dart';
import '../../services/storage_service.dart';

class SignupPersonDetailsController extends BaseController {
  final NotificationPermissionService _notificationPermissionService =
      NotificationPermissionService();
  SignupPersonDetailsController(this._api);

  // ignore: unused_field
  final DioClient _api;

  late final GlobalKey<FormState> formKey;

  final fullNameController = TextEditingController();
  final dobController = TextEditingController();
  final genderController = TextEditingController();
  final postcodeController = TextEditingController();
  final addressController = TextEditingController();
  final promoCodeController = TextEditingController();

  // Selected address data
  final selectedLatitude = Rxn<double>();
  final selectedLongitude = Rxn<double>();

  final selectedDob = Rxn<DateTime>();
  final genders = ['Male', 'Female', 'Prefer not to say'];
  final selectedGender = ''.obs;
  final isManualPostcode = false.obs;
  final isManualAddress = false.obs;
  final selectedImage = Rxn<File>();
  final socialProfileImageUrl = ''.obs;
  final isSocialLogin = false.obs;
  final isPromoCodeApplied = false.obs;
  final isPromoCodeValid = false.obs;
  final promoCodeMessage = ''.obs;
  final hasValidated = false.obs;
  final ImagePicker _imagePicker = ImagePicker();
  final LocationPermissionService _locationPermissionService =
      LocationPermissionService();
  final CameraStoragePermissionService _cameraStoragePermissionService =
      CameraStoragePermissionService();
  final SocialAuthService _socialAuthService = SocialAuthService();
  StorageService? _storageService;

  @override
  void onInit() {
    super.onInit();
    // Initialize formKey to ensure a new key is created each time
    formKey = GlobalKey<FormState>();
    _storageService =
        Get.isRegistered<StorageService>() ? Get.find<StorageService>() : null;
    _loadIsSocialLogin();
    _applySocialDataFromArguments(Get.arguments as Map<String, dynamic>?);
    _loadPersistedSocialData();
    // Get current location and auto-fill address and postcode
    // _getCurrentLocationAndFillAddress();
  }

  @override
  void onReady() {
    super.onReady();
    _notificationPermissionService.ensurePermissionAfterFirstScreen();
  }

  void _loadIsSocialLogin() {
    final storage = _storageService;
    if (storage == null) return;
    isSocialLogin.value = storage.readBool('is_social_login') ?? false;
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

      if (Get.isRegistered<SocketService>()) {
        final professionalSocket = Get.find<SocketService>();
        professionalSocket.disconnect();
        Get.delete<SocketService>();
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
      socialProfileImageUrl.value = profilePic;
    }

    if (arguments['profileImageFile'] is File) {
      selectedImage.value = arguments['profileImageFile'] as File;
    }
  }

  void _loadPersistedSocialData() {
    final storage = _storageService;
    if (storage == null) return;

    if (fullNameController.text.trim().isEmpty) {
      String fullName = storage.readString('user_full_name')?.trim() ?? '';
      if (fullName.isEmpty) {
        fullName =
            storage.readString(SharePreferenceConst.socialFullName)?.trim() ??
                '';
      }
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

    if (selectedImage.value == null && socialProfileImageUrl.value.isEmpty) {
      String profilePic =
          storage.readString('user_profile_picture')?.trim() ?? '';
      if (profilePic.isEmpty) {
        profilePic = storage
                .readString(SharePreferenceConst.socialProfilePicture)
                ?.trim() ??
            '';
      }
      if (profilePic.isEmpty) {
        profilePic = _readProfilePictureFromStoredUserData(storage);
      }
      if (profilePic.isNotEmpty) {
        socialProfileImageUrl.value = profilePic;
      }
    }
  }

  String _readFullNameFromStoredUserData(StorageService storage) {
    for (final key in ['user_data', SharePreferenceConst.userData]) {
      final json = storage.readString(key);
      if (json == null || json.isEmpty) continue;
      try {
        final userData = jsonDecode(json) as Map<String, dynamic>;
        final name = userData['full_name']?.toString().trim() ?? '';
        if (name.isNotEmpty) return name;
      } catch (_) {
        continue;
      }
    }
    return '';
  }

  String _readProfilePictureFromStoredUserData(StorageService storage) {
    for (final key in ['user_data', SharePreferenceConst.userData]) {
      final json = storage.readString(key);
      if (json == null || json.isEmpty) continue;
      try {
        final userData = jsonDecode(json) as Map<String, dynamic>;
        final picture = userData['profile_picture']?.toString().trim() ?? '';
        if (picture.isNotEmpty) return picture;
      } catch (_) {
        continue;
      }
    }
    return '';
  }

  @override
  void onClose() {
    fullNameController.dispose();
    dobController.dispose();
    genderController.dispose();
    postcodeController.dispose();
    addressController.dispose();
    promoCodeController.dispose();
    super.onClose();
  }

  Future<void> checkPromoCode() async {
    final promoCode = promoCodeController.text.trim();
    final storage = _storageService;
    if (storage == null) return;

    final email = storage.readString('user_email') ?? '';

    if (promoCode.isEmpty) {
      promoCodeMessage.value = 'Please enter a promo code';
      isPromoCodeValid.value = false;
      return;
    }

    if (email.isEmpty) {
      promoCodeMessage.value = 'Email not found. Please log in again.';
      isPromoCodeValid.value = false;
      return;
    }

    final userApiService =
        Get.isRegistered<UserApiService>() ? Get.find<UserApiService>() : null;

    if (userApiService == null) {
      promoCodeMessage.value = 'API service not available';
      isPromoCodeValid.value = false;
      return;
    }

    await callDataService<ApiResponse<dynamic>>(
      userApiService.checkPromoCode(
        promoCode: promoCode,
        email: email,
      ),
      showLoader: true,
      onComplete: () {
        resetState();
      },
      mapErrorMessage: (error) {
        if (error is ApiResponse) {
          return error.errorMessage;
        }
        return mapErrorToMessage(error);
      },
      onError: (error, stack) {
        final errorMsg = errorMessage.value.isNotEmpty
            ? errorMessage.value
            : 'Failed to validate promo code';
        promoCodeMessage.value = errorMsg;
        isPromoCodeValid.value = false;
      },
      onSuccess: (response) async {
        if (response.success) {
          if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            final isValid = data['is_valid'] as bool? ?? false;

            if (isValid) {
              promoCodeMessage.value =
                  response.message ?? 'Promo code applied successfully!';
              isPromoCodeValid.value = true;
              isPromoCodeApplied.value = true;
            } else {
              promoCodeMessage.value = response.message ?? 'Invalid promo code';
              isPromoCodeValid.value = false;
            }
          } else {
            promoCodeMessage.value =
                response.message ?? 'Promo code applied successfully!';
            isPromoCodeValid.value = true;
            isPromoCodeApplied.value = true;
          }
        } else {
          promoCodeMessage.value =
              response.errorMessage ?? 'Invalid promo code';
          isPromoCodeValid.value = false;
        }
      },
    );
  }

  void removePromoCode() {
    promoCodeController.clear();
    isPromoCodeApplied.value = false;
    isPromoCodeValid.value = false;
    promoCodeMessage.value = '';
  }

  void setGender(String? value) {
    if (value == null) return;
    selectedGender.value = value;
    genderController.text = value;
  }

  Future<void> pickGender(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(HightWidthSizes.setValue_20),
              topRight: Radius.circular(HightWidthSizes.setValue_20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.only(
                  top: HightWidthSizes.setValue_12,
                  bottom: HightWidthSizes.setValue_8,
                ),
                width: HightWidthSizes.setValue_40,
                height: HightWidthSizes.setValue_4,
                decoration: BoxDecoration(
                  color: AppColor.color_9D9D9D,
                  borderRadius:
                      BorderRadius.circular(HightWidthSizes.setValue_2),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: HightWidthSizes.setValue_16,
                  vertical: HightWidthSizes.setValue_8,
                ),
                child: Text(
                  'Select Gender',
                  style: TextStyle(
                    fontFamily: AppFonts.rubikMedium,
                    fontWeight: FontWeight.w500,
                    fontSize: FontSizes.setFontValue_20,
                    color: AppColor.color_2D2D2D,
                  ),
                ),
              ),
              ...genders.map((gender) {
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: HightWidthSizes.setValue_10,
                    vertical: HightWidthSizes.setValue_1,
                  ),
                  title: Text(
                    gender,
                    style: TextStyle(
                      fontFamily: AppFonts.rubikRegular,
                      fontWeight: FontWeight.w400,
                      fontSize: FontSizes.setFontValue_16,
                      color: AppColor.color_0E1027,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, gender),
                  trailing: selectedGender.value == gender
                      ? Icon(
                          Icons.check,
                          color: AppColor.color_2FC4B2,
                          size: HightWidthSizes.setValue_20,
                        )
                      : null,
                );
              }),
              SizedBox(height: HightWidthSizes.setValue_2),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      setGender(selected);
    }
  }

  Future<void> pickDate(BuildContext context) async {
    final now = DateTime.now();
    // Strip time so user can never pick a date after "today"
    final today = DateTime(now.year, now.month, now.day);
    final initial =
        selectedDob.value ?? DateTime(today.year, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(today) ? today : initial,
      firstDate: DateTime(1900),
      // Allow navigating to future months, but disable selection of future days
      lastDate: DateTime(2100),
      locale: const Locale('en', 'GB'), // UK locale for date picker
      selectableDayPredicate: (day) => !day.isAfter(today),
    );

    if (picked != null) {
      selectedDob.value = picked;
      dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      // Trigger validation to show age error immediately if needed
      if (hasValidated.value) {
        formKey.currentState?.validate();
      }
    }
  }

  void enableManualPostcode() {
    isManualPostcode.value = true;
    isManualAddress.value = true;
  }

  String? validateNotEmpty(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $label';
    }
    return null;
  }

  String? validateFullName(String? value) {
    if (isSocialLogin.value && !shouldShowFullNameField) return null;
    return validateNotEmpty(value, 'your full name');
  }

  String? validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your date of birth';
    }

    if (selectedDob.value == null) {
      return null; // Will be validated by date picker
    }

    final now = DateTime.now();
    final age = now.year - selectedDob.value!.year;
    final monthDiff = now.month - selectedDob.value!.month;
    final dayDiff = now.day - selectedDob.value!.day;

    final actualAge =
        monthDiff < 0 || (monthDiff == 0 && dayDiff < 0) ? age - 1 : age;

    if (actualAge < 18) {
      return 'You must be 18 years old to use this app.';
    }

    return null;
  }

  void onNext() {
    hasValidated.value = true;
    final isValid = formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    Get.toNamed(
      Routes.signupTermsConditions,
      arguments: {
        'fullName': fullNameController.text.trim(),
        'dob': dobController.text.trim(),
        'gender': selectedGender.value,
        'postcode': postcodeController.text.trim(),
        'address': addressController.text.trim(),
        'latitude': selectedLatitude.value,
        'longitude': selectedLongitude.value,
        'profileImagePath': selectedImage.value?.path,
        'socialProfileImageUrl': socialProfileImageUrl.value,
        'promoCode':
            isPromoCodeValid.value ? promoCodeController.text.trim() : '',
      },
    );
  }

  Future<void> pickProfileImage(BuildContext context) async {
    try {
      // Show options to pick from camera or gallery
      final source = await _showImageSourceDialog(context);
      if (source == null) return;

      if (source == ImageSource.camera) {
        await _pickFromCamera();
      } else if (source == ImageSource.gallery) {
        await _pickFromGallery();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      // Request camera permission for camera access
      final hasCameraPermission =
          await _cameraStoragePermissionService.requestCameraPermission();
      if (!hasCameraPermission) return;

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await _processSelectedImage(pickedFile);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      if (Platform.isAndroid) {
        // ── Android: Let image_picker handle permissions internally ────────
        // DO NOT call Permission.photos.request() or Permission.storage.request().
        // On Android 13+, READ_MEDIA_VISUAL_USER_SELECTED (partial access)
        // causes permission_handler to show the system photo picker, then
        // image_picker opens a SECOND one.
        // image_picker's native ActivityResultLauncher handles this cleanly.
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (pickedFile != null) {
          await _processSelectedImage(pickedFile);
        }
      } else if (Platform.isIOS) {
        // ── iOS: Check current status WITHOUT triggering a prompt ──────────
        PermissionStatus status = await Permission.photos.status;
        debugPrint('iOS photo permission status (before): $status');

        if (status.isPermanentlyDenied) {
          await _cameraStoragePermissionService
              .showPhotoLibraryPermissionDeniedDialog();
          return;
        }
        if (status.isDenied) {
          status = await Permission.photos.request();
          debugPrint('iOS photo permission status (after request): $status');

          // if (status.isLimited) {
          //   // iOS already showed its own photo sheet during the request.
          //   // Do NOT call pickImage() — that opens a second picker.
          //   // User must tap again; second tap hits isLimited below → opens once.
          //   Get.snackbar(
          //     'Limited Access Granted',
          //     'Tap the photo icon again to select a photo.',
          //     snackPosition: SnackPosition.BOTTOM,
          //     duration: const Duration(seconds: 3),
          //   );
          //   return; // ← KEY FIX
          // }

          if (status.isPermanentlyDenied) {
            await _cameraStoragePermissionService
                .showPhotoLibraryPermissionDeniedDialog();
            return;
          }
        }

        // Status is .granted or .limited (second tap) — safe to open picker
        if (status.isGranted || status.isLimited) {
          final XFile? pickedFile = await _imagePicker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1024,
            maxHeight: 1024,
            imageQuality: 85,
          );

          if (pickedFile != null) {
            await _processSelectedImage(pickedFile);
          }
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Process the selected image (common logic for both platforms)
  Future<void> _processSelectedImage(XFile pickedFile) async {
    try {
      // Crop the selected image
      final croppedFile = await _cropImage(File(pickedFile.path));
      if (croppedFile != null) {
        selectedImage.value = croppedFile;
        socialProfileImageUrl.value = '';
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to process image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<File?> _cropImage(File imageFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
            aspectRatioLockEnabled: true,
          ),
        ],
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 85,
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error cropping image: $e');
      Get.snackbar(
        'Error',
        'Failed to crop image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  Future<ImageSource?> _showImageSourceDialog(BuildContext context) async {
    return await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
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

  /// Public method to get current location and auto-fill address and postcode
  /// Can be called manually to refresh location
  Future<void> getCurrentLocationAndFillAddress() async {
    await _getCurrentLocationAndFillAddress();
  }

  /// Get current location and auto-fill address and postcode
  Future<void> _getCurrentLocationAndFillAddress() async {
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

      // Reverse geocode to get address and postcode
      // await _reverseGeocodeAndFillFields(
      //   position.latitude,
      //   position.longitude,
      // );
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

  ImageProvider? get avatarImageProvider {
    final file = selectedImage.value;
    if (file != null) {
      return FileImage(file);
    }

    final url = socialProfileImageUrl.value;
    if (url.isNotEmpty) {
      return NetworkImage(url);
    }

    return null;
  }

  /// Reverse geocode coordinates and fill address and postcode fields
  Future<void> _reverseGeocodeAndFillFields(
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
          // Auto-fill postcode
          postcodeController.text = placemark.postalCode!;
          addressParts.add(placemark.postalCode!);
        }
        if (placemark.country != null && placemark.country!.isNotEmpty) {
          addressParts.add(placemark.country!);
        }

        // Auto-fill address
        addressController.text = addressParts.join(', ');
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
    }
  }

  /// Navigate to map screen to select address
  Future<void> navigateToMapScreen() async {
    // Prepare arguments for map screen
    final Map<String, dynamic> arguments = {
      'hideSelectButton': true
    }; // Hide Select Address button initially

    // If we have existing coordinates, pass them to map
    if (selectedLatitude.value != null && selectedLongitude.value != null) {
      arguments['latitude'] = selectedLatitude.value;
      arguments['longitude'] = selectedLongitude.value;
      debugPrint(
          'Passing existing coordinates to map: lat=${selectedLatitude.value}, lng=${selectedLongitude.value}');
    }

    // If we have existing address, pass it to map
    if (addressController.text.isNotEmpty) {
      arguments['existingAddress'] = addressController.text;
      debugPrint('Passing existing address to map: ${addressController.text}');
    }

    final result =
        await Get.toNamed(Routes.selectAddressMap, arguments: arguments);
    if (result != null && result is Map<String, dynamic>) {
      selectedLatitude.value = result['latitude'] as double?;
      selectedLongitude.value = result['longitude'] as double?;
      addressController.text = result['address'] as String? ?? '';

      // Auto-fill postcode if available
      if (result['postcode'] != null &&
          result['postcode'].toString().isNotEmpty) {
        postcodeController.text = (result['postcode'] as String?)!;
      }
    }
  }
}
