import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/base_view.dart';
import '../../theme/colors.dart';
import '../../theme/font_sizes.dart';
import '../../theme/fonts.dart';
import '../../theme/hight_width_sizes.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_text_field.dart';
import 'create_new_password_controller.dart';

class CreateNewPasswordView extends BaseView<CreateNewPasswordController> {
  const CreateNewPasswordView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: '',
      titleColor: AppColor.color000000,
      titleFontSize: FontSizes.setFontValue_18,
      titlefontFamily: AppFonts.rubikMedium,
      isBackButtonEnabled: true,
      isCenterTitle: false,
    );
  }

  @override
  Widget buildView(BuildContext context) {
    return Container(
      color: AppColor.white,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: HightWidthSizes.setValue_8),
                Text(
                  'Create new password',
                  style: TextStyle(
                    fontFamily: AppFonts.rubikMedium,
                    fontWeight: FontWeight.w500,
                    fontSize: FontSizes.setFontValue_24,
                    color: AppColor.color_2D3648,
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_18),
                Obx(
                  () => CustomTextField(
                    label: 'Enter new password',
                    showLabel: false,
                    hintText: 'Enter new password',
                    icon: Icons.lock_outline,
                    controller: controller.passwordController,
                    obscureText: !controller.isPasswordVisible.value,
                    validator: controller.validatePassword,
                    onSubmitted: (_) => controller.submit(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.isPasswordVisible.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: HightWidthSizes.setValue_16,
                        color: AppColor.textMuted,
                      ),
                      onPressed: controller.togglePasswordVisibility,
                    ),
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_8),
                Padding(
                  padding: EdgeInsets.only(left: HightWidthSizes.setValue_4),
                  child: Text(
                    'Your password must be at least 8-12 characters long and include at least one uppercase letter, one lowercase letter, and one number. Please revise your password to meet these criteria.',
                    style: TextStyle(
                      fontFamily: AppFonts.rubikRegular,
                      fontWeight: FontWeight.w400,
                      fontSize: FontSizes.setFontValue_12,
                      color: AppColor.color_898989,
                    ),
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_18),
                Obx(
                  () => CustomTextField(
                    label: 'Confirm password',
                    showLabel: false,
                    hintText: 'Confirm password',
                    icon: Icons.lock_outline,
                    controller: controller.confirmPasswordController,
                    obscureText: !controller.isConfirmPasswordVisible.value,
                    textInputAction: TextInputAction.done,
                    validator: controller.validateConfirmPassword,
                    onSubmitted: (_) => controller.submit(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.isConfirmPasswordVisible.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: HightWidthSizes.setValue_16,
                        color: AppColor.textMuted,
                      ),
                      onPressed: controller.toggleConfirmPasswordVisibility,
                    ),
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_24),
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: controller.isButtonEnabled.value
                            ? AppColor.color_2FC4B2
                            : AppColor.color_96E1D8,
                        foregroundColor: AppColor.white,
                        elevation: 0,
                        disabledBackgroundColor: AppColor.color_96E1D8,
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
                      onPressed: controller.isButtonEnabled.value
                          ? controller.submit
                          : null,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
