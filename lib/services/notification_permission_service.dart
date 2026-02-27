import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Service class for handling notification permissions across the application
class NotificationPermissionService {
  /// Request notification permission
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestNotificationPermission() async {
    try {
      if (Platform.isAndroid) {
        // Get Android version
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        // For Android 13+ (API 33+), notification permission needs to be explicitly requested
        // For Android < 13, notifications are enabled by default
        if (sdkInt >= 33) {
          final notificationStatus = await Permission.notification.status;

          // if (notificationStatus.isPermanentlyDenied) {
          //   await _showNotificationPermissionSettingsDialog();
          //   return false;
          // }

          if (!notificationStatus.isGranted) {
            final requestedStatus = await Permission.notification.request();

            if (requestedStatus.isPermanentlyDenied) {
              await _showNotificationPermissionSettingsDialog();
              return false;
            }

            if (requestedStatus.isDenied) {
              // Show dialog to explain why permission is needed
              final shouldRetry =
                  await _showNotificationPermissionDeniedDialog();
              if (shouldRetry == true) {
                // Retry requesting permission
                return await requestNotificationPermission();
              }
              return false;
            }

            return requestedStatus.isGranted;
          }

          return notificationStatus.isGranted;
        } else {
          // For Android < 13, notifications are enabled by default
          // But we still check the status
          final notificationStatus = await Permission.notification.status;
          return notificationStatus.isGranted;
        }
      } else {
        // iOS: Use Firebase Messaging to check and request notification permission
        // This is more reliable than permission_handler on iOS
        try {
          final firebaseMessaging = FirebaseMessaging.instance;
          
          // Check current notification settings
          final currentSettings = await firebaseMessaging.getNotificationSettings();
          debugPrint('Current iOS notification authorization status: ${currentSettings.authorizationStatus}');
          
          // If already authorized or provisional, return true
          if (currentSettings.authorizationStatus == AuthorizationStatus.authorized ||
              currentSettings.authorizationStatus == AuthorizationStatus.provisional) {
            debugPrint('Notification permission already granted (authorized or provisional)');
            return true;
          }
          
          // Request permission via Firebase Messaging (this shows the system dialog)
          debugPrint('Requesting notification permission via Firebase Messaging...');
          final requestedSettings = await firebaseMessaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );
          
          debugPrint('Requested iOS notification authorization status: ${requestedSettings.authorizationStatus}');
          
          // Check if permission was granted
          if (requestedSettings.authorizationStatus == AuthorizationStatus.authorized ||
              requestedSettings.authorizationStatus == AuthorizationStatus.provisional) {
            debugPrint('Notification permission granted via Firebase Messaging');
            return true;
          }
          
          // If denied, check if it's permanently denied (user needs to go to Settings)
          if (requestedSettings.authorizationStatus == AuthorizationStatus.denied) {
            // Wait a moment and check again - sometimes there's a delay
            await Future.delayed(const Duration(milliseconds: 500));
            final recheckSettings = await firebaseMessaging.getNotificationSettings();
            
            if (recheckSettings.authorizationStatus == AuthorizationStatus.authorized ||
                recheckSettings.authorizationStatus == AuthorizationStatus.provisional) {
              debugPrint('Notification permission granted after recheck');
              return true;
            }
            
            // Check if it's permanently denied (notDetermined means we can still request)
            // On iOS, if authorizationStatus is denied, it means user explicitly denied
            // We should guide them to Settings
            debugPrint('Notification permission denied. Authorization status: ${recheckSettings.authorizationStatus}');
            
            // Show settings dialog to guide user to enable in Settings
            await _showNotificationPermissionSettingsDialog();
            return false;
          }
          
          // If notDetermined, we can try again later
          if (requestedSettings.authorizationStatus == AuthorizationStatus.notDetermined) {
            debugPrint('Notification permission not determined yet');
            return false;
          }
          
          return false;
        } catch (e, stackTrace) {
          debugPrint('Error using Firebase Messaging for iOS notification permission: $e');
          debugPrint('Stack trace: $stackTrace');
          // Fallback to permission_handler if Firebase fails
          final notificationStatus = await Permission.notification.status;
          if (notificationStatus.isGranted) {
            return true;
          }
          final requestedStatus = await Permission.notification.request();
          return requestedStatus.isGranted;
        }

      }
    } catch (e, stackTrace) {
      debugPrint('Error in requestNotificationPermission: $e');
      debugPrint('Stack trace: $stackTrace');
      // Don't show error to user, just return false silently
      return false;
    }
  }

  /// Check current notification permission status
  /// Returns true if permission is granted, false otherwise
  Future<bool> checkNotificationPermissionStatus() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        // For Android 13+, check notification permission
        if (sdkInt >= 33) {
          final notificationStatus = await Permission.notification.status;
          return notificationStatus.isGranted;
        } else {
          // For Android < 13, notifications are enabled by default
          return true;
        }
      } else {
        // For iOS, use Firebase Messaging to check notification permission
        // This is more reliable than permission_handler on iOS
        try {
          final firebaseMessaging = FirebaseMessaging.instance;
          final settings = await firebaseMessaging.getNotificationSettings();
          
          // Return true if authorized or provisional
          return settings.authorizationStatus == AuthorizationStatus.authorized ||
                 settings.authorizationStatus == AuthorizationStatus.provisional;
        } catch (e) {
          debugPrint('Error checking iOS notification permission via Firebase: $e');
          // Fallback to permission_handler
          final notificationStatus = await Permission.notification.status;
          return notificationStatus.isGranted;
        }
      }
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
      return false;
    }
  }

  Future<void> _showNotificationPermissionSettingsDialog() async {
    final result = await Get.dialog<bool>(
      barrierDismissible: false,
      PopScope(
        canPop: false, // Prevent back button dismissal
        child: AlertDialog(
          title: const Text('Notification Permission Required'),
          content: const Text(
            'Notification permission is required to receive important updates and alerts. Please enable it in app settings to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Open Settings'),
            ),
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
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
      final isGranted = await checkNotificationPermissionStatus();

      if (isGranted) {
        // Permission granted, dismiss any open dialogs
        if (Get.isDialogOpen == true) {
          Get.back();
        }
        return;
      }
    }
  }

  Future<bool?> _showNotificationPermissionDeniedDialog() async {
    return await Get.dialog<bool>(
      barrierDismissible: false,
      PopScope(
        canPop: false, // Prevent back button dismissal
        child: AlertDialog(
          title: const Text('Notification Permission Required'),
          content: const Text(
            'Notification permission is essential to receive important updates, alerts, and messages. Please grant this permission to stay informed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Grant Permission'),
            ),
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Not Now'),
            ),
          ],
        ),
      ),
    );
  }
}
