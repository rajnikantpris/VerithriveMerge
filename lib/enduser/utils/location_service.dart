import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/utils/location_permission_service.dart';

/// Global service for getting current location (latitude and longitude)
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final LocationPermissionService _locationPermissionService = LocationPermissionService();

  /// Get current location (latitude and longitude)
  /// Returns a Map with 'latitude' and 'longitude' keys, or null if failed
  Future<Map<String, double>?> getCurrentLocation() async {
    try {
      // Check and request location permission
      final hasPermission = await _locationPermissionService.requestLocationPermission();
      
      if (!hasPermission) {
        Get.snackbar(
          'Location Permission',
          'Location permission is required to search for professionals nearby.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          'Location Services',
          'Please enable location services to search for professionals nearby.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      print('Error getting current location: $e');
      Get.snackbar(
        'Error',
        'Failed to get current location. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  /// Get current location with loading indicator
  /// Shows a loading dialog while fetching location
  Future<Map<String, double>?> getCurrentLocationWithLoading() async {
    try {
      // Show loading dialog
      Get.dialog(
        Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      final location = await getCurrentLocation();

      // Close loading dialog
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      return location;
    } catch (e) {
      // Close loading dialog if still open
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      return null;
    }
  }
}

