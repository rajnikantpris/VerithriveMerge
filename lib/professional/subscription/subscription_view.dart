import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/base_view.dart';
import '../../theme/colors.dart';
import '../../theme/font_sizes.dart';
import '../../theme/fonts.dart';
import '../../theme/hight_width_sizes.dart';
import '../../theme/image_paths.dart';
import '../../widgets/custom_app_bar.dart';
import 'subscription_controller.dart';

class SubscriptionView extends BaseView<SubscriptionController> {
  const SubscriptionView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    // Hide back button if there's no route to go back to (e.g., opened from login/splash via offAllNamed)
    final canGoBack = Navigator.canPop(context);
    return CustomAppBar(
      appBarTitleText: '',
      isBackButtonEnabled: canGoBack,
      isCenterTitle: false,
      titleColor: AppColor.color000000,
      titleFontSize: FontSizes.setFontValue_18,
      titlefontFamily: AppFonts.rubikMedium,
      leading: canGoBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColor.color000000),
              onPressed: Get.back,
            )
          : null,
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: HightWidthSizes.setValue_12),
                    Text(
                      'Choose your plan',
                      style: TextStyle(
                        fontFamily: AppFonts.rubikMedium,
                        fontWeight: FontWeight.w500,
                        fontSize: FontSizes.setFontValue_20,
                        color: AppColor.color_32435F,
                      ),
                    ),
                    SizedBox(height: HightWidthSizes.setValue_6),
                    Text(
                      'No commitment. Cancel anytime',
                      style: TextStyle(
                        fontFamily: AppFonts.rubikRegular,
                        fontWeight: FontWeight.w400,
                        fontSize: FontSizes.setFontValue_14,
                        color: AppColor.color_2D3648,
                      ),
                    ),
                    SizedBox(height: HightWidthSizes.setValue_18),
                    Obx(
                      () => Column(
                        children: controller.plans
                            .map((plan) => _planTile(plan))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget? bottomNavigationBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Obx(
          () => SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.color_2FC4B2,
                disabledBackgroundColor: AppColor.color_96E1D8,
                foregroundColor: AppColor.white,
                disabledForegroundColor: AppColor.white.withOpacity(0.9),
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
              onPressed: controller.selectedPlanId.value.isEmpty
                  ? null
                  : controller.continueToPayment,
              child: Text(
                'Continue',
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
      ),
    );
  }

  Widget _planTile(PlanOption plan) {
    return Obx(() {
      final isSelected = controller.selectedPlanId.value == plan.id;
      return GestureDetector(
        onTap: () => controller.selectPlan(plan.id),
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: HightWidthSizes.setValue_12),
          padding: EdgeInsets.symmetric(
            horizontal: HightWidthSizes.setValue_14,
            vertical: HightWidthSizes.setValue_12,
          ),
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.circular(HightWidthSizes.setValue_12),
            border: Border.all(
              color: isSelected
                  ? AppColor.color_2FC4B2
                  : AppColor.color_000000.withOpacity(0.2),
              width: HightWidthSizes.setValue_1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColor.color_000000.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(HightWidthSizes.setValue_8),
                width: HightWidthSizes.setValue_36,
                height: HightWidthSizes.setValue_36,
                alignment: Alignment.center,
                child: plan.assetPath != null
                    ? AppImages.svg(
                        plan.assetPath!,
                        width: HightWidthSizes.setValue_20,
                        height: HightWidthSizes.setValue_20,
                        fit: BoxFit.contain,
                        // Keep original SVG colors; no tinting so brand colors show.
                        color: null,
                      )
                    : Icon(
                        Icons.star,
                        color: plan.accentColor,
                        size: HightWidthSizes.setValue_20,
                      ),
              ),
              SizedBox(width: HightWidthSizes.setValue_12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: TextStyle(
                        fontFamily: AppFonts.rubikRegular,
                        fontWeight: FontWeight.w400,
                        fontSize: FontSizes.setFontValue_16,
                        color: AppColor.color_32435F,
                      ),
                    ),
                    SizedBox(height: HightWidthSizes.setValue_8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: HightWidthSizes.setValue_6,
                          children: [
                            Text(
                              plan.priceLabel,
                              style: TextStyle(
                                fontFamily: AppFonts.rubikMedium,
                                fontWeight: FontWeight.w500,
                                fontSize: FontSizes.setFontValue_15,
                                color: AppColor.color_1E1E1E,
                              ),
                            ),
                            if (plan.promoLabel != null)
                              Text(
                                '(${plan.promoLabel!})',
                                style: TextStyle(
                                  fontFamily: AppFonts.rubikRegular,
                                  fontWeight: FontWeight.w400,
                                  fontSize: FontSizes.setFontValue_8,
                                  color: AppColor.color_32435F,
                                ),
                              ),
                          ],
                        ),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: HightWidthSizes.setValue_8,
                          children: [
                            if (plan.cutPriceLabel != null)
                              Text(
                                plan.cutPriceLabel!,
                                style: TextStyle(
                                  fontFamily: AppFonts.rubikRegular,
                                  fontWeight: FontWeight.w400,
                                  fontSize: FontSizes.setFontValue_12,
                                  color: AppColor.color_9D9D9D,
                                  decoration: TextDecoration.lineThrough,
                                  decorationThickness: 1.5,
                                ),
                              ),
                            if (plan.perMonthLabel != null)
                              Text(
                                '(${plan.perMonthLabel})',
                                style: TextStyle(
                                  fontFamily: AppFonts.rubikRegular,
                                  fontWeight: FontWeight.w400,
                                  fontSize: FontSizes.setFontValue_12,
                                  color: AppColor.color_32435F,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color:
                    isSelected ? AppColor.color_2FC4B2 : AppColor.color_9D9D9D,
              ),
            ],
          ),
        ),
      );
    });
  }
}
