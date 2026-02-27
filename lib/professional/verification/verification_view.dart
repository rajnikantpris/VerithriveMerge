import 'package:flutter/material.dart';

import '../../common/base_view.dart';
import '../../theme/colors.dart';
import '../../theme/font_sizes.dart';
import '../../theme/fonts.dart';
import '../../theme/hight_width_sizes.dart';
import '../../theme/image_paths.dart';
import 'verification_controller.dart';

class VerificationView extends BaseView<VerificationController> {
  const VerificationView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => null;

  @override
  Widget buildView(BuildContext context) {
    return Container(
      color: AppColor.white,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: HightWidthSizes.setValue_100 * 2.2,
                  child: AppImages.verificationAwaitImage(
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_30),
                Text(
                  'Sit back & Await verification',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.rubikBold,
                    fontWeight: FontWeight.w600,
                    fontSize: FontSizes.setFontValue_18,
                    color: AppColor.color_2FC4B2,
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_12),
                Text(
                  "Sit tight! We're giving your profile the Verithrive seal of approval. You'll hear from us as soon as you're approved.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    height: 1.5,
                    fontFamily: AppFonts.rubikRegular,
                    fontWeight: FontWeight.w400,
                    fontSize: FontSizes.setFontValue_14,
                    color: AppColor.color_32435F,
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_28),
                TextButton(
                  onPressed: controller.goToHomepage,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColor.color_2FC4B2,
                    padding: EdgeInsets.symmetric(
                      horizontal: HightWidthSizes.setValue_8,
                    ),
                    textStyle: TextStyle(
                      fontFamily: AppFonts.rubikBold,
                      fontWeight: FontWeight.w600,
                      fontSize: FontSizes.setFontValue_18,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Go to Homepage'),
                      SizedBox(width: HightWidthSizes.setValue_4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

