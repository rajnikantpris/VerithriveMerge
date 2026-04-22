import 'package:get/get.dart';
import 'package:dio/dio.dart';

/// Service to check internet connectivity
class ConnectivityService extends GetxService {
  static ConnectivityService get to => Get.find();

  final Dio _dio = Dio();

  /// Check if device has internet connection
  Future<bool> hasInternetConnection() async {
    try {
      return await _hasActualInternetAccess();
    } catch (e) {
      return false;
    }
  }

  /// Test actual internet connectivity by making a real request
  Future<bool> _hasActualInternetAccess() async {
    try {
      // Use multiple reliable endpoints for better accuracy
      final endpoints = [
        'https://www.google.com',
        'https://www.cloudflare.com',
        'https://httpbin.org/get',
        'https://jsonplaceholder.typicode.com/posts/1',
      ];

      for (final endpoint in endpoints) {
        try {
          final response = await _dio.get(
            endpoint,
            options: Options(
              connectTimeout: const Duration(seconds: 3),
              receiveTimeout: const Duration(seconds: 2),
              sendTimeout: const Duration(seconds: 2),
            ),
          );
          
          if (response.statusCode == 200) {
            return true;
          }
        } catch (e) {
          // Continue to next endpoint if this one fails
          continue;
        }
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Force refresh connectivity status and check again
  Future<bool> refreshAndCheckConnection() async {
    try {
      // Wait a brief moment for connectivity to stabilize
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Test actual internet access
      return await _hasActualInternetAccess();
    } catch (e) {
      return false;
    }
  }

  /// Simple connectivity check - returns true if internet is available
  Future<bool> isConnected() async {
    return await hasInternetConnection();
  }

  /// Check connectivity with retry mechanism
  Future<bool> checkWithRetry({int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      if (await hasInternetConnection()) {
        return true;
      }
      // Wait before retry
      await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
    }
    return false;
  }
}
