import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/base_view.dart';
import '../../theme/colors.dart';
import '../../theme/font_sizes.dart';
import '../../theme/fonts.dart';
import '../../theme/hight_width_sizes.dart';
import '../../theme/image_paths.dart';
import '../../widgets/custom_app_bar.dart';
import 'payment_method_controller.dart';

class PaymentMethodView extends BaseView<PaymentMethodController> {
  const PaymentMethodView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: 'Payment method',
      isBackButtonEnabled: true,
      isCenterTitle: false,
      titleColor: AppColor.color000000,
      titleFontSize: FontSizes.setFontValue_18,
      titlefontFamily: AppFonts.rubikMedium,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColor.color000000),
        onPressed: Get.back,
      ),
    );
  }

  @override
  Widget buildView(BuildContext context) {
    return Container(
      color: AppColor.white,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            children: controller.methods
                .map((method) => _methodTile(method))
                .toList(),
          ),
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
              onPressed: controller.selectedMethodId.value.isEmpty ||
                      controller.isConfirming.value
                  ? null
                  : controller.confirmPayment,
              child: Text(
                controller.isConfirming.value
                    ? 'Processing...'
                    : 'Make payment',
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

  Widget _methodTile(PaymentMethodOption method) {
    return Obx(() {
      final isSelected = controller.selectedMethodId.value == method.id;
      return GestureDetector(
        onTap: () => controller.selectMethod(method.id),
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: HightWidthSizes.setValue_12),
          padding: EdgeInsets.symmetric(
            horizontal: HightWidthSizes.setValue_14,
            vertical: HightWidthSizes.setValue_14,
          ),
          decoration: BoxDecoration(
            color: AppColor.white,
            borderRadius: BorderRadius.circular(HightWidthSizes.setValue_12),
            border: Border.all(
              color: isSelected
                  ? AppColor.color_2FC4B2
                  : AppColor.color_000000.withOpacity(0.08),
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
            children: [
              _methodIcon(method),
              SizedBox(width: HightWidthSizes.setValue_12),
              Expanded(
                child: Text(
                  method.title,
                  style: TextStyle(
                    fontFamily: AppFonts.rubikMedium,
                    fontWeight: FontWeight.w500,
                    fontSize: FontSizes.setFontValue_14,
                    color: AppColor.color_2D3648,
                  ),
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

  Widget _methodIcon(PaymentMethodOption method) {
    return Container(
      height: HightWidthSizes.setValue_36,
      width: HightWidthSizes.setValue_36,
      child: Center(
        child: method.assetPath != null
            ? _assetIcon(method.assetPath!)
            : Icon(
                method.icon,
                color: method.accentColor,
                size: HightWidthSizes.setValue_20,
              ),
      ),
    );
  }

  Widget _assetIcon(String assetPath) {
    final height = HightWidthSizes.setValue_18;
    if (assetPath.toLowerCase().endsWith('.svg')) {
      return AppImages.svg(assetPath, height: height, fit: BoxFit.contain);
    }
    return Image.asset(assetPath, height: height, fit: BoxFit.contain);
  }
}
