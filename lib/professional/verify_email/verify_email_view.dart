import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/base_view.dart';
import '../../theme/colors.dart';
import '../../theme/font_sizes.dart';
import '../../theme/fonts.dart';
import '../../theme/hight_width_sizes.dart';
import '../../widgets/custom_app_bar.dart';
import 'verify_email_controller.dart';

class VerifyEmailView extends BaseView<VerifyEmailController> {
  const VerifyEmailView({super.key});

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: HightWidthSizes.setValue_12),
              Text(
                'Enter OTP',
                style: TextStyle(
                  fontFamily: AppFonts.rubikMedium,
                  fontWeight: FontWeight.w500,
                  fontSize: FontSizes.setFontValue_24,
                  color: AppColor.color_414141,
                ),
              ),
              SizedBox(height: HightWidthSizes.setValue_8),
              Text(
                'Please enter OTP (one time password) sent to your registered email address${controller.email.isNotEmpty ? ' (${controller.email})' : ''}.',
                style: TextStyle(
                  fontFamily: AppFonts.rubikRegular,
                  fontWeight: FontWeight.w400,
                  fontSize: FontSizes.setFontValue_14,
                  color: AppColor.color_898989,
                  height: 1.5,
                ),
              ),
              SizedBox(height: HightWidthSizes.setValue_20),
              _buildOtpFields(context),
              SizedBox(height: HightWidthSizes.setValue_10),
              Obx(
                () => Row(
                  children: [
                    Text(
                      'No code yet?',
                      style: TextStyle(
                        fontFamily: AppFonts.rubikRegular,
                        fontSize: FontSizes.setFontValue_14,
                        fontWeight: FontWeight.w400,
                        color: AppColor.color_454545,
                      ),
                    ),
                    SizedBox(width: HightWidthSizes.setValue_5),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed:
                          controller.canResend ? controller.resendOtp : null,
                      child: Text(
                        controller.isResending.value
                            ? 'Sending...'
                            : controller.resendLabel,
                        style: TextStyle(
                          fontFamily: AppFonts.rubikBold,
                          fontSize: FontSizes.setFontValue_14,
                          fontWeight: FontWeight.w700,
                          color: AppColor.color_2FC4B2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: HightWidthSizes.setValue_26),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.color_2FC4B2,
                      disabledBackgroundColor: AppColor.color_96E1D8,
                      foregroundColor: AppColor.white,
                      disabledForegroundColor: AppColor.white.withOpacity(0.9),
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
                    onPressed: controller.isOtpComplete &&
                            !controller.isVerifying.value
                        ? controller.submitOtp
                        : null,
                    child: Text(
                      controller.isVerifying.value
                          ? 'Verifying...'
                          : 'Continue',
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
    );
  }

  Widget _buildOtpFields(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        controller.codeControllers.length,
        (index) => SizedBox(
          width: HightWidthSizes.setValue_46,
          child: TextField(
            controller: controller.codeControllers[index],
            focusNode: controller.focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            decoration: InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.zero,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(HightWidthSizes.setValue_8),
                borderSide: const BorderSide(
                  color: AppColor.color_B3B3B3,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(HightWidthSizes.setValue_8),
                borderSide: const BorderSide(
                  color: AppColor.color_B3B3B3,
                  width: 1,
                ),
              ),
              fillColor: AppColor.white,
              filled: true,
            ),
            onChanged: (value) => controller.handleChange(index, value),
          ),
        ),
      ),
    );
  }
}
