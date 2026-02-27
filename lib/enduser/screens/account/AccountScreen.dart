import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/routes/app_routes.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import 'package:verithrive_dev/enduser/utils/app_text_styles.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import '../change_password/ChangePasswordBinding.dart';
import '../change_password/ChangePasswordScreen.dart';
import '../../utils/AppText.dart';
import '../../utils/CustomTextField.dart';
import 'AccountController.dart';

class AccountScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AccountController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(AppAssets.back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Account',
          style: AppTextStyles.mediumTextStyle(
            fontSize: 20,
            color: AppColors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email field
                    CustomTextField(
                      controller: controller.emailController,
                      label: AppText.email,
                      hint: AppText.enterEmail,
                      keyboardType: TextInputType.emailAddress,
                      readOnly: true,
                      enabled: false,
                    ),
                    SizedBox(height: 16),
                    // Password field
                    CustomTextField(
                      controller: controller.passwordController,
                      label: AppText.password,
                      hint: AppText.password,
                      isPassword: true,
                      readOnly: true,
                      enabled: false,
                    ),
                    SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => Get.to(
                          () => ChangePasswordScreen(),
                          binding: ChangePasswordBinding(),
                        ),
                        child: Text(
                          'Change Password',
                          style: AppTextStyles.mediumTextStyle(
                            fontSize: 14,
                            color: AppColors.color2D2D2D,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    // Delete account section
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => controller.showDeleteAccountDialog(),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              AppAssets.delete,
                              width: 20,
                              height: 20,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Delete account',
                              style: AppTextStyles.regularTextStyle(
                                fontSize: 16,
                                color: AppColors.redDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            // Update information button - Fixed at bottom
            /*Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,

              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => controller.updateInformation(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Update information',
                    style: AppTextStyles.buttonTextStyle(),
                  ),
                ),
              ),
            ),*/
          ],
        ),
      ),
    );
  }
}
