import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:geolocator/geolocator.dart';

/// Helper class to get device information
class DeviceInfoHelper {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Get device ID (unique identifier for the device)
  /// Returns device ID string
  static Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // Use Android ID as device identifier
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        // Use identifierForVendor as device identifier
        return iosInfo.identifierForVendor ?? 'unknown-ios-device';
      } else {
        return 'unknown-device';
      }
    } catch (e) {
      return 'unknown-device';
    }
  }

  /// Get device type (ios, android, etc.)
  /// Returns device type string
  static String getDeviceType() {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else {
      return Platform.operatingSystem;
    }
  }

  /// Get platform name
  /// Returns platform name string
  static String getPlatform() {
    return Platform.operatingSystem;
  }

  /// Get app version
  /// Returns app version string in format "version+buildNumber"
  static Future<String> getAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (_) {
      return 'unknown';
    }
  }

  /// Get device name
  /// Returns device name/model string
  static Future<String> getDeviceName() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.name;
      } else {
        return 'unknown';
      }
    } catch (_) {
      return 'unknown';
    }
  }

  /// Get OS version
  /// Returns OS version string
  static Future<String> getOSVersion() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return 'iOS ${iosInfo.systemVersion}';
      } else {
        return Platform.operatingSystemVersion;
      }
    } catch (_) {
      return 'unknown';
    }
  }

  /// Get current location (latitude and longitude)
  /// Returns Position object with latitude and longitude, or null if unable to get location
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      return position;
    } catch (e) {
      return null;
    }
  }

  /// Get language code
  /// Returns language code string (e.g., "en", "es", etc.)
  static String getLanguage() {
    try {
      return Platform.localeName.split('_').first;
    } catch (_) {
      return 'en';
    }
  }
}
