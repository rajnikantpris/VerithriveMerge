import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';

/// Service class for handling location permissions across the application
class LocationPermissionService {
  /// Request location permission
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestLocationPermission() async {
    try {
      if (Platform.isAndroid) {
        // Get Android version
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        // For Android 12+ (API 31+), we need to request fine location
        // For older versions, we can use fine or coarse location
        if (sdkInt >= 31) {
          // Android 12+ requires fine location permission
          final locationStatus = await Permission.locationWhenInUse.status;

          if (locationStatus.isPermanentlyDenied) {
            await _showLocationPermissionSettingsDialog();
            return false;
          }

          if (!locationStatus.isGranted) {
            final requestedStatus =
                await Permission.locationWhenInUse.request();

            if (requestedStatus.isPermanentlyDenied) {
              await _showLocationPermissionSettingsDialog();
              return false;
            }

            if (requestedStatus.isDenied) {
              // Show dialog to explain why permission is needed and retry
              final shouldRetry = await _showLocationPermissionDeniedDialog();
              if (shouldRetry == true) {
                // Retry requesting permission
                return await requestLocationPermission();
              }
              return false;
            }

            return requestedStatus.isGranted;
          }

          return locationStatus.isGranted;
        } else {
          // For Android < 12, request location permission
          final locationStatus = await Permission.location.status;

          if (locationStatus.isPermanentlyDenied) {
            await _showLocationPermissionSettingsDialog();
            return false;
          }

          if (!locationStatus.isGranted) {
            final requestedStatus = await Permission.location.request();

            if (requestedStatus.isPermanentlyDenied) {
              await _showLocationPermissionSettingsDialog();
              return false;
            }

            if (requestedStatus.isDenied) {
              // Show dialog to explain why permission is needed and retry
              final shouldRetry = await _showLocationPermissionDeniedDialog();
              if (shouldRetry == true) {
                // Retry requesting permission
                return await requestLocationPermission();
              }
              return false;
            }

            return requestedStatus.isGranted;
          }

          return locationStatus.isGranted;
        }
      } else {
        // iOS: Use Geolocator for permission check - more reliable than permission_handler
        // which can wrongly report isPermanentlyDenied when user has actually granted permission
        final locationPermission = await Geolocator.checkPermission();

        if (locationPermission == LocationPermission.whileInUse ||
            locationPermission == LocationPermission.always) {
          return true;
        }

        if (locationPermission == LocationPermission.deniedForever) {
          await _showLocationPermissionSettingsDialog();
          return false;
        }

        // LocationPermission.denied - request permission
        final requestedPermission = await Geolocator.requestPermission();

        if (requestedPermission == LocationPermission.whileInUse ||
            requestedPermission == LocationPermission.always) {
          return true;
        }

        if (requestedPermission == LocationPermission.deniedForever) {
          await _showLocationPermissionSettingsDialog();
          return false;
        }

        if (requestedPermission == LocationPermission.denied) {
          final shouldRetry = await _showLocationPermissionDeniedDialog();
          if (shouldRetry == true) {
            return await requestLocationPermission();
          }
          return false;
        }

        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('Error in requestLocationPermission: $e');
      debugPrint('Stack trace: $stackTrace');
      Get.snackbar(
        'Error',
        'Failed to request location permission: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Check current location permission status
  /// Returns true if permission is granted, false otherwise
  Future<bool> checkLocationPermissionStatus() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 31) {
          final locationStatus = await Permission.locationWhenInUse.status;
          return locationStatus.isGranted;
        } else {
          final locationStatus = await Permission.location.status;
          return locationStatus.isGranted;
        }
      } else {
        // iOS: Use Geolocator for accurate permission status
        final locationPermission = await Geolocator.checkPermission();
        return locationPermission == LocationPermission.whileInUse ||
            locationPermission == LocationPermission.always;
      }
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      return false;
    }
  }

  Future<void> _showLocationPermissionSettingsDialog() async {
    final result = await Get.dialog<bool>(
      barrierDismissible: false,
      PopScope(
        canPop: false, // Prevent back button dismissal
        child: AlertDialog(
          title: const Text('Location Denied'),
          content: const Text(
            "Couldn't detect your location, please allow location from settings!",
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Go to Settings'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await openAppSettings();

      // Check permission status periodically after opening settings
      // This will dismiss the dialog automatically if permission is granted
      _checkPermissionAfterSettings();
    }
  }

  Future<void> _checkPermissionAfterSettings() async {
    // Check permission status every 500ms for up to 30 seconds
    const maxChecks = 60; // 30 seconds total (60 * 500ms)
    int checkCount = 0;

    while (checkCount < maxChecks) {
      await Future.delayed(const Duration(milliseconds: 500));
      checkCount++;

      // Check if permission is now granted
      final isGranted = await checkLocationPermissionStatus();

      if (isGranted) {
        // Permission granted, dismiss any open dialogs
        if (Get.isDialogOpen == true) {
          Get.back();
        }
        return;
      }
    }

    // After checking period, if permission is still not granted, show the dialog again
    if (!await checkLocationPermissionStatus() && Get.isDialogOpen != true) {
      await _showLocationPermissionSettingsDialog();
    }
  }

  Future<bool?> _showLocationPermissionDeniedDialog() async {
    return await Get.dialog<bool>(
      barrierDismissible: false,
      PopScope(
        canPop: false, // Prevent back button dismissal
        child: AlertDialog(
          title: const Text('Location Denied'),
          content: const Text(
            "Couldn't detect your location, please allow location from settings!",
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Go to Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
