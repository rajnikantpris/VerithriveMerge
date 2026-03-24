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
import 'add_service_format_controller.dart';

class AddServiceFormatView extends BaseView<AddServiceFormatController> {
  const AddServiceFormatView({super.key});

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
            'Service format',
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
              // Service format label
              Text(
                'Service format*',
                style: TextStyle(
                  fontFamily: AppFonts.rubikRegular,
                  fontWeight: FontWeight.w400,
                  fontSize: FontSizes.setFontValue_14,
                  color: AppColor.color_2D2D2D,
                ),
              ),
              SizedBox(height: HightWidthSizes.setValue_10),
              // Service format input field
              Obx(
                () => CustomTextField(
                  label: '',
                  hintText: 'Select here',
                  controller: controller.serviceFormatController,
                  showLabel: false,
                  readOnly: true,
                  onTap: controller.navigateToServiceFormat,
                  validator: (value) => controller.validateServiceFormat(),
                  borderColor: controller.serviceFormatError.value != null
                      ? Colors.red
                      : Color(0xFFE0E2E6),
                  suffixIcon: Padding(
                    padding: EdgeInsets.only(
                      right: HightWidthSizes.setValue_15,
                      left: HightWidthSizes.setValue_10,
                    ),
                    child: AppImages.profile_right_arrow_svg(
                      width: HightWidthSizes.setValue_20,
                      height: HightWidthSizes.setValue_20,
                      color: AppColor.color_32435F,
                    ),
                  ),
                ),
              ),
              // Show error message if validation fails
              Obx(
                () => controller.serviceFormatError.value != null
                    ? Padding(
                        padding: EdgeInsets.only(
                          top: HightWidthSizes.setValue_4,
                        ),
                        child: Text(
                          controller.serviceFormatError.value ?? '',
                          style: TextStyle(
                            fontFamily: AppFonts.poppinsRegular,
                            fontWeight: FontWeight.w400,
                            fontSize: FontSizes.setFontValue_12,
                            color: Colors.red,
                          ),
                        ),
                      )
                    : SizedBox.shrink(),
              ),
              SizedBox(height: HightWidthSizes.setValue_10),

              Center(
                child: Container(
                  height: HightWidthSizes.setValue_2,
                  decoration: BoxDecoration(
                    color: AppColor.color000000.withOpacity(0.1),
                  ),
                ),
              ),
              SizedBox(height: HightWidthSizes.setValue_10),
              // Service format cards
              Obx(
                () => controller.serviceFormats.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: HightWidthSizes.setValue_20,
                          ),
                          child: Text(
                            'No services selected',
                            style: TextStyle(
                              fontFamily: AppFonts.rubikRegular,
                              fontSize: FontSizes.setFontValue_16,
                              color: AppColor.color_2D2D2D,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...controller.serviceFormats
                              .asMap()
                              .entries
                              .map((entry) {
                            final index = entry.key;
                            final serviceFormat = entry.value;
                            return _buildServiceFormatCard(
                                context, index, serviceFormat);
                          }),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceFormatCard(
    BuildContext context,
    int index,
    ServiceFormatData serviceFormat,
  ) {
    final isBundle = serviceFormat.isBundle;

    return Container(
      margin: EdgeInsets.only(bottom: HightWidthSizes.setValue_16),
      padding: EdgeInsets.all(HightWidthSizes.setValue_16),
      decoration: BoxDecoration(
        color: Color(0x05455A64), // #455A6405
        borderRadius: BorderRadius.circular(HightWidthSizes.setValue_10),
        border: Border.all(
          color: Color(0x0A000000), // #0000000A
          width: HightWidthSizes.setValue_1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with service name and delete button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  serviceFormat.serviceName,
                  style: TextStyle(
                    fontFamily: AppFonts.rubikMedium,
                    fontWeight: FontWeight.w500,
                    fontSize: FontSizes.setFontValue_16,
                    color: AppColor.color_2D2D2D,
                  ),
                ),
              ),
              InkWell(
                onTap: () => controller.deleteServiceFormat(index),
                child: Padding(
                  padding: EdgeInsets.all(HightWidthSizes.setValue_8),
                  child: AppImages.delete_account_svg(
                    width: HightWidthSizes.setValue_20,
                    height: HightWidthSizes.setValue_20,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: HightWidthSizes.setValue_1),
          Center(
            child: Container(
              height: HightWidthSizes.setValue_1,
              decoration: BoxDecoration(
                color: AppColor.color000000.withOpacity(0.1),
              ),
            ),
          ),
          SizedBox(height: HightWidthSizes.setValue_8),
          if (isBundle) ...[
            // Bundle fields: Time per session and Bundle price
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(
                            () => DropdownButtonFormField2<String>(
                              isExpanded: true,
                              isDense: true,
                              alignment: AlignmentDirectional.centerStart,
                              value: controller.serviceFormats[index]
                                              .timePerSession !=
                                          null &&
                                      controller.serviceFormats[index]
                                          .timePerSession!.isNotEmpty
                                  ? controller
                                      .serviceFormats[index].timePerSession
                                  : null,
                              decoration: _dropdownDecoration(
                                controller.fieldErrors['timePerSession_$index'],
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
                                'Time per session',
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
                                  controller.selectDuration(index, true, value);
                                }
                              },
                              validator: (value) =>
                                  controller.validateTimePerSession(index),
                            ),
                          ),
                          // Error message for time per session
                          Obx(
                            () => controller
                                        .fieldErrors['timePerSession_$index'] !=
                                    null
                                ? Padding(
                                    padding: EdgeInsets.only(
                                      top: HightWidthSizes.setValue_4,
                                      left: HightWidthSizes.setValue_14,
                                    ),
                                    child: Text(
                                      controller.fieldErrors[
                                              'timePerSession_$index'] ??
                                          '',
                                      style: TextStyle(
                                        fontFamily: AppFonts.poppinsRegular,
                                        fontWeight: FontWeight.w400,
                                        fontSize: FontSizes.setFontValue_12,
                                        color: Colors.red,
                                        height: 1.4,
                                      ),
                                    ),
                                  )
                                : SizedBox(height: HightWidthSizes.setValue_16),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: HightWidthSizes.setValue_12),
                    Expanded(
                      child: Obx(
                        () => CustomTextField(
                          label: '',
                          hintText: 'Bundle price',
                          controller:
                              controller.getBundlePriceController(index),
                          showLabel: false,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          borderColor:
                              controller.fieldErrors['bundlePrice_$index'] !=
                                      null
                                  ? Colors.red
                                  : Color(0xFFE0E2E6), // #E0E2E6
                          hintTextColor: Color(0xFF828282), // #828282
                          hintTextFontFamily: AppFonts.poppinsRegular,
                          hintTextFontSize: FontSizes.setFontValue_12,
                          validator: (value) =>
                              controller.validateBundlePrice(index),
                          onChanged: (value) {
                            // Update the value first
                            controller.updateBundlePrice(index, value);
                            // Clear error when user types
                            if (value.trim().isNotEmpty) {
                              controller.fieldErrors
                                  .remove('bundlePrice_$index');
                              controller.fieldErrors.refresh();
                              // Trigger form validation to update field state
                              controller.formKey.currentState?.validate();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                Obx(
                  () => controller.isDropdownOpen(index, true)
                      ? Padding(
                          padding:
                              EdgeInsets.only(top: HightWidthSizes.setValue_4),
                          child: _buildDurationDropdown(context, index, true),
                        )
                      : SizedBox.shrink(),
                ),
              ],
            ),
            SizedBox(height: HightWidthSizes.setValue_16),
            // Offer text field
            CustomTextField(
              label: '',
              hintText: 'Offer text',
              controller: controller.getOfferTextController(index),
              showLabel: false,
              maxLines: 2,
              borderColor: Color(0xFFE0E2E6), // #E0E2E6
              hintTextColor: Color(0xFF828282), // #828282
              hintTextFontFamily: AppFonts.poppinsRegular,
              textInputAction: TextInputAction.done,
              hintTextFontSize: FontSizes.setFontValue_12,
              validator: (value) => controller.validateOfferText(index),
              onChanged: (value) {
                // Update the value first
                controller.updateOfferText(index, value);
                // Clear error when user types (offer text is optional)
                controller.fieldErrors.remove('offerText_$index');
                controller.fieldErrors.refresh();
              },
            ),
          ] else ...[
            // Regular service fields: Time and Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(
                            () => DropdownButtonFormField2<String>(
                              isExpanded: true,
                              isDense: true,
                              alignment: AlignmentDirectional.centerStart,
                              value: controller.serviceFormats[index].time !=
                                          null &&
                                      controller.serviceFormats[index].time!
                                          .isNotEmpty
                                  ? controller.serviceFormats[index].time
                                  : null,
                              decoration: _dropdownDecoration(
                                controller.fieldErrors['time_$index'],
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
                                'Time',
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
                                            fontSize: FontSizes.setFontValue_12,
                                            color: AppColor.color_2D2D2D,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  controller.selectDuration(
                                      index, false, value);
                                }
                              },
                              validator: (value) =>
                                  controller.validateTime(index),
                            ),
                          ),
                          // Error message for time
                          Obx(
                            () => controller.fieldErrors['time_$index'] != null
                                ? Padding(
                                    padding: EdgeInsets.only(
                                      top: HightWidthSizes.setValue_4,
                                      left: HightWidthSizes.setValue_14,
                                    ),
                                    child: Text(
                                      controller.fieldErrors['time_$index'] ??
                                          '',
                                      style: TextStyle(
                                        fontFamily: AppFonts.poppinsRegular,
                                        fontWeight: FontWeight.w400,
                                        fontSize: FontSizes.setFontValue_12,
                                        color: Colors.red,
                                        height: 1.4,
                                      ),
                                    ),
                                  )
                                : SizedBox(height: HightWidthSizes.setValue_16),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: HightWidthSizes.setValue_12),
                    Expanded(
                      child: Obx(
                        () => CustomTextField(
                          label: '',
                          hintText: 'Price',
                          controller: controller.getPriceController(index),
                          showLabel: false,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          borderColor:
                              controller.fieldErrors['price_$index'] != null
                                  ? Colors.red
                                  : Color(0xFFE0E2E6), // #E0E2E6
                          hintTextColor: Color(0xFF828282), // #828282
                          hintTextFontFamily: AppFonts.poppinsRegular,
                          hintTextFontSize: FontSizes.setFontValue_12,
                          validator: (value) => controller.validatePrice(index),
                          onChanged: (value) {
                            // Update the value first
                            controller.updatePrice(index, value);
                            // Clear error when user types
                            if (value.trim().isNotEmpty) {
                              controller.fieldErrors.remove('price_$index');
                              controller.fieldErrors.refresh();
                              // Trigger form validation to update field state
                              controller.formKey.currentState?.validate();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                Obx(
                  () => controller.isDropdownOpen(index, false)
                      ? Padding(
                          padding:
                              EdgeInsets.only(top: HightWidthSizes.setValue_4),
                          child: _buildDurationDropdown(context, index, false),
                        )
                      : SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ],
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
                controller.onAddServiceFormat();
              } else {
                // Trigger validation for all fields
                controller.onAddServiceFormat();
              }
            },
            child: Text(
              'Add service format',
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

  Widget _buildDurationDropdown(
    BuildContext context,
    int index,
    bool isBundle,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = HightWidthSizes.setValue_16;
    final spacing = HightWidthSizes.setValue_12;
    final dropdownWidth = (screenWidth - (padding * 2) - spacing) / 2;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(HightWidthSizes.setValue_10),
      color: Colors.transparent,
      child: Container(
        width: dropdownWidth,
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(HightWidthSizes.setValue_10),
          border: Border.all(
            color: Color(0xFFE0E2E6), // #E0E2E6
            width: HightWidthSizes.setValue_1,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000), // #0000001A
              blurRadius: HightWidthSizes.setValue_10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: controller.durationOptions.asMap().entries.map((entry) {
            final isLast = entry.key == controller.durationOptions.length - 1;
            return InkWell(
              onTap: () => controller.selectDuration(
                index,
                isBundle,
                entry.value,
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: HightWidthSizes.setValue_16,
                  vertical: HightWidthSizes.setValue_12,
                ),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: AppColor.color_ECECEC,
                            width: HightWidthSizes.setValue_1,
                          ),
                        ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontFamily: AppFonts.poppinsRegular,
                          fontWeight: FontWeight.w400,
                          fontSize: FontSizes.setFontValue_14,
                          color: AppColor.color_2D2D2D,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
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
        // left: HightWidthSizes.setValue_14,
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
      // Don't show error text here - we show it explicitly below the field
      errorText: null,
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
