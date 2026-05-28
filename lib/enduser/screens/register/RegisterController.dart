import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/core/base/base_controller.dart';
import 'package:verithrive_dev/enduser/screens/main/MainScreen.dart';
import 'package:verithrive_dev/enduser/screens/otp/OTPBinding.dart';
import 'package:verithrive_dev/enduser/screens/otp/OTPView.dart';
import 'package:verithrive_dev/enduser/screens/profile/ProfileBinding.dart';
import 'package:verithrive_dev/enduser/screens/profile/ProfileView.dart';
import 'package:verithrive_dev/enduser/utils/common_dialog.dart';
import '../login/LoginBinding.dart';
import '../login/LoginView.dart';
import '../../routes/app_routes.dart';
import '../../data/repository/project_repository.dart';
import '../../network/exceptions/base_exception.dart';
import '../../utils/api_services.dart';
import '../../data/model/login_model.dart';
import '../../core/values/sharePrefrenceConst.dart';
import 'package:verithrive_dev/services/storage_service.dart';
import 'package:verithrive_dev/services/social_auth_service.dart';
import 'package:verithrive_dev/services/analytics_service.dart';
import 'dart:convert';

class RegisterController extends BaseController {
  final formKey = GlobalKey<FormState>();

  final ProjectRepository _repository =
      Get.find(tag: (ProjectRepository).toString());
  final StorageService? _storageService =
      Get.isRegistered<StorageService>() ? Get.find<StorageService>() : null;
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final SocialAuthService _socialAuthService = SocialAuthService();

  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final isLoading = false.obs;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (value.length < 10) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8 || value.length > 20) {
      return 'Password must be 8-20 characters long';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must include at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must include at least one lowercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must include at least one number';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void registerApiCall() {
    // Get.toNamed(AppRoutes.otp);
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    callRegisterService();
  }

  void callRegisterService() {
    // Store values to avoid accessing disposed controllers
    final email = emailController.value.text.trim();
    final phone = phoneController.value.text.trim();
    final password = passwordController.value.text.trim();

    Map<String, dynamic> toJson() {
      final Map<String, dynamic> data = <String, dynamic>{};
      data['email'] = email;
      data['mobile_number'] = phone;
      data['password'] = password;
      data['user_type'] = 'normal';
      return data;
    }

    var service = _repository.sendPostApiRequest(toJson, send_otp, false);

    callDataService(
      service,
      onSuccess: _handleRegisterResponseSuccess,
      onError: handleOnError,
      isShowLoading: true,
    );
  }

  Future<void> _handleRegisterResponseSuccess(dynamic baseResponse) async {
    isLoading.value = false;

    try {
      // Parse the response - baseResponse is a Dio Response object
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
      String message = responseData['message'] ?? 'Registration completed';

      // Extract OTP from response data if available
      String? receivedOtp;
      if (responseData['data'] != null && responseData['data'] is Map) {
        receivedOtp = responseData['data']['otp']?.toString();
      }

      if (success == true) {
        // Analytics: Log registration start (OTP sent)

        // Show success message
        showResponseDialog(
          message: message,
          title: 'Success',
          isError: false,
          showButton: true,
          onOkPressed: () {
            // Store values before navigation to avoid using disposed controllers
            final email = emailController.value.text.trim();
            final phone = phoneController.value.text.trim();
            final password = passwordController.value.text.trim();

            // Navigate to OTP screen after successful registration with all registration data and OTP
            Map<String, dynamic> arguments = {
              'type': 'register',
              'email': email,
              'phone': phone,
              'password': password,
            };
            if (receivedOtp != null && receivedOtp.isNotEmpty) {
              arguments['otp'] = receivedOtp;
            }
            // Use offNamed to remove register screen from stack
            // Get.offNamed(AppRoutes.otp, arguments: arguments);
            Get.to(() => const OTPView(),
                binding: OTPBinding(), arguments: arguments);
          },
        );
      } else {
        showResponseDialog(
          message: message,
          title: 'Error',
          isError: true,
          showButton: true,
          onOkPressed: () {
            // dispose();
          },
        );
      }
    } catch (e) {
      showResponseDialog(
        message: "Error processing registration response: $e",
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {
          // dispose();
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
          // dispose();
        },
      );
    }
  }

  Future<void> continueWithGoogle() async {
    try {
      final userInfo = await _socialAuthService.signInWithGoogle();

      if (userInfo == null) {
        // User cancelled sign-in
        return;
      }

      final socialId = userInfo['id'] ?? '';
      final email = userInfo['email'] ?? '';

      if (socialId.isEmpty || email.isEmpty) {
        showResponseDialog(
          message: 'Unable to retrieve Google account information',
          title: 'Error',
          isError: true,
          showButton: true,
        );
        return;
      }

      // For registration, we'll directly proceed to social registration
      await _handleSocialRegistration(
        email: email,
        socialType: 'google',
        socialId: socialId,
        fullName: userInfo['displayName'],
        profilePicture: userInfo['photoUrl'],
      );
    } catch (e) {
      showResponseDialog(
        message: 'Google sign-in failed: ${e.toString()}',
        title: 'Error',
        isError: true,
        showButton: true,
      );
    }
  }

  /// Handle social registration (Google or Apple)
  Future<void> _handleSocialRegistration({
    required String email,
    required String socialType,
    required String socialId,
    String? fullName,
    String? profilePicture,
  }) async {
    Map<String, dynamic> toJson() {
      final Map<String, dynamic> data = <String, dynamic>{};
      data['email'] = email;
      data['social_type'] = socialType;
      data['social_id'] = socialId;
      data['full_name'] = fullName ?? "";
      data['profile_picture'] = profilePicture ?? "";
      return data;
    }

    var service = _repository.sendPostApiRequest(toJson, social_signin, false);

    callDataService(
      service,
      onSuccess: _handleSocialRegisterResponseSuccess,
      onError: handleOnError,
      isShowLoading: true,
    );
  }

  /// Sign out from Google account
  Future<void> _signOutGoogle() async {
    try {
      await _socialAuthService.signOutGoogle();
    } catch (e) {
      print('Error signing out from Google: $e');
    }
  }

  Future<void> _handleSocialRegisterResponseSuccess(
      dynamic baseResponse) async {
    isLoading.value = false;

    try {
      // Parse the response - baseResponse is a Dio Response object
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
        final storage = _storageService;

        if (storage != null) {
          // Save login status
          await storage.writeBool(SharePreferenceConst.isLogin, true);
          // Clear guest flag when user logs in
          await storage.writeBool(SharePreferenceConst.isGuest, false);

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
          // Save social login specific data (full_name and profile_picture) from User model
          if (user.isSocialLogin == true) {
            if (user.fullName != null && user.fullName!.isNotEmpty) {
              await storage.writeString(
                  SharePreferenceConst.socialFullName, user.fullName!);
            }
            // Save profile picture from API
            if (user.profilePicture != null &&
                user.profilePicture!.isNotEmpty) {
              await storage.writeString(
                  SharePreferenceConst.socialProfilePicture,
                  user.profilePicture!);
            }
          }
          if (user.mobileNumber != null) {
            await storage.writeString(
                SharePreferenceConst.mobile, user.mobileNumber!);
            await storage.writeString(
                SharePreferenceConst.mobileNumber, user.mobileNumber!);
          }
          if (user.userType != null) {
            await storage.writeString(
                SharePreferenceConst.userType, user.userType!);
          }

          // Boolean flags
          if (user.isSocialLogin != null) {
            await storage.writeBool(
                SharePreferenceConst.isSocialLogin, user.isSocialLogin!);
          }
        }

        // Navigate based on is_personal_details
        bool isPersonalDetailsCompleted = user?.isPersonalDetails ?? false;

        // Prepare social login data to pass to profile screen
        Map<String, dynamic> socialData = {};
        if (user?.isSocialLogin == true) {
          socialData = {
            'fullName': user?.fullName ?? '',
            'profilePicture': user?.profilePicture ?? '',
          };
        }

/*        if (isPersonalDetailsCompleted) {
          Get.offAllNamed(AppRoutes.main);
        } else {
            Get.offAllNamed(AppRoutes.profile, arguments: socialData);
        }*/

        if (isPersonalDetailsCompleted) {
          await AnalyticsService.instance.setUserProfile(
            loginState: 'logged_in',
            userId: user?.id,
            persona: 'end_user',
            city: await getCityFromAddress(user!.address.toString()),
            plan: '',
            registrationType: user.registrationType == 'email'
                ? 'regular'
                : (user.registrationType ?? 'regular'),
          );
          Get.offAll(() => MainScreen());
        } else {
          Get.offAll(
            () => const ProfileView(),
            binding: ProfileBinding(),
            arguments: socialData,
          );
        }
      } else {
        // Show error message if registration failed
        showResponseDialog(
          message: response.message,
          title: 'Error',
          isError: true,
          showButton: true,
          onOkPressed: () {
            // dispose();
          },
        );
      }
    } catch (e) {
      showResponseDialog(
        message: "Error processing social registration response: $e",
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {
          // dispose();
        },
      );
    }
  }

  Future<String?> getCityFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        double lat = locations.first.latitude;
        double lng = locations.first.longitude;

        List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

        if (placemarks.isNotEmpty) {
          return placemarks.first.locality!.toLowerCase(); // return city
        }
      }
    } catch (e) {
      print("Error: $e");
    }

    return null;
  }

  Future<void> continueWithApple() async {
    try {
      final isAvailable = await _socialAuthService.isAppleSignInAvailable();

      if (!isAvailable) {
        showResponseDialog(
          message: 'Apple Sign In is not available on this device',
          title: 'Error',
          isError: true,
          showButton: true,
        );
        return;
      }

      final userInfo = await _socialAuthService.signInWithApple();

      if (userInfo == null) {
        // User cancelled sign-in
        return;
      }

      final socialId = userInfo['id'] ?? '';
      final email = userInfo['email'] ?? '';

      if (socialId.isEmpty || email.isEmpty) {
        showResponseDialog(
          message: 'Unable to retrieve Apple account information',
          title: 'Error',
          isError: true,
          showButton: true,
        );
        return;
      }

      // For registration, we'll directly proceed to social registration
      await _handleSocialRegistration(
        email: email,
        socialType: 'apple',
        socialId: socialId,
        fullName: userInfo['displayName'],
        profilePicture: userInfo['photoUrl'],
      );
    } catch (e) {
      // showResponseDialog(
      //   message: 'Apple sign-in failed: ${e.toString()}',
      //   title: 'Error',
      //   isError: true,
      //   showButton: true,
      // );
    }
  }

  void navigateToLogin() {
    Get.off(
      () => const LoginView(),
      binding: LoginBinding(),
    );
  }

  @override
  void onClose() {
    // Dispose controllers safely
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
