import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import 'package:verithrive_dev/widgets/custom_text_field.dart';
import '../../utils/AppText.dart';
import '../../utils/app_assets.dart';
import '../../utils/app_text_styles.dart';
import 'ForgotPasswordController.dart';

class ForgotPasswordView extends GetView<ForgotPasswordController> {

  ForgotPasswordView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(AppAssets.back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Title
                 Text(
                  AppText.enterEmail,
                  style: AppTextStyles.titleStyle(),
                ),

                const SizedBox(height: 12),

                // Subtitle
                Text(
                  AppText.enterEmailDescription,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Rubik',
                    fontWeight: FontWeight.w400,
                    color: AppColors.color7a7a7a,
                  ),
                ),

                const SizedBox(height: 20),


                CustomTextField(
                  controller: controller.emailController,
                  label: '',
                  hintText: AppText.emailAddress,
                  keyboardType: TextInputType.emailAddress,
                  icon: Icons.email_outlined,
                  validator: controller.validateEmail,
                ),

                const SizedBox(height: 40),



                // Continue Button (Moved to top)
                Obx(() => SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value ? null : controller.openOTPScreen,
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
                      style: AppTextStyles.buttonTextStyle(),
                    ),
                  ),
                )),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}