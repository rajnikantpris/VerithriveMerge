import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/base_view.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/fonts.dart';
import '../../../../theme/font_sizes.dart';
import '../../../../theme/hight_width_sizes.dart';
import '../../../../theme/image_paths.dart';
import '../../../../widgets/custom_text_field.dart';
import 'address_controller.dart';

class AddressView extends BaseView<AddressController> {
  const AddressView({super.key});

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
            'Address',
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
    return Form(
      key: controller.formKey,
      child: Container(
        color: AppColor.white,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: HightWidthSizes.setValue_16,
            vertical: HightWidthSizes.setValue_20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Your address section
              _buildSectionTitle('Your address'),
              SizedBox(height: HightWidthSizes.setValue_14),
              _buildPostcodeField(
                label: 'Postcode*',
                controller: controller.yourPostcodeController,
                hint: 'LS12AA',
                isManual: controller.isManualYourPostcode,
                onEnableManual: controller.enableManualYourPostcode,
                isRequired: true,
                onTap: controller.onYourAddressTap,
              ),
              SizedBox(height: HightWidthSizes.setValue_14),
              Text(
                'Address*',
                style: TextStyle(
                  fontFamily: AppFonts.rubikRegular,
                  fontWeight: FontWeight.w400,
                  fontSize: FontSizes.setFontValue_14,
                  color: AppColor.color_2D2D2D,
                ),
              ),
              SizedBox(height: HightWidthSizes.setValue_5),
              Obx(
                () => CustomTextField(
                  label: '',
                  hintText: 'Select address',
                  controller: controller.yourAddressController,
                  showLabel: false,
                  readOnly: !controller.isManualYourAddress.value,
                  onTap: controller.isManualYourAddress.value ? null : controller.onYourAddressTap,
                  suffixIcon: GestureDetector(
                    onTap: controller.onYourAddressTap,
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: HightWidthSizes.setValue_15,
                        left: HightWidthSizes.setValue_10,
                      ),
                      child: Icon(Icons.location_on, color: AppColor.color_2FC4B2),
                    ),
                  ),
                  validator: (value) =>
                      controller.validateNotEmpty(value, 'address'),
                ),
              ),
              SizedBox(height: HightWidthSizes.setValue_24),

              // Work address section
              _buildSectionTitleWithOptional('Work address'),
              SizedBox(height: HightWidthSizes.setValue_14),
              _buildPostcodeField(
                label: 'Postcode',
                controller: controller.workPostcodeController,
                hint: 'Eg. EC1 2AB',
                isManual: controller.isManualWorkPostcode,
                onEnableManual: controller.enableManualWorkPostcode,
                isRequired: false,
                onTap: controller.onWorkAddressTap,
              ),
              SizedBox(height: HightWidthSizes.setValue_14),
              Text(
                'Address',
                style: TextStyle(
                  fontFamily: AppFonts.rubikRegular,
                  fontWeight: FontWeight.w400,
                  fontSize: FontSizes.setFontValue_14,
                  color: AppColor.color_2D2D2D,
                ),
              ),
              SizedBox(height: HightWidthSizes.setValue_5),
              Obx(
                () => CustomTextField(
                  label: '',
                  hintText: 'Select address',
                  controller: controller.workAddressController,
                  showLabel: false,
                  readOnly: !controller.isManualWorkAddress.value,
                  onTap: controller.isManualWorkAddress.value ? null : controller.onWorkAddressTap,
                  suffixIcon: GestureDetector(
                    onTap: controller.onWorkAddressTap,
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: HightWidthSizes.setValue_15,
                        left: HightWidthSizes.setValue_10,
                      ),
                      child: Icon(Icons.location_on, color: AppColor.color_2FC4B2),
                    ),
                  ),
                ),
              ),
              SizedBox(height: HightWidthSizes.setValue_20),
            ],
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
            onPressed: controller.onUpdateAddress,
            child: Text(
              'Update address',
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

  Widget _buildSectionTitle(String title, {bool isOptional = false}) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: AppFonts.rubikMedium,
        fontWeight: FontWeight.w500,
        fontSize: FontSizes.setFontValue_16,
        color: isOptional ? AppColor.color_7F7F7F : AppColor.color_2D3648,
      ),
    );
  }

  Widget _buildSectionTitleWithOptional(String title) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: title,
            style: TextStyle(
              fontFamily: AppFonts.rubikMedium,
              fontWeight: FontWeight.w500,
              fontSize: FontSizes.setFontValue_15,
              color: AppColor.color_2D3648,
            ),
          ),
          TextSpan(
            text: ' (optional)',
            style: TextStyle(
              fontFamily: AppFonts.rubikRegular,
              fontWeight: FontWeight.w400,
              fontSize: FontSizes.setFontValue_14,
              color: AppColor.color_9D9D9D,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostcodeField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required RxBool isManual,
    required VoidCallback onEnableManual,
    required bool isRequired,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.rubikRegular,
                fontWeight: FontWeight.w400,
                fontSize: FontSizes.setFontValue_14,
                color: AppColor.color_2D2D2D,
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onEnableManual,
              child: Text(
                'Enter manually',
                style: TextStyle(
                  fontFamily: AppFonts.rubikRegular,
                  fontWeight: FontWeight.w400,
                  fontSize: FontSizes.setFontValue_14,
                  color: AppColor.color_2D2D2D,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: HightWidthSizes.setValue_5),
        CustomTextField(
          label: '',
          hintText: hint,
          controller: controller,
          showLabel: false,
          readOnly: true,
          onTap: onTap,
          validator: isRequired
              ? (value) => this.controller.validateNotEmpty(value, 'postcode')
              : null,
        )
      ],
    );
  }
}
