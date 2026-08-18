import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/base_view.dart';
import '../../../theme/colors.dart';
import '../../../theme/fonts.dart';
import '../../../theme/font_sizes.dart';
import '../../../theme/hight_width_sizes.dart';
import '../../../theme/image_paths.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../../services/analytics_service.dart';
import 'edit_availability_controller.dart';

class EditAvailabilityView extends BaseView<EditAvailabilityController> {
  const EditAvailabilityView({super.key});

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
            'Edit availability',
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
      child: SingleChildScrollView(
        padding: EdgeInsets.all(HightWidthSizes.setValue_16),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date field (disabled for edit)
              CustomTextField(
                label: 'Date',
                hintText: 'dd/mm/yyyy',
                controller: controller.dateController,
                readOnly: true,
                enabled: false,
                validator: controller.validateDate,
                suffixIcon: Padding(
                  padding: EdgeInsets.only(
                    right: HightWidthSizes.setValue_15,
                    left: HightWidthSizes.setValue_25,
                  ),
                  child: AppImages.availability_calender_svg(
                    width: HightWidthSizes.setValue_18,
                    height: HightWidthSizes.setValue_18,
                  ),
                ),
              ),
              SizedBox(height: HightWidthSizes.setValue_16),

              Center(
                child: Container(
                  height: HightWidthSizes.setValue_2,
                  decoration: BoxDecoration(
                    color: AppColor.color_F4F4F4,
                  ),
                ),
              ),
              SizedBox(height: HightWidthSizes.setValue_16),

              // Available from
              Text(
                'Available from',
                style: TextStyle(
                  fontFamily: AppFonts.rubikRegular,
                  fontWeight: FontWeight.w400,
                  fontSize: FontSizes.setFontValue_14,
                  color: AppColor.color_2D2D2D,
                ),
              ),
              SizedBox(height: HightWidthSizes.setValue_8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: '',
                      hintText: 'From',
                      controller: controller.availableFromController,
                      readOnly: true,
                      showLabel: false,
                      onTap: () => controller.pickAvailableFrom(context),
                      validator: controller.validateAvailableFrom,
                      suffixIcon: Padding(
                        padding: EdgeInsets.only(
                          right: HightWidthSizes.setValue_15,
                          left: HightWidthSizes.setValue_25,
                        ),
                        child: AppImages.availability_clock_svg(
                          width: HightWidthSizes.setValue_18,
                          height: HightWidthSizes.setValue_18,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: HightWidthSizes.setValue_12),
                  Expanded(
                    child: CustomTextField(
                      label: '',
                      hintText: 'Until',
                      controller: controller.availableUntilController,
                      readOnly: true,
                      showLabel: false,
                      onTap: () => controller.pickAvailableUntil(context),
                      validator: controller.validateAvailableUntil,
                      suffixIcon: Padding(
                        padding: EdgeInsets.only(
                          right: HightWidthSizes.setValue_15,
                          left: HightWidthSizes.setValue_25,
                        ),
                        child: AppImages.availability_clock_svg(
                          width: HightWidthSizes.setValue_18,
                          height: HightWidthSizes.setValue_18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: HightWidthSizes.setValue_16),
              Center(
                child: Container(
                  height: HightWidthSizes.setValue_2,
                  decoration: BoxDecoration(
                    color: AppColor.color_F4F4F4,
                  ),
                ),
              ),
              SizedBox(height: HightWidthSizes.setValue_16),

              // Unavailable time
              Text(
                'Unavailable time',
                style: TextStyle(
                  fontFamily: AppFonts.rubikRegular,
                  fontWeight: FontWeight.w400,
                  fontSize: FontSizes.setFontValue_14,
                  color: AppColor.color_2D2D2D,
                ),
              ),
              SizedBox(height: HightWidthSizes.setValue_8),
              Form(
                key: controller.unavailableTimeFormKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: '',
                        hintText: 'From',
                        controller: controller.unavailableFromController,
                        readOnly: true,
                        onTap: () => controller.pickUnavailableFrom(context),
                        showLabel: false,
                        validator: controller.validateUnavailableFrom,
                        suffixIcon: Padding(
                          padding: EdgeInsets.only(
                            right: HightWidthSizes.setValue_15,
                            left: HightWidthSizes.setValue_10,
                          ),
                          child: AppImages.availability_clock_svg(
                            width: HightWidthSizes.setValue_18,
                            height: HightWidthSizes.setValue_18,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: HightWidthSizes.setValue_12),
                    Expanded(
                      child: CustomTextField(
                        label: '',
                        hintText: 'Until',
                        controller: controller.unavailableUntilController,
                        readOnly: true,
                        onTap: () => controller.pickUnavailableUntil(context),
                        showLabel: false,
                        validator: controller.validateUnavailableUntil,
                        suffixIcon: Padding(
                          padding: EdgeInsets.only(
                            right: HightWidthSizes.setValue_15,
                            left: HightWidthSizes.setValue_10,
                          ),
                          child: AppImages.availability_clock_svg(
                            width: HightWidthSizes.setValue_18,
                            height: HightWidthSizes.setValue_18,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: HightWidthSizes.setValue_12),
                    ElevatedButton(
                      onPressed: controller.addUnavailableTime,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.color_2FC4B2,
                        foregroundColor: AppColor.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: HightWidthSizes.setValue_16,
                          vertical: HightWidthSizes.setValue_14,
                        ),
                        minimumSize: Size(
                          HightWidthSizes.setValue_70,
                          HightWidthSizes.setValue_50,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            HightWidthSizes.setValue_10,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Add',
                        style: TextStyle(
                          fontFamily: AppFonts.rubikRegular,
                          fontWeight: FontWeight.w400,
                          color: AppColor.white,
                          fontSize: FontSizes.setFontValue_14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // List of added unavailable times
              Obx(
                () => controller.unavailableTimes.isEmpty
                    ? SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: HightWidthSizes.setValue_12),
                          ...controller.unavailableTimes.asMap().entries.map(
                            (entry) {
                              final index = entry.key;
                              final unavailableTime = entry.value;
                              return Container(
                                margin: EdgeInsets.only(
                                  bottom: HightWidthSizes.setValue_8,
                                ),
                                padding: EdgeInsets.all(
                                  HightWidthSizes.setValue_12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColor.color_F7F7F7,
                                  borderRadius: BorderRadius.circular(
                                    HightWidthSizes.setValue_10,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${_formatTimeOfDay2(unavailableTime.from)} - ${_formatTimeOfDay2(unavailableTime.until)}',
                                        style: TextStyle(
                                          fontFamily: AppFonts.rubikRegular,
                                          fontWeight: FontWeight.w400,
                                          fontSize: FontSizes.setFontValue_14,
                                          color: AppColor.color_2D2D2D,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.close,
                                        size: HightWidthSizes.setValue_18,
                                        color: AppColor.color_B53232,
                                      ),
                                      onPressed: () =>
                                          controller.removeUnavailableTime(
                                        index,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
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
              // Analytics: Log update availability tap event
              AnalyticsService.instance.logEvent(
                name: 'update_availability_tap',
                parameters: {
                  'screen_name': 'ProfessionalEditAvailabilityScreen',
                  'screen_class': 'EditAvailabilityView',
                  'element_text': 'update availability',
                  'element_location': 'button_tap_cta',
                  'page_category': 'calendar',
                },
              );
              controller.onUpdateAvailability();
            },
            child: Text(
              'Update availability',
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

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatTimeOfDay2(TimeOfDay time) {
    int hour12 = time.hour;
    final period = time.hour < 12 ? 'AM' : 'PM';

    // Convert 24-hour format to 12-hour format
    if (hour12 == 0) {
      hour12 = 12; // 0:00 becomes 12:00 AM
    } else if (hour12 > 12) {
      hour12 = hour12 - 12; // 13-23 becomes 1-11 PM
    }
    // 1-11 stays as is for AM, 12 stays as 12 for PM

    final hour = hour12.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}
