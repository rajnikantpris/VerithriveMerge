import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import '../../utils/AppText.dart';
import '../../utils/CustomTextField.dart';
import '../../utils/app_assets.dart';
import '../../utils/app_text_styles.dart';
import 'CreatePasswordController.dart';

class CreatePasswordView extends GetView<CreatePasswordController> {


  const CreatePasswordView({Key? key}) : super(key: key);


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
                  AppText.createNewPassword,
                  style: AppTextStyles.titleStyle(),
                ),

                const SizedBox(height: 12),

                Obx(() => CustomTextField(
                  controller: controller.passwordController,
                  label: '',
                  hint: AppText.enterNewPassword,
                  isPassword: !controller.isPasswordVisible.value,
                  prefixIcon: SvgPicture.asset(AppAssets.password_fill,width: 20,height: 20,),
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
                  onChanged: (value) => controller.updatePasswordState(),
                )),

                SizedBox(height: 8),

                // Password Criteria
                Text(
                  AppText.passwordCriteria,
                  style: AppTextStyles.regularTextStyle(
                    color: AppColors.greyText,
                    fontSize: 10
                  ),
                ),

                SizedBox(height: 16),

                // Confirm Password Field
                Obx(() => CustomTextField(
                  controller: controller.confirmPasswordController,
                  label: '',
                  hint: AppText.confirmPassword,
                  isPassword: !controller.isConfirmPasswordVisible.value,
                  prefixIcon: SvgPicture.asset(AppAssets.password_fill,width: 20,height: 20,),
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
                  onChanged: (value) => controller.updatePasswordState(),
                )),

                SizedBox(height: 40),

                // Continue Button (Moved to top)
                Obx(() => SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (controller.isLoading.value || !controller.isPasswordComplete)
                        ? null
                        : controller.clickContinueBtn,
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