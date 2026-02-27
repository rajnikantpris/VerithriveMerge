import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseTokenManager {
  static String? _cachedToken;
  static bool _isInitialized = false;
  
  // Initialize token fetch in background without blocking
  static Future<void> initializeInBackground() async {
    if (_isInitialized) return;
    _isInitialized = true;
    
    // Fetch token asynchronously without waiting
    _fetchAndCacheToken();
  }
  
  static Future<void> _fetchAndCacheToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken()
          .timeout(Duration(seconds: 10));
      
      if (token != null) {
        _cachedToken = token;
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('firebase_device_token', token);
        print('Firebase token cached: $token');
      }
    } catch (e) {
      print('Failed to fetch Firebase token: $e');
      // Load from cache if available
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        _cachedToken = prefs.getString('firebase_device_token');
      } catch (_) {}
    }
  }
  
  // Get token immediately (returns cached or empty)
  static Future<String> getTokenNonBlocking() async {
    if (_cachedToken != null) {
      return _cachedToken!;
    }
    
    // Try to get from SharedPreferences (fast)
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cached = prefs.getString('firebase_device_token');
      if (cached != null && cached.isNotEmpty) {
        _cachedToken = cached;
        return cached;
      }
    } catch (_) {}
    
    // Return empty string if no token available
    return '';
  }
  
  // Update token to server later (after login)
  static Future<void> updateTokenToServer() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken()
          .timeout(Duration(seconds: 10));
      
      if (token != null && token.isNotEmpty) {
        _cachedToken = token;
        
        // Cache it
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('firebase_device_token', token);
        
        // Call a separate API to update device token
        // This won't block login flow
        await _sendTokenToServer(token);
      }
    } catch (e) {
      print('Failed to update token to server: $e');
      // Don't rethrow - this is not critical
    }
  }
  
  static Future<void> _sendTokenToServer(String token) async {
    // Implement your API call to update device token
    // This can be a separate endpoint like /api/update-device-token
    try {
      // Example:
      // await apiService.updateDeviceToken(token);
    } catch (e) {
      print('Error sending token to server: $e');
    }
  }
}