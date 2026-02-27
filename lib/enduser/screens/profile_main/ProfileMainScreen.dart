import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import 'package:verithrive_dev/enduser/utils/app_text_styles.dart';
import '../account/AccountScreen.dart';
import '../account/AccountBinding.dart';
import '../card_details/CardDetailsScreen.dart';
import '../card_details/CardDetailsBinding.dart';
import '../notifications/NotificationsScreen.dart';
import '../notifications/NotificationsBinding.dart';
import '../update_profile/UpdateProfileScreen.dart';
import '../update_profile/UpdateProfileBinding.dart';
import 'ProfileMainController.dart';

class ProfileMainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileMainController>(tag: 'profile');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 4, // 🔴 Add shadow depth (try 2-8)
        shadowColor: Colors.black.withOpacity(
          0.1,
        ), // Optional: customize shadow color
        scrolledUnderElevation: 4,
        centerTitle: true,
        title: Text(
          "Profile",
          style: AppTextStyles.mediumTextStyle(
            fontSize: 20,
            color: AppColors.black,
          ),
        ),
      ),
      body: Obx(
        () => controller.isLoading.value
            ? Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  _buildProfileOption(
                    icon: AppAssets.your_profile,
                    title: 'Your profile',
                    onTap: () => Get.to(() => UpdateProfileScreen(), binding: UpdateProfileBinding()),
                  ),
                  Divider(height: 1, color: AppColors.lightGrey),
                  _buildProfileOption(
                    icon: AppAssets.card_details,
                    title: 'Card details',
                    onTap: () => Get.to(() => CardDetailsScreen(), binding: CardDetailsBinding()),
                  ),
                  Divider(height: 1, color: AppColors.lightGrey),
                  _buildProfileOption(
                    icon: AppAssets.notification,
                    title: 'Notifications',
                    onTap: () => Get.to(() => NotificationsScreen(), binding: NotificationsBinding()),
                  ),
                  Divider(height: 1, color: AppColors.lightGrey),
                  _buildProfileOption(
                    icon: AppAssets.settings, // Using filter as settings icon
                    title: 'Account',
                    onTap: () => Get.to(() => AccountScreen(), binding: AccountBinding()),
                  ),
                  Divider(height: 1, color: AppColors.lightGrey),
                  _buildProfileOption(
                    icon: AppAssets.logout,
                    title: 'Log out',
                    onTap: () {
                      showLogoutDialog(() {
                        controller.logoutApiCall();
                      },);
                    },
                  ),
                  Divider(height: 1, color: AppColors.lightGrey),
                ],
              ),
      ),
    );
  }

  Widget _buildProfileOption({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            SvgPicture.asset(icon, width: 20, height: 20),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.regularTextStyle(
                  fontSize: 16,
                  color: AppColors.color454545,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.grey, size: 24),
          ],
        ),
      ),
    );
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
              horizontal: 16,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Title
                  Text(
                    'Log out?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Rubik",
                      fontWeight: FontWeight.w500,
                      fontSize: 20,
                      color: AppColors.color2D3648,
                    ),
                  ),
                  SizedBox(height:16),

                  // Body text
                  Text(
                    'Are you sure you want to log out? You\'ll need to sign in again to access your account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: "Rubik",
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: AppColors.color2D2D2D,
                    ),
                  ),
                  SizedBox(height: 24),

                  // No, go back button (Primary)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.color2FC4B2,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            10,
                          ),
                        ),
                      ),
                      child: Text(
                        'No, go back',
                        style: TextStyle(
                          fontFamily: "Rubik",
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

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
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            10,
                          ),
                        ),
                      ),
                      child: Text(
                        'Yes, log out',
                        style: TextStyle(
                          fontFamily: "Rubik",
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                          color: AppColors.colorB53232,
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
}
