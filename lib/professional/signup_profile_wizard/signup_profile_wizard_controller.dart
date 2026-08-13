import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart' as dio;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

import '../../api/api_response.dart';
import '../../api/user_api_service.dart';
import '../../common/base_controller.dart';
import '../../models/profession_type_model.dart';
import '../../models/profession_sub_type_model.dart';
import '../../models/service_model.dart';
import '../../models/college_university_model.dart';
import '../../models/profile_details_model.dart';
import '../../models/address_details_model.dart';
import '../../routes/app_routes.dart';
import '../../services/location_permission_service.dart';
import '../../services/camera_storage_permission_service.dart';
import '../../services/storage_service.dart';
import '../../services/analytics_service.dart';
import '../../utils/logger.dart';
import '../../widgets/response_dialog.dart';
import '../../theme/colors.dart';
import '../../theme/font_sizes.dart';
import '../../theme/fonts.dart';
import '../../theme/hight_width_sizes.dart';

class SignupProfileWizardController extends BaseController {
  final UserApiService _userApiService;
  final StorageService? _storageService =
      Get.isRegistered<StorageService>() ? Get.find<StorageService>() : null;
  final pageController = PageController();
  final currentStep = 0.obs;
  int initialStep = 0; // Track the initial step when wizard was opened

  // Profile ID for update scenario
  final profileId = Rxn<String>();

  // Step 1 - Create profile
  final locationController = TextEditingController();
  final professionController = TextEditingController();
  final fullNameController = TextEditingController();
  final dobController = TextEditingController();
  final selectedDob = Rxn<DateTime>();
  final selectedGender = ''.obs;
  final genders = ['Male', 'Female', 'Prefer not to say'];

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

  // Profession types and sub-types
  final professionTypes = <String>[].obs;
  final professionTypesMap = <String, String>{}.obs; // Maps type name to _id
  final professionSubTypes = <String>[].obs;
  final professionSubTypesMap =
      <String, String>{}.obs; // Maps sub-type name to _id
  final selectedProfessionType = Rxn<String>();
  final selectedProfessionTypeId =
      Rxn<String>(); // Store the _id of selected profession type
  final selectedProfessionSubType = Rxn<String>();
  final selectedProfessionSubTypeId =
      Rxn<String>(); // Store the _id of selected profession sub-type
  final isLoadingProfessionTypes = false.obs;
  final isLoadingProfessionSubTypes = false.obs;

  // Step 2 - Address
  final postcodeController = TextEditingController();
  final addressController = TextEditingController();
  final workPostcodeController = TextEditingController();
  final workAddressController = TextEditingController();

  // Location data
  final isManualPostcode = false.obs;
  final isManualWorkPostcode = false.obs;
  final isManualAddress = false.obs;
  final isManualWorkAddress = false.obs;
  final selectedLatitude = Rxn<double>();
  final selectedLongitude = Rxn<double>();
  final workLatitude = Rxn<double>();
  final workLongitude = Rxn<double>();
  final fullAddressId = Rxn<String>();
  final workAddressId = Rxn<String>();
  final LocationPermissionService _locationPermissionService =
      LocationPermissionService();
  final CameraStoragePermissionService _cameraStoragePermissionService =
      CameraStoragePermissionService();
  final ImagePicker _imagePicker = ImagePicker();

  // Step 3 - Services
  final RxList<ServiceModel> services = <ServiceModel>[].obs;
  final selectedServices = <String>{}
      .obs; // Stores selected service names or sub-service names (for UI)
  final selectedServiceIds = <String>{}.obs; // Stores selected service IDs
  final selectedSubServiceIds = <String, List<String>>{}
      .obs; // Maps service_id to list of sub_service_ids
  final expandedServices = <String>{}.obs; // Tracks which services are expanded
  final isLoadingServices = false.obs;
  final hasLoadedServices =
      false.obs; // Track if services API has been called and completed
  final professionSubTypeIdFromResponse = Rxn<String>();
  final hasUserMadeManualSelection =
      false.obs; // Track if user has manually selected services
  final hasLoadedOldServices =
      false.obs; // Track if old services have been loaded from API

  // Step 4 - Qualifications
  final qualifications = <QualificationItem>[].obs;
  final yearsExperienceController = TextEditingController();
  final qualificationsScrollController = ScrollController();
  final collegesUniversities = <String>[].obs;
  final collegesUniversitiesMap = <String, String>{}.obs; // Maps name to _id
  final isLoadingCollegesUniversities = false.obs;
  final removedQualificationIds =
      <String>[].obs; // Track IDs of deleted qualifications

  // Step 5 - Identification
  final idTypeController = TextEditingController(text: 'Passport');
  final idExpiryController = TextEditingController();
  final idUploadController =
      TextEditingController(text: 'Upload file (PDF or Image)');
  final confirmRightToWork = false.obs;
  final selectedIdType = ''.obs;
  final idTypes = ['Passport', 'Driving license'];
  File? idFile; // Store uploaded ID file
  final identificationId = Rxn<String>(); // Store identification ID for updates
  String? idDocumentUrl; // Store document URL from API for existing documents

  // Step 6 - About you
  final aboutYouController = TextEditingController();
  final aboutYouCharacterCount = 0.obs;

  late final GlobalKey<FormState> formKey;
  final addressFormKey = GlobalKey<FormState>();
  final qualificationFormKeys = <GlobalKey<FormState>>[].obs;
  final experienceFormKey = GlobalKey<FormState>();
  final identificationFormKey = GlobalKey<FormState>();
  final aboutYouFormKey = GlobalKey<FormState>();
  final hasValidated = false.obs;
  final addressHasValidated = false.obs;
  final qualificationsHasValidated = false.obs;
  final identificationHasValidated = false.obs;
  final aboutYouHasValidated = false.obs;

  int get totalSteps => 6;

  SignupProfileWizardController(this._userApiService) {
    qualifications.add(QualificationItem.initial());
    qualificationFormKeys.add(GlobalKey<FormState>());
  }

  @override
  void onInit() {
    super.onInit();
    // Initialize formKey to ensure a new key is created each time
    formKey = GlobalKey<FormState>();

    // Get initial step from arguments if provided
    final args = Get.arguments as Map<String, dynamic>? ?? {};

    // Populate initial personal details if passed
    final initialFullName = args['fullName'] as String?;
    final initialDob = args['dob'] as String?;
    final initialGender = args['gender'] as String?;
    final initialProfileImagePath = args['profileImagePath'] as String?;
    final initialSocialProfileImageUrl =
        args['socialProfileImageUrl'] as String?;

    if (initialFullName != null && initialFullName.isNotEmpty) {
      fullNameController.text = initialFullName;
    }
    if (initialDob != null && initialDob.isNotEmpty) {
      dobController.text = initialDob;
      // Also parse and set selectedDob to avoid validation error
      try {
        final parts = initialDob.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          selectedDob.value = DateTime(year, month, day);
        } else {
          // Try ISO format as fallback
          selectedDob.value = DateTime.parse(initialDob);
        }
      } catch (e) {
        debugPrint('Error parsing initial DOB: $e');
      }
    }
    if (initialGender != null && initialGender.isNotEmpty) {
      selectedGender.value = _convertGenderFromApiFormat(initialGender);
    }
    // Note: If profileId is null, we can assume this is a new profile creation
    // and potentially use initialProfileImagePath or initialSocialProfileImageUrl
    // for the avatar if needed, but currently this controller doesn't seem to
    // manage the avatar selection (Step 0) - it only manages the rest of the profile.

    // Populate initial address details if passed
    final initialPostcode = args['postcode'] as String?;
    final initialAddress = args['address'] as String?;
    final initialLatitude = args['latitude'] as double?;
    final initialLongitude = args['longitude'] as double?;

    if (initialPostcode != null && initialPostcode.isNotEmpty) {
      postcodeController.text = initialPostcode;
    }
    if (initialAddress != null && initialAddress.isNotEmpty) {
      addressController.text = initialAddress;
    }
    if (initialLatitude != null) {
      selectedLatitude.value = initialLatitude;
    }
    if (initialLongitude != null) {
      selectedLongitude.value = initialLongitude;
    }

    final initialStepArg = args['initialStep'] as int?;
    if (initialStepArg != null &&
        initialStepArg >= 0 &&
        initialStepArg < totalSteps) {
      initialStep = initialStepArg;
      currentStep.value = initialStep;
      // Jump to the initial step page after the first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (pageController.hasClients) {
          pageController.jumpToPage(initialStep);
        }
      });
    }

    // Load profession types on init
    _loadProfessionTypes();

    // Load create profile details when step 0 is shown
    if (initialStep == 0) {
      _loadCreateProfileDetails();
    }

    // Add listeners to postcode controllers to trigger validation
    postcodeController.addListener(() {
      if (addressFormKey.currentState != null) {
        addressFormKey.currentState?.validate();
      }
    });
    workPostcodeController.addListener(() {
      if (addressFormKey.currentState != null) {
        addressFormKey.currentState?.validate();
      }
    });
    // Add listeners to address controllers to trigger validation
    addressController.addListener(() {
      if (addressFormKey.currentState != null) {
        addressFormKey.currentState?.validate();
      }
    });
    workAddressController.addListener(() {
      if (addressFormKey.currentState != null) {
        addressFormKey.currentState?.validate();
      }
    });

    // Centralized step-wise API loading
    ever(currentStep, (step) {
      _loadStepData(step);
    });

    // Load data for initial step using centralized method
    if (initialStep > 0) {
      _loadStepData(initialStep);
    }
  }

  bool _isPicking = false;

  Future<void> pickProfileImage(BuildContext context) async {
    // Guard: prevent multiple simultaneous picker calls
    if (_isPicking) return;

    try {
      final source = await _showImageSourceDialog(context);
      if (source == null) return;

      if (source == ImageSource.camera) {
        await _pickFromCamera();
      } else if (source == ImageSource.gallery) {
        await _pickFromGallery();
      }
    } catch (e) {
      debugPrint('Error in pickProfileImage: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _pickFromCamera() async {
    if (_isPicking) return;
    _isPicking = true;

    try {
      final bool hasPermission = await _cameraStoragePermissionService
          .requestCameraAndStoragePermissions();
      if (!hasPermission) {
        _showPermissionSettingsSnackbar();
        return;
      }

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final croppedFile = await _cropImage(File(pickedFile.path));
        if (croppedFile != null) {
          // selectedImage.value = croppedFile; // This controller does not have selectedImage
        }
      }
    } catch (e) {
      debugPrint('Error picking from camera: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isPicking = false;
    }
  }

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
            // selectedImage.value = croppedFile;
          }
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
            final croppedFile = await _cropImage(File(pickedFile.path));
            if (croppedFile != null) {
              // selectedImage.value = croppedFile;
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
              ],
            ),
          ),
        );
      },
    );
  }

  /// Centralized method to load step-wise data
  /// This ensures APIs are called at the right time for each step
  void _loadStepData(int step) {
    debugPrint('_loadStepData called for step: $step');
    switch (step) {
      case 0:
        // Step 0: Create Profile
        debugPrint('Loading step 0: Create Profile');
        _loadCreateProfileDetails();
        break;
      case 1:
        // Step 1: Add Address
        debugPrint('Loading step 1: Add Address');
        _loadCreateAddressDetails();
        break;
      case 2:
        // Step 2: Services
        debugPrint('Loading step 2: Services');
        debugPrint(
            'Services count: ${services.length}, isLoading: ${isLoadingServices.value}');
        // Reset flags to allow loading old services if user hasn't made manual selections
        hasLoadedOldServices.value = false;
        // Always reload services to ensure we have latest data
        // This is important when navigating back from other steps
        _loadServices();
        // Note: _loadProfessionServices() is called in _loadServices() onComplete callback
        break;
      case 3:
        // Step 3: Qualifications
        // Load colleges first, then qualifications (so IDs can be matched)
        _loadCollegesUniversities().then((_) {
          // Wait a bit for colleges to be fully processed
          Future.delayed(const Duration(milliseconds: 100), () {
            _loadQualificationsDetails();
          });
        });
        break;
      case 4:
        // Step 4: Identification
        _loadPersonalIdentificationDetails();
        break;
      case 5:
        // Step 5: About You
        _loadAboutYouDetails();
        break;
      default:
        break;
    }
  }

  /// Load profession types from API
  Future<void> _loadProfessionTypes() async {
    isLoadingProfessionTypes.value = true;
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.getProfessionTypes(),
      showLoader: false,
      onSuccess: (response) {
        if (response.success && response.data != null) {
          // Extract profession types from response using model class
          // Response structure: {success: true, data: [{_id: "...", type: "..."}, ...]}
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
                // Skip invalid items
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
                  // Skip invalid items
                  continue;
                }
              }
              professionTypes.value = types;
            }
          }
        }
      },
      onComplete: () {
        isLoadingProfessionTypes.value = false;
      },
    );
  }

  /// Load create profile details from API
  Future<void> _loadCreateProfileDetails() async {
    // Wait for profession types to be loaded first
    while (isLoadingProfessionTypes.value) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // If profile details are already set (e.g. passed from arguments), skip initial API call
    if (fullNameController.text.isNotEmpty &&
        dobController.text.isNotEmpty &&
        selectedGender.value.isNotEmpty) {
      debugPrint(
          'Profile details already set from arguments, skipping initial API call');
      return;
    }

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

              // Store profile ID if available (for update scenario)
              if (profileDetails.id != null && profileDetails.id!.isNotEmpty) {
                profileId.value = profileDetails.id;
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

                // Find profession type name by ID
                try {
                  final matchingType = professionTypesMap.entries.firstWhere(
                    (entry) => entry.value == professionTypeId,
                  );
                  selectedProfessionType.value = matchingType.key;
                  selectedProfessionTypeId.value = professionTypeId;

                  // Load profession sub-types for the selected type
                  loadProfessionSubTypes(professionTypeId).then((_) {
                    // Populate profession sub-type after sub-types are loaded
                    if (profileDetails.professionSubTypeId != null &&
                        profileDetails.professionSubTypeId!.isNotEmpty) {
                      final professionSubTypeId =
                          profileDetails.professionSubTypeId!;

                      // Store profession_sub_type_id for use in step 2
                      professionSubTypeIdFromResponse.value =
                          professionSubTypeId;
                      debugPrint(
                          'Stored profession_sub_type_id from profile details: $professionSubTypeId');

                      // Find profession sub-type name by ID
                      try {
                        final matchingSubType =
                            professionSubTypesMap.entries.firstWhere(
                          (entry) => entry.value == professionSubTypeId,
                        );
                        selectedProfessionSubType.value = matchingSubType.key;
                        selectedProfessionSubTypeId.value = professionSubTypeId;
                      } catch (e) {
                        // Profession sub-type not found, skip
                        debugPrint(
                            'Profession sub-type not found in map, but ID stored: $professionSubTypeId');
                      }
                    }
                  });
                } catch (e) {
                  // Profession type not found, skip
                }
              }
            }
          } catch (e) {
            // Handle parsing errors silently or log them
            print('Error parsing create profile details: $e');
          }
        }
      },
    );
  }

  /// Load create address details from API
  Future<void> _loadCreateAddressDetails() async {
    // If address is already set (e.g. passed from arguments), skip initial API call
    if (postcodeController.text.isNotEmpty &&
        addressController.text.isNotEmpty) {
      debugPrint(
          'Address already set from arguments, skipping initial API call');
      return;
    }

    await callDataService<ApiResponse<dynamic>>(
      _userApiService.getCreateAddressDetails(),
      showLoader: true,
      onSuccess: (response) {
        if (response.success && response.data != null) {
          try {
            final data = response.data as Map<String, dynamic>?;
            if (data != null) {
              // Parse response using model
              final addressDetails = AddressDetailsModel.fromJson(data);

              // Populate main address
              if (addressDetails.postcode != null &&
                  addressDetails.postcode!.isNotEmpty) {
                postcodeController.text = addressDetails.postcode!;
              }
              if (addressDetails.address != null &&
                  addressDetails.address!.isNotEmpty) {
                addressController.text = addressDetails.address!;
                // Trigger validation after address is set to clear any errors
                Future.microtask(() {
                  addressFormKey.currentState?.validate();
                });
              }
              if (addressDetails.latitude != null &&
                  addressDetails.longitude != null) {
                selectedLatitude.value = addressDetails.latitude;
                selectedLongitude.value = addressDetails.longitude;
              }
              // Store full address ID if available
              if (addressDetails.fullAddressId != null &&
                  addressDetails.fullAddressId!.isNotEmpty) {
                fullAddressId.value = addressDetails.fullAddressId;
              }

              // Populate work address (optional)
              if (addressDetails.workPostcode != null &&
                  addressDetails.workPostcode!.isNotEmpty) {
                workPostcodeController.text = addressDetails.workPostcode!;
              }
              if (addressDetails.workAddress != null &&
                  addressDetails.workAddress!.isNotEmpty) {
                workAddressController.text = addressDetails.workAddress!;
              }
              if (addressDetails.workLatitude != null &&
                  addressDetails.workLongitude != null) {
                workLatitude.value = addressDetails.workLatitude;
                workLongitude.value = addressDetails.workLongitude;
              }
              // Store work address ID if available
              if (addressDetails.workAddressId != null &&
                  addressDetails.workAddressId!.isNotEmpty) {
                workAddressId.value = addressDetails.workAddressId;
              }

              // If address data exists, don't get current location
              // Otherwise, fallback to getting current location
              // if (addressDetails.postcode == null ||
              //     addressDetails.postcode!.isEmpty ||
              //     addressDetails.address == null ||
              //     addressDetails.address!.isEmpty) {
              //   _getCurrentLocationAndFillAddress();
              // }
            }
          } catch (e) {
            // Handle parsing errors
            print('Error parsing create address details: $e');
            // Fallback to getting current location if parsing fails
            // _getCurrentLocationAndFillAddress();
          }
        } else {
          // If no data, get current location
          // _getCurrentLocationAndFillAddress();
        }
      },
      onError: (error, stackTrace) {
        // On error, fallback to getting current location
        // _getCurrentLocationAndFillAddress();
      },
    );
  }

  /// Load profession sub-types based on selected profession type _id
  Future<void> loadProfessionSubTypes(String professionTypeId) async {
    if (professionTypeId.isEmpty) {
      professionSubTypes.clear();
      selectedProfessionSubType.value = null;
      return;
    }

    isLoadingProfessionSubTypes.value = true;
    professionSubTypes.clear();
    selectedProfessionSubType.value = null;

    await callDataService<ApiResponse<dynamic>>(
      _userApiService.getProfessionSubTypes(professionTypeId: professionTypeId),
      showLoader: false,
      onSuccess: (response) {
        if (response.success && response.data != null) {
          // Extract profession sub-types from response using model class
          // Response structure: {success: true, data: [{_id: "...", profession_type: "...", sub_type: "..."}, ...]}
          professionSubTypesMap.clear();
          if (response.data is List) {
            final list = response.data as List;
            final subTypes = <String>[];
            for (final item in list) {
              try {
                if (item is Map<String, dynamic>) {
                  final professionSubType =
                      ProfessionSubTypeModel.fromJson(item);
                  if (professionSubType.subType != null &&
                      professionSubType.id != null) {
                    professionSubTypesMap[professionSubType.subType!] =
                        professionSubType.id!;
                    subTypes.add(professionSubType.subType!);
                  }
                }
              } catch (e) {
                // Skip invalid items
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
                    if (professionSubType.subType != null &&
                        professionSubType.id != null) {
                      professionSubTypesMap[professionSubType.subType!] =
                          professionSubType.id!;
                      subTypes.add(professionSubType.subType!);
                    }
                  }
                } catch (e) {
                  // Skip invalid items
                  continue;
                }
              }
              professionSubTypes.value = subTypes;
            }
          }
        }
      },
      onComplete: () {
        isLoadingProfessionSubTypes.value = false;
      },
    );
  }

  /// Set selected profession type and load sub-types
  void setProfessionType(String? value) {
    if (value == null || value.isEmpty) {
      selectedProfessionType.value = null;
      selectedProfessionTypeId.value = null;
      locationController.clear();
      professionSubTypes.clear();
      selectedProfessionSubType.value = null;
      professionController.clear();
      return;
    }

    selectedProfessionType.value = value;
    locationController.text = value;
    // Get the _id for the selected profession type
    final professionTypeId = professionTypesMap[value];
    if (professionTypeId != null) {
      selectedProfessionTypeId.value = professionTypeId;
      // Load sub-types for the selected profession type using _id
      loadProfessionSubTypes(professionTypeId);
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

  Future<void> nextStep() async {
    // Step 0: Create Profile - Validate form and call API
    // API: create-profile
    // Response: Contains profession_sub_type which is saved for Step 2
    if (currentStep.value == 0) {
      hasValidated.value = true;
      final isValid = formKey.currentState?.validate() ?? false;
      if (!isValid) {
        return;
      }
      await _createProfile();
      return;
    }

    // Step 1: Address - Validate form and call API independently
    // API: create-address
    // This step calls its own API independently, does not extract profession_sub_type
    if (currentStep.value == 1) {
      addressHasValidated.value = true;
      if (addressFormKey.currentState != null) {
        final isValid = addressFormKey.currentState!.validate();
        if (!isValid) {
          return;
        }
      }
      await _createAddress();
      return;
    }

    // Step 2: Services - Validate selection and call API
    // API: save-profession-services
    // Uses profession_sub_type from Step 0 API response (stored in professionSubTypeIdFromResponse)
    if (currentStep.value == 2) {
      // Validate that at least one service is selected
      if (selectedServiceIds.isEmpty && selectedSubServiceIds.isEmpty) {
        showResponseDialog(
          title: 'Error',
          message: 'Please select at least one service',
          isError: true,
          showButton: true,
        );
        return;
      }
      await _saveProfessionServices();
      return;
    }

    // Step 3: Qualifications - Validate forms and call API
    if (currentStep.value == 3) {
      qualificationsHasValidated.value = true;
      await _saveQualifications();
      return;
    }

    // Step 4: Personal Identification - Validate form and call API
    if (currentStep.value == 4) {
      identificationHasValidated.value = true;
      if (identificationFormKey.currentState != null) {
        final isValid = identificationFormKey.currentState!.validate();
        if (!isValid) {
          return;
        }
      }
      await _savePersonalIdentification();
      return;
    }

    // Step 5: About You - Validate form and call API
    if (currentStep.value == 5) {
      aboutYouHasValidated.value = true;
      if (aboutYouFormKey.currentState != null) {
        final isValid = aboutYouFormKey.currentState!.validate();
        if (!isValid) {
          return;
        }
      }
      await _saveAboutYou();
      return;
    }

    // Fallback navigation (should not reach here)
    if (currentStep.value < totalSteps - 1) {
      currentStep.value += 1;
      // Reset validation state for next step
      hasValidated.value = false;
      addressHasValidated.value = false;
      qualificationsHasValidated.value = false;
      // Load colleges/universities when navigating to step 3 (Qualifications)
      if (currentStep.value == 3) {
        _loadCollegesUniversities();
      }
      pageController.animateToPage(
        currentStep.value,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
      return;
    }

    // Get.offAllNamed(Routes.subscription);

    loadProfileDetails();

    // Get.offAllNamed(Routes.home);
  }

  Future<void> loadProfileDetails() async {
    final apiService = _userApiService;
    if (apiService == null) {
      logError('UserApiService not available');
      return;
    }

    await callDataService(
      apiService.getProfileDetails(),
      showLoader: true,
      onSuccess: (response) async {
        if (response.success && response.data != null) {
          try {
            final data = response.data as Map<String, dynamic>?;
            if (data != null) {
              final profile = ProfileDetailsModel.fromJson(data);
              // if (isFromSignup) {
              final resolvedPersona = AnalyticsService.resolvePersona(
                professionName: profile.profession_name,
              );
              final resolvedCity =
                  await getCityFromAddress(profile.address.toString());
              final regType = profile.registrationType?.toString() ?? 'email';
              final analyticsRegType =
                  (regType == 'google' || regType == 'facebook')
                      ? 'google'
                      : (regType == 'apple' ? 'apple' : 'regular');

              await AnalyticsService.instance.setUserProfile(
                loginState: 'logged_in',
                userId: profile.id,
                city: resolvedCity,
                persona: resolvedPersona,
                plan: profile.planNameSnapshot,
                registrationType: analyticsRegType,
                oncePerLogin: true,
              );

              Get.offAllNamed(Routes.home);

              // Log subscription purchase event
              // final planPeriod = _getTimePeriodFromPlan(selectedtitle.value);
              // await AnalyticsService.instance.logPurchaseEvent(
              //   item: AnalyticsService.instance.buildItem(
              //     itemId: selectedPlanId.value.isNotEmpty ? selectedPlanId.value : 'unknown',
              //     itemName: selectedtitle.value.isNotEmpty ? selectedtitle.value : 'subscription',
              //     itemCategory: resolvedPersona,
              //     itemVariant: planPeriod,
              //     itemBrand: 'verithrive',
              //     price: 0.0,
              //     quantity: 1,
              //   ),
              //   transactionId: selectedPlanId.value.isNotEmpty
              //       ? '${selectedPlanId.value}_${DateTime.now().millisecondsSinceEpoch}'
              //       : DateTime.now().millisecondsSinceEpoch.toString(),
              //   value: 0.0,
              //   currency: 'GBP',
              // );

              // } else {
              //   await AnalyticsService.instance.setUserProfile(
              //     plan: _getTimePeriodFromPlan(selectedtitle.value),
              //   );
              // }
            } else {
              logError('Profile data is null');
            }
          } catch (e, stackTrace) {
            logError('Error parsing profile details',
                error: e, stackTrace: stackTrace);
          }
        } else {
          logError('Failed to load profile details: ${response.message}');
        }
      },
      onError: (error, stack) {
        logError('Failed to load profile details',
            error: error, stackTrace: stack);
      },
    );
  }

  Future<String?> getCityFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        double lat = locations.first.latitude;
        double lng = locations.first.longitude;
        List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          return (placemarks.first.locality ??
                  placemarks.first.subAdministrativeArea ??
                  '')
              .toLowerCase();
        }
      }
    } catch (e) {
      print("Error getCityFromAddress: $e");
    }
    return null;
  }

  /// Create profile API call (Step 0)
  /// This API creates the user profile and returns profession_sub_type in response
  /// The profession_sub_type is extracted and saved for use in Step 2
  Future<void> _createProfile() async {
    // Note: Form validation is done in nextStep() before calling this method
    final professionTypeId = selectedProfessionTypeId.value;
    final professionSubTypeId = selectedProfessionSubTypeId.value;
    final fullName = fullNameController.text.trim();
    final dobText = dobController.text.trim();
    final gender = selectedGender.value;

    // Additional server-side validation (backup check)
    if (professionTypeId == null || professionTypeId.isEmpty) {
      showResponseDialog(
        title: 'Error',
        message: 'Please select profession type',
        isError: true,
        showButton: true,
      );
      return;
    }

    if (professionSubTypeId == null || professionSubTypeId.isEmpty) {
      showResponseDialog(
        title: 'Error',
        message: 'Please select profession',
        isError: true,
        showButton: true,
      );
      return;
    }

    if (fullName.isEmpty) {
      showResponseDialog(
        title: 'Error',
        message: 'Please enter full name',
        isError: true,
        showButton: true,
      );
      return;
    }

    if (dobText.isEmpty || selectedDob.value == null) {
      showResponseDialog(
        title: 'Error',
        message: 'Please select date of birth',
        isError: true,
        showButton: true,
      );
      return;
    }

    if (gender.isEmpty) {
      showResponseDialog(
        title: 'Error',
        message: 'Please select gender',
        isError: true,
        showButton: true,
      );
      return;
    }

    // Format date from dd/MM/yyyy to yyyy-MM-dd
    String formattedDob;
    try {
      final dobDate = selectedDob.value!;
      formattedDob =
          '${dobDate.year}-${dobDate.month.toString().padLeft(2, '0')}-${dobDate.day.toString().padLeft(2, '0')}';
    } catch (e) {
      // Try parsing from dd/MM/yyyy format if selectedDob is null
      try {
        final parts = dobText.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          formattedDob =
              '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
        } else {
          throw Exception('Invalid date format');
        }
      } catch (e) {
        showResponseDialog(
          title: 'Error',
          message: 'Invalid date format. Please select date again.',
          isError: true,
          showButton: true,
        );
        return;
      }
    }

    await callDataService<ApiResponse<dynamic>>(
      _userApiService.createProfile(
        professionTypeId: professionTypeId,
        professionSubTypeId: professionSubTypeId,
        fullName: fullName,
        dob: formattedDob,
        gender: gender,
        id: profileId.value,
      ),
      showLoader: true,
      onSuccess: (response) async {
        if (response.success) {
          // Extract and save user flags from response
          // Response structure: {success: true, data: {user: {...}}}
          final storage = _storageService;
          if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;

            // Extract user object
            if (data['user'] is Map<String, dynamic>) {
              final user = data['user'] as Map<String, dynamic>;

              // Extract profession_sub_type from Step 0 API response for use in Step 2
              final professionSubType = user['profession_sub_type'] as String?;
              if (professionSubType != null && professionSubType.isNotEmpty) {
                professionSubTypeIdFromResponse.value = professionSubType;
                debugPrint(
                    'Step 0: Extracted profession_sub_type: $professionSubType');
              }

              // Extract and save all user flags
              if (storage != null) {
                final flags = [
                  'is_profile_created',
                  'is_work_full',
                  'is_professional_services',
                  'is_qualification',
                  'is_personal_identification',
                  'is_about_you',
                  'is_payment',
                  'is_personal_details',
                  'is_term_condition',
                ];

                for (final flag in flags) {
                  final value = user[flag] as bool?;
                  if (value != null) {
                    await storage.writeBool(flag, value);
                  }
                }
              }
            }
          }

          // Navigate to next step after successful API call
          if (currentStep.value < totalSteps - 1) {
            currentStep.value += 1;
            // Analytics: Log step completion

            // Reset validation state for next step
            hasValidated.value = false;
            addressHasValidated.value = false;
            qualificationsHasValidated.value = false;
            identificationHasValidated.value = false;
            aboutYouHasValidated.value = false;
            // Load colleges/universities when navigating to step 3 (Qualifications)
            if (currentStep.value == 3) {
              _loadCollegesUniversities();
            }
            pageController.animateToPage(
              currentStep.value,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
            );
          }
        } else {
          showResponseDialog(
            title: 'Error',
            message: response.errorMessage,
            isError: true,
            showButton: true,
          );
        }
      },
      onError: (error, stack) {
        final errorMsg = errorMessage.value.isNotEmpty
            ? errorMessage.value
            : 'Failed to create profile. Please try again.';
        showResponseDialog(
          title: 'Error',
          message: errorMsg,
          isError: true,
          showButton: true,
        );
      },
    );
  }

  String? validateNotEmpty(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $label';
    }
    return null;
  }

  /// Create address API call (Step 1)
  /// This step calls its own API independently
  /// Does not extract profession_sub_type (already extracted from Step 0)
  Future<void> _createAddress() async {
    // Note: Form validation is done in nextStep() before calling this method
    final postcode = postcodeController.text.trim();
    final address = addressController.text.trim();
    final workPostcode = workPostcodeController.text.trim();
    final workAddress = workAddressController.text.trim();

    // Prepare full_address array with latitude and longitude
    final fullAddressMap = <String, dynamic>{
      'postcode': postcode,
      'address': address,
    };

    // Add latitude and longitude - use selected first, then fallback to current location
    double? latitude;
    double? longitude;

    if (selectedLatitude.value != null && selectedLongitude.value != null) {
      // Use selected coordinates (from map selection)
      latitude = selectedLatitude.value;
      longitude = selectedLongitude.value;
    } else {
      // Fallback to current location if selected coordinates are not available
      try {
        bool hasPermission =
            await _locationPermissionService.checkLocationPermissionStatus();
        if (!hasPermission) {
          hasPermission =
              await _locationPermissionService.requestLocationPermission();
        }

        if (hasPermission) {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw TimeoutException('Location request timed out'),
          );
          latitude = position.latitude;
          longitude = position.longitude;
        }
      } catch (e) {
        debugPrint('Could not get current location: $e');
        // Continue without coordinates if location cannot be obtained
      }
    }

    // Add coordinates to full_address if available
    if (latitude != null && longitude != null) {
      fullAddressMap['latitude'] = latitude;
      fullAddressMap['longitude'] = longitude;
    }

    // Add _id if available (for update scenario)
    if (fullAddressId.value != null && fullAddressId.value!.isNotEmpty) {
      fullAddressMap['id'] = fullAddressId.value;
    }

    final fullAddress = [fullAddressMap];

    // Prepare work_address array (optional) with latitude and longitude
    // Validation is handled by form validators, so we can proceed if form is valid
    List<Map<String, dynamic>>? workAddressList;
    if (workPostcode.isNotEmpty && workAddress.isNotEmpty) {
      final workAddressMap = <String, dynamic>{
        'postcode': workPostcode,
        'address': workAddress,
      };

      // Add work latitude and longitude if available
      if (workLatitude.value != null && workLongitude.value != null) {
        workAddressMap['latitude'] = workLatitude.value;
        workAddressMap['longitude'] = workLongitude.value;
      }

      // Add work address _id if available (for update scenario)
      if (workAddressId.value != null && workAddressId.value!.isNotEmpty) {
        workAddressMap['id'] = workAddressId.value;
      }

      workAddressList = [workAddressMap];
    }

    await callDataService<ApiResponse<dynamic>>(
      _userApiService.createAddress(
        fullAddress: fullAddress,
        workAddress: workAddressList,
      ),
      showLoader: true,
      onSuccess: (response) async {
        if (response.success) {
          // Step 1 API call - Address creation
          // Extract and save user flags from response (same as login controller)
          final storage = _storageService;
          if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            if (data['user'] is Map<String, dynamic>) {
              final user = data['user'] as Map<String, dynamic>;

              // Extract profession_sub_type from response as fallback/update
              final professionSubType = user['profession_sub_type'] as String?;
              if (professionSubType != null && professionSubType.isNotEmpty) {
                // Update profession_sub_type if available (fallback/update from Step 1)
                professionSubTypeIdFromResponse.value = professionSubType;
                debugPrint(
                    'Step 1: Updated profession_sub_type from address API: $professionSubType');
              }

              // Extract and save all user flags (same pattern as login controller)
              if (storage != null) {
                final flags = [
                  'is_personal_details',
                  'is_term_condition',
                  'is_profile_created',
                  'is_work_full',
                  'is_professional_services',
                  'is_qualification',
                  'is_personal_identification',
                  'is_about_you',
                  'is_payment',
                  'is_notification',
                ];

                for (final flag in flags) {
                  final value = user[flag] as bool?;
                  if (value != null) {
                    await storage.writeBool(flag, value);
                    debugPrint('Step 1: Saved flag $flag = $value');
                  }
                }
              }
            }
          }

          // Navigate to next step after successful API call
          if (currentStep.value < totalSteps - 1) {
            currentStep.value += 1;
            // Analytics: Log step completion

            // Reset validation state for next step
            hasValidated.value = false;
            addressHasValidated.value = false;
            qualificationsHasValidated.value = false;
            identificationHasValidated.value = false;
            aboutYouHasValidated.value = false;
            // Load colleges/universities when navigating to step 3 (Qualifications)
            if (currentStep.value == 3) {
              _loadCollegesUniversities();
            }
            pageController.animateToPage(
              currentStep.value,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
            );
          }
        } else {
          showResponseDialog(
            title: 'Error',
            message: response.errorMessage,
            isError: true,
            showButton: true,
          );
        }
      },
      onError: (error, stack) {
        final errorMsg = errorMessage.value.isNotEmpty
            ? errorMessage.value
            : 'Failed to save address. Please try again.';
        showResponseDialog(
          title: 'Error',
          message: errorMsg,
          isError: true,
          showButton: true,
        );
      },
    );
  }

  /// Save profession services API call (Step 2)
  /// Uses profession_sub_type from Step 0 API response
  Future<void> _saveProfessionServices() async {
    // Use profession_sub_type from Step 0 API response (stored in professionSubTypeIdFromResponse)
    // Fallback to selectedProfessionSubTypeId if not available
    final professionTypeId = selectedProfessionTypeId.value;
    final professionSubTypeId = professionSubTypeIdFromResponse.value ??
        selectedProfessionSubTypeId.value;

    debugPrint(
        'Step 2: Using profession_sub_type from Step 0: ${professionSubTypeIdFromResponse.value ?? "Not available, using selected: ${selectedProfessionSubTypeId.value}"}');

    // Validate required fields
    if (professionTypeId == null || professionTypeId.isEmpty) {
      showResponseDialog(
        title: 'Error',
        message: 'Profession type is required',
        isError: true,
        showButton: true,
      );
      return;
    }

    if (professionSubTypeId == null || professionSubTypeId.isEmpty) {
      showResponseDialog(
        title: 'Error',
        message: 'Profession sub-type is required',
        isError: true,
        showButton: true,
      );
      return;
    }

    // Note: Service selection validation is done in nextStep() before calling this method

    // Build services array for API
    final servicesList = <Map<String, dynamic>>[];

    // Add services without sub-services (simple services)
    // These are services that don't have sub_services array or have empty sub_services
    for (final serviceId in selectedServiceIds) {
      // Only add if this service doesn't have sub-services selected
      // (services with sub-services are handled separately)
      if (!selectedSubServiceIds.containsKey(serviceId)) {
        servicesList.add({
          'service_id': serviceId,
          'sub_service_ids': <String>[],
        });
      }
    }

    // Add services with sub-services
    // These are services that have sub_services and at least one sub-service is selected
    for (final entry in selectedSubServiceIds.entries) {
      if (entry.value.isNotEmpty) {
        servicesList.add({
          'service_id': entry.key,
          'sub_service_ids': entry.value,
        });
      }
    }

    await callDataService<ApiResponse<dynamic>>(
      _userApiService.saveProfessionServices(
        professionTypeId: professionTypeId,
        professionSubTypeId: professionSubTypeId,
        services: servicesList,
      ),
      showLoader: true,
      onSuccess: (response) async {
        if (response.success) {
          // Analytics: Log professional wizard completion

          // Extract and save user flags from response (same as login controller)
          final storage = _storageService;
          if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            if (data['user'] is Map<String, dynamic>) {
              final user = data['user'] as Map<String, dynamic>;

              // Extract and save all user flags
              if (storage != null) {
                final flags = [
                  'is_personal_details',
                  'is_term_condition',
                  'is_profile_created',
                  'is_work_full',
                  'is_professional_services',
                  'is_qualification',
                  'is_personal_identification',
                  'is_about_you',
                  'is_payment',
                  'is_notification',
                ];

                for (final flag in flags) {
                  final value = user[flag] as bool?;
                  if (value != null) {
                    await storage.writeBool(flag, value);
                    debugPrint('Step 2: Saved flag $flag = $value');
                  }
                }
              }
            }
          }

          // Reset manual selection flag after successful save
          // This allows old services to be loaded next time user visits this step
          hasUserMadeManualSelection.value = false;
          hasLoadedOldServices.value = false;

          // Navigate to next step after successful API call
          if (currentStep.value < totalSteps - 1) {
            currentStep.value += 1;
            // Analytics: Log step completion

            // Reset validation state for next step
            hasValidated.value = false;
            addressHasValidated.value = false;
            qualificationsHasValidated.value = false;
            identificationHasValidated.value = false;
            aboutYouHasValidated.value = false;
            // Load colleges/universities when navigating to step 3 (Qualifications)
            if (currentStep.value == 3) {
              _loadCollegesUniversities();
            }
            pageController.animateToPage(
              currentStep.value,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
            );
          }
        } else {
          showResponseDialog(
            title: 'Error',
            message: response.errorMessage,
            isError: true,
            showButton: true,
          );
        }
      },
      onError: (error, stack) {
        final errorMsg = errorMessage.value.isNotEmpty
            ? errorMessage.value
            : 'Failed to save services. Please try again.';
        showResponseDialog(
          title: 'Error',
          message: errorMsg,
          isError: true,
          showButton: true,
        );
      },
    );
  }

  void previousStep() {
    // If we're at step 0 (first step), navigate back to previous screen
    if (currentStep.value == 0) {
      Get.back();
      return;
    }
    // Otherwise, go to previous step within wizard
    // Allow navigation to all previous steps regardless of initialStep
    final previousStepValue = currentStep.value - 1;
    currentStep.value = previousStepValue;

    // Note: _loadStepData() will be called automatically by the ever() listener
    // when currentStep.value changes, so we don't need to call it explicitly here

    pageController.animateToPage(
      currentStep.value,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void setGender(String? value) {
    selectedGender.value = value ?? '';
  }

  void setIdType(String? value) {
    selectedIdType.value = value ?? '';
    if (value != null) {
      idTypeController.text = value;
    }
    // Trigger form validation after selection
    identificationFormKey.currentState?.validate();
  }

  void toggleService(String serviceName, String serviceId) {
    // Mark that user has made manual selection
    hasUserMadeManualSelection.value = true;

    if (selectedServices.contains(serviceName)) {
      selectedServices.remove(serviceName);
      selectedServiceIds.remove(serviceId);
    } else {
      selectedServices.add(serviceName);
      selectedServiceIds.add(serviceId);
    }
    selectedServices.refresh();
    selectedServiceIds.refresh();
  }

  void toggleServiceExpansion(String serviceId) {
    if (expandedServices.contains(serviceId)) {
      expandedServices.remove(serviceId);
    } else {
      expandedServices.add(serviceId);
    }
    expandedServices.refresh();
  }

  bool isServiceExpanded(String serviceId) {
    return expandedServices.contains(serviceId);
  }

  void toggleSubService(
      String subServiceName, String subServiceId, String serviceId) {
    // Mark that user has made manual selection
    hasUserMadeManualSelection.value = true;

    // Toggle UI selection
    if (selectedServices.contains(subServiceName)) {
      selectedServices.remove(subServiceName);
      // Remove from sub-service IDs map
      if (selectedSubServiceIds.containsKey(serviceId)) {
        selectedSubServiceIds[serviceId]!.remove(subServiceId);
        if (selectedSubServiceIds[serviceId]!.isEmpty) {
          selectedSubServiceIds.remove(serviceId);
        }
      }
    } else {
      selectedServices.add(subServiceName);
      // Add to sub-service IDs map
      if (!selectedSubServiceIds.containsKey(serviceId)) {
        selectedSubServiceIds[serviceId] = [];
      }
      if (!selectedSubServiceIds[serviceId]!.contains(subServiceId)) {
        selectedSubServiceIds[serviceId]!.add(subServiceId);
      }
    }
    selectedServices.refresh();
    selectedSubServiceIds.refresh();
  }

  void onAboutYouChanged(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      aboutYouCharacterCount.value = 0;
      return;
    }
    // Count characters (excluding spaces)
    final characterCount = trimmed.replaceAll(' ', '').length;
    aboutYouCharacterCount.value = characterCount;
    debugPrint('Character count calculated: $characterCount characters');
    debugPrint(
        'Text preview: "${trimmed.substring(0, trimmed.length > 100 ? 100 : trimmed.length)}..."');
  }

  Future<void> pickDobDate(BuildContext context) async {
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
      selectableDayPredicate: (day) => !day.isAfter(today),
    );

    if (picked != null) {
      selectedDob.value = picked;
      dobController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<void> pickDate(
    BuildContext context,
    TextEditingController target,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) {
      target.text = '${picked.day.toString().padLeft(2, '0')}/'
          '${picked.month.toString().padLeft(2, '0')}/'
          '${picked.year}';
    }
  }

  Future<void> pickIdExpiryDate(
    BuildContext context,
    TextEditingController target, {
    int? qualificationIndex,
  }) async {
    final now = DateTime.now();
    // Set initial date to tomorrow to ensure it's always a future date
    final initialDate = now.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now, // Only allow today and future dates
      lastDate: DateTime(now.year + 50), // Allow up to 50 years in the future
    );
    if (picked != null) {
      target.text = '${picked.day.toString().padLeft(2, '0')}/'
          '${picked.month.toString().padLeft(2, '0')}/'
          '${picked.year}';
      // Trigger form validation after date is selected
      if (qualificationIndex != null &&
          qualificationIndex >= 0 &&
          qualificationIndex < qualificationFormKeys.length) {
        // Validate qualification form
        final formKey = qualificationFormKeys[qualificationIndex];
        formKey.currentState?.validate();
      } else {
        // Validate identification form
        identificationFormKey.currentState?.validate();
      }
    }
  }

  void addQualification() {
    qualifications.add(QualificationItem.initial());
    qualificationFormKeys.add(GlobalKey<FormState>());
    qualifications.refresh();
    // Scroll to the bottom to show the newly added section after a short delay to allow UI to update
    Future.delayed(const Duration(milliseconds: 150), () {
      if (qualificationsScrollController.hasClients) {
        // Scroll to the maximum extent to show the newly added section
        qualificationsScrollController.animateTo(
          qualificationsScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void removeQualification(QualificationItem item) {
    if (qualifications.length <= 1) return;
    final index = qualifications.indexOf(item);
    if (index >= 0 && index < qualificationFormKeys.length) {
      qualificationFormKeys.removeAt(index);
    }
    // If the qualification has an ID (from API), add it to removedIds
    if (item.id != null && item.id!.isNotEmpty) {
      removedQualificationIds.add(item.id!);
      debugPrint('Added qualification ID to removedIds: ${item.id}');
    }
    qualifications.remove(item);
    item.dispose();
    qualifications.refresh();
  }

  /// Validate date format (dd/MM/yyyy)
  String? validateDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    final datePattern = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!datePattern.hasMatch(value.trim())) {
      return 'Please enter date in dd/mm/yyyy format';
    }
    try {
      final parts = value.trim().split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        if (day < 1 || day > 31 || month < 1 || month > 12 || year < 1900) {
          return 'Please enter a valid date';
        }
      }
    } catch (e) {
      return 'Please enter a valid date';
    }
    return null;
  }

  /// Validate required date field
  String? validateRequiredDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter expiry date';
    }
    final datePattern = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!datePattern.hasMatch(value.trim())) {
      return 'Please enter date in dd/mm/yyyy format';
    }
    try {
      final parts = value.trim().split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        if (day < 1 || day > 31 || month < 1 || month > 12 || year < 1900) {
          return 'Please enter a valid date';
        }
      }
    } catch (e) {
      return 'Please enter a valid date';
    }
    return null;
  }

  /// Set selected college/university for a qualification item
  void setCollegeUniversity(QualificationItem item, String? value, int index) {
    if (value == null || value.isEmpty) {
      item.selectedCollegeUniversity = null;
      item.selectedCollegeUniversityId = null;
      item.schoolController.clear();
      // Trigger form validation
      if (index >= 0 && index < qualificationFormKeys.length) {
        final formKey = qualificationFormKeys[index];
        formKey.currentState?.validate();
      }
      return;
    }

    item.selectedCollegeUniversity = value;
    item.schoolController.text = value;
    // Get the _id for the selected college/university
    final collegeUniversityId = collegesUniversitiesMap[value];
    if (collegeUniversityId != null) {
      item.selectedCollegeUniversityId = collegeUniversityId;
    } else {
      // Custom text entered - no ID
      item.selectedCollegeUniversityId = null;
    }

    // Trigger form validation after selection
    if (index >= 0 && index < qualificationFormKeys.length) {
      final formKey = qualificationFormKeys[index];
      formKey.currentState?.validate();
    }
  }

  /// Handle text change in college/university field
  void onCollegeUniversityTextChanged(
      QualificationItem item, String value, int index) {
    item.schoolController.text = value;
    // Check if the text matches any college/university
    final matchedCollege = collegesUniversities.firstWhereOrNull(
      (college) => college.toLowerCase() == value.toLowerCase(),
    );

    if (matchedCollege != null) {
      // Exact match found
      item.selectedCollegeUniversity = matchedCollege;
      item.selectedCollegeUniversityId =
          collegesUniversitiesMap[matchedCollege];
    } else {
      // Custom text - no match
      item.selectedCollegeUniversity = value.isNotEmpty ? value : null;
      item.selectedCollegeUniversityId = null;
    }

    // Trigger form validation after text change
    if (index >= 0 && index < qualificationFormKeys.length) {
      final formKey = qualificationFormKeys[index];
      formKey.currentState?.validate();
    }
  }

  /// Get filtered colleges/universities based on search query
  List<String> getFilteredCollegesUniversities(String query) {
    if (query.isEmpty) {
      return collegesUniversities;
    }
    return collegesUniversities
        .where((college) => college.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Handle degree/certificate text changes and validate form
  void onDegreeCertificateChanged(String value, int index) {
    // Trigger form validation after text change to clear errors
    if (index >= 0 && index < qualificationFormKeys.length) {
      final formKey = qualificationFormKeys[index];
      formKey.currentState?.validate();
    }
  }

  /// Save qualifications API call
  Future<void> _saveQualifications() async {
    debugPrint('=== Starting Save Qualifications ===');
    debugPrint('Total Qualifications: ${qualifications.length}');

    // Validate all qualification forms
    bool allFormsValid = true;
    for (int i = 0; i < qualificationFormKeys.length; i++) {
      final formKey = qualificationFormKeys[i];
      if (formKey.currentState != null) {
        final isValid = formKey.currentState!.validate();
        if (!isValid) {
          allFormsValid = false;
          debugPrint('Qualification form[$i] is invalid');
        }
      }
    }

    // Validate experience form
    if (experienceFormKey.currentState != null) {
      final isExperienceValid = experienceFormKey.currentState!.validate();
      if (!isExperienceValid) {
        allFormsValid = false;
        debugPrint('Experience form is invalid');
      }
    }

    if (!allFormsValid) {
      return;
    }

    // Parse total experience
    int totalExperience = 0;
    try {
      final experienceText = yearsExperienceController.text.trim();
      debugPrint('Experience Text: $experienceText');
      if (experienceText.isNotEmpty) {
        totalExperience = int.parse(experienceText);
      }
    } catch (e) {
      // If parsing fails, default to 0
      debugPrint('Error parsing experience: $e');
      totalExperience = 0;
    }
    // debugPrint('Total Experience (parsed): $totalExperience');

    // Build qualifications array
    final qualificationsList = <Map<String, dynamic>>[];
    final certificateFiles = <File>[];

    for (int i = 0; i < qualifications.length; i++) {
      final qualification = qualifications[i];
      final school = qualification.schoolController.text.trim();
      final degree = qualification.degreeController.text.trim();
      final expiryText =
          qualification.qualificationExpiryController.text.trim();

      debugPrint('--- Processing Qualification[$i] ---');
      debugPrint('School: $school');
      debugPrint('Degree: $degree');
      debugPrint('Expiry Text: $expiryText');
      debugPrint('Qualification ID: ${qualification.id}');
      debugPrint(
          'Is in removed list: ${qualification.id != null && removedQualificationIds.contains(qualification.id)}');
      debugPrint(
          'Has College ID: ${qualification.selectedCollegeUniversityId != null && qualification.selectedCollegeUniversityId!.isNotEmpty}');
      debugPrint('College ID: ${qualification.selectedCollegeUniversityId}');
      debugPrint(
          'Has Certificate File: ${qualification.certificateFile != null}');
      debugPrint(
          'Has Certificate URL: ${qualification.certificateUrl != null && qualification.certificateUrl!.isNotEmpty}');

      // Format expiry date from dd/MM/yyyy to yyyy-MM-dd
      String? formattedExpiryDate;
      if (expiryText.isNotEmpty) {
        try {
          final parts = expiryText.split('/');
          if (parts.length == 3) {
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            formattedExpiryDate =
                '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
            debugPrint('Formatted Expiry Date: $formattedExpiryDate');
          }
        } catch (e) {
          debugPrint('Error parsing expiry date: $e');
        }
      }

      // Build qualification object
      final qualificationData = <String, dynamic>{
        'degree_or_certificate': degree,
      };

      // Add qualification ID ONLY if it exists and is NOT in the removed list (for updates)
      // New qualifications (added by user) will not have an ID, so they won't have _id field
      if (qualification.id != null &&
          qualification.id!.isNotEmpty &&
          !removedQualificationIds.contains(qualification.id)) {
        qualificationData['id'] = qualification.id;
        debugPrint('Qualification ID for update: ${qualification.id}');
      } else if (qualification.id != null && qualification.id!.isNotEmpty) {
        debugPrint(
            'Qualification ID ${qualification.id} is in removed list, skipping _id');
      } else {
        debugPrint('Qualification is new (no ID), will be created');
      }

      // If school/university has an ID (selected from dropdown):
      // - Pass college/university ID in 'school_or_university' field
      // Otherwise (custom text):
      // - Pass text in 'school_or_university' field
      if (qualification.selectedCollegeUniversityId != null &&
          qualification.selectedCollegeUniversityId!.isNotEmpty) {
        // Selected from dropdown - pass college/university ID
        qualificationData['school_or_university'] =
            qualification.selectedCollegeUniversityId;
        debugPrint(
            'College/University ID: ${qualification.selectedCollegeUniversityId}');
        debugPrint('School/University Name: $school');
      } else {
        // Custom text entered - pass text in 'school_or_university'
        qualificationData['school_or_university'] = school;
        debugPrint('Using Custom Text: $school');
      }

      if (formattedExpiryDate != null) {
        qualificationData['expiry_date'] = formattedExpiryDate;
      }

      qualificationsList.add(qualificationData);
      debugPrint('Qualification Data: $qualificationData');

      // Add certificate file if available (new upload or existing from URL)
      if (qualification.certificateFile != null) {
        certificateFiles.add(qualification.certificateFile!);
        debugPrint(
            'Added certificate file: ${qualification.certificateFile!.path}');
      } else if (qualification.certificateUrl != null &&
          qualification.certificateUrl!.isNotEmpty) {
        // Download existing certificate from URL
        try {
          final downloadedFile = await _downloadCertificateFile(
              qualification.certificateUrl!, qualification.id ?? 'cert_$i');
          if (downloadedFile != null) {
            certificateFiles.add(downloadedFile);
            debugPrint(
                'Downloaded and added certificate file from URL: ${downloadedFile.path}');
          } else {
            debugPrint(
                'Failed to download certificate from URL: ${qualification.certificateUrl}');
          }
        } catch (e) {
          debugPrint('Error downloading certificate: $e');
        }
      }
    }

    debugPrint('=== Prepared Data for API ===');
    debugPrint('Total Experience: $totalExperience');
    debugPrint('Qualifications Count: ${qualificationsList.length}');
    debugPrint('Certificate Files Count: ${certificateFiles.length}');
    debugPrint('Removed IDs Count: ${removedQualificationIds.length}');
    debugPrint('Removed IDs: ${removedQualificationIds.toList()}');

    debugPrint('=== Calling API ===');
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.upsertQualifications(
        totalExperience: totalExperience,
        qualifications: qualificationsList,
        removedIds: removedQualificationIds.toList(),
        certificateFiles: certificateFiles.isNotEmpty ? certificateFiles : null,
      ),
      showLoader: true,
      onSuccess: (response) async {
        debugPrint('=== API Response Success ===');
        debugPrint('Success: ${response.success}');
        debugPrint('Error Message: ${response.errorMessage}');
        if (response.success) {
          // Analytics: Log professional wizard completion

          // Extract and save user flags from response (same as login controller)
          final storage = _storageService;
          if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            if (data['user'] is Map<String, dynamic>) {
              final user = data['user'] as Map<String, dynamic>;

              // Extract and save all user flags
              if (storage != null) {
                final flags = [
                  'is_personal_details',
                  'is_term_condition',
                  'is_profile_created',
                  'is_work_full',
                  'is_professional_services',
                  'is_qualification',
                  'is_personal_identification',
                  'is_about_you',
                  'is_payment',
                  'is_notification',
                ];

                for (final flag in flags) {
                  final value = user[flag] as bool?;
                  if (value != null) {
                    await storage.writeBool(flag, value);
                    debugPrint('Step 3: Saved flag $flag = $value');
                  }
                }
              }
            }
          }

          // Navigate to next step after successful API call
          if (currentStep.value < totalSteps - 1) {
            currentStep.value += 1;
            // Analytics: Log step completion

            // Reset validation state for next step
            hasValidated.value = false;
            addressHasValidated.value = false;
            qualificationsHasValidated.value = false;
            identificationHasValidated.value = false;
            aboutYouHasValidated.value = false;
            pageController.animateToPage(
              currentStep.value,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
            );
          }
        } else {
          debugPrint('=== API Response Failed ===');
          debugPrint('Error: ${response.errorMessage}');
          showResponseDialog(
            title: 'Error',
            message: response.errorMessage,
            isError: true,
            showButton: true,
          );
        }
      },
      onError: (error, stack) {
        debugPrint('=== API Call Error ===');
        debugPrint('Error: $error');
        debugPrint('Stack: $stack');
        final errorMsg = errorMessage.value.isNotEmpty
            ? errorMessage.value
            : 'Failed to save qualifications. Please try again.';
        debugPrint('Error Message: $errorMsg');
        showResponseDialog(
          title: 'Error',
          message: errorMsg,
          isError: true,
          showButton: true,
        );
      },
    );
  }

  /// Save personal identification API call
  Future<void> _savePersonalIdentification() async {
    debugPrint('=== Starting Save Personal Identification ===');

    // Note: Form validation is done in nextStep() before calling this method
    final idTypeText = selectedIdType.value;
    final expiryText = idExpiryController.text.trim();

    debugPrint('ID Type Text: $idTypeText');
    debugPrint('Expiry Text: $expiryText');
    debugPrint('Has ID File: ${idFile != null}');
    debugPrint('Identification ID: ${identificationId.value}');

    // Convert ID type to API format
    String idType;
    if (idTypeText.toLowerCase() == 'passport') {
      idType = 'passport';
    } else if (idTypeText.toLowerCase() == 'driving license') {
      idType = 'driving_license';
    } else {
      showResponseDialog(
        title: 'Error',
        message: 'Please select a valid ID type',
        isError: true,
        showButton: true,
      );
      return;
    }

    // Format expiry date from dd/MM/yyyy to yyyy-MM-dd
    String formattedExpiryDate;
    try {
      final parts = expiryText.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        formattedExpiryDate =
            '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
        debugPrint('Formatted Expiry Date: $formattedExpiryDate');
      } else {
        showResponseDialog(
          title: 'Error',
          message: 'Please enter a valid expiry date',
          isError: true,
          showButton: true,
        );
        return;
      }
    } catch (e) {
      debugPrint('Error parsing expiry date: $e');
      showResponseDialog(
        title: 'Error',
        message: 'Please enter a valid expiry date',
        isError: true,
        showButton: true,
      );
      return;
    }

    // Validate file exists (either new upload or existing from URL)
    if (idFile == null && (idDocumentUrl == null || idDocumentUrl!.isEmpty)) {
      showResponseDialog(
        title: 'Error',
        message: 'Please upload ID document',
        isError: true,
        showButton: true,
      );
      return;
    }

    // If no new file but document URL exists, download it
    File? documentFileToUpload = idFile;
    if (documentFileToUpload == null &&
        idDocumentUrl != null &&
        idDocumentUrl!.isNotEmpty) {
      try {
        documentFileToUpload = await _downloadIdDocumentFile(idDocumentUrl!);
        if (documentFileToUpload == null) {
          showResponseDialog(
            title: 'Error',
            message:
                'Failed to download existing document. Please upload a new document.',
            isError: true,
            showButton: true,
          );
          return;
        }
        debugPrint(
            'Downloaded existing ID document from URL: ${documentFileToUpload.path}');
      } catch (e) {
        debugPrint('Error downloading ID document: $e');
        showResponseDialog(
          title: 'Error',
          message:
              'Failed to download existing document. Please upload a new document.',
          isError: true,
          showButton: true,
        );
        return;
      }
    }

    await callDataService<ApiResponse<dynamic>>(
      _userApiService.upsertPersonalIdentification(
        idType: idType,
        expiryDate: formattedExpiryDate,
        documentFile: documentFileToUpload!,
        confirmLegalRight: confirmRightToWork.value,
        id: identificationId.value, // Pass ID if exists (for updates)
      ),
      showLoader: true,
      onSuccess: (response) async {
        debugPrint('=== API Response Success ===');
        debugPrint('Success: ${response.success}');
        debugPrint('Error Message: ${response.errorMessage}');
        if (response.success) {
          // Extract and save user flags from response (same as login controller)
          final storage = _storageService;
          if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            if (data['user'] is Map<String, dynamic>) {
              final user = data['user'] as Map<String, dynamic>;

              // Extract and save all user flags
              if (storage != null) {
                final flags = [
                  'is_personal_details',
                  'is_term_condition',
                  'is_profile_created',
                  'is_work_full',
                  'is_professional_services',
                  'is_qualification',
                  'is_personal_identification',
                  'is_about_you',
                  'is_payment',
                  'is_notification',
                ];

                for (final flag in flags) {
                  final value = user[flag] as bool?;
                  if (value != null) {
                    await storage.writeBool(flag, value);
                    debugPrint('Step 4: Saved flag $flag = $value');
                  }
                }
              }
            }
          }

          // Navigate to next step after successful API call
          if (currentStep.value < totalSteps - 1) {
            currentStep.value += 1;
            // Analytics: Log step completion

            // Reset validation state for next step
            hasValidated.value = false;
            addressHasValidated.value = false;
            qualificationsHasValidated.value = false;
            identificationHasValidated.value = false;
            aboutYouHasValidated.value = false;
            pageController.animateToPage(
              currentStep.value,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
            );
          }
        } else {
          debugPrint('=== API Response Failed ===');
          debugPrint('Error: ${response.errorMessage}');
          showResponseDialog(
            title: 'Error',
            message: response.errorMessage,
            isError: true,
            showButton: true,
          );
        }
      },
      onError: (error, stack) {
        debugPrint('=== API Call Error ===');
        debugPrint('Error: $error');
        debugPrint('Stack: $stack');
        final errorMsg = errorMessage.value.isNotEmpty
            ? errorMessage.value
            : 'Failed to save personal identification. Please try again.';
        debugPrint('Error Message: $errorMsg');
        showResponseDialog(
          title: 'Error',
          message: errorMsg,
          isError: true,
          showButton: true,
        );
      },
    );
  }

  // Save about you API call
  Future<void> _saveAboutYou() async {
    debugPrint('=== Starting Save About You ===');

    // Note: Form validation is done in nextStep() before calling this method
    final description = aboutYouController.text.trim();

    debugPrint('Description: $description');

    await callDataService<ApiResponse<dynamic>>(
      _userApiService.saveAboutYou(
        description: description,
      ),
      showLoader: true,
      onSuccess: (response) async {
        debugPrint('=== API Response Success ===');
        debugPrint('Success: ${response.success}');
        debugPrint('Error Message: ${response.errorMessage}');
        if (response.success) {
          // Extract and save user flags from response (same as login controller)
          final storage = _storageService;
          if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            if (data['user'] is Map<String, dynamic>) {
              final user = data['user'] as Map<String, dynamic>;

              // Extract and save all user flags
              if (storage != null) {
                final flags = [
                  'is_personal_details',
                  'is_term_condition',
                  'is_profile_created',
                  'is_work_full',
                  'is_professional_services',
                  'is_qualification',
                  'is_personal_identification',
                  'is_about_you',
                  'is_payment',
                  'is_notification',
                ];

                for (final flag in flags) {
                  final value = user[flag] as bool?;
                  if (value != null) {
                    await storage.writeBool(flag, value);
                    debugPrint('Step 5: Saved flag $flag = $value');
                  }
                }
              }
            }
          }

          // Show success dialog
          final successMessage =
              response.message ?? 'Your account is successfully created';
          showResponseDialog(
            message: successMessage,
            title: 'Success',
            isError: false,
            showButton: false,
            onOkPressed: () {
              // Navigate to subscription page after dialog is dismissed
              // Get.toNamed(Routes.subscription);
              loadProfileDetails();
              // Get.offAllNamed(Routes.home);
            },
          );
        } else {
          debugPrint('=== API Response Failed ===');
          debugPrint('Error: ${response.errorMessage}');
          showResponseDialog(
            title: 'Error',
            message: response.errorMessage,
            isError: true,
            showButton: true,
          );
        }
      },
      onError: (error, stack) {
        debugPrint('=== API Call Error ===');
        debugPrint('Error: $error');
        debugPrint('Stack: $stack');
        final errorMsg = errorMessage.value.isNotEmpty
            ? errorMessage.value
            : 'Failed to save about you. Please try again.';
        debugPrint('Error Message: $errorMsg');
        showResponseDialog(
          title: 'Error',
          message: errorMsg,
          isError: true,
          showButton: true,
        );
      },
    );
  }

  /// Show file picker dialog to choose between image or PDF
  Future<void> pickCertificateFile(
    BuildContext context,
    QualificationItem qualification,
    int index,
  ) async {
    try {
      final source = await showModalBottomSheet<FilePickerSource>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(HightWidthSizes.setValue_20),
              topRight: Radius.circular(HightWidthSizes.setValue_20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.all(HightWidthSizes.setValue_16),
                  child: Text(
                    'Select File Type',
                    style: TextStyle(
                      fontFamily: AppFonts.rubikMedium,
                      fontSize: FontSizes.setFontValue_18,
                      fontWeight: FontWeight.w500,
                      color: AppColor.color_2D2D2D,
                    ),
                  ),
                ),
                ListTile(
                  leading:
                      const Icon(Icons.image, color: AppColor.color_2D2D2D),
                  title: Text(
                    'Image',
                    style: TextStyle(
                      fontFamily: AppFonts.rubikRegular,
                      fontSize: FontSizes.setFontValue_16,
                      color: AppColor.color_2D2D2D,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, FilePickerSource.image),
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf,
                      color: AppColor.color_2D2D2D),
                  title: Text(
                    'PDF',
                    style: TextStyle(
                      fontFamily: AppFonts.rubikRegular,
                      fontSize: FontSizes.setFontValue_16,
                      color: AppColor.color_2D2D2D,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, FilePickerSource.pdf),
                ),
                SizedBox(height: HightWidthSizes.setValue_8),
              ],
            ),
          ),
        ),
      );

      if (source == null) return;

      if (source == FilePickerSource.image) {
        await _pickImage(qualification, index);
      } else if (source == FilePickerSource.pdf) {
        await _pickPDF(qualification, index);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick file: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Pick image file
  Future<void> _pickImage(QualificationItem qualification, int index) async {
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
          maxWidth: 2048,
          maxHeight: 2048,
          imageQuality: 90,
        );

        if (pickedFile != null) {
          await _processSelectedFile(pickedFile, qualification, index);
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
            maxWidth: 2048,
            maxHeight: 2048,
            imageQuality: 90,
          );

          if (pickedFile != null) {
            await _processSelectedFile(pickedFile, qualification, index);
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

  /// Process the selected file (common logic for both platforms)
  Future<void> _processSelectedFile(
      XFile pickedFile, QualificationItem qualification, int index) async {
    final file = File(pickedFile.path);
    final fileSize = await file.length();
    const maxSize = 5 * 1024 * 1024; // 5MB

    if (fileSize > maxSize) {
      Get.snackbar(
        'Error',
        'File size exceeds 5MB limit',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    qualification.certificateFile = file;
    qualification.uploadCertificateController.text = pickedFile.name;

    // Trigger form validation after file is selected
    if (index >= 0 && index < qualificationFormKeys.length) {
      final formKey = qualificationFormKeys[index];
      formKey.currentState?.validate();
    }
  }

  /// Pick PDF file
  Future<void> _pickPDF(QualificationItem qualification, int index) async {
    try {
      // final hasPermissions =
      //     await _cameraStoragePermissionService.requestStoragePermission();
      // if (!hasPermissions) {
      //   return;
      // }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();
        const maxSize = 5 * 1024 * 1024; // 5MB

        if (fileSize > maxSize) {
          Get.snackbar(
            'Error',
            'File size exceeds 5MB limit',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }

        qualification.certificateFile = file;
        qualification.uploadCertificateController.text =
            result.files.single.name;

        // Trigger form validation after file is selected
        if (index >= 0 && index < qualificationFormKeys.length) {
          final formKey = qualificationFormKeys[index];
          formKey.currentState?.validate();
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick PDF: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Show file picker dialog to choose between image or PDF for ID
  Future<void> pickIdFile(BuildContext context) async {
    try {
      final source = await showModalBottomSheet<FilePickerSource>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(HightWidthSizes.setValue_20),
              topRight: Radius.circular(HightWidthSizes.setValue_20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.all(HightWidthSizes.setValue_16),
                  child: Text(
                    'Select File Type',
                    style: TextStyle(
                      fontFamily: AppFonts.rubikMedium,
                      fontSize: FontSizes.setFontValue_18,
                      fontWeight: FontWeight.w500,
                      color: AppColor.color_2D2D2D,
                    ),
                  ),
                ),
                ListTile(
                  leading:
                      const Icon(Icons.image, color: AppColor.color_2D2D2D),
                  title: Text(
                    'Image',
                    style: TextStyle(
                      fontFamily: AppFonts.rubikRegular,
                      fontSize: FontSizes.setFontValue_16,
                      color: AppColor.color_2D2D2D,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, FilePickerSource.image),
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf,
                      color: AppColor.color_2D2D2D),
                  title: Text(
                    'PDF',
                    style: TextStyle(
                      fontFamily: AppFonts.rubikRegular,
                      fontSize: FontSizes.setFontValue_16,
                      color: AppColor.color_2D2D2D,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, FilePickerSource.pdf),
                ),
                SizedBox(height: HightWidthSizes.setValue_8),
              ],
            ),
          ),
        ),
      );

      if (source == null) return;

      if (source == FilePickerSource.image) {
        await _pickIdImage();
      } else if (source == FilePickerSource.pdf) {
        await _pickIdPDF();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick file: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Pick ID image file
  Future<void> _pickIdImage() async {
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
          maxWidth: 2048,
          maxHeight: 2048,
          imageQuality: 90,
        );

        if (pickedFile != null) {
          await _processSelectedIdFile(pickedFile);
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
            maxWidth: 2048,
            maxHeight: 2048,
            imageQuality: 90,
          );

          if (pickedFile != null) {
            await _processSelectedIdFile(pickedFile);
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

  /// Process the selected ID file (common logic for both platforms)
  Future<void> _processSelectedIdFile(XFile pickedFile) async {
    final file = File(pickedFile.path);
    final fileSize = await file.length();
    const maxSize = 5 * 1024 * 1024; // 5MB

    if (fileSize > maxSize) {
      Get.snackbar(
        'Error',
        'File size exceeds 5MB limit',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    idFile = file;
    idUploadController.text = pickedFile.name;
    idDocumentUrl = null; // Clear existing URL when new file is selected

    // Trigger form validation after file is selected
    identificationFormKey.currentState?.validate();
  }

  Future<void> _pickIdPDF() async {
    try {
      if (Platform.isAndroid) {
        // ── Android: Let file_picker handle permissions internally ────────
        // DO NOT call Permission.storage.request() manually.
        // On Android 13+, file_picker handles permissions properly.
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );

        if (result != null && result.files.single.path != null) {
          await _processSelectedPdfFile(result.files.single);
        }
      } else if (Platform.isIOS) {
        // ── iOS: Check current status WITHOUT triggering a prompt ──────────
        // PermissionStatus status = await Permission.photos.status;
        // debugPrint('iOS photo permission status (before): $status');

        // if (status.isPermanentlyDenied) {
        //   await _cameraStoragePermissionService
        //       .showPhotoLibraryPermissionDeniedDialog();
        //   return;
        // }

        // // Status is .granted or .limited — safe to open picker
        // if (status.isGranted || status.isLimited) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );

        if (result != null && result.files.single.path != null) {
          await _processSelectedPdfFile(result.files.single);
        }
        // }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick PDF: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Process the selected PDF file (common logic for both platforms)
  Future<void> _processSelectedPdfFile(PlatformFile file) async {
    if (file.path != null) {
      final pdfFile = File(file.path!);
      final fileSize = await pdfFile.length();
      const maxSize = 5 * 1024 * 1024; // 5MB

      if (fileSize > maxSize) {
        Get.snackbar(
          'Error',
          'File size exceeds 5MB limit',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      idFile = pdfFile;
      idUploadController.text = file.name;
      idDocumentUrl = null; // Clear existing URL when new file is selected

      // Trigger form validation after file is selected
      formKey.currentState?.validate();
    }
  }

  // /// Pick ID PDF file
  // Future<void> _pickIdPDF() async {
  //   try {
  //     final hasPermissions =
  //     await _cameraStoragePermissionService.requestStoragePermission();
  //     if (!hasPermissions) {
  //       return;
  //     }

  //     final result = await FilePicker.platform.pickFiles(
  //       type: FileType.custom,
  //       allowedExtensions: ['pdf'],
  //     );

  //     if (result != null && result.files.single.path != null) {
  //       final file = File(result.files.single.path!);
  //       final fileSize = await file.length();
  //       const maxSize = 5 * 1024 * 1024; // 5MB

  //       if (fileSize > maxSize) {
  //         Get.snackbar(
  //           'Error',
  //           'File size exceeds 5MB limit',
  //           snackPosition: SnackPosition.BOTTOM,
  //         );
  //         return;
  //       }

  //       idFile = file;
  //       idUploadController.text = result.files.single.name;

  //       // Trigger form validation after file is selected
  //       identificationFormKey.currentState?.validate();
  //     }
  //   } catch (e) {
  //     Get.snackbar(
  //       'Error',
  //       'Failed to pick PDF: ${e.toString()}',
  //       snackPosition: SnackPosition.BOTTOM,
  //     );
  //   }
  // }

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
      await _reverseGeocodeAndFillFields(
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
          // Auto-fill postcode only if not manually entered
          if (!isManualPostcode.value) {
            postcodeController.text = placemark.postalCode!;
          }
          addressParts.add(placemark.postalCode!);
        }
        if (placemark.country != null && placemark.country!.isNotEmpty) {
          addressParts.add(placemark.country!);
        }

        // Auto-fill address
        addressController.text = addressParts.join(', ');
        // Trigger validation after address is filled
        addressFormKey.currentState?.validate();
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

      // Auto-fill postcode if available and not manually entered
      if (!isManualPostcode.value &&
          result['postcode'] != null &&
          result['postcode'].toString().isNotEmpty) {
        postcodeController.text = result['postcode'] as String;
      }
      // Trigger validation after address is selected
      addressFormKey.currentState?.validate();
    }
  }

  /// Navigate to map screen to select work address
  Future<void> navigateToWorkMapScreen() async {
    // Prepare arguments for map screen
    final Map<String, dynamic> arguments = {
      'hideSelectButton': true
    }; // Hide Select Address button initially

    debugPrint(
        'Current coordinates for work address: lat=${workLatitude.value}, lng=${workLongitude.value}');

    if (workLatitude.value != null && workLongitude.value != null) {
      arguments['latitude'] = workLatitude.value;
      arguments['longitude'] = workLongitude.value;
      debugPrint('Passing coordinates to map: $arguments');
    } else {
      debugPrint('No valid coordinates to pass to map');
    }

    // Pass existing address from API if available
    if (workAddressController.text.isNotEmpty) {
      arguments['existingAddress'] = workAddressController.text;
      debugPrint(
          'Passing existing address to map: ${workAddressController.text}');
    }

    final result = await Get.toNamed(Routes.selectAddressMap,
        arguments: arguments.isNotEmpty ? arguments : null);
    if (result != null && result is Map<String, dynamic>) {
      workLatitude.value = result['latitude'] as double?;
      workLongitude.value = result['longitude'] as double?;
      workAddressController.text = result['address'] as String? ?? '';

      // Auto-fill postcode if available and not manually entered
      if (!isManualWorkPostcode.value &&
          result['postcode'] != null &&
          result['postcode'].toString().isNotEmpty) {
        workPostcodeController.text = result['postcode'] as String;
      }
      // Trigger validation after work address is selected
      addressFormKey.currentState?.validate();
    }
  }

  void enableManualPostcode() {
    isManualPostcode.value = true;
    isManualAddress.value = true;
  }

  void enableManualWorkPostcode() {
    isManualWorkPostcode.value = true;
    isManualWorkAddress.value = true;
  }

  /// Load services from API based on profession_sub_type_id
  Future<void> _loadServices() async {
    // Use profession_sub_type_id from response if available, otherwise use selected one
    var professionSubTypeId = professionSubTypeIdFromResponse.value ??
        selectedProfessionSubTypeId.value;

    // If profession_sub_type_id is not available, try to load it from profile details
    if (professionSubTypeId == null || professionSubTypeId.isEmpty) {
      debugPrint(
          'No profession_sub_type_id available, loading profile details first...');
      // Wait for profession types to be loaded first
      while (isLoadingProfessionTypes.value) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      // Load profile details to get profession_sub_type_id
      await _loadCreateProfileDetails();
      // Wait for profession sub-types to be loaded
      int retryCount = 0;
      while (isLoadingProfessionSubTypes.value && retryCount < 20) {
        await Future.delayed(const Duration(milliseconds: 100));
        retryCount++;
      }
      // Additional delay to ensure sub-types are processed
      await Future.delayed(const Duration(milliseconds: 300));
      // Try again after loading profile details
      professionSubTypeId = professionSubTypeIdFromResponse.value ??
          selectedProfessionSubTypeId.value;
      debugPrint(
          'After loading profile details, profession_sub_type_id: $professionSubTypeId');
    }

    if (professionSubTypeId == null || professionSubTypeId.isEmpty) {
      debugPrint(
          'No profession_sub_type_id available to load services after loading profile details');
      return;
    }

    debugPrint(
        'Loading services with profession_sub_type_id: $professionSubTypeId');

    isLoadingServices.value = true;
    hasLoadedServices.value = false; // Reset flag when starting new load
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.getAllServices(
        professionSubTypeId: professionSubTypeId,
      ),
      showLoader: true,
      onSuccess: (response) {
        // Handle "no services available" as a valid empty list, not an error
        if (!response.success) {
          final errorMsg = response.errorMessage.toLowerCase();
          if (errorMsg.contains('no services available') ||
              errorMsg.contains('there are no services')) {
            // Clear services list and treat as valid empty response
            this.services.clear();
            debugPrint('No services available for this profession sub-type');
            return;
          }
          // For other errors, log but don't show error dialog
          debugPrint('Error loading services: ${response.errorMessage}');
          return;
        }

        if (response.data != null) {
          // Extract services from response
          // Response structure: {success: true, data: [{_id: "...", service_name: "...", sub_services: [...]}, ...]}
          if (response.data is List) {
            final list = response.data as List;
            final serviceList = <ServiceModel>[];
            for (final item in list) {
              try {
                if (item is Map<String, dynamic>) {
                  final service = ServiceModel.fromJson(item);
                  if (service.serviceName != null &&
                      service.serviceName!.isNotEmpty) {
                    serviceList.add(service);
                  }
                }
              } catch (e) {
                debugPrint('Error parsing service: $e');
                continue;
              }
            }
            this.services.clear();
            this.services.addAll(serviceList);
          } else if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            if (data['data'] is List) {
              final list = data['data'] as List;
              final serviceList = <ServiceModel>[];
              for (final item in list) {
                try {
                  if (item is Map<String, dynamic>) {
                    final service = ServiceModel.fromJson(item);
                    if (service.serviceName != null &&
                        service.serviceName!.isNotEmpty) {
                      serviceList.add(service);
                    }
                  }
                } catch (e) {
                  debugPrint('Error parsing service: $e');
                  continue;
                }
              }
              this.services.clear();
              this.services.addAll(serviceList);
            }
          }
        } else {
          // No data in response, clear services list
          this.services.clear();
        }
      },
      onComplete: () {
        isLoadingServices.value = false;
        hasLoadedServices.value =
            true; // Mark that services API call has completed
        resetState(); // Reset pageState to dismiss loader
        debugPrint('Services loaded. Count: ${services.length}');
        // After services are loaded, load selected profession services
        // This ensures selected services are displayed when navigating to step 2
        // Wait a bit to ensure services list is fully populated and UI is updated
        Future.delayed(const Duration(milliseconds: 400), () {
          debugPrint(
              'Loading profession services. Services count: ${services.length}');
          if (services.isNotEmpty) {
            _loadProfessionServices();
          } else {
            debugPrint('No services available for this profession sub-type');
          }
        });
      },
    );
  }

  /// Load profession services (selected services) from API
  Future<void> _loadProfessionServices() async {
    debugPrint('_loadProfessionServices called');
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.getProfessionServices(),
      showLoader: false,
      onSuccess: (response) {
        debugPrint('Profession services API response received');
        if (response.success && response.data != null) {
          try {
            final data = response.data as Map<String, dynamic>?;
            if (data != null) {
              // Parse services array from response
              // Expected structure: {success: true, data: {services: [{_id: "...", service_name: "...", sub_services: [{_id: "...", sub_service_name: "..."}, ...]}, ...]}}
              List<dynamic>? servicesList;
              if (data['services'] is List) {
                servicesList = data['services'] as List;
              } else if (data['data'] is Map<String, dynamic>) {
                final nestedData = data['data'] as Map<String, dynamic>;
                if (nestedData['services'] is List) {
                  servicesList = nestedData['services'] as List;
                }
              }

              if (servicesList != null && servicesList.isNotEmpty) {
                // Only load old services if user hasn't made any manual selections yet
                if (!hasUserMadeManualSelection.value) {
                  debugPrint(
                      'Clearing existing selections before loading old services');
                  // Clear existing selections only when loading old services
                  selectedServices.clear();
                  selectedServiceIds.clear();
                  selectedSubServiceIds.clear();
                  for (final serviceItem in servicesList) {
                    if (serviceItem is Map<String, dynamic>) {
                      final serviceId = serviceItem['_id']?.toString();
                      final serviceName =
                          serviceItem['service_name']?.toString();
                      final subServicesList =
                          serviceItem['sub_services'] as List?;

                      if (serviceId != null && serviceId.isNotEmpty) {
                        // Check if this service has sub-services
                        if (subServicesList != null &&
                            subServicesList.isNotEmpty) {
                          // Service has sub-services selected
                          // Get existing sub-service IDs for this service (if any) to merge
                          final existingSubServiceIds =
                              selectedSubServiceIds[serviceId] ?? <String>[];
                          final subServiceIdList =
                              existingSubServiceIds.toSet().toList();

                          for (final subServiceItem in subServicesList) {
                            if (subServiceItem is Map<String, dynamic>) {
                              final subServiceId =
                                  subServiceItem['_id']?.toString();
                              final subServiceName =
                                  subServiceItem['sub_service_name']
                                      ?.toString();

                              if (subServiceId != null &&
                                  subServiceId.isNotEmpty) {
                                // Add sub-service ID if not already present
                                if (!subServiceIdList.contains(subServiceId)) {
                                  subServiceIdList.add(subServiceId);
                                }
                                // Add sub-service name to selectedServices for UI
                                if (subServiceName != null &&
                                    subServiceName.isNotEmpty) {
                                  selectedServices.add(subServiceName);
                                }
                              }
                            }
                          }

                          if (subServiceIdList.isNotEmpty) {
                            // Store sub-service IDs (merge with existing if any)
                            selectedSubServiceIds[serviceId] = subServiceIdList;
                          }
                        } else {
                          // Service without sub-services (simple service) - service itself is selected
                          selectedServiceIds.add(serviceId);
                          if (serviceName != null && serviceName.isNotEmpty) {
                            selectedServices.add(serviceName);
                          }
                        }
                      }
                    }
                  }
                  // Mark that old services have been loaded
                  hasLoadedOldServices.value = true;
                  // Refresh UI
                  debugPrint(
                      'Selected services count: ${selectedServices.length}');
                  debugPrint(
                      'Selected service IDs count: ${selectedServiceIds.length}');
                  debugPrint(
                      'Selected sub-service IDs count: ${selectedSubServiceIds.length}');
                  selectedServices.refresh();
                  selectedServiceIds.refresh();
                  selectedSubServiceIds.refresh();
                  debugPrint('UI refreshed with selected services');
                } else {
                  debugPrint(
                      'Skipping loading old services - user has made manual selections');
                }
              } else {
                debugPrint('No services found in profession services response');
              }
            } else {
              debugPrint('Profession services data is null');
            }
          } catch (e) {
            debugPrint('Error parsing profession services: $e');
          }
        } else {
          debugPrint('Profession services API response was not successful');
        }
      },
      onError: (error, stackTrace) {
        debugPrint('Error loading profession services: $error');
      },
    );
  }

  /// Load qualifications details from API
  Future<void> _loadQualificationsDetails() async {
    debugPrint('Loading qualifications details...');
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.getQualificationsDetails(),
      showLoader: false,
      onSuccess: (response) {
        if (response.success && response.data != null) {
          try {
            final data = response.data as Map<String, dynamic>?;
            if (data != null) {
              // Load total experience
              if (data['total_experience'] != null) {
                final experience = data['total_experience'];
                if (experience is num) {
                  yearsExperienceController.text = experience.toString();
                } else if (experience is String) {
                  yearsExperienceController.text = experience;
                }
              }

              // Load qualifications
              List<dynamic>? qualificationsList;
              if (data['qualifications'] is List) {
                qualificationsList = data['qualifications'] as List;
              } else if (data['data'] is Map<String, dynamic>) {
                final nestedData = data['data'] as Map<String, dynamic>;
                if (nestedData['qualifications'] is List) {
                  qualificationsList = nestedData['qualifications'] as List;
                }
              }

              if (qualificationsList != null && qualificationsList.isNotEmpty) {
                // Clear removed IDs list when loading new data
                removedQualificationIds.clear();
                // Dispose all existing qualifications
                for (final qual in qualifications) {
                  qual.dispose();
                }
                qualifications.clear();
                qualificationFormKeys.clear();

                // Load qualifications from API response
                for (final qualData in qualificationsList) {
                  if (qualData is Map<String, dynamic>) {
                    final qualification = QualificationItem(
                      id: qualData['_id']?.toString(),
                    );

                    // Load school/university
                    if (qualData['school_or_university'] != null) {
                      final schoolValue =
                          qualData['school_or_university'].toString();

                      // Check if it's an ID (24 character hex string - MongoDB ObjectId format)
                      final isId = schoolValue.length == 24 &&
                          RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(schoolValue);

                      if (isId) {
                        // It's an ID - look it up in colleges/universities map
                        String? matchedCollegeName;
                        for (final entry in collegesUniversitiesMap.entries) {
                          if (entry.value == schoolValue) {
                            matchedCollegeName = entry.key;
                            break;
                          }
                        }
                        if (matchedCollegeName != null) {
                          qualification.schoolController.text =
                              matchedCollegeName;
                          qualification.selectedCollegeUniversity =
                              matchedCollegeName;
                          qualification.selectedCollegeUniversityId =
                              schoolValue;
                        } else {
                          // ID not found in map - might need to wait for colleges to load
                          // Store the ID and try to match later
                          qualification.schoolController.text = '';
                          qualification.selectedCollegeUniversityId =
                              schoolValue;
                          debugPrint(
                              'College/University ID not found in map: $schoolValue');
                        }
                      } else {
                        // It's a string (custom text)
                        qualification.schoolController.text = schoolValue;
                        // Try to find if it's in the colleges/universities list
                        String? matchedCollege;
                        for (final college in collegesUniversities) {
                          if (college.toLowerCase() ==
                              schoolValue.toLowerCase()) {
                            matchedCollege = college;
                            break;
                          }
                        }
                        if (matchedCollege != null) {
                          qualification.selectedCollegeUniversity =
                              matchedCollege;
                          qualification.selectedCollegeUniversityId =
                              collegesUniversitiesMap[matchedCollege];
                        } else {
                          qualification.selectedCollegeUniversity = schoolValue;
                          qualification.selectedCollegeUniversityId = null;
                        }
                      }
                    }

                    // Load degree/certificate
                    if (qualData['degree_or_certificate'] != null) {
                      qualification.degreeController.text =
                          qualData['degree_or_certificate'].toString();
                    }

                    // Load expiry date
                    if (qualData['expiry_date'] != null) {
                      final expiryDate = qualData['expiry_date'].toString();
                      try {
                        // Parse ISO format (yyyy-MM-dd) to dd/MM/yyyy
                        final date = DateTime.parse(expiryDate);
                        qualification.qualificationExpiryController.text =
                            DateFormat('dd/MM/yyyy').format(date);
                      } catch (e) {
                        // If parsing fails, try other formats or set as is
                        try {
                          final parts = expiryDate.split('/');
                          if (parts.length == 3) {
                            qualification.qualificationExpiryController.text =
                                expiryDate;
                          } else {
                            qualification.qualificationExpiryController.text =
                                expiryDate;
                          }
                        } catch (e2) {
                          qualification.qualificationExpiryController.text =
                              expiryDate;
                        }
                      }
                    }

                    // Load certificate file URL
                    if (qualData['certificate_file'] != null) {
                      final certUrl = qualData['certificate_file'].toString();
                      qualification.certificateUrl = certUrl;
                      // Update the upload controller text to indicate certificate exists
                      if (certUrl.isNotEmpty) {
                        // Extract filename from URL or show a message
                        final uri = Uri.tryParse(certUrl);
                        if (uri != null) {
                          final pathSegments = uri.pathSegments;
                          if (pathSegments.isNotEmpty) {
                            qualification.uploadCertificateController.text =
                                pathSegments.last;
                          } else {
                            qualification.uploadCertificateController.text =
                                'Certificate uploaded';
                          }
                        } else {
                          qualification.uploadCertificateController.text =
                              'Certificate uploaded';
                        }
                      }
                      debugPrint('Loaded certificate URL: $certUrl');
                    }

                    qualifications.add(qualification);
                    qualificationFormKeys.add(GlobalKey<FormState>());
                  }
                }

                // If no qualifications were loaded, ensure at least one empty qualification exists
                if (qualifications.isEmpty) {
                  qualifications.add(QualificationItem.initial());
                  qualificationFormKeys.add(GlobalKey<FormState>());
                }

                // Try to match any college/university IDs that weren't matched
                _retryMatchCollegeIds();

                qualifications.refresh();
                debugPrint(
                    'Loaded ${qualifications.length} qualifications from API');
              } else {
                // No qualifications in response, ensure at least one empty qualification exists
                if (qualifications.isEmpty) {
                  qualifications.add(QualificationItem.initial());
                  qualificationFormKeys.add(GlobalKey<FormState>());
                }
                debugPrint('No qualifications found in API response');
              }
            }
          } catch (e) {
            debugPrint('Error parsing qualifications details: $e');
            // Ensure at least one qualification exists on error
            if (qualifications.isEmpty) {
              qualifications.add(QualificationItem.initial());
              qualificationFormKeys.add(GlobalKey<FormState>());
            }
          }
        }
      },
      onError: (error, stackTrace) {
        debugPrint('Error loading qualifications details: $error');
        // Ensure at least one qualification exists on error
        if (qualifications.isEmpty) {
          qualifications.add(QualificationItem.initial());
          qualificationFormKeys.add(GlobalKey<FormState>());
        }
      },
    );
  }

  /// Download ID document file from URL
  Future<File?> _downloadIdDocumentFile(String url) async {
    try {
      debugPrint('Downloading ID document from URL: $url');
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      // Extract file extension from URL or use default
      final uri = Uri.parse(url);
      final extension = path.extension(uri.path).isNotEmpty
          ? path.extension(uri.path)
          : '.jpg';
      // Create file path
      final filePath = path.join(
        tempDir.path,
        'id_document_${DateTime.now().millisecondsSinceEpoch}$extension',
      );

      // Use Dio to download the file
      final dioClient = dio.Dio();
      final response = await dioClient.download(
        url,
        filePath,
        options: dio.Options(
          responseType: dio.ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final file = File(filePath);
        debugPrint('ID document downloaded to: $filePath');
        return file;
      } else {
        debugPrint(
            'Failed to download ID document. Status code: ${response.statusCode}');
        // Clean up the file if download failed
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
        return null;
      }
    } catch (e) {
      debugPrint('Error downloading ID document file: $e');
      return null;
    }
  }

  /// Download certificate file from URL
  Future<File?> _downloadCertificateFile(
      String url, String qualificationId) async {
    try {
      debugPrint('Downloading certificate from URL: $url');
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      // Extract file extension from URL or use default
      final uri = Uri.parse(url);
      final extension = path.extension(uri.path).isNotEmpty
          ? path.extension(uri.path)
          : '.jpg';
      // Create file path
      final filePath = path.join(
        tempDir.path,
        'certificate_${qualificationId}_${DateTime.now().millisecondsSinceEpoch}$extension',
      );

      // Use Dio to download the file
      final dioClient = dio.Dio();
      final response = await dioClient.download(
        url,
        filePath,
        options: dio.Options(
          responseType: dio.ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final file = File(filePath);
        debugPrint('Certificate downloaded to: $filePath');
        return file;
      } else {
        debugPrint(
            'Failed to download certificate. Status code: ${response.statusCode}');
        // Clean up the file if download failed
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
        return null;
      }
    } catch (e) {
      debugPrint('Error downloading certificate file: $e');
      return null;
    }
  }

  /// Retry matching college/university IDs for qualifications that have IDs but no names
  void _retryMatchCollegeIds() {
    for (final qualification in qualifications) {
      // If we have an ID but no school name, try to match it
      if (qualification.selectedCollegeUniversityId != null &&
          qualification.selectedCollegeUniversityId!.isNotEmpty &&
          (qualification.schoolController.text.isEmpty ||
              qualification.selectedCollegeUniversity == null)) {
        final collegeId = qualification.selectedCollegeUniversityId!;
        // Check if it's an ID format (24 chars)
        if (collegeId.length == 24 &&
            RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(collegeId)) {
          // Look it up in colleges/universities map
          String? matchedCollegeName;
          for (final entry in collegesUniversitiesMap.entries) {
            if (entry.value == collegeId) {
              matchedCollegeName = entry.key;
              break;
            }
          }
          if (matchedCollegeName != null) {
            qualification.schoolController.text = matchedCollegeName;
            qualification.selectedCollegeUniversity = matchedCollegeName;
            debugPrint(
                'Matched college ID $collegeId to name: $matchedCollegeName');
          }
        }
      }
    }
  }

  /// Load personal identification details from API
  Future<void> _loadPersonalIdentificationDetails() async {
    debugPrint('Loading personal identification details...');
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.getPersonalIdentificationDetails(),
      showLoader: true,
      onSuccess: (response) {
        if (response.success && response.data != null) {
          try {
            final data = response.data as Map<String, dynamic>?;
            if (data != null) {
              // The response structure has identifications array
              List<dynamic>? identificationsList;
              if (data['identifications'] is List) {
                identificationsList = data['identifications'] as List;
              } else if (data['data'] is Map<String, dynamic>) {
                final nestedData = data['data'] as Map<String, dynamic>;
                if (nestedData['identifications'] is List) {
                  identificationsList = nestedData['identifications'] as List;
                }
              }

              // Clear identification ID first (will be set if data exists)
              identificationId.value = null;

              // Load the first identification (if available)
              if (identificationsList != null &&
                  identificationsList.isNotEmpty) {
                final identificationData =
                    identificationsList[0] as Map<String, dynamic>?;
                if (identificationData != null) {
                  // Store identification ID for updates
                  if (identificationData['_id'] != null) {
                    identificationId.value =
                        identificationData['_id'].toString();
                    debugPrint(
                        'Loaded identification ID: ${identificationId.value}');
                  }

                  // Load ID type
                  if (identificationData['id_type'] != null) {
                    final idType =
                        identificationData['id_type'].toString().toLowerCase();
                    // Convert API format to display format
                    if (idType == 'passport') {
                      selectedIdType.value = 'Passport';
                      idTypeController.text = 'Passport';
                    } else if (idType == 'driving_license' ||
                        idType == 'driving license') {
                      selectedIdType.value = 'Driving license';
                      idTypeController.text = 'Driving license';
                    }
                    debugPrint('Loaded ID type: ${selectedIdType.value}');
                  }

                  // Load expiry date
                  if (identificationData['expiry_date'] != null) {
                    final expiryDate =
                        identificationData['expiry_date'].toString();
                    try {
                      // Parse ISO format (yyyy-MM-dd or yyyy-MM-ddTHH:mm:ss.sssZ) to dd/MM/yyyy
                      final date = DateTime.parse(expiryDate);
                      idExpiryController.text =
                          DateFormat('dd/MM/yyyy').format(date);
                      debugPrint(
                          'Loaded expiry date: ${idExpiryController.text}');
                    } catch (e) {
                      // If parsing fails, try other formats or set as is
                      try {
                        final parts = expiryDate.split('/');
                        if (parts.length == 3) {
                          idExpiryController.text = expiryDate;
                        } else {
                          idExpiryController.text = expiryDate;
                        }
                      } catch (e2) {
                        idExpiryController.text = expiryDate;
                      }
                    }
                  }

                  // Load confirm legal right to work
                  // Note: This field might not be in the response, check if it exists
                  if (identificationData['confirm_legal_right'] != null) {
                    final confirmRight =
                        identificationData['confirm_legal_right'];
                    if (confirmRight is bool) {
                      confirmRightToWork.value = confirmRight;
                    } else if (confirmRight is String) {
                      confirmRightToWork.value =
                          confirmRight.toLowerCase() == 'true';
                    }
                    debugPrint(
                        'Loaded confirm right to work: ${confirmRightToWork.value}');
                  }

                  // Load document file URL (if available)
                  if (identificationData['document_file'] != null) {
                    final docUrl =
                        identificationData['document_file'].toString();
                    if (docUrl.isNotEmpty) {
                      // Store the document URL
                      idDocumentUrl = docUrl;
                      // Extract filename from URL or show a message
                      final uri = Uri.tryParse(docUrl);
                      if (uri != null) {
                        final pathSegments = uri.pathSegments;
                        if (pathSegments.isNotEmpty) {
                          idUploadController.text = pathSegments.last;
                        } else {
                          idUploadController.text = 'ID document uploaded';
                        }
                      } else {
                        idUploadController.text = 'ID document uploaded';
                      }
                      debugPrint('Loaded document file URL: $docUrl');
                    }
                  } else {
                    // Clear document URL if not present
                    idDocumentUrl = null;
                  }

                  debugPrint(
                      'Personal identification details loaded successfully');
                } else {
                  debugPrint('Identification data is null');
                  // Clear ID if data is null
                  identificationId.value = null;
                }
              } else {
                debugPrint('No identifications found in API response');
                // Clear ID if no identifications found
                identificationId.value = null;
              }
            }
          } catch (e) {
            debugPrint('Error parsing personal identification details: $e');
          }
        }
      },
      onError: (error, stackTrace) {
        debugPrint('Error loading personal identification details: $error');
      },
    );
  }

  /// Load about you details from API
  Future<void> _loadAboutYouDetails() async {
    debugPrint('Loading about you details...');
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.getAboutYouDetails(),
      showLoader: true,
      onSuccess: (response) {
        if (response.success && response.data != null) {
          try {
            final data = response.data as Map<String, dynamic>?;
            if (data != null) {
              // The response might have description directly or nested in data
              String? description;
              if (data['description'] != null) {
                description = data['description'].toString();
              } else if (data['data'] is Map<String, dynamic>) {
                final nestedData = data['data'] as Map<String, dynamic>;
                if (nestedData['description'] != null) {
                  description = nestedData['description'].toString();
                }
              }

              if (description != null && description.isNotEmpty) {
                aboutYouController.text = description;
                // Update word count
                onAboutYouChanged(description);
                debugPrint(
                    'Loaded about you description: ${description.length} characters');
              } else {
                debugPrint('No description found in API response');
              }
            }
          } catch (e) {
            debugPrint('Error parsing about you details: $e');
          }
        }
      },
      onError: (error, stackTrace) {
        debugPrint('Error loading about you details: $error');
      },
    );
  }

  /// Load colleges and universities from API
  Future<void> _loadCollegesUniversities() async {
    debugPrint('Loading colleges and universities...');
    isLoadingCollegesUniversities.value = true;
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.getCollegesUniversities(),
      showLoader: true,
      onSuccess: (response) {
        debugPrint('Colleges/Universities API response: ${response.success}');
        if (response.success && response.data != null) {
          debugPrint('Colleges/Universities data: ${response.data}');
          // Extract colleges/universities from response using model class
          // Response structure: {success: true, data: [{_id: "...", name: "..."}, ...]}
          collegesUniversitiesMap.clear();
          if (response.data is List) {
            final list = response.data as List;
            final names = <String>[];
            for (final item in list) {
              try {
                if (item is Map<String, dynamic>) {
                  final collegeUniversity =
                      CollegeUniversityModel.fromJson(item);
                  if (collegeUniversity.id != null &&
                      collegeUniversity.name != null) {
                    collegesUniversitiesMap[collegeUniversity.name!] =
                        collegeUniversity.id!;
                    names.add(collegeUniversity.name!);
                  }
                }
              } catch (e) {
                // Skip invalid items
                continue;
              }
            }
            collegesUniversities.value = names;
          } else if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            if (data['data'] is List) {
              final list = data['data'] as List;
              final names = <String>[];
              for (final item in list) {
                try {
                  if (item is Map<String, dynamic>) {
                    final collegeUniversity =
                        CollegeUniversityModel.fromJson(item);
                    if (collegeUniversity.id != null &&
                        collegeUniversity.name != null) {
                      collegesUniversitiesMap[collegeUniversity.name!] =
                          collegeUniversity.id!;
                      names.add(collegeUniversity.name!);
                    }
                  }
                } catch (e) {
                  // Skip invalid items
                  continue;
                }
              }
              collegesUniversities.value = names;
            }
          }
          // After colleges are loaded, try to match any pending qualification IDs
          _retryMatchCollegeIds();
        } else {
          debugPrint(
              'Colleges/Universities API failed: ${response.errorMessage}');
        }
      },
      onError: (error, stack) {
        debugPrint('Colleges/Universities API error: $error');
        final errorMsg = errorMessage.value.isNotEmpty
            ? errorMessage.value
            : 'Failed to load colleges/universities. Please try again.';
        // Don't show dialog for this, just log the error
        debugPrint('Error loading colleges/universities: $errorMsg');
      },
      onComplete: () {
        debugPrint('Colleges/Universities loading completed');
        isLoadingCollegesUniversities.value = false;
      },
    );
  }

  Future<void> _clearLocalDataAndNavigate() async {
    // Clear all storage except remember me data
    if (Get.isRegistered<StorageService>()) {
      final storage = Get.find<StorageService>();

      // Save remember me data temporarily
      final rememberMe = storage.readBool('remember_me') ?? false;
      final savedEmail = storage.readString('saved_email') ?? '';
      final savedPassword = storage.readString('saved_password') ?? '';

      // Clear all storage except remember me keys
      await storage
          .clearAllExcept(['remember_me', 'saved_email', 'saved_password']);

      // Restore remember me data if it was enabled
      if (rememberMe) {
        await storage.writeBool('remember_me', rememberMe);
        await storage.writeString('saved_email', savedEmail);
        await storage.writeString('saved_password', savedPassword);
      } else {
        // Clear remember me data if it was not enabled
        await storage.writeBool('remember_me', false);
        await storage.writeString('saved_email', '');
        await storage.writeString('saved_password', '');
      }
    }

    // Navigate to login page
    Get.offAllNamed(Routes.login);
  }

  @override
  void onClose() {
    pageController.dispose();
    locationController.dispose();
    professionController.dispose();
    fullNameController.dispose();
    dobController.dispose();
    postcodeController.dispose();
    addressController.dispose();
    workPostcodeController.dispose();
    workAddressController.dispose();
    for (final qualification in qualifications) {
      qualification.dispose();
    }
    yearsExperienceController.dispose();
    qualificationsScrollController.dispose();
    idTypeController.dispose();
    idExpiryController.dispose();
    idUploadController.dispose();
    aboutYouController.dispose();
    super.onClose();
  }
}

class QualificationItem {
  QualificationItem({
    TextEditingController? schoolController,
    TextEditingController? degreeController,
    TextEditingController? qualificationExpiryController,
    TextEditingController? uploadCertificateController,
    String? selectedCollegeUniversity,
    String? selectedCollegeUniversityId,
    File? certificateFile,
    String? certificateUrl, // URL from API for existing certificates
    String? id, // ID for existing qualifications (for updates)
  })  : schoolController = schoolController ?? TextEditingController(),
        degreeController = degreeController ?? TextEditingController(),
        qualificationExpiryController =
            qualificationExpiryController ?? TextEditingController(),
        uploadCertificateController = uploadCertificateController ??
            TextEditingController(text: 'Upload file (PDF or Image)'),
        selectedCollegeUniversity = selectedCollegeUniversity,
        selectedCollegeUniversityId = selectedCollegeUniversityId,
        certificateFile = certificateFile,
        certificateUrl = certificateUrl,
        id = id;

  final TextEditingController schoolController;
  final TextEditingController degreeController;
  final TextEditingController qualificationExpiryController;
  final TextEditingController uploadCertificateController;
  String? selectedCollegeUniversity;
  String? selectedCollegeUniversityId;
  File? certificateFile;
  String? certificateUrl; // URL from API for existing certificates
  String? id; // ID for existing qualifications (for updates)

  factory QualificationItem.initial() => QualificationItem();

  void dispose() {
    schoolController.dispose();
    degreeController.dispose();
    qualificationExpiryController.dispose();
    uploadCertificateController.dispose();
  }
}

enum FilePickerSource {
  image,
  pdf,
}
