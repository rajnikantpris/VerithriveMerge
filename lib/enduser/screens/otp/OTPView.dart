import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import '../../utils/AppText.dart';
import '../../utils/OTPInputField.dart';
import '../../utils/app_text_styles.dart';
import 'OTPController.dart';

class OTPView extends GetView<OTPController> {
  const OTPView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon:  SvgPicture.asset(AppAssets.back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Title
               Text(
                AppText.enterOTP,
                style: AppTextStyles.titleStyleBlack(),
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                AppText.otpDescription,
                style: AppTextStyles.regularTextStyle(
                  color: AppColors.greyText
                ),
              ),

              const SizedBox(height: 40),

              // OTP Input Fields
              OTPInputField(
                fieldKey: controller.otpFieldKey,
                length: 6,
                fieldWidth: 50,
                fieldHeight: 50,
                borderRadius: 8,
                onCompleted: controller.onOTPChanged,
                onChanged: controller.onOTPChanged,
                borderColor: AppColors.colorb3b3b3,
                focusedBorderColor: AppColors.primaryColor,
                fillColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black
                ),
              ),

              const SizedBox(height: 20),

              // Resend OTP
              Obx(() => Row(
                children: [
                  Text(
                    AppText.noCodeYet,
                    style: AppTextStyles.regularTextStyle(
                      color: AppColors.color454545
                    ),
                  ),
                  GestureDetector(
                    onTap: controller.canResend.value
                        ? controller.resendOTP
                        : null,
                    child: Text(
                      AppText.sendItAgain,
                      style: AppTextStyles.semiboldTextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 14
                      ),
                    ),
                  ),
                  if (!controller.canResend.value) ...[
                    const SizedBox(width: 8),
                    Text(
                      controller.timerDisplay,
                      style: AppTextStyles.semiboldTextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 14
                      ),
                    ),
                  ],
                ],
              )),

              const SizedBox(height: 32),

              // Continue Button (Moved to top)
              Obx(() => SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (controller.isLoading.value || !controller.isOTPComplete)
                      ? null
                      : controller.verifyOTP,
                //  onPressed:controller.verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:  AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: AppColors.otpBtnBlur,
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    AppText.continueText,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: "Rubik",
                      fontWeight: FontWeight.w500,
                      color: controller.isOTPComplete
                          ? AppColors.white
                          : AppColors.white,
                    ),
                  ),
                ),
              )),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}