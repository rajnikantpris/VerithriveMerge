import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/core/base/base_controller.dart';
import 'package:verithrive_dev/enduser/screens/create_password/CreatePasswordBinding.dart';
import 'package:verithrive_dev/enduser/screens/create_password/CreatePasswordView.dart';
import 'package:verithrive_dev/enduser/screens/main/MainScreen.dart';
import 'package:verithrive_dev/enduser/screens/profile/ProfileBinding.dart';
import 'package:verithrive_dev/enduser/screens/profile/ProfileView.dart';
import 'package:verithrive_dev/enduser/screens/register/RegisterView.dart';
import 'package:verithrive_dev/enduser/screens/register/register_binding.dart';
import 'package:verithrive_dev/enduser/utils/common_dialog.dart';
import '../../data/repository/project_repository.dart';
import '../../network/exceptions/base_exception.dart';
import '../../utils/api_services.dart';
import '../../core/values/sharePrefrenceConst.dart';
import '../../data/model/login_model.dart';
import 'package:verithrive_dev/services/storage_service.dart';
import 'package:verithrive_dev/services/analytics_service.dart';
import '../../utils/OTPInputField.dart';

class OTPController extends BaseController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final GlobalKey<OTPInputFieldState> otpFieldKey =
      GlobalKey<OTPInputFieldState>();

  final ProjectRepository _repository =
      Get.find(tag: (ProjectRepository).toString());
  final StorageService? _storageService =
      Get.isRegistered<StorageService>() ? Get.find<StorageService>() : null;

  final isLoading = false.obs;
  final otpValue = ''.obs;
  final canResend = false.obs;
  final timerSeconds = 89.obs; // 2 minutes = 120 seconds

  Timer? _timer;
  final String? email;
  final String? phone;

  OTPController({this.email, this.phone});

  String type = "";
  String? userEmail = "";
  String? userPhone = "";
  String? userPassword = "";
  String? _pendingOtp;

  String? get initialOtp => _pendingOtp;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is Map) {
      type = Get.arguments['type'] ?? "";
      userEmail = Get.arguments['email'];
      userPhone = Get.arguments['phone'];
      userPassword = Get.arguments['password'];

      // Auto-fill OTP if received from arguments
      if (Get.arguments['otp'] != null) {
        String receivedOtp = Get.arguments['otp'].toString();
        if (receivedOtp.isNotEmpty) {
          _pendingOtp = receivedOtp;
          _autoFillOTP(receivedOtp);
        }
      }
    } else if (Get.arguments is String) {
      type = Get.arguments;
    } else {
      type = "";
    }

    // If email not in arguments, try to get from storage
    if (userEmail == null || userEmail!.isEmpty) {
      final storage = _storageService;
      final value = storage?.readString(SharePreferenceConst.email) ?? '';
      if (value.isNotEmpty) {
        userEmail = value;
      }
    }

    // If phone not in arguments, try to get from storage
    if (userPhone == null || userPhone!.isEmpty) {
      final storage = _storageService;
      final value = storage?.readString(SharePreferenceConst.mobile) ?? '';
      if (value.isNotEmpty) {
        userPhone = value;
      }
    }

    startTimer();
  }

  void startTimer() {
    canResend.value = false;
    timerSeconds.value = 89;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timerSeconds.value > 0) {
        timerSeconds.value--;
      } else {
        canResend.value = true;
        timer.cancel();
      }
    });
  }

  String get timerDisplay {
    int minutes = timerSeconds.value ~/ 60;
    int seconds = timerSeconds.value % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void onOTPCompleted(String otp) {
    otpValue.value = otp;
    print('OTP Entered: $otp');
  }

  void onOTPChanged(String otp) {
    otpValue.value = otp;
  }

  void _autoFillOTP(String otp) {
    final sanitized = otp.replaceAll(RegExp(r'[^0-9]'), '');
    if (sanitized.isEmpty) return;

    final otpDigits =
        sanitized.length > 6 ? sanitized.substring(0, 6) : sanitized;
    _pendingOtp = otpDigits;
    otpValue.value = otpDigits;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      otpFieldKey.currentState?.setOTP(otpDigits);
    });
  }

  bool get isOTPComplete => otpValue.value.length == 6;

  Future<void> verifyOTP() async {
    //Get.toNamed(AppRoutes.profile);
    if (otpValue.value.length != 6) {
      showResponseDialog(
        message: 'Please enter complete OTP',
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
      return;
    }

    // Get email from arguments or storage
    String emailToUse = userEmail ?? '';
    if (emailToUse.isEmpty) {
      final storage = _storageService;
      emailToUse = storage?.readString(SharePreferenceConst.email) ?? '';
    }

    if (emailToUse.isEmpty) {
      showResponseDialog(
        message: 'Email not found. Please register again.',
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {
          Get.offAll(
            () => RegisterView(),
            binding: RegisterBinding(),
          );
        },
      );
      return;
    }

    isLoading.value = true;
    callVerifyOTPService(emailToUse);
  }

  void callVerifyOTPService(String email) {
    // Check if this is a forgot password flow
    if (type.isNotEmpty && type == 'forgot_password') {
      callForgotPasswordVerifyOTPService(email);
    } else {
      callRegisterVerifyOTPService(email);
    }
  }

  void callForgotPasswordVerifyOTPService(String email) {
    Map<String, dynamic> toJson() {
      final Map<String, dynamic> data = <String, dynamic>{};
      data['email'] = email;
      data['otp'] = otpValue.value;
      data['user_type'] = 'normal';
      return data;
    }

    var service = _repository.sendPostApiRequest(
        toJson, forgot_password_verify_otp, false);

    callDataService(
      service,
      onSuccess: _handleForgotPasswordVerifyOTPResponseSuccess,
      onError: handleOnError,
      isShowLoading: true,
    );
  }

  void callRegisterVerifyOTPService(String email) {
    Map<String, dynamic> toJson() {
      final Map<String, dynamic> data = <String, dynamic>{};
      data['email'] = email;
      data['otp'] = otpValue.value;
      data['user_type'] = 'normal';
      data['password'] = userPassword;
      data['mobile_number'] = userPhone;
      return data;
    }

    var service =
        _repository.sendPostApiRequest(toJson, verify_otp_and_register, false);

    callDataService(
      service,
      onSuccess: _handleVerifyOTPResponseSuccess,
      onError: handleOnError,
      isShowLoading: true,
    );
  }

  Future<void> _handleVerifyOTPResponseSuccess(dynamic baseResponse) async {
    isLoading.value = false;

    try {
      Map<String, dynamic> responseData;
      if (baseResponse != null && baseResponse.data != null) {
        responseData = baseResponse.data is Map<String, dynamic>
            ? baseResponse.data
            : baseResponse.data as Map<String, dynamic>;
      } else if (baseResponse is Map<String, dynamic>) {
        responseData = baseResponse;
      } else {
        throw Exception('Invalid response format');
      }

      LoginModel response = LoginModel.fromJson(responseData);

      if (response.success == true && response.data != null) {
        LoginData loginData = response.data!;
        User? user = loginData.user;

        // Analytics: Log successful sign up verification

        final storage = _storageService;

        if (storage != null) {
          // Save login status
          await storage.writeBool(SharePreferenceConst.isLogin, true);

          // Save token
          await storage.writeString(
              SharePreferenceConst.access_token, loginData.token);
          await storage.writeString(StorageService.keyToken, loginData.token);
        }

        // Save all user data if available
        if (user != null && storage != null) {
          // Basic user info
          if (user.id != null) {
            await storage.writeString(SharePreferenceConst.id, user.id!);
          }
          if (user.email != null) {
            await storage.writeString(SharePreferenceConst.email, user.email!);
          }
          if (user.mobileNumber != null) {
            await storage.writeString(
                SharePreferenceConst.mobile, user.mobileNumber!);
            await storage.writeString(
                SharePreferenceConst.mobileNumber, user.mobileNumber!);
          }
          if (user.timezone != null) {
            await storage.writeString(
                SharePreferenceConst.TimeZone, user.timezone!);
          }

          // Email verification fields
          if (user.emailVerifiedAt != null) {
            await storage.writeString(
                SharePreferenceConst.emailVerifiedAt, user.emailVerifiedAt!);
          }
          if (user.isEmailVerified != null) {
            await storage.writeBool(
                SharePreferenceConst.isEmailVerified, user.isEmailVerified!);
          }

          // User type and experience
          if (user.userType != null) {
            await storage.writeString(
                SharePreferenceConst.userType, user.userType!);
          }
          if (user.totalExperience != null) {
            await storage.writeInt(
                SharePreferenceConst.totalExperience, user.totalExperience!);
          }

          // Boolean flags
          if (user.isOtpVerified != null) {
            await storage.writeBool(
                SharePreferenceConst.isOtpVerified, user.isOtpVerified!);
          }
          if (user.isActive != null) {
            await storage.writeBool(
                SharePreferenceConst.isActive, user.isActive!);
          }
          if (user.isApproved != null) {
            await storage.writeBool(
                SharePreferenceConst.isApproved, user.isApproved!);
          }
          if (user.isSocialLogin != null) {
            await storage.writeBool(
                SharePreferenceConst.isSocialLogin, user.isSocialLogin!);
          }
          if (user.isDeleted != null) {
            await storage.writeBool(
                SharePreferenceConst.isDeleted, user.isDeleted!);
          }
          if (user.isPersonalDetails != null) {
            await storage.writeBool(SharePreferenceConst.isPersonalDetails,
                user.isPersonalDetails!);
          }
          if (user.isTermCondition != null) {
            await storage.writeBool(
                SharePreferenceConst.isTermCondition, user.isTermCondition!);
          }
          if (user.isProfileCreated != null) {
            await storage.writeBool(
                SharePreferenceConst.isProfileCreated, user.isProfileCreated!);
          }
          if (user.isWorkFull != null) {
            await storage.writeBool(
                SharePreferenceConst.isWorkFull, user.isWorkFull!);
          }
          if (user.isPersonalIdentification != null) {
            await storage.writeBool(
                SharePreferenceConst.isPersonalIdentification,
                user.isPersonalIdentification!);
          }
          if (user.isAboutYou != null) {
            await storage.writeBool(
                SharePreferenceConst.isAboutYou, user.isAboutYou!);
          }
          if (user.isProfessionalServices != null) {
            await storage.writeBool(SharePreferenceConst.isProfessionalServices,
                user.isProfessionalServices!);
          }
          if (user.isQualification != null) {
            await storage.writeBool(
                SharePreferenceConst.isQualification, user.isQualification!);
          }
          if (user.isNotification != null) {
            await storage.writeBool(
                SharePreferenceConst.isNotification, user.isNotification!);
          }
          if (user.isPayment != null) {
            await storage.writeBool(
                SharePreferenceConst.isPayment, user.isPayment!);
          }

          // Token version
          if (user.tokenVersion != null) {
            await storage.writeInt(
                SharePreferenceConst.tokenVersion, user.tokenVersion!);
          }

          // Timestamps
          if (user.createdAt != null) {
            await storage.writeString(
                SharePreferenceConst.createdAt, user.createdAt!);
          }
          if (user.updatedAt != null) {
            await storage.writeString(
                SharePreferenceConst.updatedAt, user.updatedAt!);
          }
          if (user.lastLoginAt != null) {
            await storage.writeString(
                SharePreferenceConst.lastLoginAt, user.lastLoginAt!);
          }

          // Save complete user object as JSON for easy retrieval
          await storage.writeString(
            SharePreferenceConst.userData,
            jsonEncode(user.toJson()),
          );
        }

        // Show success message
        showResponseDialog(
          message: response.message,
          title: 'Success',
          isError: false,
          showButton: true,
          onOkPressed: () {
            // Check if personal details are completed
            bool isPersonalDetailsCompleted = user?.isPersonalDetails ?? false;
            if (isPersonalDetailsCompleted) {
              // Navigate to main/home screen if personal details are completed
              Get.offAll(
                () => MainScreen(),
              );
            } else {
              // Navigate to profile screen to complete personal details
              Get.to(
                () => ProfileView(),
                binding: ProfileBinding(),
                arguments: {
                  'email': userEmail ?? '',
                  'phone': userPhone ?? '',
                  'password': userPassword ?? '',
                },
              );
            }
          },
        );
      } else {
        // Show error message if OTP verification failed
        showResponseDialog(
          message: message,
          title: 'Error',
          isError: true,
          showButton: true,
          onOkPressed: () {
            // Clear OTP on error
            otpValue.value = '';
            final otpFieldState = otpFieldKey.currentState;
            if (otpFieldState != null && otpFieldState is OTPInputFieldState) {
              otpFieldState.clearOTP();
            }
          },
        );
      }
    } catch (e) {
      showResponseDialog(
        message: "Error processing OTP verification: $e",
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {
          // Clear OTP on error
          otpValue.value = '';
          final otpFieldState = otpFieldKey.currentState;
          if (otpFieldState != null && otpFieldState is OTPInputFieldState) {
            otpFieldState.clearOTP();
          }
        },
      );
    }
  }

  Future<void> _handleForgotPasswordVerifyOTPResponseSuccess(
      dynamic baseResponse) async {
    isLoading.value = false;

    try {
      Map<String, dynamic> responseData;
      if (baseResponse != null && baseResponse.data != null) {
        responseData = baseResponse.data is Map<String, dynamic>
            ? baseResponse.data
            : baseResponse.data as Map<String, dynamic>;
      } else if (baseResponse is Map<String, dynamic>) {
        responseData = baseResponse;
      } else {
        throw Exception('Invalid response format');
      }

      bool success = responseData['success'] ?? false;
      String message = responseData['message'] ?? 'OTP verified successfully';

      if (success == true) {
        // Analytics: Log successful forgot password OTP verification

        // Show success message and navigate to create password screen
        showResponseDialog(
          message: message,
          title: 'Success',
          isError: false,
          showButton: true,
          onOkPressed: () {
            // Navigate to create password screen for forgot password flow
            Get.to(
              () => CreatePasswordView(),
              binding: CreatePasswordBinding(),
              arguments: {
                'email': userEmail ?? '',
                'type': 'forgot_password',
              },
            );
          },
        );
      } else {
        // Show error message if OTP verification failed
        showResponseDialog(
          message: message,
          title: 'Error',
          isError: true,
          showButton: true,
          onOkPressed: () {
            // Clear OTP on error
            otpValue.value = '';
            final otpFieldState = otpFieldKey.currentState;
            if (otpFieldState != null && otpFieldState is OTPInputFieldState) {
              otpFieldState.clearOTP();
            }
          },
        );
      }
    } catch (e) {
      showResponseDialog(
        message: "Error processing OTP verification: $e",
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {
          // Clear OTP on error
          otpValue.value = '';
          final otpFieldState = otpFieldKey.currentState;
          if (otpFieldState != null && otpFieldState is OTPInputFieldState) {
            otpFieldState.clearOTP();
          }
        },
      );
    }
  }

  void handleOnError(dynamic e) {
    isLoading.value = false;

    if (e is BaseException) {
      showResponseDialog(
        message: e.message,
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {
          // Clear OTP on error
          otpValue.value = '';
          final otpFieldState = otpFieldKey.currentState;
          if (otpFieldState != null && otpFieldState is OTPInputFieldState) {
            otpFieldState.clearOTP();
          }
        },
      );
    }
  }

  Future<void> resendOTP() async {
    if (!canResend.value) return;

    // Clear the OTP input fields
    otpValue.value = '';

    // Clear all text controllers in the OTP input field
    final otpFieldState = otpFieldKey.currentState;
    if (otpFieldState != null && otpFieldState is OTPInputFieldState) {
      otpFieldState.clearOTP();
    }

    isLoading.value = true;

    // Get email from arguments or storage
    String emailToUse = userEmail ?? '';
    if (emailToUse.isEmpty) {
      final storage = _storageService;
      emailToUse = storage?.readString(SharePreferenceConst.email) ?? '';
    }

    if (emailToUse.isEmpty) {
      showResponseDialog(
        message: 'Email not found. Please register again.',
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {
          Get.offAll(
            () => RegisterView(),
            binding: RegisterBinding(),
          );
        },
      );
      isLoading.value = false;
      return;
    }

    // Call send OTP API
    callResendOTPService(emailToUse);
  }

  void callResendOTPService(String email) {
    // Check if this is a forgot password flow
    if (type.isNotEmpty && type == 'forgot_password') {
      Map<String, dynamic> toJson() {
        final Map<String, dynamic> data = <String, dynamic>{};
        data['email'] = email;
        data['user_type'] = 'normal';
        return data;
      }

      var service = _repository.sendPostApiRequest(
          toJson, forgot_password_send_otp, false);

      callDataService(
        service,
        onSuccess: _handleResendOTPResponseSuccess,
        onError: handleOnError,
        isShowLoading: true,
      );
    } else {
      Map<String, dynamic> toJson() {
        final Map<String, dynamic> data = <String, dynamic>{};
        data['email'] = email;
        data['user_type'] = 'normal';
        return data;
      }

      var service = _repository.sendPostApiRequest(toJson, send_otp, false);

      callDataService(
        service,
        onSuccess: _handleResendOTPResponseSuccess,
        onError: handleOnError,
        isShowLoading: true,
      );
    }
  }

  Future<void> _handleResendOTPResponseSuccess(dynamic baseResponse) async {
    isLoading.value = false;

    try {
      // Parse the response
      Map<String, dynamic> responseData;
      if (baseResponse != null && baseResponse.data != null) {
        responseData = baseResponse.data is Map<String, dynamic>
            ? baseResponse.data
            : baseResponse.data as Map<String, dynamic>;
      } else if (baseResponse is Map<String, dynamic>) {
        responseData = baseResponse;
      } else {
        throw Exception('Invalid response format');
      }

      bool success = responseData['success'] ?? false;
      String message = responseData['message'] ?? 'OTP sent successfully';

      // Extract OTP from response data if available
      String? receivedOtp;
      if (responseData['data'] != null && responseData['data'] is Map) {
        receivedOtp = responseData['data']['otp']?.toString();
      }

      if (success == true) {
        // Auto-fill OTP if received
        if (receivedOtp != null && receivedOtp.isNotEmpty) {
          _autoFillOTP(receivedOtp);
        }

        showResponseDialog(
          message: message,
          title: 'Success',
          isError: false,
          showButton: true,
          onOkPressed: () {
            startTimer();
          },
        );
      } else {
        showResponseDialog(
          message: message,
          title: 'Error',
          isError: true,
          showButton: true,
          onOkPressed: () {},
        );
      }
    } catch (e) {
      showResponseDialog(
        message: "Error resending OTP: $e",
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
