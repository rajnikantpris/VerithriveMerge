import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/flavors/build_config.dart';
import 'package:verithrive_dev/routes/app_routes.dart';
import 'package:verithrive_dev/services/storage_service.dart';
import 'package:verithrive_dev/api/user_api_service.dart';
import 'package:verithrive_dev/widgets/response_dialog.dart';
import 'exceptions/api_exception.dart';
import 'exceptions/app_exception.dart';
import 'exceptions/network_exception.dart';
import 'exceptions/not_found_exception.dart';
import 'exceptions/service_unavailable_exception.dart';

// Global flag to prevent multiple logout attempts
bool _isLoggingOut = false;

Exception handleError(String error) {
  final logger = BuildConfig.instance.config.logger;
  logger.e("Generic exception: $error");

  return AppException(message: error);
}

Exception handleDioError(DioException dioError) {
  switch (dioError.type) {
    case DioExceptionType.cancel:
      return AppException(message: "Request to API server was cancelled");
    case DioExceptionType.connectionTimeout:
      return AppException(message: "Connection timeout with API server");
    case DioExceptionType.connectionError:
      return NetworkException("There is no internet connection");
    case DioExceptionType.receiveTimeout:
      return TimeoutException("Receive timeout in connection with API server");
    case DioExceptionType.sendTimeout:
      return TimeoutException("Send timeout in connection with API server");
    case DioExceptionType.badResponse:
      return _parseDioErrorResponse(dioError);
    default:
      return AppException(message: "Unexpected error occurred");
  }
}

Exception _parseDioErrorResponse(DioException dioError) {
  final logger = BuildConfig.instance.config.logger;

  int statusCode = dioError.response?.statusCode ?? -1;
  String? status;
  String? serverMessage;

  try {
    // Handle cases where status code might be in the response body
    if (statusCode == -1 || statusCode == HttpStatus.ok) {
      if (dioError.response?.data is Map<String, dynamic>) {
        statusCode = dioError.response?.data["statusCode"] ?? statusCode;
      }
    }
    
    if (dioError.response?.data is Map<String, dynamic>) {
      final data = dioError.response!.data as Map<String, dynamic>;
      status = data["status"] as String?;
      serverMessage = data["message"] as String? ?? data["error"] as String?;
    }
  } catch (e, s) {
    logger.e("Error parsing response: $e");
    logger.e("Stack trace: $s");
    serverMessage = "Something went wrong. Please try again later.";
  }

  switch (statusCode) {
    case HttpStatus.unauthorized: // 401
      return _handleUnauthorizedError(dioError, serverMessage);
    case HttpStatus.badRequest: // 400
      return _handleBadRequestError(dioError, serverMessage);
    case HttpStatus.forbidden: // 403
      return ApiException(
        httpCode: statusCode,
        status: status ?? "forbidden",
        message: serverMessage ?? "Access forbidden",
      );
    case HttpStatus.notFound: // 404
      return NotFoundException(serverMessage ?? "Resource not found", status ?? "");
    case HttpStatus.internalServerError: // 500
      return ApiException(
        httpCode: statusCode,
        status: status ?? "internal_server_error",
        message: serverMessage ?? "Internal server error",
      );
    case HttpStatus.serviceUnavailable: // 503
      return ServiceUnavailableException("Service Temporarily Unavailable");
    default:
      return ApiException(
        httpCode: statusCode,
        status: status ?? "unknown_error",
        message: serverMessage ?? "An error occurred",
      );
  }
}

/// Handle 401 unauthorized errors with automatic logout
Exception _handleUnauthorizedError(DioException dioError, String? serverMessage) {
  final logger = BuildConfig.instance.config.logger;
  final requestPath = dioError.requestOptions.path;
  
  // Check if this is a public endpoint that shouldn't trigger logout
  final isPublicEndpoint = _isPublicEndpoint(requestPath);
  
  if (!isPublicEndpoint) {
    logger.w('401 Unauthorized error for protected endpoint: $requestPath');
    
    // Check if it's an account status error (blocked, deleted, on hold, etc.)
    final isAccountStatusError = serverMessage != null &&
        (_isAccountBlocked(serverMessage) ||
            _isAccountDeleted(serverMessage) ||
            _isAccountOnHold(serverMessage) ||
            _isAccountDeclined(serverMessage));

    // Handle 401 error asynchronously (don't block the error response)
    Future.microtask(() async {
      try {
        if (isAccountStatusError) {
          await _handleAccountStatusError(serverMessage);
        } else {
          await _performLogout(serverMessage);
        }
      } catch (e) {
        logger.e('Error during logout: $e');
      }
    });
  } else {
    logger.w('401 Unauthorized error for public endpoint: $requestPath - ignoring');
  }
  
  return ApiException(
    httpCode: 401,
    status: 'unauthorized',
    message: serverMessage ?? 'Authentication required',
  );
}

/// Handle 400 bad request errors with account status detection
Exception _handleBadRequestError(DioException dioError, String? serverMessage) {
  final logger = BuildConfig.instance.config.logger;
  final requestPath = dioError.requestOptions.path;
  
  // Check if this is a public endpoint that shouldn't trigger logout
  final isPublicEndpoint = _isPublicEndpoint(requestPath);
  
  if (!isPublicEndpoint) {
    // Check if it's an account status error (blocked, deleted, on hold, etc.)
    final isAccountStatusError = serverMessage != null &&
        (_isAccountBlocked(serverMessage) ||
            _isAccountDeleted(serverMessage) ||
            _isAccountOnHold(serverMessage) ||
            _isAccountDeclined(serverMessage));

    if (isAccountStatusError) {
      logger.w('400 Bad Request with account status error for protected endpoint: $requestPath');
      
      // Handle account status error asynchronously (don't block the error response)
      Future.microtask(() async {
        try {
          await _handleAccountStatusError(serverMessage);
        } catch (e) {
          logger.e('Error during account status handling: $e');
        }
      });
    } else {
      logger.w('400 Bad Request for protected endpoint: $requestPath - no account status error');
    }
  } else {
    logger.w('400 Bad Request for public endpoint: $requestPath - ignoring');
  }
  
  return ApiException(
    httpCode: 400,
    status: 'bad_request',
    message: serverMessage ?? 'Bad request',
  );
}

/// Check if the request path is a public endpoint that doesn't require auth
bool _isPublicEndpoint(String path) {
  final publicPaths = [
    '/api/v1/user/login',
    '/api/v1/user/register',
    '/api/v1/user/send-otp',
    '/api/v1/user/verify-otp',
    '/api/v1/user/forgot-password',
    '/api/v1/user/forgot-password/send-otp',
    '/api/v1/user/forgot-password/verify-otp',
    '/api/v1/user/forgot-password/reset',
    '/api/v1/user/verify-otp-and-register',
    '/api/v1/professional/login',
    '/api/v1/professional/register',
    '/api/v1/professional/send-otp',
    '/api/v1/professional/verify-otp',
    '/api/v1/professional/forgot-password',
    '/api/v1/professional/forgot-password/send-otp',
    '/api/v1/professional/forgot-password/reset',
    '/api/v1/professional/social/signin',
    '/api/v1/user/social/signin',
    '/get-services/all',
    '/profession-types/all',
    '/professionals/list',
    '/professionals/details',
    '/get-static-page',
  ];
  return publicPaths.any((publicPath) => path.contains(publicPath));
}

/// Check if error message indicates account is blocked
bool _isAccountBlocked(String errorMessage) {
  final lowerMessage = errorMessage.toLowerCase();
  return lowerMessage.contains('blocked');
}

/// Check if error message indicates account is deleted
bool _isAccountDeleted(String errorMessage) {
  final lowerMessage = errorMessage.toLowerCase();
  return lowerMessage.contains('deleted');
}

/// Check if error message indicates account is declined
bool _isAccountDeclined(String errorMessage) {
  final lowerMessage = errorMessage.toLowerCase();
  return lowerMessage.contains('declined');
}

/// Check if error message indicates account is on hold
bool _isAccountOnHold(String errorMessage) {
  final lowerMessage = errorMessage.toLowerCase();
  return lowerMessage.contains('on hold') || lowerMessage.contains('hold');
}

/// Handle account status errors (blocked, deleted, etc.) by showing dialog
Future<void> _handleAccountStatusError(String? errorMessage) async {
  if (_isLoggingOut) return;
  _isLoggingOut = true;

  // Determine title and default message based on error type
  String title;
  String defaultMessage;

  if (errorMessage != null && _isAccountBlocked(errorMessage)) {
    title = 'Account Blocked';
    defaultMessage = 'Your account has been blocked. Please contact support.';
  } else if (errorMessage != null && _isAccountDeleted(errorMessage)) {
    title = 'Account Deleted';
    defaultMessage = 'Your account has been deleted. Please contact support.';
  } else if (errorMessage != null && _isAccountOnHold(errorMessage)) {
    title = 'Account On Hold';
    defaultMessage = 'Your account is currently on hold. Please contact support.';
  } else if (errorMessage != null && _isAccountDeclined(errorMessage)) {
    title = 'Account Declined';
    defaultMessage = 'Your account has been declined. Please contact support.';
  } else {
    title = 'Account Status';
    defaultMessage = errorMessage ?? 'Your account status has changed. Please contact support.';
  }

  // Show error dialog with the account status message
   showResponseDialog(
    message: errorMessage ?? defaultMessage,
    title: title,
    isError: true,
    showButton: true,
    onOkPressed: () async {
      await _callLogoutApi();

      // Clear stored token if available
      if (Get.isRegistered<StorageService>()) {
        final storage = Get.find<StorageService>();
        await storage.writeString('access_token', '');
      }

      // Navigate to the initial page
      Get.offAllNamed(Routes.selectUser);

      // Reset flag after navigation
      _isLoggingOut = false;
    },
  );
}

/// Perform logout and navigate to select user screen
Future<void> _performLogout(String? errorMessage) async {
  if (_isLoggingOut) return;
  _isLoggingOut = true;

  // Show dialog for unauthorized error
   showResponseDialog(
    message: errorMessage ?? 'Your session has expired. Please login again.',
    title: 'Session Expired',
    isError: true,
    showButton: true,
    onOkPressed: () async {
      await _callLogoutApi();

      // Clear stored token if available
      if (Get.isRegistered<StorageService>()) {
        final storage = Get.find<StorageService>();
        await storage.writeString('access_token', '');
      }

      // Navigate to the initial page
      Get.offAllNamed(Routes.selectUser);

      // Reset flag after navigation
      _isLoggingOut = false;
    },
  );
}

/// Call logout API
Future<void> _callLogoutApi() async {
  if (!Get.isRegistered<UserApiService>()) return;
  try {
    await Get.find<UserApiService>().logout();
  } catch (e) {
    final logger = BuildConfig.instance.config.logger;
    logger.e('Logout API failed: $e');
    // Ignore logout failures; we still proceed with local cleanup
  }
}
