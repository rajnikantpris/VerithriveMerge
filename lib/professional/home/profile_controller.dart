import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/api_response.dart';
import '../../api/user_api_service.dart';
import '../../common/base_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/storage_service.dart';
import '../../services/social_auth_service.dart';
import '../../theme/colors.dart';
import '../../theme/fonts.dart';
import '../../theme/font_sizes.dart';
import '../../theme/hight_width_sizes.dart';
import '../../theme/image_paths.dart';
import '../../widgets/response_dialog.dart';

class ProfileController extends BaseController {
  ProfileController([UserApiService? userApiService])
      : _userApiService = userApiService ??
            (Get.isRegistered<UserApiService>()
                ? Get.find<UserApiService>()
                : throw Exception('UserApiService not registered'));

  final UserApiService _userApiService;
  final SocialAuthService _socialAuthService = SocialAuthService();

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
    // Sign out from Google account first
    try {
      await _socialAuthService.signOutSocialProviders();
    } catch (e) {
      debugPrint('Error signing out from Google: $e');
    }
    
    // Clear stored token if available
    if (Get.isRegistered<StorageService>()) {
      final storage = Get.find<StorageService>();
      await storage.writeString('access_token', '');
    }

    // Navigate to select user page
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
