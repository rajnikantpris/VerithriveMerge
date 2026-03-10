import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../common/base_view.dart';
import '../../theme/colors.dart';
import '../../theme/font_sizes.dart';
import '../../theme/fonts.dart';
import '../../theme/hight_width_sizes.dart';
import '../../theme/image_paths.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_text_field.dart';
import 'login_controller.dart';

class LoginView extends BaseView<ProfessionalLoginController> {
  const LoginView({super.key});

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
    return SafeArea(
      child: Container(
        color: AppColor.white,
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
                    hintText: 'Email address',
                    icon: Icons.email_outlined,
                    controller: controller.emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: controller.validateEmail,
                  ),
                  SizedBox(height: HightWidthSizes.setValue_18),
                  Obx(
                    () => CustomTextField(
                      label: 'Password',
                      hintText: 'Password',
                      icon: Icons.lock_outline,
                      controller: controller.passwordController,
                      obscureText: !controller.isPasswordVisible.value,
                      textInputAction: TextInputAction.done,
                      validator: controller.validatePassword,
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
                        onPressed: controller.onForgotPassword,
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
                            horizontal: HightWidthSizes.setValue_16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            HightWidthSizes.setValue_10,
                          ),
                        ),
                      ),
                      onPressed: controller.onLogin,
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
                          isFullWidth: !Platform.isIOS,
                        ),
                      ),
                      SizedBox(width: HightWidthSizes.setValue_5),
                      if (Platform.isIOS) ...[
                        Expanded(
                          child: _SocialButton(
                            label: 'Apple',
                            onPressed: controller.onAppleSignIn,
                            asset: AppImages.iphone,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: HightWidthSizes.setValue_22),
                  Center(
                    child: TextButton(
                      onPressed: controller.onCreateAccount,
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
    this.isFullWidth = false,
  });

  final String label;
  final VoidCallback onPressed;
  final String asset;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: HightWidthSizes.setValue_45,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColor.progressTrack, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: isFullWidth
                ? BorderRadius.circular(HightWidthSizes.setValue_10)
                : (label == "Apple"
                    ? BorderRadius.only(
                        topRight: Radius.circular(HightWidthSizes.setValue_10),
                        bottomRight: Radius.circular(HightWidthSizes.setValue_10))
                    : BorderRadius.only(
                        topLeft: Radius.circular(HightWidthSizes.setValue_10),
                        bottomLeft: Radius.circular(HightWidthSizes.setValue_10))),
          ),
          backgroundColor: AppColor.color_D7F1EB,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              label == "Google"
                  ? AppImages.google
                  : AppImages.iphone,
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
            SizedBox(width: HightWidthSizes.setValue_8),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.rubikMedium,
                fontWeight: FontWeight.w500,
                fontSize: FontSizes.setFontValue_14,
                color: AppColor.color_2D2D2D,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
