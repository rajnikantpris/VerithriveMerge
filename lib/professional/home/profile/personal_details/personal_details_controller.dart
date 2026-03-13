import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

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
import '../../home_controller.dart';

class PersonalDetailsController extends BaseController {
  final UserApiService _userApiService;
  final CameraStoragePermissionService _cameraStoragePermissionService =
      CameraStoragePermissionService();
  final ImagePicker _imagePicker = ImagePicker();

  PersonalDetailsController(this._userApiService);

  late final GlobalKey<FormState> formKey;

  // Profile picture
  final selectedImage = Rxn<File>();
  final profilePictureUrl = Rxn<String>();

  final youAreInController = TextEditingController();
  final professionController = TextEditingController();
  final fullNameController = TextEditingController();
  final dobController = TextEditingController();

  final selectedDob = Rxn<DateTime>();
  final genders = ['Male', 'Female', 'Prefer not to say'];
  final selectedGender = ''.obs;

  // Marketing preferences
  final marketingOptions = ['Yes', 'No'];
  final selectedMarketingPreference = ''.obs;

  /// Convert API gender format to display format
  /// Converts "prefer_not_to_say" to "Prefer not to say" and capitalizes other values
  String _convertGenderFromApiFormat(String apiGender) {
    final lowerGender = apiGender.toLowerCase().trim();
    if (lowerGender == 'prefer_not_to_say') {
      return 'Prefer not to say';
    }
    // Capitalize first letter for other values
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
    // Initialize formKey to ensure a new key is created each time
    formKey = GlobalKey<FormState>();
    // Load data from API
    _loadProfessionTypes();

  }

  @override
  void onClose() {
    youAreInController.dispose();
    professionController.dispose();
    fullNameController.dispose();
    dobController.dispose();
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
        selectedDob.value ?? DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null) {
      selectedDob.value = picked;
      dobController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  /// Set selected profession type
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
    // Get the _id for the selected profession type
    final professionTypeId = professionTypesMap[value];
    if (professionTypeId != null) {
      selectedProfessionTypeId.value = professionTypeId;
      // Load sub-types for the selected profession type using _id
      _loadProfessionSubTypes(professionTypeId);
    } else {
      // If _id not found, clear sub-types
      professionSubTypes.clear();
      selectedProfessionSubType.value = null;
      professionController.clear();
    }
  }

  /// Set selected profession sub-type
  void setProfessionSubType(String? value) {
    if (value == null || value.isEmpty) {
      selectedProfessionSubType.value = null;
      selectedProfessionSubTypeId.value = null;
      professionController.clear();
      return;
    }

    selectedProfessionSubType.value = value;
    professionController.text = value;
    // Get the _id for the selected profession sub-type
    final professionSubTypeId = professionSubTypesMap[value];
    if (professionSubTypeId != null) {
      selectedProfessionSubTypeId.value = professionSubTypeId;
    }
  }

  Future<void> onProfilePictureTap(BuildContext context) async {
    await pickProfileImage(context);
  }

  Future<void> pickProfileImage(BuildContext context) async {
    try {
      // Show options to pick from camera or gallery
      final source = await _showImageSourceDialog(context);
      if (source == null) return;

      // Double-check permission for the selected source
      if (source == ImageSource.camera) {
        final hasCameraPermission =
            await _cameraStoragePermissionService.requestCameraPermission();
        if (!hasCameraPermission) {
          return;
        }
      } else {
        // For gallery, check storage/photos permission
        final hasStoragePermission =
            await _cameraStoragePermissionService.requestStoragePermission();
        if (!hasStoragePermission) {
          return;
        }
      }

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Crop the selected image
        final croppedFile = await _cropImage(File(pickedFile.path));
        if (croppedFile != null) {
          selectedImage.value = croppedFile;
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

    // Validate required fields
    if (selectedProfessionTypeId.value == null ||
        selectedProfessionTypeId.value!.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select profession type',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (selectedProfessionSubTypeId.value == null ||
        selectedProfessionSubTypeId.value!.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select profession',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (selectedDob.value == null) {
      Get.snackbar(
        'Error',
        'Please select date of birth',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (selectedGender.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Please select gender',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (profileId.value == null || profileId.value!.isEmpty) {
      Get.snackbar(
        'Error',
        'Profile ID not found. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Format date of birth to ISO format
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
        optStatus: selectedMarketingPreference.value == 'Yes' ? 1 : 0,
        profilePicture: selectedImage.value,
      ),
      showLoader: true,
      onSuccess: (response) {
        if (response.success) {
          _refreshProfile();
          showResponseDialog(
            message: response.message ?? 'Profile updated successfully',
            title: 'Success',
            isError: false,
            onOkPressed: () {
              Get.back();
            },
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

  /// Load profession types from API
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

  /// Load personal details from API
  Future<void> _loadPersonalDetails() async {
    // // Wait for profession types to be loaded first
    // while (isLoadingProfessionTypes.value) {
    //   await Future.delayed(const Duration(milliseconds: 50));
    // }

    await callDataService<ApiResponse<dynamic>>(
      _userApiService.getCreateProfileDetails(),
      showLoader: true,
      onSuccess: (response) {
        if (response.success && response.data != null) {
          try {
            final data = response.data as Map<String, dynamic>?;
            if (data != null) {
              // Parse response using model
              final profileDetails = ProfileDetailsModel.fromJson(data);

              // Store profile ID
              if (profileDetails.id != null && profileDetails.id!.isNotEmpty) {
                profileId.value = profileDetails.id;
              }

              // Store profile picture URL
              if (profileDetails.profilePicture != null &&
                  profileDetails.profilePicture!.isNotEmpty) {
                profilePictureUrl.value = profileDetails.profilePicture;
              }

              // Populate full name
              if (profileDetails.fullName != null &&
                  profileDetails.fullName!.isNotEmpty) {
                fullNameController.text = profileDetails.fullName!;
              }

              // Populate date of birth
              if (profileDetails.dob != null &&
                  profileDetails.dob!.isNotEmpty) {
                try {
                  // Parse ISO format (2025-12-19T00:00:00.000Z)
                  final dobDate = DateTime.parse(profileDetails.dob!);
                  selectedDob.value = dobDate;
                  dobController.text = DateFormat('dd/MM/yyyy').format(dobDate);
                } catch (e) {
                  // If parsing fails, try other formats
                  try {
                    // Try dd/MM/yyyy format
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
                  // If all parsing fails, just set the text
                  dobController.text = profileDetails.dob!;
                }
              }
            }

            // Populate marketing preference
            if (profileDetails.optStatus != null) {
              selectedMarketingPreference.value =
                  profileDetails.optStatus == 1 ? 'Yes' : 'No';
            }

              // Populate gender
              if (profileDetails.gender != null &&
                  profileDetails.gender!.isNotEmpty) {
                // Convert API format to display format
                final displayGender =
                    _convertGenderFromApiFormat(profileDetails.gender!);
                // Try to match with dropdown items
                final matchedGender = genders.firstWhere(
                  (g) => g.toLowerCase() == displayGender.toLowerCase(),
                  orElse: () => displayGender,
                );
                selectedGender.value = matchedGender;
              }

              // Populate profession type using ID
              if (profileDetails.professionTypeId != null &&
                  profileDetails.professionTypeId!.isNotEmpty) {
                final professionTypeId = profileDetails.professionTypeId!;
                selectedProfessionTypeId.value = professionTypeId;

                // Find profession type name by ID
                try {
                  final matchingType = professionTypesMap.entries.firstWhere(
                    (entry) => entry.value == professionTypeId,
                  );
                  selectedProfessionType.value = matchingType.key;
                  youAreInController.text = matchingType.key;

                  // Load profession sub-types for the selected type
                  _loadProfessionSubTypes(professionTypeId).then((_) {
                    // Populate profession sub-type after sub-types are loaded
                    if (profileDetails.professionSubTypeId != null &&
                        profileDetails.professionSubTypeId!.isNotEmpty) {
                      final professionSubTypeId =
                          profileDetails.professionSubTypeId!;
                      selectedProfessionSubTypeId.value = professionSubTypeId;

                      // Find profession sub-type name by ID
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

  /// Load profession sub-types from API
  Future<void> _loadProfessionSubTypes(String professionTypeId) async {
    isLoadingProfessionSubTypes.value = true;
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.getProfessionSubTypes(professionTypeId: professionTypeId),
      showLoader: false,
      onSuccess: (response) {
        if (response.success && response.data != null) {
          professionSubTypesMap.clear();
          professionSubTypes.clear();
          final seenSubTypes = <String>{}; // Track unique sub-types
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

          // If selected value is not in the new list, clear it
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
