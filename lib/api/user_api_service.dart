import 'package:dio/dio.dart' as dio;
import 'dart:io';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'api_response.dart';
import 'dio_client.dart';
import '../utils/logger.dart';
import '../models/login_response_model.dart';
import '../services/social_auth_service.dart';
import '../services/connectivity_service.dart';
import '../utils/timezone_helper.dart';

/// Common API service class for user-related endpoints
class UserApiService extends GetxService {
  UserApiService(this._dioClient);

  final DioClient _dioClient;
  final SocialAuthService _socialAuthService = SocialAuthService();
  final ConnectivityService _connectivityService = ConnectivityService();

  // Base URL for the API
  //  static const String baseUrl = 'http://192.168.0.126:4142/api/v3/professional/';
  // static const String socketUrl = 'http://27.54.168.101:4142';
  static const String socketUrl = 'https://adminportal.verithrive.co.uk';
  static const String baseUrl =
      'https://adminportal.verithrive.co.uk/api/api/v3/professional/';
  //static const String baseUrl = 'http://18.135.255.93:4142/api/v2/professional/';
  // static const String baseUrl = 'http://27.54.168.101:4142/api/v3/professional/';

  /// Get the socket base URL (same server, different port/path)
  /// Extracts the protocol, host, and port from the API baseUrl
  /// Socket.IO typically runs on /socket.io path
  static String get socketBaseUrl {
    final uri = Uri.parse(socketUrl);
    return '${uri.scheme}://${uri.host}:${uri.port}';
  }

  /// Check internet connection before making API calls
  Future<ApiResponse<T>> _checkConnectivityAndExecute<T>(
    Future<ApiResponse<T>> Function() apiCall,
  ) async {
    try {
      // Check internet connection with retry mechanism
      final hasConnection =
          await _connectivityService.checkWithRetry(maxRetries: 3);

      if (!hasConnection) {
        return ApiResponse.failure(
          error: 'No internet connection',
          message: 'Please check your internet connection and try again',
        );
      }

      // If connected, proceed with the API call
      return await apiCall();
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  // API endpoints
  static const String _sendOtpPath = 'send-otp';
  static const String _verifyOtpPath = 'verify-otp';
  static const String _registerPath = 'register';
  static const String _loginPath = 'login';
  static const String _socialLoginPath = 'social/signin';
  static const String _socialCheckPath = 'social/check';
  static const String _logoutPath = 'logout';
  static const String _deleteAccountPath = 'delete-account';
  static const String _updatePersonalDetailsPath = 'update-personal-details';
  static const String _updateCreatePersonalDetailsPath =
      'update-create-personal-details';
  static const String _getStaticPagePath = 'get-static-page';
  static const String _forgotPasswordSendOtpPath = 'forgot-password/send-otp';
  static const String _resetPasswordPath = 'forgot-password/reset';
  static const String _changePasswordPath = 'change-password';
  static const String _bankDetailsPath = 'bank-details';
  static const String _professionTypesPath = 'profession-types/all';
  static const String _professionSubTypesPath = 'profession-sub-types/all';
  static const String _createProfilePath = 'create-profile';
  static const String _createAddressPath = 'create-address';
  static const String _servicesAllPath = 'services/all';
  static const String _professionServicesPath = 'profession-services';
  static const String _collegesUniversityPath = 'colleges-university';
  static const String _qualificationsUpsertPath = 'qualifications/upsert';
  static const String _aboutYouPath = 'about-you';
  static const String _personalIdentificationUpsertPath =
      'personal-identification/upsert';
  static const String _getCreateProfileDetailsPath =
      'get-create-profile-details';
  static const String _getPersonalDetailsPath = 'get-personal-details';
  static const String _getCreateAddressDetailsPath =
      'get-create-address-details';
  static const String _getProfessionServicesPath =
      'get-profession-services-details';
  static const String _getQualificationsDetailsPath =
      'get-qualifications-details';
  static const String _getPersonalIdentificationDetailsPath =
      'get-personal-identification-details';
  static const String _getAboutYouDetailsPath = 'get-about-you-details';
  static const String _getProfileDetailsPath = 'get-profile-details';
  static const String _notificationPath = 'notification';
  static const String _notificationsListPath = 'notifications/list';
  static const String _notificationsCountPath = 'notifications/count';
  static const String _subscriptionsListPath = 'subscriptions/plans';
  static const String _subscriptionsDetailsPath = 'subscriptions/details';
  static const String _buySubscriptionPath = 'subscriptions/buy';
  static const String _cancelSubscriptionPath = 'subscriptions/cancel';
  static const String _serviceFormatsAllPath = 'service-formats/all';
  static const String _serviceFormatsPath = 'service-formats';
  static const String _availabilityPath = 'availability';
  static const String _getServiceFormatAvailabilityPath =
      'get-service-format-availability';
  static const String _bookingsPath = 'bookings';
  static const String _bookingsListPath = 'bookings/list';
  static const String _bookingsReschedulePath = 'bookings/reschedule';
  static const String _updateDeviceTokenPath = 'update-device-token';
  static const String _chatInboxPath = 'chat/inbox';
  static const String _chatRoomPath = 'chat/room';
  static const String _chatMessagesPath = 'chat/messages';
  static const String _transactionHistoryPath = 'transaction-history';

  static const String check_promo_code = 'check-promo-code';

  /// Get subscriptions list
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> getSubscriptionsList() async {
    try {
      final fullUrl = '$baseUrl$_subscriptionsListPath';

      final response = await _dioClient.postRequest<dynamic>(
        fullUrl,
        withAuth: true,
        body: {
          'promo_code': '',
        },
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Get subscription details (current subscription)
  ///
  /// Returns the API response wrapped in ApiResponse with current subscription details
  Future<ApiResponse<dynamic>> getSubscriptionDetails() async {
    try {
      final fullUrl = '$baseUrl$_subscriptionsDetailsPath';

      final response = await _dioClient.getRequest<dynamic>(
        fullUrl,
        withAuth: true,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Get chat inbox
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> getChatInbox() async {
    try {
      final fullUrl = '$baseUrl$_chatInboxPath';

      final response = await _dioClient.getRequest<dynamic>(
        fullUrl,
        withAuth: true,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Create or get chat room
  ///
  /// [receiverId] - The receiver user ID
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> createOrGetChatRoom({
    required String receiverId,
  }) async {
    try {
      final fullUrl = '$baseUrl$_chatRoomPath';

      final response = await _dioClient.postRequest<dynamic>(
        fullUrl,
        withAuth: true,
        body: {
          'receiver_id': receiverId,
        },
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Get chat messages for a room
  ///
  /// [roomId] - The chat room ID
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> getChatMessages({
    required String roomId,
  }) async {
    try {
      final fullUrl = '$baseUrl$_chatMessagesPath/$roomId';

      final response = await _dioClient.getRequest<dynamic>(
        fullUrl,
        withAuth: true,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Buy subscription
  ///
  /// [subscriptionId] - The subscription plan ID
  /// [paymentMethod] - Payment method (e.g., "card", "google_pay", "apple_pay", "paypal")
  ///
  /// Returns the API response wrapped in ApiResponse with LoginResponseModel
  Future<ApiResponse<LoginResponseModel>> buySubscription({
    required String subscriptionId,
    required String paymentMethod,
  }) async {
    try {
      final fullUrl = '$baseUrl$_buySubscriptionPath';

      final response = await _dioClient.postRequest<dynamic>(
        fullUrl,
        withAuth: true,
        body: {
          'subscription_id': subscriptionId,
          'payment_method': paymentMethod,
        },
      );

      // Parse the response manually to extract LoginResponseModel
      final raw = response.data;
      final statusCode = response.statusCode;
      final isSuccess =
          statusCode != null && statusCode >= 200 && statusCode < 300;

      if (isSuccess && raw is Map<String, dynamic>) {
        final success = raw['success'] as bool? ?? true;
        final message = raw['message'] as String?;
        final data = raw['data'] as Map<String, dynamic>?;

        LoginResponseModel? loginResponse;
        if (data != null && data['user'] is Map<String, dynamic>) {
          // Parse user data into LoginResponseModel
          // The response has data: { user: {...} }, so we create LoginResponseModel with user
          loginResponse = LoginResponseModel(
            token: null, // No token in subscription buy response
            user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
          );
        }

        return ApiResponse<LoginResponseModel>(
          success: success,
          message: message,
          data: loginResponse,
          statusCode: statusCode,
          rawResponse: response,
        );
      } else {
        // Handle error response
        String? errorMessage;
        if (raw is Map<String, dynamic>) {
          errorMessage = raw['message'] as String? ?? raw['error'] as String?;
        }

        return ApiResponse<LoginResponseModel>(
          success: false,
          error: errorMessage ?? 'Request failed',
          message: errorMessage,
          statusCode: statusCode,
          rawResponse: response,
        );
      }
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Cancel subscription
  ///
  /// [subscriptionId] - The subscription ID to cancel
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> cancelSubscription({
    required String subscriptionId,
  }) async {
    try {
      final fullUrl = '$baseUrl$_cancelSubscriptionPath';

      final response = await _dioClient.postRequest<dynamic>(
        fullUrl,
        withAuth: true,
        body: {
          'subscription_id': subscriptionId,
        },
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Send OTP to user's email
  ///
  /// [email] - User's email address
  /// [userType] - Type of user (e.g., "professional", "client")
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> sendOtp({
    required String email,
    required String userType,
  }) async {
    try {
      final fullUrl = '$baseUrl$_sendOtpPath';

      final response = await _dioClient.postRequest<dynamic>(
        fullUrl,
        withAuth: false,
        body: {
          'email': email,
          'user_type': userType,
        },
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Verify OTP sent to user's email
  ///
  /// [email] - User's email address
  /// [userType] - Type of user (e.g., "professional", "client")
  /// [otp] - OTP code entered by user
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> verifyOtp({
    required String email,
    required String userType,
    required String otp,
  }) async {
    try {
      final fullUrl = '$baseUrl$_verifyOtpPath';

      final response = await _dioClient.postRequest<dynamic>(
        fullUrl,
        withAuth: false,
        body: {
          'email': email,
          'user_type': userType,
          'otp': otp,
        },
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Register a new user
  ///
  /// [email] - User's email address
  /// [userType] - Type of user (e.g., "professional", "client")
  /// [mobileNumber] - User's mobile number
  /// [password] - User's password
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> register({
    required String email,
    required String userType,
    required String mobileNumber,
    required String password,
    required String promo_code,
  }) async {
    return _checkConnectivityAndExecute(() async {
      try {
        final fullUrl = '$baseUrl$_registerPath';

        final response = await _dioClient.postRequest<dynamic>(
          fullUrl,
          withAuth: false,
          body: {
            'email': email,
            'user_type': userType,
            'mobile_number': mobileNumber,
            'password': password,
            'promo_code': promo_code,
          },
        );

        return ApiResponse.fromDioResponse(response);
      } on dio.DioException catch (e) {
        return ApiResponse.fromDioException(e);
      } catch (e) {
        return ApiResponse.failure(
          error: e.toString(),
          message: 'An unexpected error occurred',
        );
      }
    });
  }

  /// Log a user in
  ///
  /// [email] - User's email address
  /// [userType] - Type of user (e.g., "professional", "client")
  /// [password] - User's password
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> login({
    required String email,
    required String userType,
    required String password,
  }) async {
    return _checkConnectivityAndExecute(() async {
      try {
        final fullUrl = '$baseUrl$_loginPath';

        final response = await _dioClient.postRequest<dynamic>(
          fullUrl,
          withAuth: false,
          body: {
            'email': email,
            'user_type': userType,
            'password': password,
          },
        );

        return ApiResponse.fromDioResponse(response);
      } on dio.DioException catch (e) {
        return ApiResponse.fromDioException(e);
      } catch (e) {
        return ApiResponse.failure(
          error: e.toString(),
          message: 'An unexpected error occurred',
        );
      }
    });
  }

  /// Check social account before login/signup
  ///
  /// [socialId] - Social provider user ID (Google user ID or Apple user identifier)
  /// [socialType] - Social provider type ('google' or 'apple')
  /// [email] - User's email address
  /// [fullName] - User's full name from social provider (optional)
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> checkSocialAccount({
    required String socialId,
    required String socialType,
    required String email,
    String? fullName,
  }) async {
    try {
      final fullUrl = '$baseUrl$_socialCheckPath';

      final body = <String, dynamic>{
        'social_id': socialId,
        'social_type': socialType,
        'email': email,
      };
      if (fullName != null && fullName.isNotEmpty) {
        body['full_name'] = fullName;
      }

      final response = await _dioClient.postRequest<dynamic>(
        fullUrl,
        withAuth: false,
        body: body,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Social login (Google or Apple)
  ///
  /// [email] - User's email address
  /// [socialType] - Social provider type ('google' or 'apple')
  /// [socialId] - Social provider user ID (Google user ID or Apple user identifier)
  /// [fullName] - User's full name (optional)
  /// [profilePicture] - User's profile picture URL (optional)
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> socialLogin({
    required String email,
    required String socialType,
    required String socialId,
    String? fullName,
    String? profilePicture,
  }) async {
    try {
      final fullUrl = '$baseUrl$_socialLoginPath';

      // Common fields for social login
      final fields = <String, dynamic>{
        'email': email,
        'social_type': socialType,
        'social_id': socialId,
      };

      if (fullName != null && fullName.isNotEmpty) {
        fields['full_name'] = fullName;
      }

      dio.MultipartFile? profileMultipart;

      // If we received a profile picture, try to attach it as a multipart file.
      if (profilePicture != null && profilePicture.isNotEmpty) {
        try {
          if (profilePicture.startsWith('http')) {
            // Remote URL (e.g. Google photo URL) – download bytes and send as multipart
            final imageResponse = await dio.Dio().get<List<int>>(
              profilePicture,
              options: dio.Options(responseType: dio.ResponseType.bytes),
            );

            if (imageResponse.data != null) {
              profileMultipart = dio.MultipartFile.fromBytes(
                imageResponse.data!,
                // Basic filename; server can ignore if not needed
                filename:
                    'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
              );
            }
          } else {
            // Local file path – keep existing behaviour using File
            final file = File(profilePicture);
            if (await file.exists()) {
              profileMultipart = await dio.MultipartFile.fromFile(file.path);
            }
          }
        } catch (_) {
          // If anything goes wrong fetching/reading the image, just continue without it.
        }
      }

      // Build multipart FormData payload
      final formMap = <String, dynamic>{...fields};
      if (profileMultipart != null) {
        formMap['profile_picture'] = profileMultipart;
      }

      final formData = dio.FormData.fromMap(formMap);

      final response = await _dioClient.postRequest<dynamic>(
        fullUrl,
        withAuth: false,
        body: formData,
        options: dio.Options(
          contentType: 'multipart/form-data',
        ),
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Log a user out
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> logout() async {
    await _socialAuthService.signOutSocialProviders();
    try {
      final fullUrl = '$baseUrl$_logoutPath';

      final response = await _dioClient.postRequest<dynamic>(
        fullUrl,
        withAuth: true,
        body: {},
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Delete account (deactivate) for the current user
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> deleteAccount() async {
    try {
      final fullUrl = '$baseUrl$_deleteAccountPath';

      final response = await _dioClient.deleteRequest<dynamic>(
        fullUrl,
        withAuth: true,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Convert gender display value to API format
  /// Converts "Prefer not to say" to "prefer_not_to_say" and other values to lowercase
  String _convertGenderToApiFormat(String gender) {
    final lowerGender = gender.toLowerCase().trim();
    if (lowerGender == 'prefer not to say') {
      return 'prefer_not_to_say';
    }
    return lowerGender;
  }

  /// Update personal details (profile) for the current user
  ///
  /// Sends multipart/form-data including optional profile picture.
  Future<ApiResponse<dynamic>> updatePersonalDetails({
    required String fullName,
    required String dob,
    required String gender,
    required String postcode,
    required String address,
    required bool isTermCondition,
    int? optStatus,
    double? latitude,
    double? longitude,
    String? profileImagePath,
    String? promoCode,
  }) async {
    try {
      final fullUrl = '$baseUrl$_updatePersonalDetailsPath';

      final fields = <String, dynamic>{
        'full_name': fullName,
        'dob': dob,
        'gender': _convertGenderToApiFormat(gender),
        'postcode': postcode,
        'address': address,
        'is_term_condition': isTermCondition ? 'true' : 'false',
      };

      // Optional opt_status (0 = false, 1 = true)
      if (optStatus != null) {
        fields['opt_status'] = optStatus.toString();
      }

      // Optional promo code
      if (promoCode != null && promoCode.isNotEmpty) {
        fields['promo_code'] = promoCode;
      }

      // Optional coordinates
      if (latitude != null) {
        fields['latitude'] = latitude.toString();
      }
      if (longitude != null) {
        fields['longitude'] = longitude.toString();
      }

      dio.MultipartFile? profileMultipart;

      if (profileImagePath != null && profileImagePath.isNotEmpty) {
        try {
          if (profileImagePath.startsWith('http')) {
            // Remote URL (e.g. social profile picture) – download and send as multipart
            final imageResponse = await dio.Dio().get<List<int>>(
              profileImagePath,
              options: dio.Options(responseType: dio.ResponseType.bytes),
            );

            if (imageResponse.data != null) {
              profileMultipart = dio.MultipartFile.fromBytes(
                imageResponse.data!,
                filename:
                    'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
              );
            }
          } else {
            // Local file path
            final file = File(profileImagePath);
            if (await file.exists()) {
              profileMultipart = await dio.MultipartFile.fromFile(file.path);
            }
          }
        } catch (_) {
          // If image handling fails, continue without attaching the file
        }
      }

      final formMap = <String, dynamic>{...fields};
      if (profileMultipart != null) {
        formMap['profile_picture'] = profileMultipart;
      }

      final formData = dio.FormData.fromMap(formMap);

      // Log FormData contents for debugging
      logInfo('=== API Request: PUT $fullUrl ===');
      logFullResponse('FormData fields', fields);
      if (profileMultipart != null) {
        logInfo(
            'FormData file: profile_picture (${profileMultipart.length} bytes)');
      }

      final response = await _dioClient.putRequest<dynamic>(
        fullUrl,
        withAuth: true,
        body: formData,
        options: dio.Options(
          contentType: 'multipart/form-data',
        ),
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Get static page content (e.g. terms & conditions)
  Future<ApiResponse<dynamic>> getStaticPage({
    required String type,
  }) async {
    try {
      final fullUrl = '$baseUrl$_getStaticPagePath';

      final response = await _dioClient.getRequest<dynamic>(
        fullUrl,
        query: {'type': type},
        withAuth: true,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Send OTP for forgot password
  ///
  /// [email] - User's email address
  /// [userType] - Type of user (e.g., "professional", "client")
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> forgotPasswordSendOtp({
    required String email,
    required String userType,
  }) async {
    try {
      final fullUrl = '$baseUrl$_forgotPasswordSendOtpPath';

      final response = await _dioClient.postRequest<dynamic>(
        fullUrl,
        withAuth: false,
        body: {
          'email': email,
          'user_type': userType,
        },
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Reset password after OTP verification
  ///
  /// [email] - User's email address
  /// [userType] - Type of user (e.g., "professional", "client")
  /// [newPassword] - New password to set
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> resetPassword({
    required String email,
    required String userType,
    required String newPassword,
  }) async {
    try {
      final fullUrl = '$baseUrl$_resetPasswordPath';

      final response = await _dioClient.postRequest<dynamic>(
        fullUrl,
        withAuth: false,
        body: {
          'email': email,
          'user_type': userType,
          'new_password': newPassword,
        },
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Change password
  ///
  /// [newPassword] - New password to set
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> changePassword({
    required String newPassword,
  }) async {
    try {
      final fullUrl = '$baseUrl$_changePasswordPath';

      final response = await _dioClient.postRequest<dynamic>(
        fullUrl,
        withAuth: true,
        body: {
          'new_password': newPassword,
        },
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Add or update bank details
  ///
  /// [accountHolderName] - Account holder name
  /// [accountNumber] - Account number
  /// [sortCode] - Sort code in format 12-34-56
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> addBankDetails({
    required String accountHolderName,
    required String accountNumber,
    required String sortCode,
  }) async {
    try {
      final fullUrl = '$baseUrl$_bankDetailsPath';

      final response = await _dioClient.postRequest<dynamic>(
        fullUrl,
        withAuth: true,
        body: {
          'account_holder_name': accountHolderName,
          'account_number': accountNumber,
          'sort_code': sortCode,
        },
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Get bank details
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> getBankDetails() async {
    try {
      final fullUrl = '$baseUrl$_bankDetailsPath';

      final response = await _dioClient.getRequest<dynamic>(
        fullUrl,
        withAuth: true,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Get profession types list
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> getProfessionTypes() async {
    try {
      final fullUrl = '$baseUrl$_professionTypesPath';

      final response = await _dioClient.getRequest<dynamic>(
        fullUrl,
        withAuth: true,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Get profession sub-types list
  ///
  /// [professionTypeId] - The _id of the profession type to get sub-types for
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> getProfessionSubTypes({
    required String professionTypeId,
  }) async {
    try {
      final fullUrl = '$baseUrl$_professionSubTypesPath';

      final response = await _dioClient.getRequest<dynamic>(
        fullUrl,
        withAuth: true,
        query: {
          'profession_type': professionTypeId,
        },
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Create profile
  ///
  /// [professionTypeId] - The _id of the profession type
  /// [professionSubTypeId] - The _id of the profession sub-type
  /// [fullName] - User's full name
  /// [dob] - Date of birth in format "yyyy-MM-dd"
  /// [gender] - User's gender (e.g., "male", "female")
  /// [id] - Optional profile ID for update scenario
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> createProfile({
    required String professionTypeId,
    required String professionSubTypeId,
    required String fullName,
    required String dob,
    required String gender,
    String? id,
  }) async {
    try {
      final fullUrl = '$baseUrl$_createProfilePath';

      final body = <String, dynamic>{
        'profession_type_id': professionTypeId,
        'profession_sub_type_id': professionSubTypeId,
        'full_name': fullName,
        'dob': dob,
        'gender': _convertGenderToApiFormat(gender),
      };

      // Add id if available (for update scenario)
      if (id != null && id.isNotEmpty) {
        body['id'] = id;
      }

      final response = await _dioClient.postRequest<dynamic>(
        fullUrl,
        withAuth: true,
        body: body,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Update personal details profile
  ///
  /// [id] - The _id of the profile to update (required)
  /// [professionTypeId] - The profession type ID
  /// [professionSubTypeId] - The profession sub-type ID
  /// [fullName] - Full name
  /// [dob] - Date of birth
  /// [gender] - Gender
  /// [profilePicture] - Optional profile picture file (only pass if there's a value)
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> updatePersonalDetailsProfile({
    required String id,
    required String professionTypeId,
    required String professionSubTypeId,
    required String fullName,
    required String dob,
    required String gender,
    required int optStatus,
    String? mobileNumber,
    File? profilePicture,
  }) async {
    try {
      final fullUrl = '$baseUrl$_updateCreatePersonalDetailsPath';

      final fields = <String, dynamic>{
        '_id': id,
        'profession_type_id': professionTypeId,
        'profession_sub_type_id': professionSubTypeId,
        'full_name': fullName,
        'dob': dob,
        'gender': _convertGenderToApiFormat(gender),
        'opt_status': optStatus,
        if (mobileNumber != null && mobileNumber.isNotEmpty)
          'mobile_number': mobileNumber,
      };

      final response = await _dioClient.uploadMultipart<dynamic>(
        fullUrl,
        fields: fields,
        withAuth: true,
        usePut: true,
        image: profilePicture,
        singleFileFieldName: 'profile_picture',
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Create address
  ///
  /// [fullAddress] - List containing full address with postcode, address, latitude, and longitude
  /// [workAddress] - Optional list containing work address with postcode, address, latitude, and longitude
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> createAddress({
    required List<Map<String, dynamic>> fullAddress,
    List<Map<String, dynamic>>? workAddress,
  }) async {
    try {
      final fullUrl = '$baseUrl$_createAddressPath';

      final body = <String, dynamic>{
        'full_address': fullAddress,
      };

      if (workAddress != null && workAddress.isNotEmpty) {
        body['work_address'] = workAddress;
      }

      final response = await _dioClient.postRequest<dynamic>(
        fullUrl,
        withAuth: true,
        body: body,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Get all services based on profession sub-type
  ///
  /// [professionSubTypeId] - The _id of the profession sub-type to get services for
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> getAllServices({
    required String professionSubTypeId,
  }) async {
    try {
      final fullUrl = '$baseUrl$_servicesAllPath';

      final response = await _dioClient.getRequest<dynamic>(
        fullUrl,
        withAuth: true,
        query: {
          'profession_sub_type_id': professionSubTypeId,
        },
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Save profession services
  ///
  /// [professionTypeId] - The _id of the profession type
  /// [professionSubTypeId] - The _id of the profession sub-type
  /// [services] - List of services with service_id and sub_service_ids
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> saveProfessionServices({
    required String professionTypeId,
    required String professionSubTypeId,
    required List<Map<String, dynamic>> services,
  }) async {
    try {
      final fullUrl = '$baseUrl$_professionServicesPath';

      final response = await _dioClient.postRequest<dynamic>(
        fullUrl,
        withAuth: true,
        body: {
          'profession_type_id': professionTypeId,
          'profession_sub_type_id': professionSubTypeId,
          'services': services,
        },
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Get colleges and universities list
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> getCollegesUniversities() async {
    try {
      final fullUrl = '$baseUrl$_collegesUniversityPath';

      final response = await _dioClient.getRequest<dynamic>(
        fullUrl,
        withAuth: true,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Upsert qualifications with multipart file upload
  ///
  /// [totalExperience] - Total years of experience
  /// [removedIds] - List of qualification IDs to remove
  /// [qualifications] - List of qualification objects
  /// [certificateFiles] - List of certificate files (PDF or Image)
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> upsertQualifications({
    required int totalExperience,
    required List<Map<String, dynamic>> qualifications,
    List<String>? removedIds,
    List<File>? certificateFiles,
  }) async {
    try {
      final fullUrl = '$baseUrl$_qualificationsUpsertPath';
      logInfo('=== Upsert Qualifications API Call ===');
      logInfo('URL: $fullUrl');
      logInfo('Total Experience: $totalExperience');
      logFullResponse('Qualifications Data', qualifications);
      logInfo('Removed IDs: ${removedIds ?? []}');
      logInfo('Certificate Files Count: ${certificateFiles?.length ?? 0}');

      // Prepare fields for multipart - send JSON as strings
      final fields = <String, dynamic>{
        'total_experience': totalExperience.toString(),
        'qualifications': jsonEncode(qualifications),
      };

      if (removedIds != null && removedIds.isNotEmpty) {
        fields['removed_ids'] = jsonEncode(removedIds);
      } else {
        fields['removed_ids'] = jsonEncode(<String>[]);
      }

      // Prepare certificate files - send with field name 'certificates_file' (plural)
      // Multiple files with same field name will be received as array by Multer
      if (certificateFiles != null && certificateFiles.isNotEmpty) {
        logInfo('Preparing ${certificateFiles.length} certificate file(s)...');
        // Send all files with the same field name 'certificates_file'
        // Multer will receive them as an array
        final multipartFiles = await Future.wait(
          certificateFiles.map((file) async {
            logInfo(
                'Certificate File: ${file.path} (exists: ${file.existsSync()})');
            if (file.existsSync()) {
              final fileSize = await file.length();
              logInfo('Certificate File size: ${fileSize} bytes');
            }
            return await dio.MultipartFile.fromFile(file.path);
          }),
        );
        // Send as array with field name 'certificates_file' (plural, as backend expects)
        fields['certificates_file'] = multipartFiles;
      } else {
        // No files - don't send certificates_file field
        logInfo('No certificate files to upload');
      }

      logFullResponse('Form Fields (before FormData)', fields);

      // Create FormData manually to handle custom field names
      final formData = dio.FormData.fromMap(fields);
      logInfo('FormData created successfully');

      // Use postRequest with FormData - Dio will automatically handle multipart
      logInfo('Sending POST request with multipart/form-data...');
      final response = await _dioClient.postRequest<dynamic>(
        fullUrl,
        body: formData,
        withAuth: true,
        options: dio.Options(
          contentType: 'multipart/form-data',
        ),
      );

      logInfo('=== API Response Received ===');
      logInfo('Status Code: ${response.statusCode}');
      logFullResponse('Response Data', response.data);

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      logError('DioException in upsertQualifications', error: e);
      logInfo('Error Type: ${e.type}');
      logInfo('Error Message: ${e.message}');
      logFullResponse('Error Response', e.response?.data);
      return ApiResponse.fromDioException(e);
    } catch (e, stackTrace) {
      logError('Exception in upsertQualifications',
          error: e, stackTrace: stackTrace);
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Save about you description
  ///
  /// [description] - User's description about themselves
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> saveAboutYou(
      {required String description, bool? is_update}) async {
    try {
      final fullUrl = '$baseUrl$_aboutYouPath';

      final body = <String, dynamic>{
        'description': description,
      };

      if (is_update == true) {
        body['is_update'] = is_update;
      }

      final response = await _dioClient.postRequest<dynamic>(
        fullUrl,
        withAuth: true,
        body: body,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Upsert personal identification with multipart file upload
  ///
  /// [idType] - Type of ID ("passport" or "driving_license")
  /// [expiryDate] - Expiry date in format "yyyy-MM-dd"
  /// [documentFile] - ID document file (PDF or Image)
  /// [confirmLegalRight] - Boolean indicating user confirms legal right to work
  /// [id] - Optional identification ID for updates
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> upsertPersonalIdentification({
    required String idType,
    required String expiryDate,
    required File documentFile,
    required bool confirmLegalRight,
    String? id,
  }) async {
    try {
      final fullUrl = '$baseUrl$_personalIdentificationUpsertPath';
      logInfo('=== Upsert Personal Identification API Call ===');
      logInfo('URL: $fullUrl');
      logInfo('ID Type: $idType');
      logInfo('Expiry Date: $expiryDate');
      logInfo('Confirm Legal Right: $confirmLegalRight');
      logInfo(
          'Document File: ${documentFile.path} (exists: ${documentFile.existsSync()})');

      // Prepare fields for multipart
      final fields = <String, dynamic>{
        'id_type': idType,
        'expiry_date': expiryDate,
        'confirm_legal_right': confirmLegalRight.toString(),
      };

      // Add ID if provided (for updates)
      if (id != null && id.isNotEmpty) {
        fields['id'] = id;
        logInfo('Identification ID for update: $id');
      }

      // Prepare document file
      if (documentFile.existsSync()) {
        final fileSize = await documentFile.length();
        logInfo('Document File size: $fileSize bytes');

        final multipartFile = await dio.MultipartFile.fromFile(
          documentFile.path,
          filename: documentFile.path.split('/').last,
        );

        fields['document_file'] = multipartFile;
      } else {
        logError('Document file does not exist: ${documentFile.path}');
        return ApiResponse.failure(
          error: 'Document file not found',
          message: 'Please upload a valid ID document',
        );
      }

      logFullResponse('Form Fields (before FormData)', fields);

      // Create FormData manually
      final formData = dio.FormData.fromMap(fields);
      logInfo('FormData created successfully');

      // Use postRequest with FormData - Dio will automatically handle multipart
      logInfo('Sending POST request with multipart/form-data...');
      final response = await _dioClient.postRequest<dynamic>(
        fullUrl,
        withAuth: true,
        body: formData,
        options: dio.Options(
          contentType: 'multipart/form-data',
        ),
      );

      logInfo('=== API Response Received ===');
      logInfo('Status Code: ${response.statusCode}');
      logFullResponse('Response Data', response.data);

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      logError('DioException in upsertPersonalIdentification', error: e);
      logInfo('Error Type: ${e.type}');
      logInfo('Error Message: ${e.message}');
      logFullResponse('Error Response', e.response?.data);
      return ApiResponse.fromDioException(e);
    } catch (e, stackTrace) {
      logError('Exception in upsertPersonalIdentification',
          error: e, stackTrace: stackTrace);
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Get create profile details
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> getCreateProfileDetails() async {
    try {
      final fullUrl = '$baseUrl$_getCreateProfileDetailsPath';

      final response = await _dioClient.getRequest<dynamic>(
        fullUrl,
        withAuth: true,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Get personal details
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> getPersonalDetails() async {
    try {
      final fullUrl = '$baseUrl$_getPersonalDetailsPath';

      final response = await _dioClient.getRequest<dynamic>(
        fullUrl,
        withAuth: true,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Get create address details
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> getCreateAddressDetails() async {
    try {
      final fullUrl = '$baseUrl$_getCreateAddressDetailsPath';

      final response = await _dioClient.getRequest<dynamic>(
        fullUrl,
        withAuth: true,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Get profession services
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> getProfessionServices() async {
    try {
      final fullUrl = '$baseUrl$_getProfessionServicesPath';

      final response = await _dioClient.getRequest<dynamic>(
        fullUrl,
        withAuth: true,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Get qualifications details
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> getQualificationsDetails() async {
    try {
      final fullUrl = '$baseUrl$_getQualificationsDetailsPath';

      final response = await _dioClient.getRequest<dynamic>(
        fullUrl,
        withAuth: true,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Get personal identification details
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> getPersonalIdentificationDetails() async {
    try {
      final fullUrl = '$baseUrl$_getPersonalIdentificationDetailsPath';

      final response = await _dioClient.getRequest<dynamic>(
        fullUrl,
        withAuth: true,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Get about you details
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> getAboutYouDetails() async {
    try {
      final fullUrl = '$baseUrl$_getAboutYouDetailsPath';

      final response = await _dioClient.getRequest<dynamic>(
        fullUrl,
        withAuth: true,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Get profile details
  ///
  /// Returns the API response wrapped in ApiResponse with user profile details
  /// This is a common API call accessible from anywhere in the app
  Future<ApiResponse<dynamic>> getProfileDetails() async {
    try {
      final fullUrl = '$baseUrl$_getProfileDetailsPath';

      final response = await _dioClient.getRequest<dynamic>(
        fullUrl,
        withAuth: true,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Update notification settings
  ///
  /// [isNotification] - Whether notifications are enabled (true/false)
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> updateNotification({
    required bool isNotification,
  }) async {
    try {
      final fullUrl = '$baseUrl$_notificationPath';

      final response = await _dioClient.postRequest<dynamic>(
        fullUrl,
        withAuth: true,
        body: {
          'is_notification': isNotification,
        },
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Get notifications list
  ///
  /// Returns the API response wrapped in ApiResponse with list of notifications
  Future<ApiResponse<dynamic>> getNotificationsList({
    Map<String, dynamic>? body,
  }) async {
    try {
      final fullUrl = '$baseUrl$_notificationsListPath';

      final response = await _dioClient.postRequest<dynamic>(
        fullUrl,
        withAuth: true,
        body: body ?? {},
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Get notifications count
  ///
  /// Returns the API response wrapped in ApiResponse with notification count
  Future<ApiResponse<dynamic>> getNotificationsCount() async {
    try {
      final fullUrl = '$baseUrl$_notificationsCountPath';

      final response = await _dioClient.getRequest<dynamic>(
        fullUrl,
        withAuth: true,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Get all service formats
  ///
  /// Returns the API response wrapped in ApiResponse with list of service formats
  Future<ApiResponse<dynamic>> getServiceFormats() async {
    try {
      final fullUrl = '$baseUrl$_serviceFormatsAllPath';

      final response = await _dioClient.getRequest<dynamic>(
        fullUrl,
        withAuth: true,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Create service formats
  ///
  /// [serviceFormats] - List of service format objects with service_format_id, is_bundle, duration_minutes, price, etc.
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> createServiceFormats({
    required List<Map<String, dynamic>> serviceFormats,
  }) async {
    try {
      final fullUrl = '$baseUrl$_serviceFormatsPath';

      final response = await _dioClient.postRequest<dynamic>(
        fullUrl,
        withAuth: true,
        body: {
          'service_formats': serviceFormats,
        },
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Update service format by ID
  ///
  /// [id] - The service format ID to update
  /// [durationMinutes] - Duration in minutes
  /// [price] - Price for the service format
  /// [bundleOf] - Number of sessions in bundle (optional, for bundle formats)
  /// [bundlePrice] - Price for the bundle (optional, for bundle formats)
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> updateServiceFormat({
    required String id,
    required int durationMinutes,
    required int price,
    int? bundleOf,
    int? bundlePrice,
    String? offerText,
  }) async {
    try {
      final fullUrl = '$baseUrl$_serviceFormatsPath/$id';

      final body = <String, dynamic>{
        'duration_minutes': durationMinutes,
        'price': price,
      };

      // Add bundle fields if provided
      if (bundleOf != null) {
        body['bundle_of'] = bundleOf;
      }
      if (bundlePrice != null) {
        body['bundle_price'] = bundlePrice;
      }
      if (offerText != null && offerText.isNotEmpty) {
        body['offer_text'] = offerText;
      }

      final response = await _dioClient.putRequest<dynamic>(
        fullUrl,
        withAuth: true,
        body: body,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Delete service format by ID
  ///
  /// [id] - The service format ID to delete
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> deleteServiceFormat({
    required String id,
  }) async {
    try {
      final fullUrl = '$baseUrl$_serviceFormatsPath/$id';

      final response = await _dioClient.deleteRequest<dynamic>(
        fullUrl,
        withAuth: true,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Add availability
  ///
  /// [startDate] - Start date in format "yyyy-MM-dd"
  /// [repeat] - Repeat pattern (e.g., "weekly", "daily", "monthly", "Don't repeat")
  /// [repeatUntil] - Repeat until date in format "yyyy-MM-dd" (optional if repeat is "Don't repeat")
  /// [excludeWeekends] - Whether to exclude weekends
  /// [excludePublicHolidays] - Whether to exclude public holidays
  /// [availableFrom] - Available from time in format "HH:mm"
  /// [availableUntil] - Available until time in format "HH:mm"
  /// [unavailableTimes] - List of unavailable time ranges with "from" and "to" in format "HH:mm"
  /// [timezone] - IANA timezone identifier (e.g., "Asia/Kolkata")
  /// [replaceExisting] - Whether to replace existing availability records (default: false)
  /// [isConfirmed] - Whether user confirmed to delete existing availability (default: false)
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> addAvailability({
    required String startDate,
    required String repeat,
    String? repeatUntil,
    required bool excludeWeekends,
    required bool excludePublicHolidays,
    required String availableFrom,
    required String availableUntil,
    required List<Map<String, String>> unavailableTimes,
    required String timezone,
    bool replaceExisting = false,
    bool isConfirmed = false,
  }) async {
    try {
      final fullUrl = '$baseUrl$_availabilityPath';

      final body = <String, dynamic>{
        'start_date': startDate,
        'repeat': repeat,
        'exclude_weekends': excludeWeekends,
        'exclude_public_holidays': excludePublicHolidays,
        'available_from': availableFrom,
        'available_until': availableUntil,
        'unavailable_times': unavailableTimes,
        'timezone': timezone,
      };

      // Add repeat_until only if repeat is not "Don't repeat"
      if (repeatUntil != null &&
          repeatUntil.isNotEmpty &&
          repeat != "Don't repeat") {
        body['repeat_until'] = repeatUntil;
      }

      // Add replace_existing flag if true
      if (replaceExisting) {
        body['replace_existing'] = true;
      }

      // Add is_confirmed flag if true
      if (isConfirmed) {
        body['is_confirmed'] = true;
      }

      final response = await _dioClient.postRequest<dynamic>(
        fullUrl,
        withAuth: true,
        body: body,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Update availability by ID
  ///
  /// [id] - The availability ID to update
  /// [startDate] - Start date in format "yyyy-MM-dd"
  /// [availableFrom] - Available from time in format "HH:mm"
  /// [availableUntil] - Available until time in format "HH:mm"
  /// [unavailableTimes] - List of unavailable time ranges with "from" and "to" in format "HH:mm"
  /// [timezone] - IANA timezone identifier (e.g., "Asia/Kolkata")
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> updateAvailability({
    required String id,
    required String startDate,
    required String availableFrom,
    required String availableUntil,
    required List<Map<String, String>> unavailableTimes,
    required String timezone,
  }) async {
    try {
      final fullUrl = '$baseUrl$_availabilityPath/$id';

      final body = <String, dynamic>{
        'start_date': startDate,
        'available_from': availableFrom,
        'available_until': availableUntil,
        'unavailable_times': unavailableTimes,
        'timezone': timezone,
      };

      final response = await _dioClient.putRequest<dynamic>(
        fullUrl,
        withAuth: true,
        body: body,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Get service format and availability for a specific date
  ///
  /// [date] - Date in format "yyyy-MM-dd"
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> getServiceFormatAvailability({
    required String date,
  }) async {
    try {
      final fullUrl = '$baseUrl$_getServiceFormatAvailabilityPath';

      final response = await _dioClient.getRequest<dynamic>(
        fullUrl,
        query: {'date': date},
        withAuth: true,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Delete availability by ID
  ///
  /// [id] - The availability ID to delete
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> deleteAvailability({
    required String id,
  }) async {
    try {
      final fullUrl = '$baseUrl$_availabilityPath/$id';

      final response = await _dioClient.deleteRequest<dynamic>(
        fullUrl,
        withAuth: true,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Get bookings list
  ///
  /// [date] - Optional date in format "dd/MM/yyyy". If not provided, uses current date.
  /// [timezone] - Optional timezone in IANA format (e.g., "Asia/Kolkata"). If not provided, uses current timezone.
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> getBookingsList({
    DateTime? date,
    String? timezone,
  }) async {
    try {
      final fullUrl = '$baseUrl$_bookingsListPath';

      // Use provided date or current date, format as dd/MM/yyyy
      final selectedDate = date ?? DateTime.now();
      final formattedDate = DateFormat('dd/MM/yyyy').format(selectedDate);

      // Use provided timezone or current timezone
      final selectedTimezone = timezone ?? TimezoneHelper.getCurrentTimezone();

      final body = {
        'date': formattedDate,
        'timezone': selectedTimezone,
      };

      final response = await _dioClient.postRequest<dynamic>(
        fullUrl,
        withAuth: true,
        body: body,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Cancel booking by ID
  ///
  /// [bookingId] - The booking ID to cancel
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> cancelBooking({
    required String bookingId,
  }) async {
    try {
      final fullUrl = '$baseUrl$_bookingsPath/$bookingId';

      final response = await _dioClient.deleteRequest<dynamic>(
        fullUrl,
        withAuth: true,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Reschedule booking by ID
  ///
  /// [bookingId] - The booking ID to reschedule
  /// [date] - Date in format "dd/MM/yyyy" (e.g., "12/07/2025")
  /// [fromTime] - Start time in format "HH:mm" (e.g., "14:00")
  /// [toTime] - End time in format "HH:mm" (e.g., "14:45")
  /// [timezone] - IANA timezone identifier (e.g., "Asia/Kolkata")
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> rescheduleBooking({
    required String bookingId,
    required String date,
    required String fromTime,
    required String toTime,
    required String timezone,
  }) async {
    try {
      final fullUrl = '$baseUrl$_bookingsReschedulePath/$bookingId';

      final body = <String, dynamic>{
        'date': date,
        'from_time': fromTime,
        'to_time': toTime,
        'timezone': timezone,
      };

      final response = await _dioClient.putRequest<dynamic>(
        fullUrl,
        withAuth: true,
        body: body,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Update device token for push notifications
  ///
  /// [deviceId] - Unique device identifier
  /// [deviceToken] - FCM token for push notifications
  /// [deviceType] - Device type (e.g., "ios", "android")
  /// [platform] - Platform name (e.g., "ios", "android")
  /// [appVersion] - App version string
  /// [language] - Language code (e.g., "en")
  /// [deviceName] - Device name/model
  /// [osVersion] - OS version string
  /// [latitude] - Optional latitude for location
  /// [longitude] - Optional longitude for location
  /// [requireRegistrationDevice] - Whether device registration is required (default: false)
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> updateDeviceToken({
    required String deviceId,
    required String deviceToken,
    required String deviceType,
    required String platform,
    required String appVersion,
    required String language,
    required String deviceName,
    required String osVersion,
    double? latitude,
    double? longitude,
    bool requireRegistrationDevice = false,
  }) async {
    try {
      final fullUrl = '$baseUrl$_updateDeviceTokenPath';

      // Prepare body with all device information
      final body = <String, dynamic>{
        'device_id': deviceId,
        'device_token': deviceToken,
        'device_type': deviceType,
        'platform': platform,
        'app_version': appVersion,
        'language': language,
        'device_name': deviceName,
        'os_version': osVersion,
        'require_registration_device': requireRegistrationDevice,
      };

      // Add location if available
      if (latitude != null && longitude != null) {
        body['latitude'] = latitude;
        body['longitude'] = longitude;
      }

      final response = await _dioClient.putRequest<dynamic>(
        fullUrl,
        withAuth: true,
        body: body,
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Check promo code validity
  ///
  /// [promoCode] - The promo code to validate
  /// [email] - User's email address
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> checkPromoCode({
    required String promoCode,
    required String email,
  }) async {
    try {
      final fullUrl = '$baseUrl$check_promo_code';

      final response = await _dioClient.postRequest<dynamic>(
        fullUrl,
        withAuth: false,
        body: {
          'promo_code': promoCode,
          'email': email,
        },
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }

  /// Get transaction history
  ///
  /// [page] - Page number for pagination
  /// [limit] - Number of items per page
  /// [startDate] - Start date for filter (YYYY-MM-DD)
  /// [endDate] - End date for filter (YYYY-MM-DD)
  ///
  /// Returns the API response wrapped in ApiResponse
  Future<ApiResponse<dynamic>> getTransactionHistory({
    required int page,
    required int limit,
  }) async {
    try {
      final fullUrl = '$baseUrl$_transactionHistoryPath';

      final response = await _dioClient.postRequest<dynamic>(
        fullUrl,
        withAuth: true,
        body: {
          'page': page,
          'limit': limit,
        },
      );

      return ApiResponse.fromDioResponse(response);
    } on dio.DioException catch (e) {
      return ApiResponse.fromDioException(e);
    } catch (e) {
      return ApiResponse.failure(
        error: e.toString(),
        message: 'An unexpected error occurred',
      );
    }
  }
}
