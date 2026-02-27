import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/base_view.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/fonts.dart';
import '../../../../theme/font_sizes.dart';
import '../../../../theme/hight_width_sizes.dart';
import '../../../../theme/image_paths.dart';
import '../../../../widgets/custom_text_field.dart';
import 'service_format_controller.dart';

class ServiceFormatView extends BaseView<ServiceFormatController> {
  const ServiceFormatView({super.key});

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
      child: Column(
        children: [
          Expanded(
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
                  CustomTextField(
                    label: '',
                    hintText: 'Select here',
                    controller: controller.serviceFormatController,
                    showLabel: false,
                    readOnly: true,
                    onTap: controller.toggleServiceList,
                    suffixIcon: Padding(
                      padding: EdgeInsets.only(
                        right: HightWidthSizes.setValue_15,
                        left: HightWidthSizes.setValue_10,
                      ),
                      child: controller.showServiceList.value
                          ? SizedBox(
                              width: HightWidthSizes.setValue_5,
                              height: HightWidthSizes.setValue_5,
                              child: Padding(
                                padding:
                                    EdgeInsets.all(HightWidthSizes.setValue_2),
                                child: AppImages.add_down_arrow_svg(
                                  width: HightWidthSizes.setValue_10,
                                  height: HightWidthSizes.setValue_10,
                                  color: AppColor.color_32435F,
                                ),
                              ))
                          : AppImages.profile_right_arrow_svg(
                              width: HightWidthSizes.setValue_20,
                              height: HightWidthSizes.setValue_20,
                              color: AppColor.color_32435F,
                            ),
                    ),
                  ),
                  // Service options checkboxes - show when list is toggled
                  Obx(
                    () => controller.showServiceList.value &&
                            controller.serviceOptions.isNotEmpty
                        ? Column(
                            children: [
                              SizedBox(height: HightWidthSizes.setValue_24),
                              ...controller.serviceOptions.reversed
                                  .map((service) {
                                final isSelected =
                                    controller.isServiceSelected(service);
                                return Container(
                                  margin: EdgeInsets.only(
                                    bottom: HightWidthSizes.setValue_12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: AppColor.color_ECECEC,
                                        width: HightWidthSizes.setValue_1,
                                      ),
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () =>
                                        controller.toggleService(service),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: HightWidthSizes.setValue_12,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: HightWidthSizes.setValue_20,
                                            height: HightWidthSizes.setValue_20,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.rectangle,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                HightWidthSizes.setValue_4,
                                              ),
                                              border: Border.all(
                                                color: isSelected
                                                    ? AppColor.color_32435F
                                                    : Color(
                                                        0x99000000), // #00000099
                                                width:
                                                    HightWidthSizes.setValue_1,
                                              ),
                                              color: isSelected
                                                  ? AppColor.color_32435F
                                                  : Colors.transparent,
                                            ),
                                            child: isSelected
                                                ? Icon(
                                                    Icons.check,
                                                    size: HightWidthSizes
                                                        .setValue_14,
                                                    color: AppColor.white,
                                                  )
                                                : null,
                                          ),
                                          SizedBox(
                                              width:
                                                  HightWidthSizes.setValue_12),
                                          Expanded(
                                            child: Text(
                                              service,
                                              style: TextStyle(
                                                fontFamily:
                                                    AppFonts.rubikRegular,
                                                fontWeight: FontWeight.w400,
                                                fontSize:
                                                    FontSizes.setFontValue_16,
                                                color: AppColor.color_2D2D2D,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          )
                        : SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget? bottomNavigationBar(BuildContext context) {
    return Obx(
      () => controller.showServiceList.value
          ? Container(
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
                child: Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.color_2FC4B2,
                        foregroundColor: AppColor.white,
                        disabledBackgroundColor: AppColor.color_96E1D8,
                        disabledForegroundColor:
                            AppColor.white.withOpacity(0.9),
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
                      onPressed: controller.isButtonEnabled
                          ? controller.onSelectServices
                          : null,
                      child: Text(
                        'Select services',
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
            )
          : const SizedBox.shrink(),
    );
  }
}
