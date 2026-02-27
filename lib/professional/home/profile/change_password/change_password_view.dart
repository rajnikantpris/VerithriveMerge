import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/base_view.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/fonts.dart';
import '../../../../theme/font_sizes.dart';
import '../../../../theme/hight_width_sizes.dart';
import '../../../../widgets/custom_text_field.dart';
import 'change_password_controller.dart';

class ChangePasswordView extends BaseView<ChangePasswordController> {
  const ChangePasswordView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 1),
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000), // #0000001A
              blurRadius: HightWidthSizes.setValue_10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: AppBar(
          backgroundColor: AppColor.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: AppColor.color_2D3648,
            ),
            onPressed: () => Get.back(),
          ),
          centerTitle: true,
          title: Text(
            'Change password',
            style: TextStyle(
              fontFamily: AppFonts.rubikMedium,
              fontWeight: FontWeight.w500,
              fontSize: FontSizes.setFontValue_18,
              color: AppColor.color_2D3648,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildView(BuildContext context) {
    return Container(
      color: AppColor.color_F5F5F5,
      child: SingleChildScrollView(
        // padding: EdgeInsets.all(HightWidthSizes.setValue_16),
        child: Form(
          key: controller.formKey,
          child: Container(
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(HightWidthSizes.setValue_10),
            ),
            padding: EdgeInsets.all(HightWidthSizes.setValue_16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // New Password Section
                Obx(
                  () => CustomTextField(
                    label: 'Enter new password',
                    hintText: 'Enter new password',
                    icon: Icons.lock_outline,
                    controller: controller.newPasswordController,
                    obscureText: controller.obscureNewPassword.value,
                    validator: controller.validateNewPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.obscureNewPassword.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColor.color_9D9D9D,
                        size: HightWidthSizes.setValue_20,
                      ),
                      onPressed: controller.toggleNewPasswordVisibility,
                    ),
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_12),
                
                // Password Requirements Text
                Padding(
                  padding: EdgeInsets.only(left: HightWidthSizes.setValue_4),
                  child: Text(
                    'Your password must be at least 8 characters long and include at least one uppercase letter, one lowercase letter, and one number. Please revise your password to meet these criteria.',
                    style: TextStyle(
                      fontFamily: AppFonts.rubikRegular,
                      fontWeight: FontWeight.w400,
                      fontSize: FontSizes.setFontValue_12,
                      color: AppColor.color_9D9D9D,
                      height: 1.4,
                    ),
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_20),
                
                // Confirm Password Section
                Obx(
                  () => CustomTextField(
                    label: 'Confirm password',
                    hintText: 'Confirm password',
                    icon: Icons.lock_outline,
                    controller: controller.confirmPasswordController,
                    obscureText: controller.obscureConfirmPassword.value,
                    validator: controller.validateConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.obscureConfirmPassword.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColor.color_9D9D9D,
                        size: HightWidthSizes.setValue_20,
                      ),
                      onPressed: controller.toggleConfirmPasswordVisibility,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget? bottomNavigationBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: HightWidthSizes.setValue_16,
        vertical: HightWidthSizes.setValue_16,
      ),
      decoration: BoxDecoration(
        color: AppColor.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: HightWidthSizes.setValue_10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,

          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.color_2FC4B2,
              foregroundColor: AppColor.white,
              elevation: 0,
              minimumSize:
              Size(double.infinity, HightWidthSizes.setValue_45),
              padding: EdgeInsets.symmetric(
                  vertical: HightWidthSizes.setValue_12,
                  horizontal: HightWidthSizes.setValue_16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  HightWidthSizes.setValue_10,
                ),
              ),
            ),
            onPressed: controller.onContinue,
            child: Text(
              'Continue',
              style: TextStyle(
                fontFamily: AppFonts.rubikMedium,
                fontWeight: FontWeight.w500,
                color: AppColor.white,
                fontSize: FontSizes.setFontValue_16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

