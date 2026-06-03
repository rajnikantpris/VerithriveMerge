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
import '../../services/analytics_service.dart';
import 'package:geocoding/geocoding.dart';

class ProfessionalLoginController extends BaseController {
  ProfessionalLoginController(
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
  final passwordController = TextEditingController();

  final isPasswordVisible = false.obs;
  final rememberMe = false.obs;

  String? _pendingSocialDisplayName;

  late final GlobalKey<FormState> formKey;

  @override
  void onInit() {
    super.onInit();
    // Initialize formKey to ensure a new key is created each time
    formKey = GlobalKey<FormState>();
    // Load saved credentials if remember me was enabled
    _loadSavedCredentials();
    // Ask for notification permission when login screen opens
    // _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    try {
      await _notificationPermissionService.requestNotificationPermission();
    } catch (e) {
      debugPrint('Error requesting notification permission on login: $e');
    }
  }

  /// Load saved email, password, and remember me state
  Future<void> _loadSavedCredentials() async {
    final storage = _storageService;
    if (storage == null) return;

    final savedRememberMe =
        storage.readBool('professional_remember_me') ?? false;
    rememberMe.value = savedRememberMe;

    if (savedRememberMe) {
      final savedEmail = storage.readString('professional_saved_email');
      final savedPassword = storage.readString('professional_saved_password');

      if (savedEmail != null && savedEmail.isNotEmpty) {
        emailController.text = savedEmail;
      }
      if (savedPassword != null && savedPassword.isNotEmpty) {
        passwordController.text = savedPassword;
      }
    }
  }

  /// Save credentials if remember me is enabled
  Future<void> _saveCredentials(String email, String password) async {
    final storage = _storageService;
    if (storage == null) return;

    if (rememberMe.value) {
      await storage.writeString('professional_saved_email', email);
      await storage.writeString('professional_saved_password', password);
      await storage.writeBool('professional_remember_me', true);
    } else {
      // Clear saved credentials if remember me is unchecked
      await storage.writeString('professional_saved_email', '');
      await storage.writeString('professional_saved_password', '');
      await storage.writeBool('professional_remember_me', false);
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleRememberMe(bool? value) {
    rememberMe.value = value ?? false;
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

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    // if (value.length < 6) {
    //   return 'Password must be at least 6 characters';
    // }
    return null;
  }

  Future<void> onLogin() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    const userType = 'professional';

    await callDataService<ApiResponse<dynamic>>(
      _userApiService.login(
        email: email,
        userType: userType,
        password: password,
      ),
      showLoader: true,
      onComplete: () {
        resetState();
      },
      mapErrorMessage: (error) {
        if (error is ApiResponse) {
          final statusCode = error.statusCode;

          if (statusCode == 400) {
            return 'Invalid credentials. Please check your email and password.';
          }

          if (statusCode == 401) {
            // Use the actual error message from API response (e.g., "Invalid credentials")
            return error.errorMessage.isNotEmpty
                ? error.errorMessage
                : 'Invalid credentials. Please check your email and password.';
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
        // Skip showing dialog if error was already handled (e.g., connection timeout)
        if (shouldSkipErrorDialog(error, errorMessage.value)) {
          return;
        }

        // Show error dialog to user
        final errorMsg = errorMessage.value.isNotEmpty
            ? errorMessage.value
            : 'Something went wrong. Please try again.';
        Get.dialog(
          AlertDialog(
            title: Text('Error'),
            content: Text(errorMsg),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(Get.context!).pop(),
                child: Text('OK'),
              ),
            ],
          ),
          barrierDismissible: false,
        );
        // Don't reset state here - let finally block handle it
      },
      onSuccess: (response) async {
        if (response.success) {
          // Save credentials if remember me is checked
          await _saveCredentials(email, password);

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
            debugPrint('Error parsing login response: $e');
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

          // Always save userType as 'professional' for professional login
          await _storageService?.writeString('userType', 'professional');

          // Extract user flags from user model
          final userFlags = _extractUserFlagsFromModel(loginData.user);

          // await AnalyticsService.instance.setUserProfile(
          //   loginState: 'logged_in',
          //   userId: loginData.user?.id,
          //   city: await getCityFromAddress(loginData.user!.address.toString()),
          //   persona: AnalyticsService.resolvePersona(
          //     professionName: loginData.user?.profession_name,
          //   ),
          //   registrationType: 'regular',
          // );

          // Save flags to storage
          final storage = _storageService;
          if (storage != null) {
            for (final entry in userFlags.entries) {
              await storage.writeBool(entry.key, entry.value);
            }
          }

          final successMessage =
              response.message ?? 'Logged in successfully. Welcome back!';
          showResponseDialog(
            message: successMessage,
            title: 'Success',
            isError: false,
            showButton: false,
            onOkPressed: () {
              // Determine navigation based on user flags (in priority order)
              _navigateBasedOnUserFlags(userFlags, 'regular', loginData.user);
            },
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

  void onForgotPassword() {
    Get.toNamed(Routes.forgotPassword);
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
      // showResponseDialog(
      //   message: 'Apple sign-in failed: ${e.toString()}',
      //   title: 'Error',
      //   isError: true,
      //   showButton: true,
      // );
    }
  }

  /// Check social account before proceeding with login/signup
  Future<void> _checkSocialAccount({
    required String socialId,
    required String socialType,
    required String email,
    required Map<String, String?> userInfo,
  }) async {
    final resolvedFullName = await _resolveSocialFullName(userInfo);

    await callDataService<ApiResponse<dynamic>>(
      _userApiService.checkSocialAccount(
        socialId: socialId,
        socialType: socialType,
        email: email,
        fullName: resolvedFullName.isNotEmpty ? resolvedFullName : null,
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
        // Skip showing dialog if error was already handled (e.g., connection timeout)
        if (shouldSkipErrorDialog(error, errorMessage.value)) {
          return;
        }

        final errorMsg = errorMessage.value.isNotEmpty
            ? errorMessage.value
            : 'Something went wrong. Please try again.';
        Get.dialog(
          AlertDialog(
            title: Text('Error'),
            content: Text(errorMsg),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(Get.context!).pop(),
                child: Text('OK'),
              ),
            ],
          ),
          barrierDismissible: false,
        );
      },
      onSuccess: (response) async {
        if (response.success) {
          final resolvedFullName = await _resolveSocialFullName(userInfo);
          _pendingSocialDisplayName =
              resolvedFullName.isNotEmpty ? resolvedFullName : null;

          // If check passes, proceed with social login
          await _handleSocialLogin(
            email: email,
            socialType: socialType,
            socialId: socialId,
            fullName: _pendingSocialDisplayName,
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
  Future<void> _handleSocialLogin({
    required String email,
    required String socialType,
    required String socialId,
    String? fullName,
    String? profilePicture,
  }) async {
    await _persistSocialDisplayNameIfNeeded(fullName);
    final resolvedFullName = _socialAuthService.resolveSocialFullName(
      credentialDisplayName: fullName,
    );

    await callDataService<ApiResponse<dynamic>>(
      _userApiService.socialLogin(
        email: email,
        socialType: socialType,
        socialId: socialId,
        fullName: resolvedFullName.isNotEmpty ? resolvedFullName : null,
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
        // Skip showing dialog if error was already handled (e.g., connection timeout)
        if (shouldSkipErrorDialog(error, errorMessage.value)) {
          return;
        }

        final errorMsg = errorMessage.value.isNotEmpty
            ? errorMessage.value
            : 'Something went wrong. Please try again.';
        Get.dialog(
          AlertDialog(
            title: Text('Error'),
            content: Text(errorMsg),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(Get.context!).pop(),
                child: Text('OK'),
              ),
            ],
          ),
          barrierDismissible: false,
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

          final userType = loginData.user?.userType;
          // Always save userType as 'professional' for professional login
          await _storageService?.writeString('userType', 'professional');

          // Also save the userType from API if available (for debugging/backup)
          if (userType != null && userType.isNotEmpty) {
            debugPrint('API userType: $userType');
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

          _pendingSocialDisplayName = null;

          final successMessage =
              response.message ?? 'Logged in successfully. Welcome back!';
          showResponseDialog(
            message: successMessage,
            title: 'Success',
            isError: false,
            showButton: false,
            onOkPressed: () {
              // Determine navigation based on user flags (in priority order)
              _navigateBasedOnUserFlags(userFlags, socialType, loginData.user);
            },
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

  void onCreateAccount() {
    if (Get.currentRoute != Routes.signup) {
      Get.offNamed(Routes.signup);
    }
  }

  /// Extract user flags from UserModel
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

  /// Navigate based on user flags in priority order
  Future<void> _navigateBasedOnUserFlags(
      Map<String, bool> userFlags, String socialType, UserModel? user) async {
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
    // if (userFlags['is_payment'] != true) {
    //   Get.offAllNamed(Routes.subscription);
    //   return;
    // }

    await AnalyticsService.instance.setUserProfile(
      loginState: 'logged_in',
      userId: user?.id,
      city: await getCityFromAddress(user!.address.toString()),
      persona: AnalyticsService.resolvePersona(
        professionName: user.profession_name,
      ),
      registrationType:
          socialType, // Use the actual social type ('google' or 'apple')
    );

    // All steps completed - navigate to home
    Get.offAllNamed(Routes.home);
  }

  Future<void> _persistSocialDisplayNameIfNeeded(String? displayName) async {
    if (displayName == null || displayName.trim().isEmpty) return;
    await _socialAuthService.persistSocialDisplayName(displayName.trim());
  }

  /// Resolves full name from Google/Apple credential and stored Apple name.
  Future<String> _resolveSocialFullName(Map<String, String?> userInfo) async {
    final displayName = userInfo['displayName']?.trim();
    await _persistSocialDisplayNameIfNeeded(displayName);
    return _socialAuthService.resolveSocialFullName(
      credentialDisplayName: displayName,
    );
  }

  Future<void> _cacheSocialProfileData(UserModel? user) async {
    final storage = _storageService;
    if (storage == null) return;

    final socialFullName = _socialAuthService.resolveSocialFullName(
      apiFullName: user?.fullName,
      credentialDisplayName: _pendingSocialDisplayName,
    );
    await storage.writeString('user_full_name', socialFullName);

    final socialProfilePicture = user?.profilePicture ?? '';
    await storage.writeString('user_profile_picture', socialProfilePicture);

    final isSocial = user?.isSocialLogin ?? false;
    await storage.writeBool('is_social_login', isSocial);
  }
}
