import 'package:dio/dio.dart' as dio;

import '../utils/logger.dart';

/// Common structure for API responses
/// This class provides a standardized way to handle API responses
class ApiResponse<T> {
  /// Whether the request was successful
  final bool success;

  /// Response message from the server
  final String? message;

  /// Response data (can be any type)
  final T? data;

  /// HTTP status code
  final int? statusCode;

  /// Original Dio response
  final dio.Response<dynamic>? rawResponse;

  /// Error message if request failed
  final String? error;

  /// Whether the error dialog was already shown (e.g., for connection timeouts)
  final bool errorDialogShown;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.statusCode,
    this.rawResponse,
    this.error,
    this.errorDialogShown = false,
  });

  /// Create a successful response
  factory ApiResponse.success({
    T? data,
    String? message,
    int? statusCode,
    dio.Response<dynamic>? rawResponse,
  }) {
    return ApiResponse<T>(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
      rawResponse: rawResponse,
    );
  }

  /// Create a failed response
  factory ApiResponse.failure({
    String? error,
    String? message,
    int? statusCode,
    dio.Response<dynamic>? rawResponse,
  }) {
    return ApiResponse<T>(
      success: false,
      error: error,
      message: message,
      statusCode: statusCode,
      rawResponse: rawResponse,
    );
  }

  /// Parse response from Dio Response
  factory ApiResponse.fromDioResponse(dio.Response<dynamic> response) {
    final raw = response.data;
    final statusCode = response.statusCode;
    final requestUrl = response.requestOptions.uri.toString();

    // Check if status code indicates success
    final isSuccess =
        statusCode != null && statusCode >= 200 && statusCode < 300;

    if (isSuccess) {
      // Handle different response formats
      if (raw is Map<String, dynamic>) {
        // Standard JSON response with success/message/data structure
        final success = raw['success'] as bool? ?? true;
        final message = raw['message'] as String?;
        final data = raw['data'] as T? ?? (raw as T?);

        // Log API response
        logInfo('API Response [SUCCESS] - $requestUrl');
        logInfo('Status Code: $statusCode');
        logInfo('Success: $success');
        if (message != null) logInfo('Message: $message');
        logFullResponse('Full Response Data', raw);

        return ApiResponse<T>(
          success: success,
          message: message,
          data: data,
          statusCode: statusCode,
          rawResponse: response,
        );
      } else if (raw is bool) {
        // Simple boolean response (e.g., true for verification)
        // Log API response
        logInfo('API Response [SUCCESS] - $requestUrl');
        logInfo('Status Code: $statusCode');
        logFullResponse('Full Response Data', raw);

        return ApiResponse<T>(
          success: raw,
          data: raw as T?,
          statusCode: statusCode,
          rawResponse: response,
        );
      } else {
        // Direct data response
        // Log API response
        logInfo('API Response [SUCCESS] - $requestUrl');
        logInfo('Status Code: $statusCode');
        logFullResponse('Full Response Data', raw);

        return ApiResponse<T>(
          success: true,
          data: raw as T?,
          statusCode: statusCode,
          rawResponse: response,
        );
      }
    } else {
      // Handle error response
      String? errorMessage;
      if (raw is Map<String, dynamic>) {
        errorMessage = raw['message'] as String? ?? raw['error'] as String?;
      }

      // Log API error response
      logError('API Response [ERROR] - $requestUrl');
      logError('Status Code: $statusCode');
      if (errorMessage != null) logError('Error Message: $errorMessage');
      logFullResponse('Full Response Data', raw);

      return ApiResponse<T>(
        success: false,
        error: errorMessage ?? 'Request failed',
        message: errorMessage,
        statusCode: statusCode,
        rawResponse: response,
      );
    }
  }

  /// Parse error from DioException
  factory ApiResponse.fromDioException(dio.DioException error) {
    final statusCode = error.response?.statusCode;
    final requestUrl = error.requestOptions.uri.toString();
    String? errorMessage;
    String? message;

    // Check if error is already handled (e.g., connection timeout shown dialog)
    final isErrorHandled = error.requestOptions.extra['error_handled'] == true;

    // Check if it's a connection/timeout error that should show "Server Not Working"
    final isConnectionError =
        error.type == dio.DioExceptionType.connectionTimeout ||
            error.type == dio.DioExceptionType.receiveTimeout ||
            error.type == dio.DioExceptionType.sendTimeout ||
            error.type == dio.DioExceptionType.connectionError;

    if (error.response?.data is Map<String, dynamic>) {
      final data = error.response!.data as Map<String, dynamic>;
      errorMessage = data['message'] as String? ?? data['error'] as String?;
      message = errorMessage;
    }

    // Log API exception (skip if already handled to avoid duplicate logs)
    if (!isErrorHandled) {
      logError('API Exception - $requestUrl');
      logError('Status Code: $statusCode');
      logError('Error Type: ${error.type}');
      if (errorMessage != null) logError('Error Message: $errorMessage');
      if (error.message != null) logError('Dio Message: ${error.message}');
      if (error.response?.data != null) {
        logFullResponse('Full Response Data', error.response!.data);
      }
    }

    // For connection errors that are already handled, return a response with a special marker
    if (isConnectionError && isErrorHandled) {
      return ApiResponse<T>(
        success: false,
        error: 'Server Not Working',
        message: 'Server Not Working',
        statusCode: statusCode,
        rawResponse: error.response,
        errorDialogShown: true,
      );
    }

    return ApiResponse<T>(
      success: false,
      error: errorMessage ?? error.message ?? 'Request failed',
      message: message,
      statusCode: statusCode,
      rawResponse: error.response,
    );
  }

  /// Check if response has data
  bool get hasData => data != null;

  /// Get error message or default message
  String get errorMessage => error ?? message ?? 'An error occurred';

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'success': success,
        if (message != null) 'message': message,
        if (data != null) 'data': data,
        if (statusCode != null) 'statusCode': statusCode,
        if (error != null) 'error': error,
      };
}
