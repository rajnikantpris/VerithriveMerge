import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/values/sharePrefrenceConst.dart';
import '../routes/app_routes.dart';
import 'package:verithrive_dev/services/storage_service.dart';

class AuthService {

  /// Check if user is logged in (has valid token)
  static Future<bool> isLoggedIn() async {
    try {
      final storage = Get.isRegistered<StorageService>()
          ? Get.find<StorageService>()
          : null;
      if (storage == null) return false;

      String token =
          storage.readString(SharePreferenceConst.access_token) ?? '';
      bool isLogin = storage.readBool(SharePreferenceConst.isLogin) ?? false;
      return token.isNotEmpty && isLogin;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  /// Check if user is in guest mode
  static Future<bool> isGuest() async {
    try {
      final storage = Get.isRegistered<StorageService>()
          ? Get.find<StorageService>()
          : null;
      if (storage == null) return false;

      bool isGuest = storage.readBool(SharePreferenceConst.isGuest) ?? false;
      return isGuest;
    } catch (e) {
      print('Error checking guest status: $e');
      return false;
    }
  }

  /// Restrict access to authenticated screens
  /// Returns true if access is allowed, false if redirected to login
  static Future<bool> requireAuth() async {
    bool loggedIn = await isLoggedIn();
    
    if (!loggedIn) {
      // Show message and redirect to login
      Get.snackbar(
        'Login Required',
        'Please login to access this feature',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.orange.shade800,
        duration: Duration(seconds: 2),
      );
      
      // Navigate to login screen
      Get.offAllNamed(AppRoutes.login);
      return false;
    }
    
    return true;
  }

  /// Check if API call should be allowed in guest mode
  /// Only allows home screen APIs in guest mode
  static Future<bool> canMakeApiCall(String apiEndpoint) async {
    bool guest = await isGuest();
    
    if (guest) {
      // Allow only home screen related APIs in guest mode
      List<String> allowedGuestApis = [
        'profession-types/all', // Home screen profession types
        'professionals/list', // Professionals list for browsing
        'professionals/details', // Professional details for viewing
        'get-services/all', // Services list for browsing
        'login', // Login API for authentication
        'social/signin', // Login API for authentication
        'get-static-page', // Static pages like terms, privacy
      ];
      
      return allowedGuestApis.any((allowedApi) => apiEndpoint.contains(allowedApi));
    }
    
    return true; // Allow all APIs for logged-in users
  }

  /// Get authentication token
  static Future<String> getToken() async {
    try {
      final storage = Get.isRegistered<StorageService>()
          ? Get.find<StorageService>()
          : null;
      if (storage == null) return '';

      return storage.readString(SharePreferenceConst.access_token) ?? '';
    } catch (e) {
      print('Error getting token: $e');
      return '';
    }
  }
}
