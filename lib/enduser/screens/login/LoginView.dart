import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/widgets/custom_text_field.dart';
import '../../../theme/colors.dart';
import '../../../theme/font_sizes.dart';
import '../../../theme/fonts.dart';
import '../../../theme/hight_width_sizes.dart';
import '../../../theme/image_paths.dart';
import 'LoginController.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: _buildLogo()),
                  SizedBox(height: HightWidthSizes.setValue_50),
                  Text(
                    "You're back - let's do this!",
                    style: TextStyle(
                      fontFamily: AppFonts.rubikMedium,
                      fontWeight: FontWeight.w500,
                      fontSize: FontSizes.setFontValue_24,
                      color: AppColor.color_2D3648,
                    ),
                  ),
                  SizedBox(height: HightWidthSizes.setValue_22),
                  CustomTextField(
                    label: 'Email',
                    controller: controller.emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: controller.validateEmail,
                    hintText: 'Email address',
                  ),
                  SizedBox(height: HightWidthSizes.setValue_18),
                  Obx(
                    () => CustomTextField(
                      label: 'Password',
                      controller: controller.passwordController,
                      validator: controller.validatePassword,
                      obscureText: !controller.isPasswordVisible.value,
                      suffixIcon: IconButton(
                        icon: Icon(
                          size: HightWidthSizes.setValue_16,
                          controller.isPasswordVisible.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColor.textMuted,
                        ),
                        onPressed: controller.togglePasswordVisibility,
                      ),
                      hintText: 'Password',
                    ),
                  ),
                  Row(
                    children: [
                      Obx(
                        () => Checkbox(
                          value: controller.rememberMe.value,
                          onChanged: controller.toggleRememberMe,
                          activeColor: AppColor.color_2FC4B2,
                          side: BorderSide(color: AppColor.progressTrack),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      Text(
                        'Remember me',
                        style: TextStyle(
                          fontFamily: AppFonts.rubikRegular,
                          fontWeight: FontWeight.w400,
                          fontSize: FontSizes.setFontValue_14,
                          color: AppColor.color_929292,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: controller.navigateToForgotPassword,
                        child: Text(
                          'Forgot your password?',
                          style: TextStyle(
                            fontFamily: AppFonts.rubikMedium,
                            fontSize: FontSizes.setFontValue_14,
                            fontWeight: FontWeight.w500,
                            color: AppColor.color_414141,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: HightWidthSizes.setValue_15),
                  SizedBox(
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
                          horizontal: HightWidthSizes.setValue_16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            HightWidthSizes.setValue_10,
                          ),
                        ),
                      ),
                      onPressed: controller.callLoginService,
                      child: Text(
                        'Log in',
                        style: TextStyle(
                          fontFamily: AppFonts.rubikMedium,
                          fontWeight: FontWeight.w500,
                          color: AppColor.white,
                          fontSize: FontSizes.setFontValue_16,
                        ),
                        overflow: TextOverflow.visible,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(height: HightWidthSizes.setValue_18),
                  Center(
                    child: Text(
                      'or continue with',
                      style: TextStyle(
                        fontFamily: AppFonts.rubikRegular,
                        fontWeight: FontWeight.w400,
                        fontSize: FontSizes.setFontValue_14,
                        color: AppColor.color_7F7F7F,
                      ),
                    ),
                  ),
                  SizedBox(height: HightWidthSizes.setValue_18),
                  Row(
                    children: [
                      Expanded(
                        child: _SocialButton(
                          label: 'Google',
                          onPressed: controller.onGoogleSignIn,
                          asset: AppImages.google,
                        ),
                      ),
                      SizedBox(width: HightWidthSizes.setValue_5),
                      Expanded(
                        child: _SocialButton(
                          label: 'Apple',
                          onPressed: controller.onAppleSignIn,
                          asset: AppImages.iphone,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: HightWidthSizes.setValue_22),
                  Center(
                    child: TextButton(
                      onPressed: controller.navigateToRegister,
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account yet? ",
                          style: TextStyle(
                            fontFamily: AppFonts.rubikRegular,
                            fontSize: FontSizes.setFontValue_14,
                            fontWeight: FontWeight.w400,
                            color: AppColor.color000000.withOpacity(0.5),
                          ),
                          children: [
                            TextSpan(
                              text: 'Join now',
                              style: TextStyle(
                                fontFamily: AppFonts.rubikBold,
                                fontWeight: FontWeight.w700,
                                fontSize: FontSizes.setFontValue_14,
                                color: AppColor.color_2FC4B2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AppImages.splash(
        width: HightWidthSizes.setValue_250, fit: BoxFit.contain);
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.onPressed,
    required this.asset,
  });

  final String label;
  final VoidCallback onPressed;
  final String asset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: HightWidthSizes.setValue_45,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColor.progressTrack, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: label == "Apple"
                ? BorderRadius.only(
                topRight: Radius.circular(HightWidthSizes.setValue_10),
                bottomRight: Radius.circular(HightWidthSizes.setValue_10))
                : BorderRadius.only(
                topLeft: Radius.circular(HightWidthSizes.setValue_10),
                bottomLeft: Radius.circular(HightWidthSizes.setValue_10)),
          ),
          backgroundColor: AppColor.color_D7F1EB,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(asset, width: 20, height: 20, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }
}
