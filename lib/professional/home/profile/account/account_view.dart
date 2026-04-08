import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/base_view.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/fonts.dart';
import '../../../../theme/font_sizes.dart';
import '../../../../theme/hight_width_sizes.dart';
import '../../../../theme/image_paths.dart';
import '../../../../widgets/custom_text_field.dart';
import 'account_controller.dart';

class AccountView extends BaseView<AccountController> {
  const AccountView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 1),
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000), // #0000001A
              blurRadius: HightWidthSizes.setValue_10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: AppBar(
          backgroundColor: AppColor.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: AppColor.color_2D3648,
            ),
            onPressed: () => Get.back(),
          ),
          centerTitle: true,
          title: Text(
            'Account',
            style: TextStyle(
              fontFamily: AppFonts.rubikMedium,
              fontWeight: FontWeight.w500,
              fontSize: FontSizes.setFontValue_18,
              color: AppColor.color_2D3648,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildView(BuildContext context) {
    return Container(
      color: AppColor.color_F5F5F5,
      child: SingleChildScrollView(
        // padding: EdgeInsets.all(HightWidthSizes.setValue_16),
        child: Form(
          key: controller.formKey,
          child: Container(
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(HightWidthSizes.setValue_10),
            ),
            padding: EdgeInsets.all(HightWidthSizes.setValue_16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Email Section
                CustomTextField(
                  label: 'Email',
                  readOnly: true,
                  hintText: 'Enter your email',
                  controller: controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: controller.validateEmail,
                ),
                SizedBox(height: HightWidthSizes.setValue_20),

                // Password Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () => CustomTextField(
                        label: 'Password',
                        readOnly: true,
                        hintText: 'Enter your password',
                        controller: controller.passwordController,
                        obscureText: controller.obscurePassword.value,
                        validator: controller.validatePassword,
                      ),
                    ),
                    SizedBox(height: HightWidthSizes.setValue_8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: controller.onChangePassword,
                        child: Text(
                          'Change Password',
                          style: TextStyle(
                            fontFamily: AppFonts.rubikMedium,
                            fontWeight: FontWeight.w500,
                            fontSize: FontSizes.setFontValue_14,
                            color: AppColor.color_2D2D2D,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: HightWidthSizes.setValue_24),

                // Delete Account Button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(HightWidthSizes.setValue_10)),
                  child: ElevatedButton(
                    onPressed: () {
                      showDeactivateAccountDialog(
                          context, controller.onConfirmDeactivate);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0x0FB53232),
                      foregroundColor: AppColor.color_B53232,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        vertical: HightWidthSizes.setValue_14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          HightWidthSizes.setValue_10,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: HightWidthSizes.setValue_10),
                        AppImages.delete_account_svg(
                          width: HightWidthSizes.setValue_20,
                          height: HightWidthSizes.setValue_20,
                          color: AppColor.color_B53232,
                        ),
                        SizedBox(width: HightWidthSizes.setValue_8),
                        Text(
                          'Delete Account',
                          style: TextStyle(
                            fontFamily: AppFonts.rubikRegular,
                            fontWeight: FontWeight.w400,
                            fontSize: FontSizes.setFontValue_16,
                            color: AppColor.color_B53232,
                          ),
                        ),
                      ],
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

  @override
  Widget? bottomNavigationBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: HightWidthSizes.setValue_16,
        vertical: HightWidthSizes.setValue_16,
      ),
      decoration: BoxDecoration(
        color: AppColor.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: HightWidthSizes.setValue_10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.color_2FC4B2,
              foregroundColor: AppColor.white,
              elevation: 0,
              minimumSize: Size(double.infinity, HightWidthSizes.setValue_45),
              padding: EdgeInsets.symmetric(
                  vertical: HightWidthSizes.setValue_12,
                  horizontal: HightWidthSizes.setValue_16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  HightWidthSizes.setValue_10,
                ),
              ),
            ),
            onPressed: controller.onUpdateInformation,
            child: Text(
              'Update information',
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
    );
  }

  void showDeactivateAccountDialog(
      BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: HightWidthSizes.setValue_16,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius:
                    BorderRadius.circular(HightWidthSizes.setValue_10),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: HightWidthSizes.setValue_10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.all(HightWidthSizes.setValue_24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Title
                  Text(
                    'Delete my account?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.rubikMedium,
                      fontWeight: FontWeight.w500,
                      fontSize: FontSizes.setFontValue_20,
                      color: AppColor.color_2D3648,
                    ),
                  ),
                  SizedBox(height: HightWidthSizes.setValue_16),

                  // Body text
                  Text(
                    'Taking a break? You\'re welcome back anytime - but you\'ll lose all your saved data.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.rubikRegular,
                      fontWeight: FontWeight.w400,
                      fontSize: FontSizes.setFontValue_14,
                      color: AppColor.color_2D2D2D,
                    ),
                  ),
                  SizedBox(height: HightWidthSizes.setValue_24),

                  // No, go back button (Primary)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.color_2FC4B2,
                        foregroundColor: AppColor.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          vertical: HightWidthSizes.setValue_14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            HightWidthSizes.setValue_10,
                          ),
                        ),
                      ),
                      child: Text(
                        'No, go back',
                        style: TextStyle(
                          fontFamily: AppFonts.rubikMedium,
                          fontWeight: FontWeight.w500,
                          fontSize: FontSizes.setFontValue_16,
                          color: AppColor.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: HightWidthSizes.setValue_12),

                  // Yes, deactivate button (Destructive)
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onConfirm();
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: HightWidthSizes.setValue_14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            HightWidthSizes.setValue_10,
                          ),
                        ),
                      ),
                      child: Text(
                        'Yes, delete',
                        style: TextStyle(
                          fontFamily: AppFonts.rubikRegular,
                          fontWeight: FontWeight.w400,
                          fontSize: FontSizes.setFontValue_16,
                          color: AppColor.color_B53232,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
