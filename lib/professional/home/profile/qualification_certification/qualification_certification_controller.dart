import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart' as dio;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

import '../../../../api/api_response.dart';
import '../../../../api/user_api_service.dart';
import '../../../../common/base_controller.dart';
import '../../../../models/college_university_model.dart';
import '../../../../services/analytics_service.dart';
import '../../../../services/camera_storage_permission_service.dart';
import '../../../../services/storage_service.dart';
import '../../../../widgets/response_dialog.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/font_sizes.dart';
import '../../../../theme/fonts.dart';
import '../../../../theme/hight_width_sizes.dart';

enum FilePickerSource {
  image,
  pdf,
}

class QualificationCertificationController extends BaseController {
  final UserApiService _userApiService;
  final StorageService? _storageService =
      Get.isRegistered<StorageService>() ? Get.find<StorageService>() : null;
  final CameraStoragePermissionService _cameraStoragePermissionService =
      CameraStoragePermissionService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isPicking = false;

  late final GlobalKey<FormState> formKey;
  final ScrollController scrollController = ScrollController();

  final qualifications = <QualificationItem>[].obs;
  final yearsExperienceController = TextEditingController();

  final collegesUniversities = <String>[].obs;
  final collegesUniversitiesMap = <String, String>{}.obs;
  final isLoadingCollegesUniversities = false.obs;
  final hasLoadedCollegesUniversities = false.obs;
  final removedQualificationIds = <String>[].obs;
  final hasValidated = false.obs;
  final isLoading = false.obs;
  final hasValidData = false.obs;

  QualificationCertificationController(this._userApiService);

  @override
  void onInit() {
    super.onInit();
    AnalyticsService.instance.logScreenView(
      screenName: 'ProfessionalQualificationCertificationScreen',
      screenClass: 'QualificationCertificationView',
      pageCategory: 'profile',
      elementLocation: 'view',
    );
    formKey = GlobalKey<FormState>();
    // Add listener to years experience controller
    yearsExperienceController.addListener(_checkHasValidData);
    _loadCollegesUniversities().then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _loadQualificationsDetails();
      });
    });
  }

  @override
  void onClose() {
    for (var item in qualifications) {
      item.dispose();
    }
    yearsExperienceController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void addQualification() {
    final newQualification = QualificationItem.initial();
    // Add listeners to text controllers
    newQualification.schoolController.addListener(_checkHasValidData);
    newQualification.degreeController.addListener(_checkHasValidData);
    newQualification.qualificationExpiryController
        .addListener(_checkHasValidData);

    qualifications.add(newQualification);
    qualifications.refresh();
    _checkHasValidData();

    Future.delayed(const Duration(milliseconds: 150), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void removeQualification(QualificationItem item) {
    if (qualifications.length <= 1) return;
    if (item.id != null && item.id!.isNotEmpty) {
      removedQualificationIds.add(item.id!);
    }
    qualifications.remove(item);
    item.dispose();
    qualifications.refresh();
    _checkHasValidData();
  }

  Future<void> pickDate(
    BuildContext context,
    TextEditingController target,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? initialDate = today;
    if (target.text.isNotEmpty) {
      try {
        final parts = target.text.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          final existingDate = DateTime(year, month, day);
          initialDate = existingDate.isBefore(today) ? today : existingDate;
        }
      } catch (e) {
        initialDate = today;
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(now.year + 50),
    );
    if (picked != null) {
      target.text = '${picked.day.toString().padLeft(2, '0')}/'
          '${picked.month.toString().padLeft(2, '0')}/'
          '${picked.year}';
      formKey.currentState?.validate();
    }
  }

  Future<void> _loadCollegesUniversities() async {
    debugPrint('Loading colleges and universities...');
    isLoadingCollegesUniversities.value = true;
    hasLoadedCollegesUniversities.value = false;
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.getCollegesUniversities(),
      showLoader: true,
      onSuccess: (response) {
        if (response.success && response.data != null) {
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
                  continue;
                }
              }
              collegesUniversities.value = names;
            }
          }
        }
      },
      onError: (error, stack) {
        debugPrint('Error loading colleges/universities: $error');
      },
      onComplete: () {
        isLoadingCollegesUniversities.value = false;
        hasLoadedCollegesUniversities.value = true;
      },
    );
  }

  Future<void> _loadQualificationsDetails() async {
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.getQualificationsDetails(),
      showLoader: false,
      onSuccess: (response) {
        if (response.success && response.data != null) {
          try {
            final data = response.data as Map<String, dynamic>?;
            if (data != null) {
              if (data['total_experience'] != null) {
                final experience = data['total_experience'];
                if (experience is num) {
                  yearsExperienceController.text = experience.toString();
                } else if (experience is String) {
                  yearsExperienceController.text = experience;
                }
              }

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
                for (final qual in qualifications) {
                  qual.dispose();
                }
                qualifications.clear();

                for (final qualData in qualificationsList) {
                  if (qualData is Map<String, dynamic>) {
                    final qualification = QualificationItem(
                      id: qualData['_id']?.toString(),
                    );

                    if (qualData['school_or_university'] != null) {
                      final schoolValue =
                          qualData['school_or_university'].toString();
                      final isId = schoolValue.length == 24 &&
                          RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(schoolValue);

                      if (isId) {
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
                          qualification.schoolController.text = '';
                          qualification.selectedCollegeUniversityId =
                              schoolValue;
                        }
                      } else {
                        qualification.schoolController.text = schoolValue;
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

                    if (qualData['degree_or_certificate'] != null) {
                      qualification.degreeController.text =
                          qualData['degree_or_certificate'].toString();
                    }

                    if (qualData['expiry_date'] != null) {
                      final expiryDate = qualData['expiry_date'].toString();
                      try {
                        final date = DateTime.parse(expiryDate);
                        qualification.qualificationExpiryController.text =
                            '${date.day.toString().padLeft(2, '0')}/'
                            '${date.month.toString().padLeft(2, '0')}/'
                            '${date.year}';
                      } catch (e) {
                        qualification.qualificationExpiryController.text =
                            expiryDate;
                      }
                    }

                    if (qualData['certificate_file'] != null) {
                      final certUrl = qualData['certificate_file'].toString();
                      qualification.certificateUrl = certUrl;
                      qualification.uploadCertificateController.text =
                          certUrl.split('/').last;
                    }

                    qualification.schoolController
                        .addListener(_checkHasValidData);
                    qualification.degreeController
                        .addListener(_checkHasValidData);
                    qualification.qualificationExpiryController
                        .addListener(_checkHasValidData);

                    qualifications.add(qualification);
                  }
                }
              } else {
                if (qualifications.isEmpty) {
                  final initialQualification = QualificationItem.initial();
                  initialQualification.schoolController
                      .addListener(_checkHasValidData);
                  initialQualification.degreeController
                      .addListener(_checkHasValidData);
                  initialQualification.qualificationExpiryController
                      .addListener(_checkHasValidData);
                  qualifications.add(initialQualification);
                }
              }
            }
          } catch (e) {
            debugPrint('Error parsing qualifications: $e');
            if (qualifications.isEmpty) {
              final initialQualification = QualificationItem.initial();
              initialQualification.schoolController
                  .addListener(_checkHasValidData);
              initialQualification.degreeController
                  .addListener(_checkHasValidData);
              initialQualification.qualificationExpiryController
                  .addListener(_checkHasValidData);
              qualifications.add(initialQualification);
            }
          }
        } else {
          if (qualifications.isEmpty) {
            final initialQualification = QualificationItem.initial();
            initialQualification.schoolController
                .addListener(_checkHasValidData);
            initialQualification.degreeController
                .addListener(_checkHasValidData);
            initialQualification.qualificationExpiryController
                .addListener(_checkHasValidData);
            qualifications.add(initialQualification);
          }
        }
      },
      onError: (error, stackTrace) {
        if (qualifications.isEmpty) {
          final initialQualification = QualificationItem.initial();
          initialQualification.schoolController.addListener(_checkHasValidData);
          initialQualification.degreeController.addListener(_checkHasValidData);
          initialQualification.qualificationExpiryController
              .addListener(_checkHasValidData);
          qualifications.add(initialQualification);
        }
      },
      onComplete: () {
        _checkHasValidData();
      },
    );
  }

  void setCollegeUniversity(QualificationItem item, String? value, int index) {
    item.schoolController.text = value ?? '';
    final matchedCollege = collegesUniversities.firstWhereOrNull(
      (college) => college.toLowerCase() == (value ?? '').toLowerCase(),
    );
    if (matchedCollege != null) {
      item.selectedCollegeUniversity = matchedCollege;
      item.selectedCollegeUniversityId =
          collegesUniversitiesMap[matchedCollege];
    } else {
      item.selectedCollegeUniversity = value?.isNotEmpty == true ? value : null;
      item.selectedCollegeUniversityId = null;
    }
  }

  void onCollegeUniversityTextChanged(
      QualificationItem item, String text, int index) {
    item.schoolController.text = text;
    final matchedCollege = collegesUniversities.firstWhereOrNull(
      (college) => college.toLowerCase() == text.toLowerCase(),
    );
    if (matchedCollege != null) {
      item.selectedCollegeUniversity = matchedCollege;
      item.selectedCollegeUniversityId =
          collegesUniversitiesMap[matchedCollege];
    } else {
      item.selectedCollegeUniversity = text.isNotEmpty ? text : null;
      item.selectedCollegeUniversityId = null;
    }
  }

  List<String> getFilteredCollegesUniversities(String query) {
    if (query.isEmpty) return collegesUniversities;
    return collegesUniversities
        .where((college) => college.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void onSchoolTap(QualificationItem item) {
    debugPrint('School tapped');
  }

  Future<void> pickCertificateFile(
    BuildContext context,
    QualificationItem qualification,
    int index,
  ) async {
    // Guard: prevent opening if already picking
    if (_isPicking) return;

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

  // ─── CORE FIX ────────────────────────────────────────────────────────────
  //
  // Android 13+ introduces READ_MEDIA_VISUAL_USER_SELECTED (partial/limited
  // access). Calling Permission.photos.request() on Android 13+ shows the
  // system photo picker sheet. Then calling imagePicker.pickImage() opens
  // a SECOND picker — causing the double-open bug.
  //
  // Fix: Skip manual permission requests entirely on Android.
  // image_picker internally handles all permission logic via its own
  // ActivityResultLauncher and never double-opens the picker.
  //
  // On iOS we still use permission_handler carefully (see iOS comments below).
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _pickImage(QualificationItem qualification, int index) async {
    if (_isPicking) return;
    _isPicking = true;

    try {
      if (Platform.isAndroid) {
        // ── Android: Let image_picker handle permissions internally ──────
        // DO NOT call Permission.photos.request() or any permission check.
        // On Android 13+, manually requesting READ_MEDIA_IMAGES triggers the
        // system photo picker, and then pickImage() opens a second one.
        // image_picker's native plugin handles the permission seamlessly.
        final XFile? pickedFile = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 2048,
          maxHeight: 2048,
          imageQuality: 90,
        );

        if (pickedFile != null) {
          await _handlePickedImage(pickedFile, qualification);
        }
      } else if (Platform.isIOS) {
        // ── iOS: Check status before requesting to avoid double-open ────
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
            await _handlePickedImage(pickedFile, qualification);
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isPicking = false;
    }
  }

  /// Shared logic after a file is picked — validates size and updates state
  Future<void> _handlePickedImage(
      XFile pickedFile, QualificationItem qualification) async {
    final file = File(pickedFile.path);
    final fileSize = await file.length();
    const maxSize = 5 * 1024 * 1024; // 5 MB

    if (fileSize > maxSize) {
      Get.snackbar(
        'Error',
        'File size exceeds 5 MB limit',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    qualification.certificateFile = file;
    qualification.uploadCertificateController.text = pickedFile.name;
    qualification.certificateUrl = null;
    qualifications.refresh();
    _checkHasValidData();
  }

  Future<void> _pickPDF(QualificationItem qualification, int index) async {
    if (_isPicking) return;
    _isPicking = true;

    try {
      if (Platform.isAndroid) {
        // ── Android: Skip manual storage permission check ────────────────
        // On Android 13+ (API 33+), READ_EXTERNAL_STORAGE is deprecated.
        // FilePicker uses the Storage Access Framework (SAF) which shows the
        // system document picker — no manual permission needed.
        // On Android < 13, FilePicker handles READ_EXTERNAL_STORAGE itself.
        // Manually calling Permission.storage.request() would show a
        // redundant dialog and may cause conflicts.
        await _openFilePicker(qualification);
      } else if (Platform.isIOS) {
        // iOS: No special permission needed for document/file picker
        await _openFilePicker(qualification);
      }
    } catch (e) {
      debugPrint('Error picking PDF: $e');
      Get.snackbar(
        'Error',
        'Failed to pick PDF: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isPicking = false;
    }
  }

  /// Shared FilePicker logic used by both Android and iOS for PDF
  Future<void> _openFilePicker(QualificationItem qualification) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final filePath = result.files.first.path;
      if (filePath == null) {
        Get.snackbar(
          'Error',
          'Could not access the selected file.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final file = File(filePath);
      final fileSize = await file.length();
      const maxSize = 5 * 1024 * 1024; // 5 MB

      if (fileSize > maxSize) {
        Get.snackbar(
          'Error',
          'File size exceeds 5 MB limit',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      qualification.certificateFile = file;
      qualification.uploadCertificateController.text = result.files.first.name;
      qualification.certificateUrl = null;
      qualifications.refresh();
      _checkHasValidData();
    }
  }

  void _showPermissionSettingsSnackbar(String permissionType) {
    Get.snackbar(
      'Permission Required',
      '$permissionType access is required. Please enable it in Settings.',
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

  Future<File?> _downloadCertificateFile(
      String url, String qualificationId) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final uri = Uri.parse(url);
      final extension = path.extension(uri.path).isNotEmpty
          ? path.extension(uri.path)
          : '.jpg';
      final filePath = path.join(
        tempDir.path,
        'certificate_${qualificationId}_${DateTime.now().millisecondsSinceEpoch}$extension',
      );

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
        return File(filePath);
      } else {
        final file = File(filePath);
        if (await file.exists()) await file.delete();
        return null;
      }
    } catch (e) {
      debugPrint('Error downloading certificate file: $e');
      return null;
    }
  }

  void onUploadTap(QualificationItem item) {
    if (_isPicking) return;
    final index = qualifications.indexOf(item);
    if (index >= 0) {
      final context = Get.context;
      if (context != null) {
        pickCertificateFile(context, item, index);
      }
    }
  }

  /// Check if there's any valid data in the form
  void _checkHasValidData() {
    bool hasData = false;

    // Check if years of experience has data
    if (yearsExperienceController.text.trim().isNotEmpty) {
      hasData = true;
    }

    // Check if any qualification has data
    for (final qualification in qualifications) {
      if (qualification.schoolController.text.trim().isNotEmpty ||
          qualification.degreeController.text.trim().isNotEmpty ||
          qualification.qualificationExpiryController.text.trim().isNotEmpty ||
          qualification.certificateFile != null ||
          (qualification.certificateUrl != null &&
              qualification.certificateUrl!.isNotEmpty)) {
        hasData = true;
        break;
      }
    }

    hasValidData.value = hasData;
  }

  Future<void> _saveQualifications() async {
    if (formKey.currentState == null || !formKey.currentState!.validate()) {
      return;
    }
    isLoading.value = true;

    int totalExperience = 0;
    try {
      final experienceText = yearsExperienceController.text.trim();
      if (experienceText.isNotEmpty) {
        totalExperience = int.parse(experienceText);
      }
    } catch (e) {
      totalExperience = 0;
    }

    final qualificationsList = <Map<String, dynamic>>[];
    final certificateFiles = <File>[];

    for (int i = 0; i < qualifications.length; i++) {
      final qualification = qualifications[i];
      final school = qualification.schoolController.text.trim();
      final degree = qualification.degreeController.text.trim();
      final expiryText =
          qualification.qualificationExpiryController.text.trim();

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
          }
        } catch (e) {
          debugPrint('Error parsing expiry date: $e');
        }
      }

      final qualificationData = <String, dynamic>{
        'degree_or_certificate': degree,
      };

      if (qualification.id != null &&
          qualification.id!.isNotEmpty &&
          !removedQualificationIds.contains(qualification.id)) {
        qualificationData['id'] = qualification.id;
      }

      if (qualification.selectedCollegeUniversityId != null &&
          qualification.selectedCollegeUniversityId!.isNotEmpty) {
        qualificationData['school_or_university'] =
            qualification.selectedCollegeUniversityId;
      } else {
        qualificationData['school_or_university'] = school;
      }

      if (formattedExpiryDate != null) {
        qualificationData['expiry_date'] = formattedExpiryDate;
      }

      qualificationsList.add(qualificationData);

      if (qualification.certificateFile != null) {
        certificateFiles.add(qualification.certificateFile!);
      } else if (qualification.certificateUrl != null &&
          qualification.certificateUrl!.isNotEmpty) {
        try {
          final downloadedFile = await _downloadCertificateFile(
              qualification.certificateUrl!, qualification.id ?? 'cert_$i');
          if (downloadedFile != null) {
            certificateFiles.add(downloadedFile);
          }
        } catch (e) {
          debugPrint('Error downloading certificate: $e');
        }
      }
    }

    await callDataService<ApiResponse<dynamic>>(
      _userApiService.upsertQualifications(
        totalExperience: totalExperience,
        qualifications: qualificationsList,
        removedIds: removedQualificationIds.toList(),
        certificateFiles: certificateFiles.isNotEmpty ? certificateFiles : null,
      ),
      showLoader: true,
      onSuccess: (response) async {
        if (response.success) {
          final storage = _storageService;
          if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            if (data['user'] is Map<String, dynamic>) {
              final user = data['user'] as Map<String, dynamic>;
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
                  }
                }
              }
            }
          }
          removedQualificationIds.clear();
          showResponseDialog(
            title: 'Success',
            message: 'Qualifications updated successfully',
            isError: false,
            showButton: true,
            onOkPressed: () => Get.back(),
          );
        } else {
          showResponseDialog(
            title: 'Error',
            message: response.errorMessage,
            isError: true,
            showButton: true,
          );
        }
        isLoading.value = false;
      },
      onError: (error, stack) {
        final errorMsg = errorMessage.value.isNotEmpty
            ? errorMessage.value
            : 'Failed to save qualifications. Please try again.';
        showResponseDialog(
          title: 'Error',
          message: errorMsg,
          isError: true,
          showButton: true,
        );
        isLoading.value = false;
      },
    );
  }

  void onUpdateDetails() {
    hasValidated.value = true;
    _saveQualifications();
  }

  String? validateNotEmpty(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $label';
    }
    return null;
  }

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
    String? certificateUrl,
    String? id,
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
  String? certificateUrl;
  String? id;

  factory QualificationItem.initial() => QualificationItem();

  void dispose() {
    schoolController.dispose();
    degreeController.dispose();
    qualificationExpiryController.dispose();
    uploadCertificateController.dispose();
  }
}
