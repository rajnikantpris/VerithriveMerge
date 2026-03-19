import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart' as dio;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

import '../../../../api/api_response.dart';
import '../../../../api/user_api_service.dart';
import '../../../../common/base_controller.dart';
import '../../../../services/camera_storage_permission_service.dart';
import '../../../../services/storage_service.dart';
import '../../../../widgets/response_dialog.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/font_sizes.dart';
import '../../../../theme/fonts.dart';
import '../../../../theme/hight_width_sizes.dart';

enum FilePickerSource { image, pdf }

class PersonalIdentificationController extends BaseController {
  final UserApiService _userApiService;
  final StorageService? _storageService =
      Get.isRegistered<StorageService>() ? Get.find<StorageService>() : null;
  final CameraStoragePermissionService _cameraStoragePermissionService =
      CameraStoragePermissionService();
  final ImagePicker _imagePicker = ImagePicker();

  PersonalIdentificationController(this._userApiService);

  late final GlobalKey<FormState> formKey;

  final idTypeController = TextEditingController();
  final idExpiryController = TextEditingController();
  final idUploadController = TextEditingController();
  final confirmRightToWork = false.obs;

  final selectedExpiryDate = Rxn<DateTime>();
  final selectedIdType = ''.obs;
  final idTypes = ['Passport', 'Driving license'];

  File? idFile; // Store uploaded ID file
  final identificationId = Rxn<String>(); // Store identification ID for updates
  String? idDocumentUrl; // Store document URL from API for existing documents
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize formKey to ensure a new key is created each time
    formKey = GlobalKey<FormState>();
    // Load existing data from API
    _loadPersonalIdentificationDetails();
  }

  @override
  void onClose() {
    idTypeController.dispose();
    idExpiryController.dispose();
    idUploadController.dispose();
    super.onClose();
  }

  void setIdType(String? value) {
    if (value == null || value.isEmpty) {
      selectedIdType.value = '';
      idTypeController.clear();
      return;
    }
    selectedIdType.value = value;
    idTypeController.text = value;
  }

  void onIdTypeTap() {
    // Show bottom sheet for ID type selection
    Get.bottomSheet(
      Container(
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
                  'Select ID Type',
                  style: TextStyle(
                    fontFamily: AppFonts.rubikMedium,
                    fontSize: FontSizes.setFontValue_18,
                    fontWeight: FontWeight.w500,
                    color: AppColor.color_2D2D2D,
                  ),
                ),
              ),
              ...idTypes.map((idType) {
                final isSelected = selectedIdType.value == idType;
                return ListTile(
                  title: Text(
                    idType,
                    style: TextStyle(
                      fontFamily: AppFonts.rubikRegular,
                      fontSize: FontSizes.setFontValue_16,
                      color: isSelected
                          ? AppColor.color_2FC4B2
                          : AppColor.color_2D2D2D,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check,
                          color: AppColor.color_2FC4B2,
                        )
                      : null,
                  onTap: () {
                    setIdType(idType);
                    Get.back();
                  },
                );
              }),
              SizedBox(height: HightWidthSizes.setValue_8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = selectedExpiryDate.value ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now,
      lastDate: DateTime(now.year + 50),
    );

    if (picked != null) {
      selectedExpiryDate.value = picked;
      idExpiryController.text = DateFormat('dd/MM/yyyy').format(picked);
      formKey.currentState?.validate();
    }
  }

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
              'Tap the upload button again to select a photo.',
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
    formKey.currentState?.validate();
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

  /// Pick ID PDF file
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
        PermissionStatus status = await Permission.photos.status;
        debugPrint('iOS photo permission status (before): $status');

        if (status.isPermanentlyDenied) {
          _showPermissionSettingsSnackbar();
          return;
        }

        if (status.isDenied) {
          // First-time request — iOS may show its own permission dialog
          status = await Permission.photos.request();
          debugPrint('iOS photo permission status (after request): $status');

          if (status.isDenied || status.isPermanentlyDenied) {
            _showPermissionSettingsSnackbar();
            return;
          }
        }

        // Status is .granted or .limited — safe to open picker
        if (status.isGranted || status.isLimited) {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          );

          if (result != null && result.files.single.path != null) {
            await _processSelectedPdfFile(result.files.single);
          }
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

  void onUploadTap() {
    pickIdFile(Get.context!);
  }

  void toggleConfirmRightToWork(bool? value) {
    confirmRightToWork.value = value ?? false;
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
                      selectedExpiryDate.value = date;
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

                  // Load confirm legal right to work from is_personal_identification
                  if (data['is_personal_identification'] != null) {
                    final isPersonalIdentification =
                        data['is_personal_identification'];
                    if (isPersonalIdentification is bool) {
                      confirmRightToWork.value = isPersonalIdentification;
                    } else if (isPersonalIdentification is String) {
                      confirmRightToWork.value =
                          isPersonalIdentification.toLowerCase() == 'true';
                    }
                    debugPrint(
                        'Loaded is_personal_identification: ${confirmRightToWork.value}');
                  } else {
                    // Fallback to confirm_legal_right if is_personal_identification is not available
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

  /// Validate required date
  String? validateRequiredDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter expiry date';
    }
    return null;
  }

  void onUpdateDetails() async {
    if (formKey.currentState?.validate() ?? false) {
      if (!confirmRightToWork.value) {
        showResponseDialog(
          title: 'Error',
          message: 'Please confirm that you have legal right to work in the UK',
          isError: true,
          showButton: true,
        );
        return;
      }
      await _savePersonalIdentification();
    }
  }

  /// Save personal identification API call
  Future<void> _savePersonalIdentification() async {
    isLoading.value = true;
    debugPrint('=== Starting Save Personal Identification ===');

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
      isLoading.value = false;
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
        isLoading.value = false;
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
      isLoading.value = false;
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
      isLoading.value = false;
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
          isLoading.value = false;
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
        isLoading.value = false;
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

          showResponseDialog(
            title: 'Success',
            message: 'Personal identification updated successfully',
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
        isLoading.value = false;
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
        isLoading.value = false;
      },
    );
  }

  String? validateNotEmpty(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $label';
    }
    return null;
  }
}
