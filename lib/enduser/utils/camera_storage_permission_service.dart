import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Service class for handling camera and storage permissions across the application
class CameraStoragePermissionService {
  /// Request camera and storage permissions based on platform and Android version
  /// Returns true if all required permissions are granted, false otherwise
  Future<bool> requestCameraAndStoragePermissions() async {
    try {
      // Only check Android version on Android platform
      if (!Platform.isAndroid) {
        // For iOS, request camera and photos permissions together
        final statuses = await [
          Permission.camera,
          Permission.photos,
        ].request();

        final cameraStatus =
            statuses[Permission.camera] ?? PermissionStatus.denied;
        final photosStatus =
            statuses[Permission.photos] ?? PermissionStatus.denied;

        if (cameraStatus.isPermanentlyDenied ||
            photosStatus.isPermanentlyDenied) {
          await _showPermissionSettingsDialog();
          return false;
        }

        if (cameraStatus.isDenied || photosStatus.isDenied) {
          Get.snackbar(
            'Permission Denied',
            'Please grant camera and photos permissions to continue',
            snackPosition: SnackPosition.BOTTOM,
          );
          return false;
        }

        return cameraStatus.isGranted && photosStatus.isGranted;
      }

      // Get Android version
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      // For Android 21-22, permissions are granted at install time
      // But we still check and request them if needed
      if (sdkInt < 23) {
        final cameraStatus = await Permission.camera.status;
        if (!cameraStatus.isGranted) {
          final requestedStatus = await Permission.camera.request();
          return requestedStatus.isGranted;
        }
        return true;
      }

      // For Android 23-32, request CAMERA and READ_EXTERNAL_STORAGE together
      if (sdkInt >= 23 && sdkInt <= 32) {
        // Request both permissions together
        final statuses = await [
          Permission.camera,
          Permission.storage,
        ].request();

        final cameraStatus =
            statuses[Permission.camera] ?? PermissionStatus.denied;
        final storageStatus =
            statuses[Permission.storage] ?? PermissionStatus.denied;

        // Handle permanently denied
        if (cameraStatus.isPermanentlyDenied ||
            storageStatus.isPermanentlyDenied) {
          await _showPermissionSettingsDialog();
          return false;
        }

        // If still denied, show message
        if (cameraStatus.isDenied || storageStatus.isDenied) {
          Get.snackbar(
            'Permission Denied',
            'Please grant camera and storage permissions to continue',
            snackPosition: SnackPosition.BOTTOM,
          );
          return false;
        }

        return cameraStatus.isGranted && storageStatus.isGranted;
      }

      // For Android 33+ (API 33+), request CAMERA and READ_MEDIA_IMAGES together
      if (sdkInt >= 33) {
        // Request both permissions together
        final statuses = await [
          Permission.camera,
          Permission.photos,
        ].request();

        final cameraStatus =
            statuses[Permission.camera] ?? PermissionStatus.denied;
        final photosStatus =
            statuses[Permission.photos] ?? PermissionStatus.denied;

        // Handle permanently denied
        if (cameraStatus.isPermanentlyDenied ||
            photosStatus.isPermanentlyDenied) {
          await _showPermissionSettingsDialog();
          return false;
        }

        // If still denied, show message
        if (cameraStatus.isDenied || photosStatus.isDenied) {
          Get.snackbar(
            'Permission Denied',
            'Please grant camera and photos permissions to continue',
            snackPosition: SnackPosition.BOTTOM,
          );
          return false;
        }

        return cameraStatus.isGranted && photosStatus.isGranted;
      }

      return false;
    } catch (e, stackTrace) {
      debugPrint('Error in requestCameraAndStoragePermissions: $e');
      debugPrint('Stack trace: $stackTrace');
      Get.snackbar(
        'Error',
        'Failed to request permissions: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Request camera permission only
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestCameraPermission() async {
    try {
      final cameraStatus = await Permission.camera.status;

      if (cameraStatus.isPermanentlyDenied) {
        await _showCameraPermissionSettingsDialog();
        return false;
      }

      if (!cameraStatus.isGranted) {
        final requestedStatus = await Permission.camera.request();

        if (requestedStatus.isPermanentlyDenied) {
          await _showCameraPermissionSettingsDialog();
          return false;
        }

        if (requestedStatus.isDenied) {
          Get.snackbar(
            'Permission Required',
            'Camera permission is required to take a photo',
            snackPosition: SnackPosition.BOTTOM,
          );
          return false;
        }

        return requestedStatus.isGranted;
      }

      return cameraStatus.isGranted;
    } catch (e) {
      debugPrint('Error in requestCameraPermission: $e');
      Get.snackbar(
        'Error',
        'Failed to request camera permission: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Request storage/photos permission based on platform and Android version
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 33) {
          // Android 13+ uses photos permission
          final photosStatus = await Permission.photos.status;

          if (photosStatus.isPermanentlyDenied) {
            await _showStoragePermissionSettingsDialog();
            return false;
          }

          if (!photosStatus.isGranted) {
            final requestedStatus = await Permission.photos.request();

            if (requestedStatus.isPermanentlyDenied) {
              await _showStoragePermissionSettingsDialog();
              return false;
            }

            if (requestedStatus.isDenied) {
              Get.snackbar(
                'Permission Required',
                'Photos permission is required to select an image',
                snackPosition: SnackPosition.BOTTOM,
              );
              return false;
            }

            return requestedStatus.isGranted;
          }

          return photosStatus.isGranted;
        } else {
          // Android < 13 uses storage permission
          final storageStatus = await Permission.storage.status;

          if (storageStatus.isPermanentlyDenied) {
            await _showStoragePermissionSettingsDialog();
            return false;
          }

          if (!storageStatus.isGranted) {
            final requestedStatus = await Permission.storage.request();

            if (requestedStatus.isPermanentlyDenied) {
              await _showStoragePermissionSettingsDialog();
              return false;
            }

            if (requestedStatus.isDenied) {
              Get.snackbar(
                'Permission Required',
                'Storage permission is required to select an image',
                snackPosition: SnackPosition.BOTTOM,
              );
              return false;
            }

            return requestedStatus.isGranted;
          }

          return storageStatus.isGranted;
        }
      } else {
        // For iOS, check photos permission
        final photosStatus = await Permission.photos.status;

        if (photosStatus.isPermanentlyDenied) {
          await _showStoragePermissionSettingsDialog();
          return false;
        }

        if (!photosStatus.isGranted) {
          final requestedStatus = await Permission.photos.request();

          if (requestedStatus.isPermanentlyDenied) {
            await _showStoragePermissionSettingsDialog();
            return false;
          }

          if (requestedStatus.isDenied) {
            Get.snackbar(
              'Permission Required',
              'Photos permission is required to select an image',
              snackPosition: SnackPosition.BOTTOM,
            );
            return false;
          }

          return requestedStatus.isGranted;
        }

        return photosStatus.isGranted;
      }
    } catch (e) {
      debugPrint('Error in requestStoragePermission: $e');
      Get.snackbar(
        'Error',
        'Failed to request storage permission: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Shows the photo library denied dialog (e.g. iOS gallery flow when permanently denied).
  Future<void> showPhotoLibraryPermissionDeniedDialog() async {
    await _showStoragePermissionSettingsDialog();
  }

  /// Check camera permission status
  /// Returns true if permission is granted, false otherwise
  Future<bool> checkCameraPermissionStatus() async {
    try {
      final cameraStatus = await Permission.camera.status;
      return cameraStatus.isGranted;
    } catch (e) {
      debugPrint('Error checking camera permission: $e');
      return false;
    }
  }

  /// Check storage/photos permission status based on platform and Android version
  /// Returns true if permission is granted, false otherwise
  Future<bool> checkStoragePermissionStatus() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 33) {
          final photosStatus = await Permission.photos.status;
          return photosStatus.isGranted;
        } else {
          final storageStatus = await Permission.storage.status;
          return storageStatus.isGranted;
        }
      } else {
        final photosStatus = await Permission.photos.status;
        return photosStatus.isGranted;
      }
    } catch (e) {
      debugPrint('Error checking storage permission: $e');
      return false;
    }
  }

  Future<void> _showPermissionSettingsDialog() async {
    final result = await Get.dialog<bool>(
      barrierDismissible: false,
      PopScope(
        canPop: false, // Prevent back button dismissal
        child: AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            'Camera and storage permissions are required. Please enable them in app settings to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await openAppSettings();
      // Check permission status periodically after opening settings
      _checkPermissionAfterSettings();
    }
  }

  Future<void> _showCameraPermissionSettingsDialog() async {
    final result = await Get.dialog<bool>(
      barrierDismissible: false,
      PopScope(
        canPop: false, // Prevent back button dismissal
        child: AlertDialog(
          title: const Text('Unable to Access Camera'),
          content: const Text(
            'To capture and upload your profile picture, we need access to your device’s camera. Please allow Camera access to continue using this feature. You can enable it anytime from Settings → Apps → Verithrive → Permissions.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Okay'),
            )
          ],
        ),
      ),
    );

    if (result == true) {
      await openAppSettings();
      // Check permission status periodically after opening settings
      _checkCameraPermissionAfterSettings();
    }
  }

  Future<void> _showStoragePermissionSettingsDialog() async {
    final result = await Get.dialog<bool>(
      barrierDismissible: false,
      PopScope(
        canPop: false, // Prevent back button dismissal
        child: AlertDialog(
          title: const Text('Unable to Access Photo Library'),
          content: const Text(
            'To upload your profile picture, we need access to your device’s photo library. You can still continue using other app features without enabling Photo Library access. You can enable it anytime from Settings → Apps → Verithrive → Permissions.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Okay'),
            ),
            // TextButton(
            //   onPressed: () => Get.back(result: true),
            //   child: const Text('Open Settings'),
            // ),
          ],
        ),
      ),
    );

    if (result == true) {
      await openAppSettings();
      // Check permission status periodically after opening settings
      _checkStoragePermissionAfterSettings();
    }
  }

  Future<void> _checkPermissionAfterSettings() async {
    // Check permission status every 500ms for up to 30 seconds
    const maxChecks = 60; // 30 seconds total (60 * 500ms)
    int checkCount = 0;

    while (checkCount < maxChecks) {
      await Future.delayed(const Duration(milliseconds: 500));
      checkCount++;

      // Check if permissions are now granted
      final cameraGranted = await checkCameraPermissionStatus();
      final storageGranted = await checkStoragePermissionStatus();

      if (cameraGranted && storageGranted) {
        // Permissions granted, dismiss any open dialogs
        if (Get.isDialogOpen == true) {
          Get.back();
        }
        return;
      }
    }

    // After checking period, if permissions are still not granted, show the dialog again
    if ((!await checkCameraPermissionStatus() ||
            !await checkStoragePermissionStatus()) &&
        Get.isDialogOpen != true) {
      await _showPermissionSettingsDialog();
    }
  }

  Future<void> _checkCameraPermissionAfterSettings() async {
    // Check permission status every 500ms for up to 30 seconds
    const maxChecks = 60; // 30 seconds total (60 * 500ms)
    int checkCount = 0;

    while (checkCount < maxChecks) {
      await Future.delayed(const Duration(milliseconds: 500));
      checkCount++;

      // Check if permission is now granted
      final isGranted = await checkCameraPermissionStatus();

      if (isGranted) {
        // Permission granted, dismiss any open dialogs
        if (Get.isDialogOpen == true) {
          Get.back();
        }
        return;
      }
    }

    // After checking period, if permission is still not granted, show the dialog again
    if (!await checkCameraPermissionStatus() && Get.isDialogOpen != true) {
      await _showCameraPermissionSettingsDialog();
    }
  }

  Future<void> _checkStoragePermissionAfterSettings() async {
    // Check permission status every 500ms for up to 30 seconds
    const maxChecks = 60; // 30 seconds total (60 * 500ms)
    int checkCount = 0;

    while (checkCount < maxChecks) {
      await Future.delayed(const Duration(milliseconds: 500));
      checkCount++;

      // Check if permission is now granted
      final isGranted = await checkStoragePermissionStatus();

      if (isGranted) {
        // Permission granted, dismiss any open dialogs
        if (Get.isDialogOpen == true) {
          Get.back();
        }
        return;
      }
    }

    // After checking period, if permission is still not granted, show the dialog again
    if (!await checkStoragePermissionStatus() && Get.isDialogOpen != true) {
      await _showStoragePermissionSettingsDialog();
    }
  }
}
