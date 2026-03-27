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
import 'messages_controller.dart';
import 'home_controller.dart';
import 'calendar_controller.dart';

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

  @override
  void onInit() {
    super.onInit();
    fetchProfileDetails();
  }

  /// Fetch user profile details from API
  Future<void> fetchProfileDetails() async {
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
            _storageService!.writeString('user_data', jsonEncode(data));
            
            // Also update notification status in storage for consistency across the app
            if (data.containsKey('is_notification')) {
              _storageService!.writeBool('is_notification', data['is_notification'] as bool);
            }
          }
          debugPrint('Profile details fetched successfully');
        }
      },
      showLoader: userProfile.value == null, // Show loader only on first fetch
    );
  }

  /// Static list representing the profile menu options.
  final List<ProfileItem> items = const [
    ProfileItem(title: 'Your profile', asset: AppImages.profileUser),
    ProfileItem(title: 'Bank details', asset: AppImages.profileBank),
    ProfileItem(title: 'Subscription', asset: AppImages.profileTicket),
    ProfileItem(title: 'Notification', asset: AppImages.profileNotification),
    ProfileItem(title: 'Account', asset: AppImages.profileSettings),
    ProfileItem(title: 'Log out', asset: AppImages.profileLogout),
  ];

  void onItemTap(ProfileItem item) {
    // Hook for future navigation or actions per item.
    debugPrint('Tapped on ${item.title}');

    if (item.title == 'Your profile') {
      Get.toNamed(Routes.yourProfile);
    } else if (item.title == 'Bank details') {
      Get.toNamed(Routes.bankAccount);
    } else if (item.title == 'Subscription') {
      Get.toNamed(Routes.profileSubscription);
    } else if (item.title == 'Notification') {
      Get.toNamed(Routes.notificationSettings);
    } else if (item.title == 'Account') {
      Get.toNamed(Routes.account);
    } else if (item.title == 'Log out') {
      showLogoutDialog(onLogout);
    }
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
