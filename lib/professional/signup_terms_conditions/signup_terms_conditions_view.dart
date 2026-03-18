import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/base_view.dart';
import '../../theme/colors.dart';
import '../../theme/font_sizes.dart';
import '../../theme/fonts.dart';
import '../../theme/hight_width_sizes.dart';
import '../../widgets/custom_app_bar.dart';
import 'signup_terms_conditions_controller.dart';

class SignupTermsConditionsView
    extends BaseView<SignupTermsConditionsController> {
  const SignupTermsConditionsView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: 'Terms & conditions',
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () => _buildParagraph(
                        controller.termsText.value.isEmpty
                            ? 'Loading terms & conditions...'
                            : controller.termsText.value,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColor.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x24000000), // #00000014 at ~14% opacity
                    offset: const Offset(0, -4),
                    blurRadius: 12,
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMarketingOptIn(),
                  SizedBox(height: HightWidthSizes.setValue_12),
                  _buildTermsAndConditionsCheckbox(),
                  SizedBox(height: HightWidthSizes.setValue_12),
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.color_2FC4B2,
                          disabledBackgroundColor: AppColor.color_96E1D8,
                          foregroundColor: AppColor.white,
                          disabledForegroundColor:
                              AppColor.white.withOpacity(0.9),
                          elevation: 0,
                          minimumSize: Size(
                            double.infinity,
                            HightWidthSizes.setValue_45,
                          ),
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
                        onPressed: controller.termsAndConditionsAccepted.value
                            ? controller.onAccept
                            : null,
                        child: Text(
                          'Accept & continue',
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
          ],
        ),
      ),
    );
  }

  Widget _buildTermsAndConditionsCheckbox() {
    return Obx(
      () => InkWell(
        onTap: () => controller.toggleTermsAndConditions(
            !controller.termsAndConditionsAccepted.value),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: HightWidthSizes.setValue_20,
              height: HightWidthSizes.setValue_20,
              margin: EdgeInsets.only(top: HightWidthSizes.setValue_2),
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(
                  HightWidthSizes.setValue_4,
                ),
                border: Border.all(
                  color: controller.termsAndConditionsAccepted.value
                      ? AppColor.color_32435F
                      : const Color(0x99000000), // #00000099
                  width: HightWidthSizes.setValue_1,
                ),
                color: controller.termsAndConditionsAccepted.value
                    ? AppColor.color_32435F
                    : Colors.transparent,
              ),
              child: controller.termsAndConditionsAccepted.value
                  ? Icon(
                      Icons.check,
                      size: HightWidthSizes.setValue_14,
                      color: AppColor.white,
                    )
                  : null,
            ),
            SizedBox(width: HightWidthSizes.setValue_12),
            Expanded(
              child: Text(
                'I agree to the Terms & Conditions and Privacy Policy.',
                style: TextStyle(
                  fontFamily: AppFonts.rubikRegular,
                  fontWeight: FontWeight.w400,
                  fontSize: FontSizes.setFontValue_14,
                  color: AppColor.color_414141,
                  height: 1.3,
                ),
                maxLines: null,
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppFonts.rubikRegular,
        fontWeight: FontWeight.w400,
        fontSize: FontSizes.setFontValue_12,
        color: AppColor.color_2D2D2D,
        height: 1.5,
      ),
    );
  }

  Widget _buildMarketingOptIn() {
    return Obx(
      () => InkWell(
        onTap: () =>
            controller.toggleMarketingOptIn(!controller.marketingOptIn.value),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: HightWidthSizes.setValue_20,
              height: HightWidthSizes.setValue_20,
              margin: EdgeInsets.only(top: HightWidthSizes.setValue_2),
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(
                  HightWidthSizes.setValue_4,
                ),
                border: Border.all(
                  color: controller.marketingOptIn.value
                      ? AppColor.color_32435F
                      : const Color(0x99000000), // #00000099
                  width: HightWidthSizes.setValue_1,
                ),
                color: controller.marketingOptIn.value
                    ? AppColor.color_32435F
                    : Colors.transparent,
              ),
              child: controller.marketingOptIn.value
                  ? Icon(
                      Icons.check,
                      size: HightWidthSizes.setValue_14,
                      color: AppColor.white,
                    )
                  : null,
            ),
            SizedBox(width: HightWidthSizes.setValue_12),
            Expanded(
              child: Text(
                'Check this box to receive marketing emails from VERITHRIVE to keep you updated with the latest offers and trends.',
                style: TextStyle(
                  fontFamily: AppFonts.rubikRegular,
                  fontWeight: FontWeight.w400,
                  fontSize: FontSizes.setFontValue_14,
                  color: AppColor.color_414141,
                  height: 1.3,
                ),
                maxLines: null,
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),
    /*        Expanded(
              child: Text(
                'Tick if you would like to receive marketing emails from VERITHRIVE to keep you up to date about latest offers and trends.',
                style: TextStyle(
                  fontFamily: AppFonts.rubikRegular,
                  fontWeight: FontWeight.w400,
                  fontSize: FontSizes.setFontValue_14,
                  color: AppColor.color_414141,
                  height: 1.3,
                ),
                maxLines: null,
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),*/
          ],
        ),
      ),
    );
  }
}
