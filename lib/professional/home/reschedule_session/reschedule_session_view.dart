import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/base_view.dart';
import '../../../theme/colors.dart';
import '../../../theme/fonts.dart';
import '../../../theme/font_sizes.dart';
import '../../../theme/hight_width_sizes.dart';
import '../../../theme/image_paths.dart';
import '../../../widgets/custom_text_field.dart';
import 'reschedule_session_controller.dart';

class RescheduleSessionView extends BaseView<RescheduleSessionController> {
  const RescheduleSessionView({super.key});

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
            'Reschedule session',
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
    // Log screen view analytics
    /*
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.logScreenView(
        screenName: 'ProfessionalRescheduleScreen',
        screenClass: 'RescheduleSessionView',
        pageCategory: 'home',
        elementLocation: 'view',
      );
    });
    */

    return Container(
      color: AppColor.white,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(HightWidthSizes.setValue_16),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current session card
              if (controller.session != null) _buildCurrentSessionCard(),
              SizedBox(height: HightWidthSizes.setValue_20),

              // Reschedule section
              Text(
                'Reschedule',
                style: TextStyle(
                  fontFamily: AppFonts.rubikBold,
                  fontWeight: FontWeight.w600,
                  fontSize: FontSizes.setFontValue_18,
                  color: AppColor.color_2D2D2D,
                ),
              ),
              SizedBox(height: HightWidthSizes.setValue_16),

              // Date field
              CustomTextField(
                label: 'Date',
                hintText: 'dd/MM/yyyy',
                controller: controller.dateController,
                readOnly: true,
                onTap: () => controller.pickDate(context),
                validator: controller.validateDate,
                suffixIcon: Padding(
                  padding: EdgeInsets.only(
                    right: HightWidthSizes.setValue_15,
                    left: HightWidthSizes.setValue_25,
                  ),
                  child: AppImages.calender_list_svg(
                    width: HightWidthSizes.setValue_18,
                    height: HightWidthSizes.setValue_18,
                  ),
                ),
              ),
              SizedBox(height: HightWidthSizes.setValue_16),

              // Time fields row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // From time
                  Expanded(
                    child: CustomTextField(
                      label: 'From',
                      hintText: 'HH:MM AM/PM',
                      controller: controller.fromTimeController,
                      readOnly: true,
                      onTap: () => controller.pickFromTime(context),
                      validator: controller.validateTime,
                      suffixIcon: Padding(
                        padding: EdgeInsets.only(
                          right: HightWidthSizes.setValue_15,
                          left: HightWidthSizes.setValue_25,
                        ),
                        child: AppImages.clock_list_svg(
                          width: HightWidthSizes.setValue_18,
                          height: HightWidthSizes.setValue_18,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: HightWidthSizes.setValue_12),
                  // Until time (auto-calculated, read-only)
                  Expanded(
                    child: CustomTextField(
                      label: 'Until',
                      hintText: 'HH:MM AM/PM',
                      controller: controller.untilTimeController,
                      readOnly: true,
                      enabled: false, // Disable interaction since it's auto-calculated
                      validator: controller.validateUntilTime,
                    ),
                  ),
                ],
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
            onPressed: () {
              // Analytics: Log reschedule session tap event
              /*
              AnalyticsService.instance.logEvent(
                name: 'reschedule_session_tap',
                parameters: {
                  'screen_name': 'ProfessionalRescheduleScreen',
                  'screen_class': 'RescheduleSessionView',
                  'element_text': 'Reschedule Session',
                  'element_location': 'button_tap_cta',
                  'page_category': 'home',
                },
              );
              */
              controller.onReschedule();
            },
            child: Text(
              'Reschedule session',
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

  Widget _buildCurrentSessionCard() {
    final session = controller.session!;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(HightWidthSizes.setValue_14),
        border: Border.all(color: AppColor.color_ECECEC),
        boxShadow: [
          BoxShadow(
            color: AppColor.color_ECECEC,
            blurRadius: HightWidthSizes.setValue_3,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              left: HightWidthSizes.setValue_14,
              right: HightWidthSizes.setValue_14,
              top: HightWidthSizes.setValue_10,
              bottom: HightWidthSizes.setValue_10,
            ),
            decoration: BoxDecoration(
              color: AppColor.color_0045B5_0A,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(HightWidthSizes.setValue_14),
                topRight: Radius.circular(HightWidthSizes.setValue_14),
              ),
            ),
            child: Text(
              session.title,
              style: TextStyle(
                fontFamily: AppFonts.poppinsBold,
                fontWeight: FontWeight.w700,
                color: AppColor.color_414141,
                fontSize: FontSizes.setFontValue_14,
              ),
            ),
          ),
          SizedBox(height: HightWidthSizes.setValue_12),
          Row(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: HightWidthSizes.setValue_14,
                  right: HightWidthSizes.setValue_14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppImages.user_list_svg(
                          width: HightWidthSizes.setValue_15,
                          height: HightWidthSizes.setValue_15,
                        ),
                        SizedBox(width: HightWidthSizes.setValue_5),
                        Text(
                          session.name,
                          style: TextStyle(
                            fontFamily: AppFonts.rubikRegular,
                            fontWeight: FontWeight.w400,
                            color: AppColor.color_414141,
                            fontSize: FontSizes.setFontValue_14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: HightWidthSizes.setValue_5),
                    Row(
                      children: [
                        AppImages.clock_list_svg(
                          width: HightWidthSizes.setValue_15,
                          height: HightWidthSizes.setValue_15,
                        ),
                        SizedBox(width: HightWidthSizes.setValue_5),
                        Text(
                          session.timeRange,
                          style: TextStyle(
                            fontFamily: AppFonts.rubikRegular,
                            fontWeight: FontWeight.w400,
                            color: AppColor.color_898989,
                            fontSize: FontSizes.setFontValue_14,
                          ),
                        ),
                        SizedBox(width: HightWidthSizes.setValue_10),
                        AppImages.calender_list_svg(
                          width: HightWidthSizes.setValue_15,
                          height: HightWidthSizes.setValue_15,
                        ),
                        SizedBox(width: HightWidthSizes.setValue_5),
                        Text(
                          session.dateLabel,
                          style: TextStyle(
                            fontFamily: AppFonts.rubikRegular,
                            fontWeight: FontWeight.w400,
                            color: AppColor.color_898989,
                            fontSize: FontSizes.setFontValue_14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: HightWidthSizes.setValue_12),
        ],
      ),
    );
  }
}
