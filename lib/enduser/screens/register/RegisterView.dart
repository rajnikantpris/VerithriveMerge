import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/utils/app_text_styles.dart';

import '../../utils/AppText.dart';
import '../../utils/CustomTextField.dart';
import '../../utils/app_assets.dart';
import '../../utils/app_colors.dart';
import 'RegisterController.dart';

class RegisterView extends GetView<RegisterController> {

  const RegisterView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.black, size: 24),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 21),
                
                // Logo
                Center(
                  child: Image.asset(
                    AppAssets.app_logo_splash, // Add your logo here
                    height: 70,
                  ),
                ),
                
                SizedBox(height: 50),
                
                // Title
                Text(
                  AppText.createAccount,
                  style: AppTextStyles.titleStyle(),
                ),
                
                SizedBox(height: 24),
                
                // Email Field
                CustomTextField(
                  controller: controller.emailController,
                  label: AppText.email,
                  hint: AppText.emailAddress,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: SvgPicture.asset(AppAssets.email,width: 18,height: 18,),
                  validator: controller.validateEmail,
                ),
                
                SizedBox(height: 16),
                
                // Phone Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppText.phoneNumber,
                      style: AppTextStyles.labelStyle(),
                    ),
                    SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          constraints: BoxConstraints(
                            minHeight: 50,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              bottomLeft: Radius.circular(10),
                            ),
                            border: Border(
                              left: BorderSide(
                                color: AppColors.lightGrey,
                                width: 1,
                              ),
                              top: BorderSide(
                                color: AppColors.lightGrey,
                                width: 1,
                              ),
                              bottom: BorderSide(
                                color: AppColors.lightGrey,
                                width: 1,
                              ),
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                color: AppColors.color9D9D9D,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '+44',
                                style: AppTextStyles.rubikRegular(
                                  fontSize: 15.5,
                                  color: AppColors.color2D2D2D,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: CustomTextField(
                            label: '',
                            hint: AppText.phoneNumber,
                            controller: controller.phoneController,
                            keyboardType: TextInputType.phone,
                            validator: controller.validatePhone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            showLabel: false,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 16),
                
                // Password Field
                Obx(() => CustomTextField(
                  controller: controller.passwordController,
                  label: AppText.createPassword,
                  hint: AppText.password,
                  isPassword: !controller.isPasswordVisible.value,
                  prefixIcon: SvgPicture.asset(AppAssets.password,width: 20,height: 20,),
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
                  label: AppText.confirmPassword,
                  hint: AppText.password,
                  isPassword: !controller.isConfirmPasswordVisible.value,
                  prefixIcon: SvgPicture.asset(AppAssets.password,width: 20,height: 20,),
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
                
                SizedBox(height: 32),
                
                // Join Now Button
                Obx(() => SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value ? null : controller.registerApiCall,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: controller.isLoading.value
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: const CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(AppText.joinNow, style: AppTextStyles.mediumTextStyle(fontSize: 16, color: AppColors.white)),
                  ),
                )),
                
                SizedBox(height: 24),
                
                // Or Continue With
                Center(
                  child: Text(
                    AppText.orContinueWith,
                    style: AppTextStyles.regularTextStyle(
                        fontSize: 14,
                        color: AppColors.color7f7f7f
                    ),
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Social Login Buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen,
                          borderRadius: BorderRadius.only(topLeft: Radius.circular(8),bottomLeft: Radius.circular(8)),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: controller.continueWithGoogle,
                            borderRadius: BorderRadius.circular(8),
                            child: Center(
                              child: Image.asset(
                                AppAssets.google,
                                height: 24,
                                width: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 5),
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color:  AppColors.lightGreen,
                          borderRadius: BorderRadius.only(topRight: Radius.circular(8),bottomRight: Radius.circular(8)),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: controller.continueWithApple,
                            borderRadius: BorderRadius.circular(8),
                            child: Center(
                              child: SvgPicture.asset(AppAssets.apple,width: 20,height: 20,),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 24),
                
                // Already Have Account
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppText.alreadyHaveAccount,
                        style: AppTextStyles.regularTextStyle(
                            fontSize: 14,
                            color: Colors.black.withOpacity(0.50)
                        ),
                      ),
                      GestureDetector(
                        onTap: controller.navigateToLogin,
                        child: Text(
                          AppText.login,
                          style: AppTextStyles.boldTextStyle(
                            color: AppColors.primaryColor
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}