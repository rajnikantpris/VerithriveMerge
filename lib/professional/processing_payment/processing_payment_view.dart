import 'package:flutter/material.dart';

import '../../common/base_view.dart';
import '../../theme/colors.dart';
import '../../theme/font_sizes.dart';
import '../../theme/fonts.dart';
import '../../theme/hight_width_sizes.dart';
import 'processing_payment_controller.dart';

// ── End-user imports for AnimatedLoader ───────────────────────────────────────
import '../../enduser/core/widget/animated_loader.dart';
import '../../enduser/utils/app_assets.dart';
import '../../enduser/utils/AppText.dart';
import '../../enduser/utils/app_text_styles.dart';
import '../../enduser/utils/app_colors.dart';
// ─────────────────────────────────────────────────────────────────────────────

class ProcessingPaymentView extends BaseView<ProcessingPaymentController> {
  const ProcessingPaymentView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) => null;

  @override
  Widget buildView(BuildContext context) {
    return Container(
      color: AppColor.white,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Custom Circular Loader (matching your teal color)
              AnimatedLoader(
                assetPath: AppAssets.loader,
                width: 80,
                height: 80,
                duration: const Duration(seconds: 2),
              ),
              SizedBox(height: HightWidthSizes.setValue_32),
              Text(
                'Please wait!',
                textAlign: TextAlign.center,
                style: AppTextStyles.popinSemiboldTextStyle(
                  fontSize: 18,
                  color: AppColors.primaryColor,
                ),
              ),
              SizedBox(height: HightWidthSizes.setValue_12),
              Text(
                'Processing payment',
                textAlign: TextAlign.center,
                style: AppTextStyles.popinMediumTextStyle(
                  fontSize: 14,
                  color: AppColors.blueColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}
