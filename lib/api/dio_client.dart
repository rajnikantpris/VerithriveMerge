import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, MultipartFile, FormData;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http_parser/http_parser.dart' as http_parser;

import '../common/image_model.dart';
import '../api/user_api_service.dart';
import '../routes/app_pages.dart';
import '../routes/app_routes.dart';
import '../services/storage_service.dart';
import '../services/firebase_token_service.dart';
import '../utils/logger.dart';
import '../utils/timezone_helper.dart';
import '../utils/device_info_helper.dart';
import '../widgets/response_dialog.dart';

class DioClient extends GetxService {
  DioClient({Dio? client}) : _dio = client ?? Dio(_defaultOptions);

  static final BaseOptions _defaultOptions = BaseOptions(
    baseUrl: '',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 15),
    headers: {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    },
  );

  final Dio _dio;
  bool _isLoggingOut = false;

  @override
  void onInit() {
    super.onInit();
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          // Handle connection timeout and connection errors
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.connectionError) {
            // await _handleConnectionTimeout();
            // Mark error as already handled to prevent duplicate dialogs
            error.requestOptions.extra['error_handled'] = true;
            handler.next(error);
            return;
          }

          if (error.response?.statusCode == 401) {
            // Only handle unauthorized for authenticated requests
            // Skip navigation for public endpoints (login, register, etc.)
            final requestPath = error.requestOptions.path;
            final isPublicEndpoint = _isPublicEndpoint(requestPath);
            if (!isPublicEndpoint) {
              // Check if it's an account status error (blocked, deleted, on hold, etc.)
              final errorMessage = _extractErrorMessage(error);
              final isAccountStatusError = errorMessage != null &&
                  (_isAccountBlocked(errorMessage) ||
                      _isAccountDeleted(errorMessage) ||
                      _isAccountOnHold(errorMessage) ||
                      _isAccountDeclined(errorMessage));

              if (isAccountStatusError) {
                // Show dialog for account status errors
                await _handleAccountStatusError(errorMessage);

              } else {
                // Handle regular unauthorized error
                await _handleUnauthorized();
              }

              if (Get.isRegistered<StorageService>()) {
                final storage = Get.find<StorageService>();
                await storage.writeString(_accessTokenKey, '');
              }
            }
          }
          handler.next(error);
        },
      ),
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
      '/api/v1/user/reset-password',
      '/api/v1/professional/login',
      '/api/v1/professional/register',
      '/api/v1/professional/send-otp',
      '/api/v1/professional/verify-otp',
      '/api/v1/professional/forgot-password',
      '/api/v1/professional/forgot-password/send-otp',
      '/api/v1/professional/forgot-password/reset',
      // Add v2 paths
      '/api/v2/professional/login',
      '/api/v2/professional/register',
      '/api/v2/professional/send-otp',
      '/api/v2/professional/verify-otp',
      '/api/v2/professional/forgot-password',
      '/api/v2/professional/forgot-password/send-otp',
      '/api/v2/professional/forgot-password/reset',
    ];
    return publicPaths.any((publicPath) => path.contains(publicPath));
  }

  Future<Response<T>> getRequest<T>(
    String path, {
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
    bool withAuth = true,
  }) async {
    await _applyHeaders(withAuth: withAuth);
    logInfo('GET $path query=$query');
    return _dio.get<T>(
      path,
      queryParameters: query,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> postRequest<T>(
    String path, {
    Map<String, dynamic>? query,
    dynamic body,
    Options? options,
    CancelToken? cancelToken,
    bool withAuth = true,
  }) async {
    await _applyHeaders(withAuth: withAuth);
    logInfo('POST $path body=$body query=$query');
    return _dio.post<T>(
      path,
      data: body,
      queryParameters: query,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> putRequest<T>(
    String path, {
    Map<String, dynamic>? query,
    dynamic body,
    Options? options,
    CancelToken? cancelToken,
    bool withAuth = true,
    Map<String, dynamic>? additionalHeaders,
  }) async {
    await _applyHeaders(
        withAuth: withAuth, additionalHeaders: additionalHeaders);
    logInfo('PUT $path body=$body query=$query');
    return _dio.put<T>(
      path,
      data: body,
      queryParameters: query,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> deleteRequest<T>(
    String path, {
    Map<String, dynamic>? query,
    dynamic body,
    Options? options,
    CancelToken? cancelToken,
    bool withAuth = true,
  }) async {
    await _applyHeaders(withAuth: withAuth);
    logInfo('DELETE $path body=$body query=$query');
    return _dio.delete<T>(
      path,
      data: body,
      queryParameters: query,
      options: options,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> uploadMultipart<T>(
    String path, {
    Map<String, dynamic>? fields,
    File? image,
    List<File>? images,
    List<ImageModel>? media,
    Map<String, String>? headers,
    bool withAuth = true,
    bool usePut = false,
    String singleFileFieldName = 'image',
  }) async {
    await _applyHeaders(withAuth: withAuth);
    final formMap = <String, dynamic>{...?fields};

    if (image != null) {
      formMap[singleFileFieldName] = await MultipartFile.fromFile(image.path);
    }

    if (images != null && images.isNotEmpty) {
      formMap['images'] = await Future.wait(
        images.map((file) => MultipartFile.fromFile(file.path)),
      );
    }

    if (media != null && media.isNotEmpty) {
      formMap['media'] = await Future.wait(
        media.map(
          (m) => MultipartFile.fromFile(
            m.path,
            filename: m.name,
            contentType: m.type == MediaType.image
                ? http_parser.MediaType('image', 'jpeg')
                : http_parser.MediaType('video', 'mp4'),
          ),
        ),
      );
    }

    final formData = FormData.fromMap(formMap);

    final method = usePut ? 'PUT' : 'POST';
    // Build headers without forcing JSON content-type so Dio can set multipart boundary
    final multipartHeaders = Map<String, dynamic>.from(_dio.options.headers);
    multipartHeaders.remove(HttpHeaders.contentTypeHeader);
    multipartHeaders.addAll(headers ?? {});

    // Log headers for multipart (mask sensitive information)
    final multipartHeadersForLog = Map<String, dynamic>.from(multipartHeaders);
    if (multipartHeadersForLog.containsKey(HttpHeaders.authorizationHeader)) {
      final authHeader =
          multipartHeadersForLog[HttpHeaders.authorizationHeader] as String?;
      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        multipartHeadersForLog[HttpHeaders.authorizationHeader] = 'Bearer ***';
      }
    }
    logInfo('$method $path fields=$fields headers=$multipartHeadersForLog');
    return _dio.request<T>(
      path,
      data: formData,
      options: Options(
        method: method,
        headers: multipartHeaders,
      ),
    );
  }

  /// Enriches requests with auth + device headers when available.
  Future<void> _applyHeaders({
    required bool withAuth,
    Map<String, dynamic>? additionalHeaders,
  }) async {
    final headers = <String, dynamic>{
      'timezone': TimezoneHelper.getCurrentTimezone(),
      'devicetype': Platform.operatingSystem,
    };

    // Get device information
    headers['device_name'] = await _getDeviceName();
    headers['app_version'] = await _getAppVersion();
    headers['device_id'] = await DeviceInfoHelper.getDeviceId();
    headers['device_type'] = DeviceInfoHelper.getDeviceType();
    headers['platform'] = DeviceInfoHelper.getPlatform();
    headers['language'] = DeviceInfoHelper.getLanguage();
    headers['os_version'] = await DeviceInfoHelper.getOSVersion();

    // Get device token if available (optional, may not be available immediately)
    try {
      final deviceToken = await FirebaseTokenService.getFCMToken();
      if (deviceToken != null && deviceToken.isNotEmpty) {
        headers['device_token'] = deviceToken;
      }
    } catch (_) {
      // Device token not available, skip it
    }

    // Add any additional headers passed from the request
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    if (withAuth) {
      final token = _getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
      }
    }

    _dio.options.headers.addAll(headers);

    // Log headers (mask sensitive information)
    final headersForLog = Map<String, dynamic>.from(_dio.options.headers);
    if (headersForLog.containsKey(HttpHeaders.authorizationHeader)) {
      final authHeader =
          headersForLog[HttpHeaders.authorizationHeader] as String?;
      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        headersForLog[HttpHeaders.authorizationHeader] = 'Bearer ***';
      }
    }
    logInfo('Headers: $headersForLog');
  }

  String? _getAccessToken() {
    if (!Get.isRegistered<StorageService>()) return null;
    final storage = Get.find<StorageService>();
    return storage.readString(_accessTokenKey);
  }

  Future<String> _getAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (_) {
      return 'unknown';
    }
  }

  Future<String> _getDeviceName() async {
    final info = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final android = await info.androidInfo;
        return android.model;
      }
      if (Platform.isIOS) {
        final ios = await info.iosInfo;
        return ios.utsname.machine;
      }
      if (Platform.isMacOS) {
        final mac = await info.macOsInfo;
        return mac.model;
      }
      if (Platform.isWindows) {
        final win = await info.windowsInfo;
        return win.computerName;
      }
      if (Platform.isLinux) {
        final linux = await info.linuxInfo;
        return linux.name;
      }
    } catch (_) {
      // ignore
    }
    return 'unknown';
  }

  /// Extract error message from DioException response
  String? _extractErrorMessage(DioException error) {
    if (error.response?.data is Map<String, dynamic>) {
      final data = error.response!.data as Map<String, dynamic>;
      return data['message'] as String? ?? data['error'] as String?;
    }
    return null;
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
      defaultMessage =
          'Your account is currently on hold. Please contact support.';
    } else if (errorMessage != null && _isAccountDeclined(errorMessage)) {
      title = 'Account Declined';
      defaultMessage =
          'Your account has been declined. Please contact support.';
    } else {
      title = 'Account Status';
      defaultMessage = errorMessage ??
          'Your account status has changed. Please contact support.';
    }

    // Show error dialog with the account status message
    showResponseDialog(
      message: errorMessage ?? defaultMessage,
      title: title,
      isError: true,
      showButton: true,
      onOkPressed: () async {
        await _callLogoutApi();

        // Clear stored token if available.
        if (Get.isRegistered<StorageService>()) {
          final storage = Get.find<StorageService>();
          storage.writeString(_accessTokenKey, '');
        }

        // Navigate to the initial page (could be login/onboarding).
        Get.offAllNamed(Routes.selectUser);

        // Reset flag after navigation
        _isLoggingOut = false;
      },
    );
  }

  /// Handle connection timeout errors by showing dialog
  Future<void> _handleConnectionTimeout() async {
    // Show error dialog with server not working message
    showResponseDialog(
      message: 'Server Not Working',
      title: 'Connection Error',
      isError: true,
      showButton: true,
      onOkPressed: () {
        // Dialog dismissed, user can try again
      },
    );
  }

  Future<void> _handleUnauthorized() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    await _callLogoutApi();

    // Clear stored token if available.
    if (Get.isRegistered<StorageService>()) {
      final storage = Get.find<StorageService>();
      await storage.writeString(_accessTokenKey, '');
    }

    // Navigate to the initial page (could be login/onboarding).
    Get.offAllNamed(Routes.selectUser);

    _isLoggingOut = false;
  }

  Future<void> _callLogoutApi() async {
    if (!Get.isRegistered<UserApiService>()) return;
    try {
      await Get.find<UserApiService>().logout();
    } catch (_) {
      // Ignore logout failures; we still proceed with local cleanup.
    }
  }
}

const _accessTokenKey = 'access_token';
