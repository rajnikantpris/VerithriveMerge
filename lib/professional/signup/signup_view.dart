import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../common/base_view.dart';
import '../../theme/colors.dart';
import '../../theme/font_sizes.dart';
import '../../theme/fonts.dart';
import '../../theme/hight_width_sizes.dart';
import '../../theme/image_paths.dart';
import '../../widgets/custom_text_field.dart';
import 'signup_controller.dart';

class SignupView extends BaseView<SignupController> {
  const SignupView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return null;
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
                // Logo
                Center(child: Column(children: [_buildLogo()])),
                SizedBox(height: HightWidthSizes.setValue_28),
                // Create account heading
                Text(
                  'Create account',
                  style: TextStyle(
                    fontFamily: AppFonts.rubikMedium,
                    fontWeight: FontWeight.w500,
                    fontSize: FontSizes.setFontValue_24,
                    color: AppColor.color_2D3648,
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_22),
                // Email field
                CustomTextField(
                  label: 'Email',
                  hintText: 'Email address',
                  icon: Icons.email_outlined,
                  controller: controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: controller.validateEmail,
                ),
                SizedBox(height: HightWidthSizes.setValue_18),
                // Phone field
                // Column(
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     Text(
                //       'Phone number',
                //       style: TextStyle(
                //         fontFamily: AppFonts.rubikRegular,
                //         fontWeight: FontWeight.w400,
                //         fontSize: FontSizes.setFontValue_14,
                //         color: AppColor.color_2D2D2D,
                //       ),
                //     ),
                //     SizedBox(height: HightWidthSizes.setValue_5),
                //     Row(
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: [
                //         Container(
                //           constraints: BoxConstraints(
                //               minHeight: HightWidthSizes.setValue_45),
                //           decoration: BoxDecoration(
                //             color: AppColor.white,
                //             borderRadius: BorderRadius.only(
                //               topLeft: Radius.circular(
                //                 HightWidthSizes.setValue_10,
                //               ),
                //               bottomLeft: Radius.circular(
                //                 HightWidthSizes.setValue_10,
                //               ),
                //             ),
                //             border: Border(
                //               left: BorderSide(
                //                 color: AppColor.borderColor,
                //                 width: HightWidthSizes.setValue_1,
                //               ),
                //               top: BorderSide(
                //                 color: AppColor.borderColor,
                //                 width: HightWidthSizes.setValue_1,
                //               ),
                //               bottom: BorderSide(
                //                 color: AppColor.borderColor,
                //                 width: HightWidthSizes.setValue_1,
                //               ),
                //             ),
                //           ),
                //           padding: EdgeInsets.symmetric(
                //             horizontal: HightWidthSizes.setValue_12,
                //             vertical: HightWidthSizes.setValue_14,
                //           ),
                //           child: Row(
                //             mainAxisSize: MainAxisSize.min,
                //             children: [
                //               Icon(
                //                 Icons.phone_outlined,
                //                 color: AppColor.color_9D9D9D,
                //                 size: HightWidthSizes.setValue_16,
                //               ),
                //               SizedBox(width: HightWidthSizes.setValue_8),
                //               Text(
                //                 '+44',
                //                 style: TextStyle(
                //                   fontFamily: AppFonts.rubikRegular,
                //                   fontWeight: FontWeight.w400,
                //                   fontSize: FontSizes.setFontValue_15_5,
                //                   color: AppColor.color_2D2D2D,
                //                 ),
                //               ),
                //             ],
                //           ),
                //         ),
                //         Expanded(
                //           child: CustomTextField(
                //             label: '',
                //             hintText: 'Phone number',
                //             controller: controller.phoneController,
                //             keyboardType: TextInputType.phone,
                //             validator: controller.validatePhone,
                //             inputFormatters: [
                //               FilteringTextInputFormatter.digitsOnly
                //             ],
                //             showLabel: false,
                //             borderRadius: BorderRadius.only(
                //               topRight: Radius.circular(
                //                 HightWidthSizes.setValue_10,
                //               ),
                //               bottomRight: Radius.circular(
                //                 HightWidthSizes.setValue_10,
                //               ),
                //             ),
                //           ),
                //         ),
                //       ],
                //     ),
                //   ],
                // ),
                // SizedBox(height: HightWidthSizes.setValue_18),
                // Password field
                Obx(
                      () => CustomTextField(
                    label: 'Create password',
                    hintText: 'Password',
                    icon: Icons.lock_outline,
                    controller: controller.passwordController,
                    obscureText: !controller.isPasswordVisible.value,
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
                SizedBox(height: HightWidthSizes.setValue_6),
                // Password requirements
                Padding(
                  padding: EdgeInsets.only(left: HightWidthSizes.setValue_4),
                  child: Text(
                    'Your password must be at least 10-12 characters long and include at least one uppercase letter, one lowercase letter, and one number. Please revise your password to meet these criteria.',
                    style: TextStyle(
                      fontFamily: AppFonts.rubikRegular,
                      fontWeight: FontWeight.w400,
                      fontSize: FontSizes.setFontValue_10,
                      color: AppColor.color_898989,
                      height: 1.4,
                    ),
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_18),
                // Confirm password field
                Obx(
                      () => CustomTextField(
                    label: 'Confirm Password',
                    hintText: 'Password',
                    icon: Icons.lock_outline,
                    controller: controller.confirmPasswordController,
                    obscureText: !controller.isConfirmPasswordVisible.value,
                    validator: controller.validateConfirmPassword,
                    textInputAction: TextInputAction.done,
                    suffixIcon: IconButton(
                      icon: Icon(
                        size: HightWidthSizes.setValue_16,
                        controller.isConfirmPasswordVisible.value
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColor.textMuted,
                      ),
                      onPressed: controller.toggleConfirmPasswordVisibility,
                    ),
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_18),
                CustomTextField(
                  label: 'Enter promo code',
                  hintText: 'Enter here',

                  controller: controller.promoCodeController,
                  keyboardType: TextInputType.text,

                ),


                SizedBox(height: HightWidthSizes.setValue_30),
                // Join now button
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
                    onPressed: controller.onJoinNow,
                    child: Text(
                      'Join now',
                      style: TextStyle(
                        fontFamily: AppFonts.rubikMedium,
                        fontWeight: FontWeight.w500,
                        color: AppColor.white,
                        fontSize: FontSizes.setFontValue_16,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_22),
                // Or continue with
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
                SizedBox(height: HightWidthSizes.setValue_22),
                // Social login buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildSocialButton(
                        label: 'Google',
                        onPressed: controller.onGoogleSignIn,
                        isGoogle: true,
                      ),
                    ),
                    SizedBox(width: HightWidthSizes.setValue_5),
                    Expanded(
                      child: _buildSocialButton(
                        label: 'Apple',
                        onPressed: controller.onAppleSignIn,
                        isGoogle: false,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: HightWidthSizes.setValue_30),
                // Login link
                Center(
                  child: TextButton(
                    onPressed: controller.onLogin,
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(
                          fontFamily: AppFonts.rubikRegular,
                          fontSize: FontSizes.setFontValue_14,
                          fontWeight: FontWeight.w400,
                          color: AppColor.color000000.withOpacity(0.5),
                        ),
                        children: [
                          TextSpan(
                            text: 'Log in',
                            style: TextStyle(
                              fontFamily: AppFonts.rubikBold,
                              fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildLogo() {
    return AppImages.splash(width: 200, fit: BoxFit.contain);
  }

  Widget _buildSocialButton({
    required String label,
    required VoidCallback onPressed,
    required bool isGoogle,
  }) {
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
            isGoogle
                ? AppImages.google_image(
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            )
                : AppImages.apple_image(
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}
