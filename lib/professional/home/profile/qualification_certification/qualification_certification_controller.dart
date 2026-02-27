import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart' as dio;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../../../api/api_response.dart';
import '../../../../api/user_api_service.dart';
import '../../../../common/base_controller.dart';
import '../../../../models/college_university_model.dart';
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

  late final GlobalKey<FormState> formKey;
  final ScrollController scrollController = ScrollController();

  final qualifications = <QualificationItem>[].obs;
  final yearsExperienceController = TextEditingController();

  // Colleges/Universities API loading states
  final collegesUniversities = <String>[].obs;
  final collegesUniversitiesMap = <String, String>{}.obs; // Maps name to _id
  final isLoadingCollegesUniversities = false.obs;
  final hasLoadedCollegesUniversities = false
      .obs; // Track if colleges/universities API has been called and completed
  final removedQualificationIds =
      <String>[].obs; // Track IDs of deleted qualifications
  final hasValidated = false.obs; // Track if form validation has been attempted

  QualificationCertificationController(this._userApiService);

  @override
  void onInit() {
    super.onInit();
    // Initialize formKey to ensure a new key is created each time
    formKey = GlobalKey<FormState>();
    // Load colleges first, then qualifications (so IDs can be matched)
    _loadCollegesUniversities().then((_) {
      // Wait a bit for colleges to be fully processed
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
    qualifications.add(QualificationItem.initial());
    qualifications.refresh();

    // Scroll to the bottom to show the newly added section after a short delay to allow UI to update
    Future.delayed(const Duration(milliseconds: 150), () {
      if (scrollController.hasClients) {
        // Scroll to the maximum extent to show the newly added section
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
    // Track removed qualification ID if it exists
    if (item.id != null && item.id!.isNotEmpty) {
      removedQualificationIds.add(item.id!);
    }
    qualifications.remove(item);
    item.dispose();
    qualifications.refresh();
  }

  Future<void> pickDate(
    BuildContext context,
    TextEditingController target,
  ) async {
    final now = DateTime.now();
    // Strip time to get today's date only
    final today = DateTime(now.year, now.month, now.day);

    // Parse existing date if present, otherwise use today
    DateTime? initialDate = today;
    if (target.text.isNotEmpty) {
      try {
        final parts = target.text.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          final existingDate = DateTime(year, month, day);
          // Use existing date if it's today or later, otherwise use today
          initialDate = existingDate.isBefore(today) ? today : existingDate;
        }
      } catch (e) {
        // If parsing fails, use today
        initialDate = today;
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today, // Only allow today and future dates
      lastDate: DateTime(now.year + 50),
    );
    if (picked != null) {
      target.text = '${picked.day.toString().padLeft(2, '0')}/'
          '${picked.month.toString().padLeft(2, '0')}/'
          '${picked.year}';
      // Trigger form validation after date is selected to clear any error
      formKey.currentState?.validate();
    }
  }

  /// Load colleges and universities from API
  Future<void> _loadCollegesUniversities() async {
    debugPrint('Loading colleges and universities...');
    isLoadingCollegesUniversities.value = true;
    hasLoadedCollegesUniversities.value =
        false; // Reset flag when starting new load
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.getCollegesUniversities(),
      showLoader: false,
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
        hasLoadedCollegesUniversities.value =
            true; // Mark that colleges/universities API call has completed
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
                // Dispose all existing qualifications
                for (final qual in qualifications) {
                  qual.dispose();
                }
                qualifications.clear();

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
                            '${date.day.toString().padLeft(2, '0')}/'
                            '${date.month.toString().padLeft(2, '0')}/'
                            '${date.year}';
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
                      qualification.uploadCertificateController.text =
                          certUrl.split('/').last;
                    }

                    qualifications.add(qualification);
                  }
                }
              } else {
                // No qualifications from API, initialize with one empty qualification
                if (qualifications.isEmpty) {
                  qualifications.add(QualificationItem.initial());
                }
              }
            }
          } catch (e) {
            debugPrint('Error parsing qualifications: $e');
            // If parsing fails, initialize with one empty qualification
            if (qualifications.isEmpty) {
              qualifications.add(QualificationItem.initial());
            }
          }
        } else {
          // API call failed, initialize with one empty qualification
          if (qualifications.isEmpty) {
            qualifications.add(QualificationItem.initial());
          }
        }
      },
      onError: (error, stackTrace) {
        debugPrint('Error loading qualifications: $error');
        // If loading fails, initialize with one empty qualification
        if (qualifications.isEmpty) {
          qualifications.add(QualificationItem.initial());
        }
      },
    );
  }

  /// Set college/university for a qualification
  void setCollegeUniversity(QualificationItem item, String? value, int index) {
    item.schoolController.text = value ?? '';
    // Check if the text matches any college/university
    final matchedCollege = collegesUniversities.firstWhereOrNull(
      (college) => college.toLowerCase() == (value ?? '').toLowerCase(),
    );

    if (matchedCollege != null) {
      // Exact match found
      item.selectedCollegeUniversity = matchedCollege;
      item.selectedCollegeUniversityId =
          collegesUniversitiesMap[matchedCollege];
    } else {
      // Custom text - no match
      item.selectedCollegeUniversity = value?.isNotEmpty == true ? value : null;
      item.selectedCollegeUniversityId = null;
    }
  }

  /// Handle college/university text change
  void onCollegeUniversityTextChanged(
      QualificationItem item, String text, int index) {
    item.schoolController.text = text;
    // Check if the text matches any college/university
    final matchedCollege = collegesUniversities.firstWhereOrNull(
      (college) => college.toLowerCase() == text.toLowerCase(),
    );

    if (matchedCollege != null) {
      // Exact match found
      item.selectedCollegeUniversity = matchedCollege;
      item.selectedCollegeUniversityId =
          collegesUniversitiesMap[matchedCollege];
    } else {
      // Custom text - no match
      item.selectedCollegeUniversity = text.isNotEmpty ? text : null;
      item.selectedCollegeUniversityId = null;
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

  void onSchoolTap(QualificationItem item) {
    // Handle school/university selection - now handled by searchable dropdown
    debugPrint('School tapped');
  }

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
      final hasPermissions = await _cameraStoragePermissionService
          .requestCameraAndStoragePermissions();
      if (!hasPermissions) {
        return;
      }

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (pickedFile != null) {
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
        qualification.certificateUrl =
            null; // Clear URL when new file is selected
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Pick PDF file
  Future<void> _pickPDF(QualificationItem qualification, int index) async {
    try {
      final hasPermissions =
          await _cameraStoragePermissionService.requestStoragePermission();
      if (!hasPermissions) {
        return;
      }

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
        qualification.certificateUrl =
            null; // Clear URL when new file is selected
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick PDF: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
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

  void onUploadTap(QualificationItem item) {
    // Find the index of the qualification
    final index = qualifications.indexOf(item);
    if (index >= 0) {
      // Get context from Get.context
      final context = Get.context;
      if (context != null) {
        pickCertificateFile(context, item, index);
      }
    }
  }

  /// Save qualifications API call
  Future<void> _saveQualifications() async {
    debugPrint('=== Starting Save Qualifications ===');
    debugPrint('Total Qualifications: ${qualifications.length}');

    // Validate form
    if (formKey.currentState == null || !formKey.currentState!.validate()) {
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
    debugPrint('Total Experience (parsed): $totalExperience');

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
          // Extract and save user flags from response
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
                    debugPrint('Saved flag $flag = $value');
                  }
                }
              }
            }
          }

          // Clear removed IDs after successful save
          removedQualificationIds.clear();

          // Show success message and navigate back after dialog is dismissed
          showResponseDialog(
            title: 'Success',
            message: 'Qualifications updated successfully',
            isError: false,
            showButton: true,
            onOkPressed: () {
              Get.back();
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
  File? certificateFile; // Store uploaded certificate file
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
