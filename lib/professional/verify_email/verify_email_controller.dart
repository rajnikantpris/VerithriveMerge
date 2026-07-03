import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/utils/OTPInputField.dart';
import '../../api/api_response.dart';
import '../../api/user_api_service.dart';
import '../../common/base_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/storage_service.dart';
import '../../models/login_response_model.dart';
import '../../widgets/response_dialog.dart';

class VerifyEmailController extends BaseController {
  VerifyEmailController(
    this._userApiService, [
    StorageService? storageService,
  ]) : _storageService = storageService ??
            (Get.isRegistered<StorageService>()
                ? Get.find<StorageService>()
                : null);

  final UserApiService _userApiService;
  final StorageService? _storageService;

  late final String email;
  late final String phone;
  late final String password;
  String promo_code = "";
  late final String userType;
  late final String nextRoute;
  late final Map<String, dynamic> navigationArgs;
  final GlobalKey<OTPInputFieldState> otpFieldKey =
      GlobalKey<OTPInputFieldState>();
  String? _pendingOtp;

  String? get initialOtp => _pendingOtp;

  RxBool isVerifying = false.obs;
  RxBool isResending = false.obs;
  final otpValue = ''.obs;
  final resendSecondsLeft = 90.obs;
  Timer? _resendTimer;

  @override
  void onInit() {
    super.onInit();
    final args = (Get.arguments as Map<String, dynamic>?) ?? {};
    navigationArgs = Map<String, dynamic>.from(args);
    email = (args['email'] as String?) ?? '';
    phone = (args['phone'] as String?) ?? '';
    password = (args['password'] as String?) ?? '';
    promo_code = (args['promo_code'] as String?) ?? '';
    userType = (args['user_type'] as String?) ?? 'professional';
    nextRoute = (args['nextRoute'] as String?) ?? Routes.verification;

    // Auto-fill OTP if provided in arguments
    final otp = args['otp'] as String?;
    if (otp != null && otp.isNotEmpty && !isClosed) {
      _pendingOtp = otp;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!isClosed) {
          _fillOtp(otp);
        }
      });
    }

    _startResendCountdown();
  }

  @override
  void onClose() {
    _resendTimer?.cancel();
    super.onClose();
  }

  String get otpCode => otpValue.value;

  bool get isOtpComplete => otpCode.length == 6;
  bool get canResend => resendSecondsLeft.value == 0 && !isResending.value;
  String get resendLabel {
    final seconds = resendSecondsLeft.value;
    if (seconds > 0) return 'Send it again ${_formatTime(seconds)}';
    return 'Send it again';
  }

  void onOtpChanged(String otp) {
    otpValue.value = otp;
  }

  void _fillOtp(String otp) {
    if (isClosed) return;

    final sanitized = otp.replaceAll(RegExp(r'[^0-9]'), '');
    if (sanitized.isEmpty) return;

    final otpDigits =
        sanitized.length > 6 ? sanitized.substring(0, 6) : sanitized;
    _pendingOtp = otpDigits;
    otpValue.value = otpDigits;
    otpFieldKey.currentState?.setOTP(otpDigits);
  }

  Future<void> submitOtp() async {
    if (!isOtpComplete) return;

    // First verify the OTP
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.verifyOtp(
        email: email,
        userType: userType,
        otp: otpCode,
      ),
      onStart: () {
        isVerifying.value = true;
      },
      onComplete: () {
        isVerifying.value = false;
      },
      mapErrorMessage: (error) {
        if (error is ApiResponse) {
          // Handle specific HTTP status codes
          final statusCode = error.statusCode;

          if (statusCode == 429) {
            return 'Too many requests. Please wait a moment and try again.';
          }

          if (statusCode == 400) {
            return 'Invalid OTP. Please check and try again.';
          }

          if (statusCode == 401) {
            return 'Unauthorized. Please try again.';
          }

          if (statusCode == 404) {
            return 'Service not found. Please try again later.';
          }

          if (statusCode != null && statusCode >= 500) {
            return 'Server error. Please try again later.';
          }

          return error.errorMessage;
        }
        return mapErrorToMessage(error);
      },
      onSuccess: (response) async {
        if (response.success) {
          // Check if verification was successful
          // ApiResponse already handles boolean true responses
          bool isVerified = response.success;

          // Also check data if it's a boolean
          if (response.data is bool) {
            isVerified = response.data as bool;
          }

          // If OTP verification is successful, proceed based on flow type
          if (isVerified) {
            final messageText = response.message ?? 'OTP verified successfully';

            // Check if this is a forgot password flow
            if (nextRoute == Routes.createNewPassword) {
              // Forgot password flow - navigate to create new password
              showResponseDialog(
                message: messageText,
                title: 'Success',
                isError: false,
                showButton: false,
                onOkPressed: () {
                  Get.offNamed(
                    Routes.createNewPassword,
                    arguments: {
                      'email': email,
                      'otp': otpCode,
                      'user_type': userType,
                    },
                  );
                },
              );
            } else {
              await _registerUser();
              // Registration flow - proceed with registration
              // showResponseDialog(
              //   message: messageText,
              //   title: 'Success',
              //   isError: false,
              //   showButton: false,
              //   onOkPressed: () async {
              //
              //   },
              // );
            }
          } else {
            showResponseDialog(
              message: 'OTP verification failed. Please try again.',
              title: 'Error',
              isError: true,
            );
          }
        } else {
          showResponseDialog(
            message: response.errorMessage,
            title: 'Error',
            isError: true,
          );
        }
      },
    );
  }

  Future<void> _registerUser() async {
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.register(
          email: email,
          userType: userType,
          mobileNumber: phone,
          password: password,
          promo_code: promo_code),
      showLoader: true,
      mapErrorMessage: (error) {
        if (error is ApiResponse) {
          // Handle specific HTTP status codes
          final statusCode = error.statusCode;

          if (statusCode == 429) {
            return 'Too many requests. Please wait a moment and try again.';
          }

          if (statusCode == 400) {
            return 'Invalid registration data. Please check your information and try again.';
          }

          if (statusCode == 401) {
            return 'Unauthorized. Please try again.';
          }

          if (statusCode == 404) {
            return 'Service not found. Please try again later.';
          }

          if (statusCode != null && statusCode >= 500) {
            return 'Server error. Please try again later.';
          }

          return error.errorMessage;
        }
        return mapErrorToMessage(error);
      },
      onSuccess: (response) async {
        if (response.success) {
          if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            try {
              final loginData = LoginResponseModel.fromJson(data);
              await _persistAuthData(loginData);
            } catch (error, stack) {
              debugPrint('Failed to parse registration response: $error');
              debugPrint(stack.toString());
              final storage = _storageService;
              if (storage != null) {
                final token = data['token'] as String?;
                if (token != null && token.isNotEmpty) {
                  await storage.writeString('access_token', token);
                }
                if (data['user'] is Map<String, dynamic>) {
                  final user = data['user'] as Map<String, dynamic>;
                  final userEmail = user['email'] as String?;
                  if (userEmail != null && userEmail.isNotEmpty) {
                    await storage.writeString('user_email', userEmail);
                  }
                }
              }
            }
          }


          await _storageService?.writeString('userType', 'professional');

          // Fallback: Save email from controller if not found in response
          final storedEmail = _storageService?.readString('user_email');
          if ((storedEmail == null || storedEmail.isEmpty) &&
              email.isNotEmpty) {
            await _storageService?.writeString('user_email', email);
          }

          // Ensure is_social_login is false for normal registration
          await _storageService?.writeBool('is_social_login', false);

          Get.offAllNamed(Routes.signupPersonDetails);
        } else {
          showResponseDialog(
            message: response.errorMessage,
            title: 'Error',
            isError: true,
          );
        }
      },
    );
  }

  Future<void> resendOtp() async {
    otpValue.value = '';
    otpFieldKey.currentState?.clearOTP();

    // Use forgot password API if this is a forgot password flow, otherwise use registration API
    final Future<ApiResponse<dynamic>> otpFuture =
        nextRoute == Routes.createNewPassword
            ? _userApiService.forgotPasswordSendOtp(
                email: email,
                userType: userType,
              )
            : _userApiService.sendOtp(
                email: email,
                userType: userType,
              );

    await callDataService<ApiResponse<dynamic>>(
      otpFuture,
      showLoader: false,
      onStart: () => isResending.value = true,
      onComplete: () {
        isResending.value = false;
        _startResendCountdown();
      },
      mapErrorMessage: (error) {
        if (error is ApiResponse) {
          // Handle specific HTTP status codes
          final statusCode = error.statusCode;

          if (statusCode == 429) {
            return 'Too many requests. Please wait a moment before requesting a new OTP.';
          }

          if (statusCode == 400) {
            return 'Invalid request. Please try again.';
          }

          if (statusCode == 401) {
            return 'Unauthorized. Please try again.';
          }

          if (statusCode == 404) {
            return 'Service not found. Please try again later.';
          }

          if (statusCode != null && statusCode >= 500) {
            return 'Server error. Please try again later.';
          }

          return error.errorMessage;
        }
        return mapErrorToMessage(error);
      },
      onSuccess: (response) {
        if (!isClosed) {
          if (response.success) {
            // Extract and auto-fill OTP from response data if available
            if (!isClosed && response.data is Map<String, dynamic>) {
              final data = response.data as Map<String, dynamic>;
              final otpValue = data['otp'];
              if (otpValue != null && !isClosed) {
                final otp = otpValue.toString();
                _fillOtp(otp);
              }
            }

            final messageText = response.message ?? 'OTP resent successfully';
            showResponseDialog(
              message: messageText,
              title: 'Success',
              isError: false,
            );
          } else {
            showResponseDialog(
              message: response.errorMessage,
              title: 'Error',
              isError: true,
            );
          }
        }
      },
    );
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    resendSecondsLeft.value = 90;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendSecondsLeft.value <= 1) {
        timer.cancel();
        resendSecondsLeft.value = 0;
      } else {
        resendSecondsLeft.value -= 1;
      }
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final secText = seconds.toString().padLeft(2, '0');
    return '$minutes:$secText';
  }

  Future<void> _persistAuthData(LoginResponseModel loginData) async {
    final storage = _storageService;
    if (storage == null) return;

    final token = loginData.token;
    if (token != null && token.isNotEmpty) {
      await storage.writeString('access_token', token);
    }

    final user = loginData.user;
    final userEmail = user?.email;
    if (userEmail != null && userEmail.isNotEmpty) {
      await storage.writeString('user_email', userEmail);
    }

    final userId = user?.id;
    if (userId != null && userId.isNotEmpty) {
      await storage.writeString('user_id', userId);
    }

    final userFlags = _extractUserFlagsFromModel(user);
    for (final entry in userFlags.entries) {
      await storage.writeBool(entry.key, entry.value);
    }
  }

  Map<String, bool> _extractUserFlagsFromModel(UserModel? user) {
    final flags = <String, bool>{};
    if (user == null) return flags;

    flags['is_personal_details'] = user.isPersonalDetails ?? false;
    flags['is_term_condition'] = user.isTermCondition ?? false;
    flags['is_profile_created'] = user.isProfileCreated ?? false;
    flags['is_work_full'] = user.isWorkFull ?? false;
    flags['is_professional_services'] = user.isProfessionalServices ?? false;
    flags['is_qualification'] = user.isQualification ?? false;
    flags['is_personal_identification'] =
        user.isPersonalIdentification ?? false;
    flags['is_about_you'] = user.isAboutYou ?? false;
    flags['is_payment'] = user.isPayment ?? false;

    return flags;
  }
}
