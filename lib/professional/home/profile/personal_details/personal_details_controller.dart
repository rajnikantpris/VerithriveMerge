import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../api/api_response.dart';
import '../../../../api/user_api_service.dart';
import '../../../../common/base_controller.dart';
import '../../../../models/profile_details_model.dart';
import '../../../../models/profession_sub_type_model.dart';
import '../../../../models/profession_type_model.dart';
import '../../../../services/camera_storage_permission_service.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/fonts.dart';
import '../../../../theme/font_sizes.dart';
import '../../../../theme/hight_width_sizes.dart';
import '../../../../utils/logger.dart';
import '../../../../widgets/response_dialog.dart';
import '../../../../services/analytics_service.dart';
import '../../home_controller.dart';

class PersonalDetailsController extends BaseController {
  final UserApiService _userApiService;
  final CameraStoragePermissionService _cameraStoragePermissionService =
  CameraStoragePermissionService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isPicking = false; // Guard against double picker calls

  PersonalDetailsController(this._userApiService);

  late final GlobalKey<FormState> formKey;

  // Profile picture
  final selectedImage = Rxn<File>();
  final profilePictureUrl = Rxn<String>();

  final youAreInController = TextEditingController();
  final professionController = TextEditingController();
  final fullNameController = TextEditingController();
  final dobController = TextEditingController();
  final phoneController = TextEditingController();

  final selectedDob = Rxn<DateTime>();
  final genders = ['Male', 'Female', 'Prefer not to say'];
  final selectedGender = ''.obs;

  // Marketing preferences
  final marketingOptions = ['Opted In', 'Opted Out'];
  final selectedMarketingPreference = ''.obs;

  String _convertGenderFromApiFormat(String apiGender) {
    final lowerGender = apiGender.toLowerCase().trim();
    if (lowerGender == 'prefer_not_to_say') {
      return 'Prefer not to say';
    }
    if (lowerGender.isNotEmpty) {
      return lowerGender[0].toUpperCase() + lowerGender.substring(1);
    }
    return apiGender;
  }

  // Profession types and sub-types maps
  final professionTypesMap = <String, String>{};
  final professionSubTypesMap = <String, String>{};
  final professionTypes = <String>[].obs;
  final professionSubTypes = <String>[].obs;
  final isLoadingProfessionTypes = false.obs;
  final isLoadingProfessionSubTypes = false.obs;

  // Store selected values and IDs
  final selectedProfessionType = Rxn<String>();
  final selectedProfessionTypeId = Rxn<String>();
  final selectedProfessionSubType = Rxn<String>();
  final selectedProfessionSubTypeId = Rxn<String>();

  // Store profile ID from API response
  final profileId = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    formKey = GlobalKey<FormState>();
    _loadProfessionTypes();
  }

  @override
  void onClose() {
    youAreInController.dispose();
    professionController.dispose();
    fullNameController.dispose();
    dobController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  void setGender(String? value) {
    if (value == null) return;
    selectedGender.value = value;
  }

  void setMarketingPreference(String? value) {
    if (value == null) return;
    selectedMarketingPreference.value = value;
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

  Future<void> pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initial =
        selectedDob.value ?? DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(1900),
      lastDate: now,
      locale: const Locale('en', 'GB'), // UK locale for date picker
    );

    if (picked != null) {
      selectedDob.value = picked;
      dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      formKey.currentState?.validate();
    }
  }

  void setProfessionType(String? value) {
    if (value == null || value.isEmpty) {
      selectedProfessionType.value = null;
      selectedProfessionTypeId.value = null;
      youAreInController.clear();
      professionSubTypes.clear();
      selectedProfessionSubType.value = null;
      professionController.clear();
      return;
    }

    selectedProfessionType.value = value;
    youAreInController.text = value;
    final professionTypeId = professionTypesMap[value];
    if (professionTypeId != null) {
      selectedProfessionTypeId.value = professionTypeId;
      _loadProfessionSubTypes(professionTypeId);
    } else {
      professionSubTypes.clear();
      selectedProfessionSubType.value = null;
      professionController.clear();
    }
  }

  void setProfessionSubType(String? value) {
    if (value == null || value.isEmpty) {
      selectedProfessionSubType.value = null;
      selectedProfessionSubTypeId.value = null;
      professionController.clear();
      return;
    }

    selectedProfessionSubType.value = value;
    professionController.text = value;
    final professionSubTypeId = professionSubTypesMap[value];
    if (professionSubTypeId != null) {
      selectedProfessionSubTypeId.value = professionSubTypeId;
    }
  }

  Future<void> onProfilePictureTap(BuildContext context) async {
    await pickProfileImage(context);
  }

  // ─── CORE FIX ─────────────────────────────────────────────────────────────
  //
  // Android 13+ (API 33+): Calling Permission.photos.request() or
  // Permission.storage.request() before pickImage() triggers the system photo
  // picker sheet. Then pickImage() opens a SECOND picker — double-open bug.
  //
  // Fix per source:
  //   CAMERA  → Still requires explicit permission check (no double-open risk).
  //   GALLERY (Android) → Skip all manual permission calls. image_picker
  //                        handles permissions internally via ActivityResult
  //                        API and never double-opens.
  //   GALLERY (iOS)     → Check status first; only request if undetermined;
  //                        bail out if result is .limited (OS already showed
  //                        its own picker during the request).
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> pickProfileImage(BuildContext context) async {
    // Guard: prevent multiple simultaneous picker calls
    if (_isPicking) return;

    try {
      final source = await _showImageSourceDialog(context);
      if (source == null) return;

      if (source == ImageSource.camera) {
        await _pickFromCamera();
      } else {
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

  /// Pick image from CAMERA
  /// Camera always requires an explicit runtime permission check — no
  /// double-open risk because the permission prompt and the camera UI are
  /// completely separate system components.
  Future<void> _pickFromCamera() async {
    if (_isPicking) return;
    _isPicking = true;

    try {
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
        final croppedFile = await _cropImage(File(pickedFile.path));
        if (croppedFile != null) {
          selectedImage.value = croppedFile;
        }
      }
    } catch (e) {
      debugPrint('Error picking from camera: $e');
      Get.snackbar(
        'Error',
        'Failed to take photo: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isPicking = false;
    }
  }

  /// Pick image from GALLERY
  /// Applies platform-specific permission strategy to prevent double-open.
  Future<void> _pickFromGallery() async {
    if (_isPicking) return;
    _isPicking = true;

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
          final croppedFile = await _cropImage(File(pickedFile.path));
          if (croppedFile != null) {
            selectedImage.value = croppedFile;
          }
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
          // First-time request — iOS may show its own "Select Photos" sheet
          // for "Limited Access" during this call.
          status = await Permission.photos.request();
          debugPrint('iOS photo permission status (after request): $status');

          if (status.isLimited) {
            // iOS already showed its own photo selection sheet during the
            // permission request. Do NOT call pickImage() — that would open
            // a second picker. Ask user to tap again instead.
            Get.snackbar(
              'Limited Access Granted',
              'Tap the photo icon again to select a photo.',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 3),
            );
            return; // ← KEY FIX: exit without opening picker a second time
          }

          if (status.isDenied || status.isPermanentlyDenied) {
            _showPermissionSettingsSnackbar();
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
            final croppedFile = await _cropImage(File(pickedFile.path));
            if (croppedFile != null) {
              selectedImage.value = croppedFile;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isPicking = false;
    }
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
          child: SafeArea(
            child: Wrap(
              children: [
                Padding(
                  padding: EdgeInsets.all(HightWidthSizes.setValue_16),
                  child: Text(
                    'Select Image Source',
                    style: TextStyle(
                      fontFamily: AppFonts.rubikMedium,
                      fontSize: FontSizes.setFontValue_18,
                      fontWeight: FontWeight.w500,
                      color: AppColor.color_2D2D2D,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library,
                      color: AppColor.color_2D2D2D),
                  title: Text(
                    'Choose from Gallery',
                    style: TextStyle(
                      fontFamily: AppFonts.rubikRegular,
                      fontSize: FontSizes.setFontValue_16,
                      color: AppColor.color_2D2D2D,
                    ),
                  ),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera,
                      color: AppColor.color_2D2D2D),
                  title: Text(
                    'Take a Photo',
                    style: TextStyle(
                      fontFamily: AppFonts.rubikRegular,
                      fontSize: FontSizes.setFontValue_16,
                      color: AppColor.color_2D2D2D,
                    ),
                  ),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                ListTile(
                  leading:
                  const Icon(Icons.cancel, color: AppColor.color_2D2D2D),
                  title: Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: AppFonts.rubikRegular,
                      fontSize: FontSizes.setFontValue_16,
                      color: AppColor.color_2D2D2D,
                    ),
                  ),
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> onUpdateProfile() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    if (selectedProfessionTypeId.value == null ||
        selectedProfessionTypeId.value!.isEmpty) {
      Get.snackbar('Error', 'Please select profession type',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (selectedProfessionSubTypeId.value == null ||
        selectedProfessionSubTypeId.value!.isEmpty) {
      Get.snackbar('Error', 'Please select profession',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (selectedDob.value == null) {
      Get.snackbar('Error', 'Please select date of birth',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (selectedGender.value.isEmpty) {
      Get.snackbar('Error', 'Please select gender',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (profileId.value == null || profileId.value!.isEmpty) {
      Get.snackbar('Error', 'Profile ID not found. Please try again.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final dobDate = selectedDob.value!;
    final dobFormatted = DateFormat('yyyy-MM-dd').format(dobDate);

    await callDataService<ApiResponse<dynamic>>(
      _userApiService.updatePersonalDetailsProfile(
        id: profileId.value!,
        professionTypeId: selectedProfessionTypeId.value!,
        professionSubTypeId: selectedProfessionSubTypeId.value!,
        fullName: fullNameController.text.trim(),
        dob: dobFormatted,
        gender: selectedGender.value,
        optStatus: selectedMarketingPreference.value == 'Opted In' ? 1 : 0,
        mobileNumber: phoneController.text.trim(),
        profilePicture: selectedImage.value,
      ),
      showLoader: true,
      onSuccess: (response) {
        if (response.success) {
          _refreshProfile();
          // Track persona in analytics when profile is updated
          if (selectedProfessionType.value != null) {
            AnalyticsService.instance.setUserProfile(
              persona: AnalyticsService.resolvePersona(
                professionName: selectedProfessionType.value,
              ),
            );
          }
          showResponseDialog(
            message: response.message ?? 'Profile updated successfully',
            title: 'Success',
            isError: false,
            onOkPressed: () => Get.back(),
          );
        } else {
          showResponseDialog(
            message: response.errorMessage,
            title: 'Error',
            isError: true,
          );
        }
      },
      onError: (error, stack) {
        final errorMsg = errorMessage.value.isNotEmpty
            ? errorMessage.value
            : 'Failed to update profile. Please try again.';
        showResponseDialog(
          message: errorMsg,
          title: 'Error',
          isError: true,
        );
      },
    );
  }

  static void _refreshProfile() {
    try {
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        homeController.loadProfileDetails();
        logInfo('Profile data refresh triggered');
      } else {
        logInfo('HomeController not registered, skipping profile refresh');
      }
    } catch (e, stackTrace) {
      logError('Error refreshing profile data',
          error: e, stackTrace: stackTrace);
    }
  }

  String? validateNotEmpty(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $label';
    }
    return null;
  }

  String? validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your date of birth';
    }
    
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
      
      final actualAge = monthDiff < 0 || (monthDiff == 0 && dayDiff < 0) ? age - 1 : age;
      
      if (actualAge < 18) {
        return 'You must be 18 years old to use this app.';
      }
    }
    
    return null;
  }

  Future<void> _loadProfessionTypes() async {
    isLoadingProfessionTypes.value = true;
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.getProfessionTypes(),
      showLoader: true,
      onSuccess: (response) {
        if (response.success && response.data != null) {
          professionTypesMap.clear();
          if (response.data is List) {
            final list = response.data as List;
            final types = <String>[];
            for (final item in list) {
              try {
                if (item is Map<String, dynamic>) {
                  final professionType = ProfessionTypeModel.fromJson(item);
                  if (professionType.id != null && professionType.type != null) {
                    professionTypesMap[professionType.type!] =
                    professionType.id!;
                    types.add(professionType.type!);
                  }
                }
              } catch (e) {
                continue;
              }
            }
            professionTypes.value = types;
          } else if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            if (data['data'] is List) {
              final list = data['data'] as List;
              final types = <String>[];
              for (final item in list) {
                try {
                  if (item is Map<String, dynamic>) {
                    final professionType = ProfessionTypeModel.fromJson(item);
                    if (professionType.id != null &&
                        professionType.type != null) {
                      professionTypesMap[professionType.type!] =
                      professionType.id!;
                      types.add(professionType.type!);
                    }
                  }
                } catch (e) {
                  continue;
                }
              }
              professionTypes.value = types;
            }
          }
          _loadPersonalDetails();
        }
      },
      onComplete: () {
        isLoadingProfessionTypes.value = false;
      },
    );
  }

  Future<void> _loadPersonalDetails() async {
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.getCreateProfileDetails(),
      showLoader: true,
      onSuccess: (response) {
        if (response.success && response.data != null) {
          try {
            final data = response.data as Map<String, dynamic>?;
            if (data != null) {
              final profileDetails = ProfileDetailsModel.fromJson(data);

              if (profileDetails.id != null && profileDetails.id!.isNotEmpty) {
                profileId.value = profileDetails.id;
              }

              if (profileDetails.profilePicture != null &&
                  profileDetails.profilePicture!.isNotEmpty) {
                profilePictureUrl.value = profileDetails.profilePicture;
              }

              if (profileDetails.fullName != null &&
                  profileDetails.fullName!.isNotEmpty) {
                fullNameController.text = profileDetails.fullName!;
              }

              if (profileDetails.dob != null && profileDetails.dob!.isNotEmpty) {
                try {
                  final dobDate = DateTime.parse(profileDetails.dob!);
                  selectedDob.value = dobDate;
                  dobController.text = DateFormat('dd/MM/yyyy').format(dobDate);
                } catch (e) {
                  try {
                    final parts = profileDetails.dob!.split('/');
                    if (parts.length == 3) {
                      final day = int.parse(parts[0]);
                      final month = int.parse(parts[1]);
                      final year = int.parse(parts[2]);
                      final dobDate = DateTime(year, month, day);
                      selectedDob.value = dobDate;
                      dobController.text =
                          DateFormat('dd/MM/yyyy').format(dobDate);
                    }
                  } catch (e2) {
                    dobController.text = profileDetails.dob!;
                  }
                }
              }

              if (profileDetails.mobileNumber != null &&
                  profileDetails.mobileNumber!.isNotEmpty) {
                phoneController.text = profileDetails.mobileNumber!;
              }

              if (profileDetails.optStatus != null) {
                selectedMarketingPreference.value =
                profileDetails.optStatus == 1 ? 'Opted In' : 'Opted Out';
              }

              if (profileDetails.gender != null &&
                  profileDetails.gender!.isNotEmpty) {
                final displayGender =
                _convertGenderFromApiFormat(profileDetails.gender!);
                final matchedGender = genders.firstWhere(
                      (g) => g.toLowerCase() == displayGender.toLowerCase(),
                  orElse: () => displayGender,
                );
                selectedGender.value = matchedGender;
              }

              if (profileDetails.professionTypeId != null &&
                  profileDetails.professionTypeId!.isNotEmpty) {
                final professionTypeId = profileDetails.professionTypeId!;
                selectedProfessionTypeId.value = professionTypeId;

                try {
                  final matchingType = professionTypesMap.entries.firstWhere(
                        (entry) => entry.value == professionTypeId,
                  );
                  selectedProfessionType.value = matchingType.key;
                  youAreInController.text = matchingType.key;

                  _loadProfessionSubTypes(professionTypeId).then((_) {
                    if (profileDetails.professionSubTypeId != null &&
                        profileDetails.professionSubTypeId!.isNotEmpty) {
                      final professionSubTypeId =
                      profileDetails.professionSubTypeId!;
                      selectedProfessionSubTypeId.value = professionSubTypeId;

                      try {
                        final matchingSubType =
                        professionSubTypesMap.entries.firstWhere(
                              (entry) => entry.value == professionSubTypeId,
                        );
                        selectedProfessionSubType.value = matchingSubType.key;
                        professionController.text = matchingSubType.key;
                      } catch (e) {
                        debugPrint('Could not find profession sub-type: $e');
                      }
                    }
                  });
                } catch (e) {
                  debugPrint('Could not find profession type: $e');
                }
              }
            }
          } catch (e) {
            debugPrint('Error parsing personal details: $e');
          }
        }
      },
    );
  }

  Future<void> _loadProfessionSubTypes(String professionTypeId) async {
    isLoadingProfessionSubTypes.value = true;
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.getProfessionSubTypes(professionTypeId: professionTypeId),
      showLoader: false,
      onSuccess: (response) {
        if (response.success && response.data != null) {
          professionSubTypesMap.clear();
          professionSubTypes.clear();
          final seenSubTypes = <String>{};
          if (response.data is List) {
            final list = response.data as List;
            final subTypes = <String>[];
            for (final item in list) {
              try {
                if (item is Map<String, dynamic>) {
                  final professionSubType =
                  ProfessionSubTypeModel.fromJson(item);
                  if (professionSubType.id != null &&
                      professionSubType.subType != null &&
                      !seenSubTypes.contains(professionSubType.subType!)) {
                    professionSubTypesMap[professionSubType.subType!] =
                    professionSubType.id!;
                    subTypes.add(professionSubType.subType!);
                    seenSubTypes.add(professionSubType.subType!);
                  }
                }
              } catch (e) {
                continue;
              }
            }
            professionSubTypes.value = subTypes;
          } else if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            if (data['data'] is List) {
              final list = data['data'] as List;
              final subTypes = <String>[];
              for (final item in list) {
                try {
                  if (item is Map<String, dynamic>) {
                    final professionSubType =
                    ProfessionSubTypeModel.fromJson(item);
                    if (professionSubType.id != null &&
                        professionSubType.subType != null &&
                        !seenSubTypes.contains(professionSubType.subType!)) {
                      professionSubTypesMap[professionSubType.subType!] =
                      professionSubType.id!;
                      subTypes.add(professionSubType.subType!);
                      seenSubTypes.add(professionSubType.subType!);
                    }
                  }
                } catch (e) {
                  continue;
                }
              }
              professionSubTypes.value = subTypes;
            }
          }

          if (selectedProfessionSubType.value != null &&
              !professionSubTypes.contains(selectedProfessionSubType.value)) {
            selectedProfessionSubType.value = null;
            selectedProfessionSubTypeId.value = null;
            professionController.clear();
          }
        }
      },
      onComplete: () {
        isLoadingProfessionSubTypes.value = false;
      },
    );
  }
}