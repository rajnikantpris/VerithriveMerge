import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import '../../utils/AppText.dart';
import '../../utils/CustomTextField.dart';
import '../../utils/app_text_styles.dart';
import 'ChangePasswordController.dart';

class ChangePasswordScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChangePasswordController());

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
          'Change Password',
          style: AppTextStyles.boldTextStyle(
            fontSize: 18,
            color: AppColors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                SizedBox(height: 24),
                // New Password Field
                Obx(() => CustomTextField(
                  controller: controller.passwordController,
                  label: '',
                  hint: AppText.enterNewPassword,
                  isPassword: !controller.isPasswordVisible.value,
                  prefixIcon: SvgPicture.asset(AppAssets.password_fill, width: 20, height: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isPasswordVisible.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.grey,
                    ),
                    onPressed: controller.togglePasswordVisibility,
                  ),
                  validator: controller.validatePassword,
                )),
                SizedBox(height: 5),
                Text(
                  AppText.change_password_message,
                  style: AppTextStyles.mediumTextStyle(
                    fontSize: 11,
                    color: AppColors.greyText
                  ),
                ),
                SizedBox(height: 16),
                // Confirm Password Field
                Obx(() => CustomTextField(
                  controller: controller.confirmPasswordController,
                  label: '',
                  hint: AppText.confirmPassword,
                  isPassword: !controller.isConfirmPasswordVisible.value,
                  prefixIcon: SvgPicture.asset(AppAssets.password_fill, width: 20, height: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.isConfirmPasswordVisible.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.grey,
                    ),
                    onPressed: controller.toggleConfirmPasswordVisibility,
                  ),
                  validator: controller.validateConfirmPassword,
                )),
                SizedBox(height: 40),
                // Continue Button
                Obx(() => SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value ? null : controller.changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: AppColors.primaryColor.withOpacity(0.6),
                    ),
                    child: controller.isLoading.value
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(AppText.continueText, style: AppTextStyles.buttonStyle),
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

