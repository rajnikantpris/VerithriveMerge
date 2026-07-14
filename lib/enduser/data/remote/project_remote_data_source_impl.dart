import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verithrive_dev/enduser/data/remote/project_remote_data_source.dart';
import 'package:verithrive_dev/utils/timezone_helper.dart';
import '../../FirebaseTokenService.dart';
import '../../core/base/base_remote_source.dart';
import '../../core/values/sharePrefrenceConst.dart';
import '../../core/widget/common_widgets.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import '../../utils/FirebaseTokenManager.dart';
import '../../utils/api_services.dart';
import '../../utils/auth_service.dart';

class ProjectRemoteDataSourceImpl extends BaseRemoteSource
    implements ProjectRemoteDataSource {
  // Helper method to check if API call is allowed in guest mode
  Future<bool> _canMakeApiCallOld(String apiName) async {
    bool canCall = await AuthService.canMakeApiCall(apiName);
    if (!canCall) {
      print('API Call Blocked: $apiName (Guest mode restriction)');
      throw Exception(
          'Authentication required. Please login to access this feature.');
    }
    return true;
  }

  // Helper method to get current timezone
  Future<String> _getCurrentTimezone() async {
    try {
      // TimezoneInfo timezone = await FlutterTimezone.getLocalTimezone();
      final selectedTimezone = TimezoneHelper.getCurrentTimezone();
      return selectedTimezone;
    } catch (e) {
      print('Error getting timezone: $e');
      // Fallback to SharedPreferences if flutter_timezone fails
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString(SharePreferenceConst.TimeZone) ?? 'UTC';
    }
  }

  @override
  Future sendPostApiRequest(
    Map<String, dynamic> Function() toJson,
    String apiName,
    bool isToken,
  ) async {
    // Check if API call is allowed in guest mode
    //  await _canMakeApiCall(apiName);

    var endpoint = "$bareUrl$apiName";

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? token =
        sharedPreferences.getString(SharePreferenceConst.access_token);
    String timezone = await _getCurrentTimezone();

    // Get device information
    List<String> deviceData = await CommonUtils.getIntance().getDeviceData();
    //String? deviceToken = await FirebaseMessaging.instance.getToken();

    String? deviceToken = await FirebaseTokenService.getFCMToken();

    String deviceId = deviceData[0];
    String deviceName = deviceData[1];
    String deviceType = Platform.isAndroid ? "android" : "ios";
    String osVersion = deviceData[2];
    String appVersion = deviceData[3];

    // Prepare headers for JSON content
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add timezone header
    headers['timezone'] = timezone;

    // Add device information to headers
    headers['device_token'] = deviceToken ?? '';
    headers['device_id'] = deviceId;
    headers['device_type'] = deviceType;
    headers['device_name'] = deviceName;
    headers['os_version'] = osVersion;
    headers['app_version'] = appVersion;

    if (isToken) {
      if (token != null && token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }
    }

    // Send raw JSON data instead of FormData
    var dioCall = dioClient.post(
      endpoint,
      data: toJson.call(), // Dio will automatically serialize Map to JSON
      options: Options(headers: headers),
    );

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => _parseApiResponse(response));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future sendPostApiRequestNew(
    Map<String, dynamic> Function() toJson,
    String apiName,
    bool isToken,
  ) async {
    var endpoint = "$bareUrl$apiName";

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? token =
        sharedPreferences.getString(SharePreferenceConst.access_token);
    String timezone = await _getCurrentTimezone();

    // Get device information
    List<String> deviceData = await CommonUtils.getIntance().getDeviceData();

    // Get device token - NON-BLOCKING (returns immediately with cached or empty)
    String deviceToken = await FirebaseTokenManager.getTokenNonBlocking();

    String deviceId = deviceData[0];
    String deviceName = deviceData[1];
    String deviceType = Platform.isAndroid ? "android" : "ios";
    String osVersion = deviceData[2];
    String appVersion = deviceData[3];

    // Prepare headers for JSON content
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'timezone': timezone,
      'device_token': deviceToken, // Will be empty string if not available
      'device_id': deviceId,
      'device_type': deviceType,
      'device_name': deviceName,
      'os_version': osVersion,
      'app_version': appVersion,
    };

    if (isToken) {
      if (token != null && token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }
    }

    var dioCall = dioClient.post(
      endpoint,
      data: toJson.call(),
      options: Options(headers: headers),
    );

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => _parseApiResponse(response));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future sendGetApiRequest(
      Map<String, dynamic> Function() toJson, String apiName) async {
    var endpoint = "$bareUrl$apiName";

    String timezone = await _getCurrentTimezone();

    // Prepare headers
    Map<String, dynamic> headers = {
      'accept': "application/json",
    };

    // Add timezone header
    headers['timezone'] = timezone;

    var dioCall = dioClient.post(
      endpoint,
      queryParameters: toJson(),
      options: Options(headers: headers),
    );
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => _parseApiResponse(response));
    } catch (e) {
      rethrow;
    }
  }

  dynamic _parseApiResponse(Response<dynamic> response) {
    return response;
  }

  @override
  Future sendGetApiNoParamRequest(String apiName) async {
    // Check if API call is allowed in guest mode
    // await _canMakeApiCall(apiName);

    var endpoint = "$bareUrl$apiName";

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String timezone = await _getCurrentTimezone();
    String? token =
        sharedPreferences.getString(SharePreferenceConst.access_token);

    // Prepare headers
    Map<String, dynamic> headers = {
      'accept': "application/json",
    };

    // Add timezone header
    headers['timezone'] = timezone;

    // Add token for authenticated requests
    if (token != null && token.isNotEmpty) {
      headers["Authorization"] = "Bearer $token";
    }

    var dioCall = dioClient.get(endpoint, options: Options(headers: headers));
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => _parseApiResponse(response));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future sendGetApiWithParamRequest(Map<String, dynamic> Function() toJson,
      String apiName, bool isToken) async {
    // Check if API call is allowed in guest mode
    // await _canMakeApiCall(apiName);

    var endpoint = "$bareUrl$apiName";

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String timezone = await _getCurrentTimezone();
    String? token =
        sharedPreferences.getString(SharePreferenceConst.access_token);

    // Prepare headers
    Map<String, dynamic> headers = {
      'accept': "application/json",
    };

    // Add timezone header
    headers['timezone'] = timezone;

    // Add token for authenticated requests
    if (isToken) {
      if (token != null && token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }
    }

    var dioCall = dioClient.get(
      endpoint,
      queryParameters: toJson(),
      options: Options(headers: headers),
    );
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => _parseApiResponse(response));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future sendPutApiRequest(Map<String, dynamic> Function() toJson,
      String apiName, bool isToken) async {
    // Check if API call is allowed in guest mode
    // await _canMakeApiCall(apiName);

    var endpoint = "$bareUrl$apiName";

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? token =
        sharedPreferences.getString(SharePreferenceConst.access_token);
    String timezone = await _getCurrentTimezone();

    // Prepare headers for JSON content
    Map<String, dynamic> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add timezone header
    headers['timezone'] = timezone;

    if (isToken) {
      if (token != null && token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }
    }

    // Send raw JSON data using PUT method
    var dioCall = dioClient.put(
      endpoint,
      data: toJson.call(), // Dio will automatically serialize Map to JSON
      options: Options(headers: headers),
    );
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => _parseApiResponse(response));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future sendMultipartApiRequest(
    Map<String, dynamic> Function() toJson,
    String apiName,
    bool isToken, {
    File? imageFile,
    String? imageFieldName,
  }) async {
    // Check if API call is allowed in guest mode
    // await _canMakeApiCall(apiName);

    var endpoint = "$bareUrl$apiName";

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? token =
        sharedPreferences.getString(SharePreferenceConst.access_token);
    String timezone = await _getCurrentTimezone();

    List<String> deviceData = await CommonUtils.getIntance().getDeviceData();
    // String? deviceToken = await FirebaseMessaging.instance.getToken();

    String? deviceToken = await FirebaseTokenService.getFCMToken();

    String deviceId = deviceData[0];
    String deviceName = deviceData[1];
    String deviceType = Platform.isAndroid ? "android" : "ios";
    String osVersion = deviceData[2];
    String appVersion = deviceData[3];

    // Prepare headers for multipart form data
    Map<String, dynamic> headers = {
      'Accept': 'application/json',
    };

    // Add timezone header
    headers['timezone'] = timezone;

    // Add device information to headers
    headers['device_token'] = deviceToken ?? '';
    headers['device_id'] = deviceId;
    headers['device_type'] = deviceType;
    headers['device_name'] = deviceName;
    headers['os_version'] = osVersion;
    headers['app_version'] = appVersion;

    if (isToken) {
      if (token != null && token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }
    }

    // Create FormData
    FormData formData = FormData.fromMap(toJson.call());

    // Add image file if provided
    if (imageFile != null && imageFile.existsSync()) {
      String fileName = imageFile.path.split('/').last;
      formData.files.add(
        MapEntry(
          imageFieldName ?? 'profile_picture',
          await MultipartFile.fromFile(
            imageFile.path,
            filename: fileName,
          ),
        ),
      );
    }

    var dioCall = dioClient.post(
      endpoint,
      data: formData,
      options: Options(headers: headers),
    );

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => _parseApiResponse(response));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future sendMultipartApiRequestNew(
    Map<String, dynamic> Function() toJson,
    String apiName,
    bool isToken, {
    File? imageFile,
    String? imageFieldName,
  }) async {
    // Check if API call is allowed in guest mode
    // await _canMakeApiCall(apiName);

    var endpoint = "$bareUrl$apiName";

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? token =
        sharedPreferences.getString(SharePreferenceConst.access_token);
    String timezone = await _getCurrentTimezone();

    List<String> deviceData = await CommonUtils.getIntance().getDeviceData();

    // Get device token - NON-BLOCKING (returns immediately with cached or empty)
    String deviceToken = await FirebaseTokenManager.getTokenNonBlocking();

    String deviceId = deviceData[0];
    String deviceName = deviceData[1];
    String deviceType = Platform.isAndroid ? "android" : "ios";
    String osVersion = deviceData[2];
    String appVersion = deviceData[3];

    // Prepare headers for multipart form data
    Map<String, dynamic> headers = {
      'Accept': 'application/json',
      'timezone': timezone,
      'device_token': deviceToken, // Will be empty string if not available
      'device_id': deviceId,
      'device_type': deviceType,
      'device_name': deviceName,
      'os_version': osVersion,
      'app_version': appVersion,
    };

    if (isToken) {
      if (token != null && token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }
    }

    // Create FormData
    FormData formData = FormData.fromMap(toJson.call());

    // Add image file if provided
    if (imageFile != null && imageFile.existsSync()) {
      String fileName = imageFile.path.split('/').last;
      formData.files.add(
        MapEntry(
          imageFieldName ?? 'profile_picture',
          await MultipartFile.fromFile(
            imageFile.path,
            filename: fileName,
          ),
        ),
      );
    }

    var dioCall = dioClient.post(
      endpoint,
      data: formData,
      options: Options(headers: headers),
    );

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => _parseApiResponse(response));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future sendPutMultipartApiRequest(
    Map<String, dynamic> Function() toJson,
    String apiName,
    bool isToken, {
    File? imageFile,
    String? imageFieldName,
  }) async {
    // Check if API call is allowed in guest mode
    // await _canMakeApiCall(apiName);

    var endpoint = "$bareUrl$apiName";

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? token =
        sharedPreferences.getString(SharePreferenceConst.access_token);
    String timezone = await _getCurrentTimezone();

    // Prepare headers for multipart form data
    Map<String, dynamic> headers = {
      'Accept': 'application/json',
    };

    // Add timezone header
    headers['timezone'] = timezone;

    if (isToken) {
      if (token != null && token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }
    }

    // Create FormData
    FormData formData = FormData.fromMap(toJson.call());

    // Add image file if provided
    if (imageFile != null && imageFile.existsSync()) {
      String fileName = imageFile.path.split('/').last;
      formData.files.add(
        MapEntry(
          imageFieldName ?? 'profile_picture',
          await MultipartFile.fromFile(
            imageFile.path,
            filename: fileName,
          ),
        ),
      );
    }

    // Use PUT method instead of POST
    var dioCall = dioClient.put(
      endpoint,
      data: formData,
      options: Options(headers: headers),
    );

    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => _parseApiResponse(response));
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future sendDeleteApiRequest(String apiName, bool isToken) async {
    // Check if API call is allowed in guest mode
    // await _canMakeApiCall(apiName);

    var endpoint = "$bareUrl$apiName";

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? token =
        sharedPreferences.getString(SharePreferenceConst.access_token);
    String timezone = await _getCurrentTimezone();

    // Prepare headers for JSON content
    Map<String, dynamic> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add timezone header
    headers['timezone'] = timezone;

    if (isToken) {
      if (token != null && token.isNotEmpty) {
        headers["Authorization"] = "Bearer $token";
      }
    }

    // Send DELETE request
    var dioCall = dioClient.delete(
      endpoint,
      options: Options(headers: headers),
    );
    try {
      return callApiWithErrorParser(dioCall)
          .then((response) => _parseApiResponse(response));
    } catch (e) {
      rethrow;
    }
  }
}
