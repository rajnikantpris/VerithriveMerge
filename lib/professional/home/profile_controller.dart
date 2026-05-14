import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../api/api_response.dart';
import '../../api/user_api_service.dart';
import '../../common/base_controller.dart';
import '../../enduser/screens/message/socket_service.dart';
import '../../models/login_response_model.dart';
import '../../routes/app_routes.dart';
import '../../services/storage_service.dart';
import '../../services/social_auth_service.dart';
import '../../services/socket_service.dart';
import '../../theme/colors.dart';
import '../../theme/fonts.dart';
import '../../theme/font_sizes.dart';
import '../../theme/hight_width_sizes.dart';
import '../../theme/image_paths.dart';
import '../../widgets/response_dialog.dart';
import '../strip_account_create/strip_account_create_webview.dart';
import 'messages_controller.dart';
import '../../services/analytics_service.dart';
import 'calendar_controller.dart';
import 'home_controller.dart';

class ProfileController extends BaseController {
  ProfileController([UserApiService? userApiService])
      : _userApiService = userApiService ??
            (Get.isRegistered<UserApiService>()
                ? Get.find<UserApiService>()
                : throw Exception('UserApiService not registered'));

  final UserApiService _userApiService;
  final SocialAuthService _socialAuthService = SocialAuthService();
  final StorageService? _storageService =
      Get.isRegistered<StorageService>() ? Get.find<StorageService>() : null;

  final Rxn<UserModel> userProfile = Rxn<UserModel>();

  /// Fetch user profile details from API
  Future<void> fetchProfileDetails({bool? showStripeDialog}) async {
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.getProfileDetails(),
      onSuccess: (response) {
        if (response.success && response.data != null) {
          final data = response.data as Map<String, dynamic>;
          userProfile.value = UserModel.fromJson(data);

          // Optionally update storage with the latest user data
          if (_storageService != null) {
            // StorageService uses specific typed methods.
            // Encode the map to JSON string before saving via writeString.
            _storageService.writeString('user_data', jsonEncode(data));

            // Also update notification status in storage for consistency across the app
            if (data.containsKey('is_notification')) {
              _storageService.writeBool(
                'is_notification',
                data['is_notification'] as bool,
              );
            }
          }
          debugPrint('Profile details fetched successfully');
        }
      },
      showLoader: showStripeDialog ?? false, // Show loader only on first fetch
    );
  }

  /// Static list representing the profile menu options.
  final List<ProfileItem> items = const [
    ProfileItem(title: 'Your profile', asset: AppImages.profileUser),
    ProfileItem(title: 'Bank details', asset: AppImages.profileBank),
    ProfileItem(title: 'Subscription', asset: AppImages.profileTicket),
    ProfileItem(
        title: 'Transaction Summary', asset: AppImages.transactionSummary),
    ProfileItem(title: 'Notifications', asset: AppImages.profileNotification),
    ProfileItem(title: 'Account', asset: AppImages.profileSettings),
    ProfileItem(title: 'Log out', asset: AppImages.profileLogout),
  ];

  void onItemTap(ProfileItem item) async {
    // Hook for future navigation or actions per item.
    debugPrint('Tapped on ${item.title}');

    if (item.title == 'Your profile') {
      Get.toNamed(Routes.yourProfile);
    } else if (item.title == 'Bank details') {
      await _handleBankDetailsTap();
    } else if (item.title == 'Subscription') {
      await _handleSubscriptionTap();
    } else if (item.title == 'Transaction Summary') {
      Get.toNamed(Routes.transactionSummary);
    } else if (item.title == 'Notifications') {
      Get.toNamed(Routes.notificationSettings);
    } else if (item.title == 'Account') {
      Get.toNamed(Routes.account);
    } else if (item.title == 'Log out') {
      showLogoutDialog(onLogout);
    }
  }

  Future<void> _handleBankDetailsTap() async {
    String? cleanString(dynamic value) {
      if (value == null) return null;
      final raw = value.toString().trim();
      if (raw.length >= 2 &&
          ((raw.startsWith('"') && raw.endsWith('"')) ||
              (raw.startsWith("'") && raw.endsWith("'")))) {
        return raw.substring(1, raw.length - 1).trim();
      }
      return raw;
    }

    Map<String, dynamic>? readProfileMap() {
      final raw = _storageService?.readString('user_data');
      if (raw == null || raw.trim().isEmpty) return null;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
        return null;
      } catch (_) {
        return null;
      }
    }

    Map<String, dynamic>? profile = readProfileMap();
    final stripeDetails = profile?['stripeDetails'];

    String? connectStatus = cleanString(
      stripeDetails is Map<String, dynamic>
          ? stripeDetails['stripe_connect_status']
          : null,
    );
    connectStatus ??= cleanString(profile?['stripe_connect_status']);

    String? onboardingUrl = cleanString(
      stripeDetails is Map<String, dynamic>
          ? stripeDetails['onboarding_link']
          : null,
    );
    onboardingUrl ??= cleanString(profile?['onboarding_link']);

    final connectStatusRaw = connectStatus?.toLowerCase();

    if (connectStatusRaw != 'completed' &&
        onboardingUrl != null &&
        onboardingUrl.isNotEmpty) {
      final String url = onboardingUrl;

      await showDialog(
        context: Get.context!,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (BuildContext context) {
          return PopScope(
            canPop: false,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(
                horizontal: HightWidthSizes.setValue_16,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColor.white,
                  borderRadius:
                      BorderRadius.circular(HightWidthSizes.setValue_10),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: HightWidthSizes.setValue_10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(HightWidthSizes.setValue_24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Get Started with Stripe',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.rubikMedium,
                        fontWeight: FontWeight.w500,
                        fontSize: FontSizes.setFontValue_20,
                        color: AppColor.color_2D3648,
                      ),
                    ),
                    SizedBox(height: HightWidthSizes.setValue_16),
                    Text(
                      'Please complete your Stripe onboarding to enable charges and payouts.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.rubikRegular,
                        fontWeight: FontWeight.w400,
                        fontSize: FontSizes.setFontValue_14,
                        color: AppColor.color_2D2D2D,
                      ),
                    ),
                    SizedBox(height: HightWidthSizes.setValue_24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();

                          final result = await Get.to(
                              () => StripAccountWebViewScreen(url: url));

                          // When returning from WebView, check result and navigate if successful
                          if (result == 'success') {
                            await fetchProfileDetails(showStripeDialog: true);
                            showResponseDialog(
                              message: 'Stripe account created successfully.',
                              title: 'Stripe Account Created',
                              showButton: true,
                              onOkPressed: () =>
                                  Get.toNamed(Routes.bankAccount),
                            );
                          } else if (result == 'failed') {
                            await fetchProfileDetails(showStripeDialog: true);
                            showResponseDialog(
                              message:
                                  'Stripe account create failed. Please try again.',
                              title: 'Stripe Account Create Failed',
                              isError: true,
                              showButton: true,
                              onOkPressed: () {},
                            );
                          }

                          // await Get.to(
                          //   () => ProfessionalWebViewScreen(url: url),
                          // );

                          // await fetchProfileDetails(showStripeDialog: true);
                          // profile = readProfileMap();
                          // final refreshedStripeDetails = profile?['stripeDetails'];

                          // String? refreshedStatus = cleanString(
                          //   refreshedStripeDetails is Map<String, dynamic>
                          //       ? refreshedStripeDetails['stripe_connect_status']
                          //       : null,
                          // );
                          // refreshedStatus ??=
                          //     cleanString(profile?['stripe_connect_status']);

                          // if (refreshedStatus?.toLowerCase() == 'completed') {
                          //   Get.toNamed(Routes.bankAccount);
                          // } else {
                          //   showResponseDialog(
                          //     title: 'Stripe onboarding',
                          //     message:
                          //         'Please complete your Stripe onboarding to access bank details.',
                          //     isError: true,
                          //     showButton: true,
                          //   );
                          // }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.color_2FC4B2,
                          foregroundColor: AppColor.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            vertical: HightWidthSizes.setValue_14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              HightWidthSizes.setValue_10,
                            ),
                          ),
                        ),
                        child: Text(
                          'Continue',
                          style: TextStyle(
                            fontFamily: AppFonts.rubikMedium,
                            fontWeight: FontWeight.w500,
                            fontSize: FontSizes.setFontValue_16,
                            color: AppColor.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: HightWidthSizes.setValue_12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: HightWidthSizes.setValue_14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              HightWidthSizes.setValue_10,
                            ),
                          ),
                        ),
                        child: Text(
                          'Later',
                          style: TextStyle(
                            fontFamily: AppFonts.rubikRegular,
                            fontWeight: FontWeight.w400,
                            fontSize: FontSizes.setFontValue_16,
                            color: AppColor.color_B53232,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
      return;
    }

    Get.toNamed(Routes.bankAccount);
  }

  Future<void> _handleSubscriptionTap() async {
    Map<String, dynamic>? readProfileMap() {
      final raw = _storageService?.readString('user_data');
      if (raw == null || raw.trim().isEmpty) return null;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
        return null;
      } catch (_) {
        return null;
      }
    }

    Map<String, dynamic>? profile = readProfileMap();
    final isApproved = profile?['is_approved'] ?? profile?['isApproved'] ?? false;

    // If approved, directly navigate to subscription screen
    if (isApproved) {
      Get.toNamed(Routes.profileSubscription);
      return;
    }

    // If not approved, show the dialog
    showResponseDialog(
      title: 'Application Under Review',
      message:
          'Your professional application has been successfully submitted. Please wait while we review your application. Once it is approved, you will be able to access and use our services.',
      isError: false,
      showButton: true,
    );
  }

  Future<void> onLogout() async {
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.logout(),
      showLoader: true,
      onComplete: () {
        resetState();
      },
      mapErrorMessage: (error) {
        if (error is ApiResponse) {
          final statusCode = error.statusCode;

          if (statusCode == 401) {
            return 'Session expired. Please log in again.';
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
            : 'Failed to log out. Please try again.';
        showResponseDialog(
          message: errorMsg,
          title: 'Error',
          isError: true,
          showButton: true,
          onOkPressed: () {
            // Even if logout API fails, clear local storage and navigate
            _clearLocalDataAndNavigate();
          },
        );
      },
      onSuccess: (response) async {
        if (response.success) {
          // Analytics: Log logout event at the moment logout API succeeds.

          await AnalyticsService.instance.clearUser();

          // Clear local storage and navigate
          await _clearLocalDataAndNavigate();
        } else {
          // API returned error but still clear local data
          await _clearLocalDataAndNavigate();
          showResponseDialog(
            message: response.errorMessage,
            title: 'Error',
            isError: true,
            showButton: true,
            onOkPressed: () {
              // Navigation already handled
            },
          );
        }
      },
    );
  }

  Future<void> _clearLocalDataAndNavigate() async {
    // 1. Reset socket services first (IMPORTANT: Disconnect before deleting)
    if (Get.isRegistered<EndUserSocketService>()) {
      final endUserSocket = Get.find<EndUserSocketService>();
      endUserSocket.disconnect();
      Get.delete<EndUserSocketService>();
      print('EndUserSocketService disconnected and removed');
    }

    if (Get.isRegistered<SocketService>()) {
      final professionalSocket = Get.find<SocketService>();
      professionalSocket.disconnect();
      Get.delete<SocketService>();
      print('Professional SocketService disconnected and removed');
    }

    // 2. Explicitly delete ALL professional controllers to clear their memory state
    if (Get.isRegistered<MessagesController>()) {
      Get.delete<MessagesController>();
      print('MessagesController deleted');
    }

    if (Get.isRegistered<HomeController>()) {
      Get.delete<HomeController>();
      print('HomeController deleted');
    }

    if (Get.isRegistered<CalendarController>()) {
      Get.delete<CalendarController>();
      print('CalendarController deleted');
    }

    // 3. Sign out from social providers
    try {
      await _socialAuthService.signOutSocialProviders();
    } catch (e) {
      debugPrint('Error signing out from social providers: $e');
    }

    // 4. Clear stored data except remember me credentials
    if (Get.isRegistered<StorageService>()) {
      final storage = Get.find<StorageService>();

      // Define keys to keep (all remember me data)
      final keysToKeep = [
        'professional_remember_me',
        'professional_saved_email',
        'professional_saved_password',
        'rememberMe', // End-user key
        'savedEmail', // End-user key
        'savedPassword', // End-user key
      ];

      await storage.clearAllExcept(keysToKeep);
    }

    // 5. Final cleanup: reset current route and navigate
    // Use offAllNamed to ensure a fresh start on the login screen
    Get.offAllNamed(Routes.selectUser);
  }
}

void showLogoutDialog(VoidCallback onConfirm) {
  showDialog(
    context: Get.context!,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext context) {
      return PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: HightWidthSizes.setValue_16,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(HightWidthSizes.setValue_10),
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: HightWidthSizes.setValue_10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: EdgeInsets.all(HightWidthSizes.setValue_24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title
                Text(
                  'Log out?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.rubikMedium,
                    fontWeight: FontWeight.w500,
                    fontSize: FontSizes.setFontValue_20,
                    color: AppColor.color_2D3648,
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_16),

                // Body text
                Text(
                  'Are you sure you want to log out? You\'ll need to sign in again to access your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.rubikRegular,
                    fontWeight: FontWeight.w400,
                    fontSize: FontSizes.setFontValue_14,
                    color: AppColor.color_2D2D2D,
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_24),

                // No, go back button (Primary)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.color_2FC4B2,
                      foregroundColor: AppColor.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        vertical: HightWidthSizes.setValue_14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          HightWidthSizes.setValue_10,
                        ),
                      ),
                    ),
                    child: Text(
                      'No, go back',
                      style: TextStyle(
                        fontFamily: AppFonts.rubikMedium,
                        fontWeight: FontWeight.w500,
                        fontSize: FontSizes.setFontValue_16,
                        color: AppColor.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_12),

                // Yes, log out button (Destructive)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onConfirm();
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: HightWidthSizes.setValue_14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          HightWidthSizes.setValue_10,
                        ),
                      ),
                    ),
                    child: Text(
                      'Yes, log out',
                      style: TextStyle(
                        fontFamily: AppFonts.rubikRegular,
                        fontWeight: FontWeight.w400,
                        fontSize: FontSizes.setFontValue_16,
                        color: AppColor.color_B53232,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class ProfileItem {
  const ProfileItem({
    required this.title,
    required this.asset,
  });

  final String title;
  final String asset;
}
