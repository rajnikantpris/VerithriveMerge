import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../common/base_view.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/fonts.dart';
import '../../../../theme/font_sizes.dart';
import '../../../../theme/hight_width_sizes.dart';
import '../../../../theme/image_paths.dart';
import '../../../../widgets/custom_text_field.dart';
import 'edit_service_format_controller.dart';

class EditServiceFormatView extends BaseView<EditServiceFormatController> {
  const EditServiceFormatView({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping anywhere on screen
        FocusScope.of(context).unfocus();
      },
      child: super.build(context),
    );
  }

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
          centerTitle: false,
          title: Text(
            'Edit service format',
            style: TextStyle(
              fontFamily: AppFonts.rubikMedium,
              fontWeight: FontWeight.w500,
              fontSize: FontSizes.setFontValue_18,
              color: AppColor.color_414141,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildView(BuildContext context) {
    return Container(
      color: AppColor.white,
      child: Form(
        key: controller.formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: HightWidthSizes.setValue_16,
            vertical: HightWidthSizes.setValue_20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service type name with delete button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      controller.serviceFormatName,
                      style: TextStyle(
                        fontFamily: AppFonts.rubikMedium,
                        fontWeight: FontWeight.w500,
                        fontSize: FontSizes.setFontValue_16,
                        color: AppColor.color_2D2D2D,
                      ),
                    ),
                  ),
                  // InkWell(
                  //   onTap: controller.deleteServiceFormat,
                  //   child: Padding(
                  //     padding: EdgeInsets.all(HightWidthSizes.setValue_8),
                  //     child: AppImages.delete_account_svg(
                  //       width: HightWidthSizes.setValue_20,
                  //       height: HightWidthSizes.setValue_20,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
              SizedBox(height: HightWidthSizes.setValue_16),
              // Duration and Price row
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => DropdownButtonFormField2<String>(
                        isExpanded: true,
                        isDense: true,
                        alignment: AlignmentDirectional.centerStart,
                        value: controller.selectedDuration.value.isNotEmpty
                            ? controller.selectedDuration.value
                            : null,
                        decoration: _dropdownDecoration(
                          controller.fieldErrors['duration'],
                        ),
                        dropdownStyleData: DropdownStyleData(
                          decoration: BoxDecoration(
                            color: AppColor.white,
                            borderRadius: BorderRadius.circular(
                                HightWidthSizes.setValue_10),
                          ),
                        ),
                        iconStyleData: IconStyleData(
                          icon: AppImages.right_arrow_image(
                            width: HightWidthSizes.setValue_12,
                            height: HightWidthSizes.setValue_12,
                          ),
                        ),
                        hint: Text(
                          'Duration',
                          style: TextStyle(
                            fontFamily: AppFonts.poppinsRegular,
                            fontWeight: FontWeight.w400,
                            fontSize: FontSizes.setFontValue_12,
                            color: Color(0xFF828282), // #828282
                          ),
                        ),
                        items: controller.durationOptions
                            .map((option) => DropdownMenuItem<String>(
                                  value: option,
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      fontFamily: AppFonts.poppinsRegular,
                                      fontWeight: FontWeight.w400,
                                      fontSize: FontSizes.setFontValue_14,
                                      color: AppColor.color_2D2D2D,
                                    ),
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            controller.selectDuration(value);
                          }
                        },
                        validator: (value) => controller.validateDuration(),
                      ),
                    ),
                  ),
                  SizedBox(width: HightWidthSizes.setValue_12),
                  Expanded(
                    child: CustomTextField(
                      label: '',
                      hintText: 'Price',
                      controller: controller.priceController,
                      showLabel: false,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.number,
                      borderColor: Color(0xFFE0E2E6), // #E0E2E6
                      hintTextColor: Color(0xFF828282), // #828282
                      hintTextFontFamily: AppFonts.poppinsRegular,
                      hintTextFontSize: FontSizes.setFontValue_12,
                      validator: (value) => controller.validatePrice(),
                      onChanged: (value) {
                        controller.updatePrice(value);
                        if (value.isNotEmpty) {
                          controller.fieldErrors.remove('price');
                          controller.fieldErrors.refresh();
                        }
                        controller.formKey.currentState?.validate();
                      },
                    ),
                  ),
                ],
              ),
              // Offer text field for bundles
              Obx(
                () => controller.isBundle.value
                    ? Column(
                        children: [
                          SizedBox(height: HightWidthSizes.setValue_16),
                          CustomTextField(
                            label: '',
                            hintText: 'Offer text',
                            textInputAction: TextInputAction.done,
                            controller: controller.offerTextController,
                            showLabel: false,
                            maxLines: 2,
                            borderColor: Color(0xFFE0E2E6), // #E0E2E6
                            hintTextColor: Color(0xFF828282), // #828282
                            hintTextFontFamily: AppFonts.poppinsRegular,
                            hintTextFontSize: FontSizes.setFontValue_12,
                            validator: (value) =>
                                controller.validateOfferText(),
                            onChanged: (value) {
                              controller.updateOfferText(value);
                            },
                          ),
                        ],
                      )
                    : SizedBox.shrink(),
              ),
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
            onPressed: () {
              if (controller.formKey.currentState?.validate() ?? false) {
                controller.onUpdateServiceFormat();
              } else {
                controller.onUpdateServiceFormat();
              }
            },
            child: Text(
              'Update service format',
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

  InputDecoration _dropdownDecoration([String? errorMessage]) {
    final hasError = errorMessage != null && errorMessage.isNotEmpty;
    return InputDecoration(
      filled: true,
      fillColor: AppColor.white,
      contentPadding: EdgeInsets.only(
        right: HightWidthSizes.setValue_14,
        top: HightWidthSizes.setValue_14,
        bottom: HightWidthSizes.setValue_14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HightWidthSizes.setValue_10),
        borderSide: BorderSide(
          color: hasError ? Colors.red : Color(0xFFE0E2E6), // #E0E2E6
          width: HightWidthSizes.setValue_1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HightWidthSizes.setValue_10),
        borderSide: BorderSide(
          color: hasError ? Colors.red : Color(0xFFE0E2E6), // #E0E2E6
          width: HightWidthSizes.setValue_1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HightWidthSizes.setValue_10),
        borderSide: BorderSide(
          color: hasError ? Colors.red : Color(0xFFE0E2E6), // #E0E2E6
          width: HightWidthSizes.setValue_1,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HightWidthSizes.setValue_10),
        borderSide: BorderSide(
          color: Colors.red,
          width: HightWidthSizes.setValue_1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HightWidthSizes.setValue_10),
        borderSide: BorderSide(
          color: Colors.red,
          width: HightWidthSizes.setValue_1,
        ),
      ),
      errorText: errorMessage,
      errorStyle: TextStyle(
        fontFamily: AppFonts.poppinsRegular,
        fontWeight: FontWeight.w400,
        fontSize: FontSizes.setFontValue_12,
        color: Colors.red,
        height: 1.2,
      ),
      errorMaxLines: 2,
    );
  }
}
