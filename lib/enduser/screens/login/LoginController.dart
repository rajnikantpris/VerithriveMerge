import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/core/base/base_controller.dart';
import 'package:verithrive_dev/enduser/utils/common_dialog.dart';
import 'dart:io';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../../../services/social_auth_service.dart';
import '../../data/repository/project_repository.dart';
import '../../network/exceptions/base_exception.dart';
import '../../utils/api_services.dart';
import '../../data/model/login_model.dart';
import '../../core/values/sharePrefrenceConst.dart';
import 'package:verithrive_dev/services/storage_service.dart';
import '../forgot_password/ForgotPasswordBinding.dart';
import '../forgot_password/ForgotPasswordView.dart';
import '../register/RegisterView.dart';
import '../register/register_binding.dart';
import '../main/MainScreen.dart';
import '../profile/ProfileBinding.dart';
import '../profile/ProfileView.dart';
import 'dart:convert';

import '../therapy_details/TherapistDetailController.dart';

class LoginController extends BaseController {
  late final formKey = GlobalKey<FormState>();

  final ProjectRepository _repository =
      Get.find(tag: (ProjectRepository).toString());
  final StorageService? _storageService =
      Get.isRegistered<StorageService>() ? Get.find<StorageService>() : null;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final SocialAuthService _socialAuthService = SocialAuthService();

  final isPasswordVisible = false.obs;
  final rememberMe = false.obs;
  final isLoading = false.obs;

  String guestUser = "";

  @override
  void onInit() {
    super.onInit();
    if(Get.arguments != null) {
      guestUser = Get.arguments;
    }
    _loadRememberMeData();
  }

  // Load saved email, password, and remember me state
  Future<void> _loadRememberMeData() async {
    try {
      final storage = _storageService;
      if (storage == null) return;

      final isRememberMe =
          storage.readBool(SharePreferenceConst.rememberMe) ?? false;

      if (isRememberMe) {
        rememberMe.value = true;

        // Load saved email
        final savedEmail =
            storage.readString(SharePreferenceConst.savedEmail) ?? '';
        if (savedEmail.isNotEmpty) {
          emailController.text = savedEmail;
        }

        // Load saved password
        final savedPassword =
            storage.readString(SharePreferenceConst.savedPassword) ?? '';
        if (savedPassword.isNotEmpty) {
          passwordController.text = savedPassword;
        }
      }
    } catch (e) {
      // Ignore errors when loading
      print('Error loading remember me data: $e');
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter email";
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter password';
    }
    // // You can tighten these rules to match register if you want
    // if (value.length < 6) {
    //   return 'Password must be at least 6 characters';
    // }
    return null;
  }

  void loginApiCall() {
    // Get.toNamed(AppRoutes.main);
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;

    callLoginService();
  }

  Future<void> onGoogleSignIn() async {
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

      // Check social account first
      await _checkSocialAccount(
        socialId: socialId,
        socialType: 'google',
        email: email,
        userInfo: userInfo,
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

  Future<void> onAppleSignIn() async {
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

      // Check social account first
      await _checkSocialAccount(
        socialId: socialId,
        socialType: 'apple',
        email: email,
        userInfo: userInfo,
      );
    } catch (e) {
      showResponseDialog(
        message: 'Apple sign-in failed: ${e.toString()}',
        title: 'Error',
        isError: true,
        showButton: true,
      );
    }
  }

  /// Check social account before proceeding with login/signup
  Future<void> _checkSocialAccount({
    required String socialId,
    required String socialType,
    required String email,
    required Map<String, String?> userInfo,
  }) async {
    Map<String, dynamic> toJson() {
      final Map<String, dynamic> data = <String, dynamic>{};
      data['social_id'] = socialId;
      data['social_type'] = socialType;
      data['email'] = email;
      return data;
    }

    // For end user, we'll directly proceed to social login since check API may not be available
    await _handleSocialLogin(
      email: email,
      socialType: socialType,
      socialId: socialId,
      fullName: userInfo['displayName'],
      profilePicture: userInfo['photoUrl'],
    );
  }

  /// Handle social login (Google or Apple)
  Future<void> _handleSocialLogin({
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
      onSuccess: _handleLoginResponseSuccess,
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

  void navigateToRegister() {
    Get.to(
      () => const RegisterView(),
      binding: RegisterBinding(),
    );
  }

  void navigateToForgotPassword() {
    Get.to(
      () => ForgotPasswordView(),
      binding: ForgotPasswordBinding(),
    );
  }

/*  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }*/

  void callLoginService() {

    if (!(formKey.currentState?.validate() ?? false)) return;

    Map<String, dynamic> toJson() {
      final Map<String, dynamic> data = <String, dynamic>{};
      data['email'] = emailController.value.text.trim();
      data['password'] = passwordController.value.text.trim();
      data['user_type'] = 'normal';
      return data;
    }

    var service = _repository.sendPostApiRequest(toJson, login, false);

    callDataService(service,
        onSuccess: _handleLoginResponseSuccess,
        onError: handleOnError,
        isShowLoading: true);
  }

  void toggleRememberMe(bool? value) {
    rememberMe.value = value ?? false;
  }

  Future<void> _handleLoginResponseSuccess(dynamic baseResponse,
      [File? profileImageFile]) async {
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
          // await storage.writeString('token', loginData.token);

          // Save remember me data if checkbox is checked
          if (rememberMe.value) {
            await storage.writeBool(SharePreferenceConst.rememberMe, true);
            await storage.writeString(
              SharePreferenceConst.savedEmail,
              emailController.text.trim(),
            );
            await storage.writeString(
              SharePreferenceConst.savedPassword,
              passwordController.text.trim(),
            );
          } else {
            // Clear remember me data if unchecked
            await storage.writeBool(SharePreferenceConst.rememberMe, false);
            await storage.remove(SharePreferenceConst.savedEmail);
            await storage.remove(SharePreferenceConst.savedPassword);
          }
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
          if (user.timezone != null) {
            await storage.writeString(
                SharePreferenceConst.TimeZone, user.timezone!);
          }

          final userType = user.userType;
          if (userType != null && userType.isNotEmpty) {
            await _storageService?.writeString('userType', userType);
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

        if(guestUser.isNotEmpty && guestUser == "guest"){
          final TherapistDetailController controller = Get.put(TherapistDetailController());
          controller.getPreferenceDetails();
          Get.back();
        } else {
          // Navigate based on is_personal_details
          bool isPersonalDetailsCompleted = user?.isPersonalDetails ?? false;
          // Prepare social login data to pass to profile screen
          Map<String, dynamic> socialData = {};
          if (user?.isSocialLogin == true) {
            socialData = {
              'fullName': user?.fullName ?? '',
              'profilePicture': user?.profilePicture ?? '',
              'profileImageFile': profileImageFile,
            };
          }

          if (isPersonalDetailsCompleted) {
            Get.offAll(() => MainScreen());
          } else {
            Get.offAll(
                  () => const ProfileView(),
              binding: ProfileBinding(),
              arguments: socialData,
            );
          }
          update();
        }
      } else {
        // Show error message if login failed
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
        message: "Error processing login response" + e.toString(),
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
}
