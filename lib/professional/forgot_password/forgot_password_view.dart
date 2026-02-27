import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/base_view.dart';
import '../../theme/colors.dart';
import '../../theme/font_sizes.dart';
import '../../theme/fonts.dart';
import '../../theme/hight_width_sizes.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_text_field.dart';
import 'forgot_password_controller.dart';

class ForgotPasswordView extends BaseView<ForgotPasswordController> {
  const ForgotPasswordView({super.key});

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
                  'Enter email',
                  style: TextStyle(
                    fontFamily: AppFonts.rubikMedium,
                    fontWeight: FontWeight.w500,
                    fontSize: FontSizes.setFontValue_24,
                    color: AppColor.color_414141,
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_10),
                Text(
                  "Enter the email you signed up with and we'll send you a one-time code to log in.",
                  style: TextStyle(
                    fontFamily: AppFonts.rubikRegular,
                    fontWeight: FontWeight.w400,
                    fontSize: FontSizes.setFontValue_14,
                    color: AppColor.color_A7A7A7,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_18),
                CustomTextField(
                  label: 'Email address',
                  showLabel: false,
                  hintText: 'Email address',
                  icon: Icons.email_outlined,
                  controller: controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: controller.validateEmail,
                  onChanged: controller.onEmailChanged,
                  onSubmitted: (_) => controller.sendResetCode(),
                ),
                SizedBox(height: HightWidthSizes.setValue_20),
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: controller.isEmailValid.value
                            ? AppColor.color_2FC4B2
                            : AppColor.color_A7A7A7,
                        foregroundColor: AppColor.white,
                        disabledBackgroundColor: AppColor.color_96E1D8,
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
                      onPressed: controller.isEmailValid.value
                          ? controller.sendResetCode
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
