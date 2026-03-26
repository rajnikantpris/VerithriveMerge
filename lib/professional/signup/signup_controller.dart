import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/api_response.dart';
import '../../api/user_api_service.dart';
import '../../common/base_controller.dart';
import '../../models/login_response_model.dart';
import '../../routes/app_routes.dart';
import '../../services/notification_permission_service.dart';
import '../../services/social_auth_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/response_dialog.dart';

class SignupController extends BaseController {
  SignupController(
    this._userApiService, [
    StorageService? storageService,
  ]) : _storageService = storageService ??
            (Get.isRegistered<StorageService>()
                ? Get.find<StorageService>()
                : null);

  final UserApiService _userApiService;
  final StorageService? _storageService;
  final SocialAuthService _socialAuthService = SocialAuthService();
  final NotificationPermissionService _notificationPermissionService =
      NotificationPermissionService();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final promoCodeController = TextEditingController();

  final confirmPasswordController = TextEditingController();

  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final isPromoCodeApplied = false.obs;
  final isPromoCodeValid = false.obs;
  final promoCodeMessage = ''.obs;

  late final GlobalKey<FormState> formKey;

  @override
  void onInit() {
    super.onInit();
    // Initialize formKey to ensure a new key is created each time
    formKey = GlobalKey<FormState>();
    // Ask for notification permission when signup screen opens
    _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    try {
      await _notificationPermissionService.requestNotificationPermission();
    } catch (e) {
      debugPrint('Error requesting notification permission on signup: $e');
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    promoCodeController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  Future<void> checkPromoCode() async {
    final promoCode = promoCodeController.text.trim();
    final email = emailController.text.trim();

    if (promoCode.isEmpty) {
      promoCodeMessage.value = 'Please enter a promo code';
      isPromoCodeValid.value = false;
      return;
    }

    if (email.isEmpty) {
      promoCodeMessage.value = 'Please enter your email first';
      isPromoCodeValid.value = false;
      return;
    }

    await callDataService<ApiResponse<dynamic>>(
      _userApiService.checkPromoCode(
        promoCode: promoCode,
        email: email,
      ),
      showLoader: true,
      onComplete: () {
        resetState();
      },
      mapErrorMessage: (error) {
        if (error is ApiResponse) {
          return error.errorMessage;
        }
        return mapErrorToMessage(error);
      },
      onError: (error, stack) {
        final errorMsg = errorMessage.value.isNotEmpty
            ? errorMessage.value
            : 'Failed to validate promo code';
        promoCodeMessage.value = errorMsg;
        isPromoCodeValid.value = false;
      },
      onSuccess: (response) async {
        if (response.success) {
          // Check if the promo code is actually valid from the response data
          if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            final isValid = data['is_valid'] as bool? ?? false;

            if (isValid) {
              promoCodeMessage.value =
                  response.message ?? 'Promo code applied successfully!';
              isPromoCodeValid.value = true;
              isPromoCodeApplied.value = true;
            } else {
              // Promo code is invalid (not found, expired, etc.)
              promoCodeMessage.value = response.message ?? 'Invalid promo code';
              isPromoCodeValid.value = false;
            }
          } else {
            // Fallback for unexpected response format
            promoCodeMessage.value =
                response.message ?? 'Promo code applied successfully!';
            isPromoCodeValid.value = true;
            isPromoCodeApplied.value = true;
          }
        } else {
          promoCodeMessage.value =
              response.errorMessage ?? 'Invalid promo code';
          isPromoCodeValid.value = false;
        }
      },
    );
  }

  void removePromoCode() {
    promoCodeController.clear();
    isPromoCodeApplied.value = false;
    isPromoCodeValid.value = false;
    promoCodeMessage.value = '';
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
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

  Future<void> onJoinNow() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    final email = emailController.text.trim();
    // final phone = phoneController.text.trim();
    final promoCode = promoCodeController.text.trim();
    final password = passwordController.text.trim();
    const userType = 'professional';

    await callDataService<ApiResponse<dynamic>>(
      _userApiService.sendOtp(
        email: email,
        userType: userType,
      ),
      showLoader: true,
      onComplete: () {
        // Ensure state is reset after API call completes
        resetState();
      },
      mapErrorMessage: (error) {
        if (error is ApiResponse) {
          // Handle specific HTTP status codes
          final statusCode = error.statusCode;

          if (statusCode == 429) {
            return 'Too many requests. Please wait a moment and try again.';
          }

          if (statusCode == 400) {
            return 'Invalid request. Please check your information and try again.';
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
      onError: (error, stack) {
        // Show error dialog to user
        final errorMsg = errorMessage.value.isNotEmpty
            ? errorMessage.value
            : 'Something went wrong. Please try again.';
        showResponseDialog(
          message: errorMsg,
          title: 'Error',
          isError: true,
          showButton: true,
          onOkPressed: () {
            // Get.back();
          },
        );
        // Don't reset state here - let finally block handle it
      },
      onSuccess: (response) async {
        if (response.success) {
          final messageText = response.message ?? 'OTP sent successfully';

          // Extract OTP from response data if available
          String? otp;
          if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            final otpValue = data['otp'];
            if (otpValue != null) {
              otp = otpValue.toString();
            }
          }
          // Get.toNamed(
          //   Routes.verifyEmail,
          //   arguments: {
          //     'email': email,
          //     // 'phone': phone,
          //     'promo_code': isPromoCodeValid.value ? promoCode : '',
          //     'password': password,
          //     'user_type': userType,
          //     if (otp != null) 'otp': otp,
          //   },
          // );

          showResponseDialog(
            message: messageText,
            title: 'Success',
            isError: false,
            showButton: false,
            onOkPressed: () {
              Get.toNamed(
                Routes.verifyEmail,
                arguments: {
                  'email': email,
                  // 'phone': phone,
                  'promo_code': isPromoCodeValid.value ? promoCode : '',
                  'password': password,
                  'user_type': userType,
                  if (otp != null) 'otp': otp,
                },
              );
            },
          );
        } else {
          // Handle failure case
          showResponseDialog(
            message: response.errorMessage,
            title: 'Error',
            isError: true,
            showButton: true,
            onOkPressed: () {
              // Get.back();
            },
          );
        }
      },
    );
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
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.checkSocialAccount(
        socialId: socialId,
        socialType: socialType,
        email: email,
      ),
      showLoader: true,
      onComplete: () {
        resetState();
      },
      mapErrorMessage: (error) {
        if (error is ApiResponse) {
          final statusCode = error.statusCode;

          if (statusCode == 400) {
            return 'Invalid account information. Please try again.';
          }

          if (statusCode == 404) {
            return 'Service not found. Please try again later.';
          }

          if (statusCode == 429) {
            return 'Too many attempts. Please wait and try again.';
          }

          if (statusCode != null && statusCode >= 500) {
            return 'Server error. Please try again later.';
          }

          return error.errorMessage;
        }
        return mapErrorToMessage(error);
      },
      onError: (error, stack) {
        final errorMsg = errorMessage.value.isNotEmpty
            ? errorMessage.value
            : 'Something went wrong. Please try again.';
        showResponseDialog(
          message: errorMsg,
          title: 'Error',
          isError: true,
          showButton: true,
          onOkPressed: () {
            // Get.back();
          },
        );
      },
      onSuccess: (response) async {
        if (response.success) {
          // If check passes, proceed with social login
          await _handleSocialLogin(
            email: email,
            socialType: socialType,
            socialId: socialId,
            fullName: userInfo['displayName'],
            profilePicture: userInfo['photoUrl'],
          );
        } else {
          showResponseDialog(
            message: response.errorMessage,
            title: 'Error',
            isError: true,
            showButton: true,
          );
        }
      },
    );
  }

  /// Handle social login (Google or Apple)
  /// For signup, this will create a new account or log in if account exists
  Future<void> _handleSocialLogin({
    required String email,
    required String socialType,
    required String socialId,
    String? fullName,
    String? profilePicture,
  }) async {
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.socialLogin(
        email: email,
        socialType: socialType,
        socialId: socialId,
        fullName: fullName,
        profilePicture: profilePicture,
      ),
      showLoader: true,
      onComplete: () {
        resetState();
      },
      mapErrorMessage: (error) {
        if (error is ApiResponse) {
          final statusCode = error.statusCode;

          if (statusCode == 400) {
            return 'Invalid credentials. Please try again.';
          }

          if (statusCode == 401) {
            return error.errorMessage.isNotEmpty
                ? error.errorMessage
                : 'Authentication failed. Please try again.';
          }

          if (statusCode == 404) {
            return 'Service not found. Please try again later.';
          }

          if (statusCode == 429) {
            return 'Too many attempts. Please wait and try again.';
          }

          if (statusCode != null && statusCode >= 500) {
            return 'Server error. Please try again later.';
          }

          return error.errorMessage;
        }
        return mapErrorToMessage(error);
      },
      onError: (error, stack) {
        final errorMsg = errorMessage.value.isNotEmpty
            ? errorMessage.value
            : 'Something went wrong. Please try again.';
        showResponseDialog(
          message: errorMsg,
          title: 'Error',
          isError: true,
          showButton: true,
          onOkPressed: () {
            // Get.back();
          },
        );
      },
      onSuccess: (response) async {
        if (response.success) {
          // Parse login response data
          if (response.data is! Map<String, dynamic>) {
            showResponseDialog(
              message: 'Invalid response format',
              title: 'Error',
              isError: true,
              showButton: true,
            );
            return;
          }

          // Parse response using LoginResponseModel
          LoginResponseModel loginData;
          try {
            loginData = LoginResponseModel.fromJson(
              response.data as Map<String, dynamic>,
            );
          } catch (e) {
            debugPrint('Error parsing social login response: $e');
            showResponseDialog(
              message: 'Failed to parse login response',
              title: 'Error',
              isError: true,
              showButton: true,
            );
            return;
          }

          // Extract and save token
          final token = loginData.token;
          if (token != null && token.isNotEmpty) {
            await _storageService?.writeString('access_token', token);
          }

          await _storageService?.writeString('userType', 'professional');


          // Save user ID from login response
          final userId = loginData.user?.id;
          if (userId != null && userId.isNotEmpty) {
            await _storageService?.writeString('user_id', userId);
          }

          // Save user email from login response
          final userEmail = loginData.user?.email;
          if (userEmail != null && userEmail.isNotEmpty) {
            await _storageService?.writeString('user_email', userEmail);
          }

          // Extract user flags from user model
          final userFlags = _extractUserFlagsFromModel(loginData.user);

          // Save flags to storage
          final storage = _storageService;
          if (storage != null) {
            for (final entry in userFlags.entries) {
              await storage.writeBool(entry.key, entry.value);
            }
          }

          await _cacheSocialProfileData(loginData.user);

          final successMessage =
              response.message ?? 'Account created successfully. Welcome!';

          _navigateBasedOnUserFlags(userFlags);

          // showResponseDialog(
          //   message: successMessage,
          //   title: 'Success',
          //   isError: false,
          //   showButton: false,
          //   onOkPressed: () {
          //     // Navigate based on user flags (same as login)
          //     _navigateBasedOnUserFlags(userFlags);
          //   },
          // );
        } else {
          showResponseDialog(
            message: response.errorMessage,
            title: 'Error',
            isError: true,
            showButton: true,
          );
        }
      },
    );
  }

  /// Extract user flags from UserModel (same as LoginController)
  Map<String, bool> _extractUserFlagsFromModel(UserModel? user) {
    final flags = <String, bool>{};

    if (user == null) {
      return flags;
    }

    // Extract all user flags from model with default value false
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

  /// Navigate based on user flags in priority order (same as LoginController)
  void _navigateBasedOnUserFlags(Map<String, bool> userFlags) {
    // Priority order: check flags in sequence and navigate to first incomplete step

    if (userFlags['is_personal_details'] != true) {
      Get.offAllNamed(Routes.signupPersonDetails);
      return;
    }

    // Step 1: Check if profile creation is needed (step 0)
    if (userFlags['is_profile_created'] != true) {
      Get.offAllNamed(
        Routes.signupProfileWizard,
        arguments: {'initialStep': 0},
      );
      return;
    }

    // Step 2: Check if work address is needed (step 1)
    if (userFlags['is_work_full'] != true) {
      Get.offAllNamed(
        Routes.signupProfileWizard,
        arguments: {'initialStep': 1},
      );
      return;
    }

    // Step 3: Check if professional services are needed (step 2)
    if (userFlags['is_professional_services'] != true) {
      Get.offAllNamed(
        Routes.signupProfileWizard,
        arguments: {'initialStep': 2},
      );
      return;
    }

    // Step 4: Check if qualifications are needed (step 3)
    if (userFlags['is_qualification'] != true) {
      Get.offAllNamed(
        Routes.signupProfileWizard,
        arguments: {'initialStep': 3},
      );
      return;
    }

    // Step 5: Check if personal identification is needed (step 4)
    if (userFlags['is_personal_identification'] != true) {
      Get.offAllNamed(
        Routes.signupProfileWizard,
        arguments: {'initialStep': 4},
      );
      return;
    }

    // Step 6: Check if about you is needed (step 5)
    if (userFlags['is_about_you'] != true) {
      Get.offAllNamed(
        Routes.signupProfileWizard,
        arguments: {'initialStep': 5},
      );
      return;
    }

    // Step 7: Check if payment/subscription is needed
    if (userFlags['is_payment'] != true) {
      Get.offAllNamed(Routes.subscription);
      return;
    }

    // All steps completed - navigate to home
    Get.offAllNamed(Routes.home);
  }

  Future<void> _cacheSocialProfileData(UserModel? user) async {
    final storage = _storageService;
    if (storage == null) return;

    final socialFullName = user?.fullName?.trim() ?? '';
    await storage.writeString('user_full_name', socialFullName);

    final socialProfilePicture = user?.profilePicture ?? '';
    await storage.writeString('user_profile_picture', socialProfilePicture);

    final isSocial = user?.isSocialLogin ?? false;
    await storage.writeBool('is_social_login', isSocial);
  }

  void onLogin() {
    if (Get.currentRoute != Routes.login) {
      Get.offNamed(Routes.login);
    }
  }
}
