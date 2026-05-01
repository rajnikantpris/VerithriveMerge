import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import 'package:verithrive_dev/enduser/utils/app_text_styles.dart';
import '../../utils/AppText.dart';
import '../../utils/app_assets.dart';
import '../../../services/analytics_service.dart';
import 'AppointmentController.dart';

class AppointmentBookingScreen extends StatelessWidget {
  final AppointmentController controller = Get.put(AppointmentController());

  @override
  Widget build(BuildContext context) {
    // Log screen view analytics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.logScreenView(
        screenName: 'AppointmentBookingScreen',
        screenClass: 'AppointmentBookingScreen',
        pageCategory: 'wellness',
        elementLocation: 'view',
      );
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(AppAssets.back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppText.lastMinuteAppointment,
                          style: AppTextStyles.popinSemiboldTextStyle(
                            fontSize: 20,
                            color: AppColors.black,
                          ),
                        ),
                        SizedBox(height: 24),

                        // Yes/No Buttons
                        Obx(() => Row(
                          children: [
                            Expanded(
                              child: _buildOptionButton(
                                text: AppText.yes,
                                isSelected: controller.isLastMinute.value,
                                onTap: () {
                                  // Analytics: Log hurry tap event
                                  AnalyticsService.instance.logEvent(
                                    name: 'hurry_tap',
                                    parameters: {
                                      'screen_name': 'AppointmentBookingScreen',
                                      'screen_class': 'AppointmentBookingScreen',
                                      'element_text': 'hurry yes',
                                      'element_location': 'button_tap_cta',
                                      'page_category': 'wellness',
                                    },
                                  );
                                  controller.toggleAppointmentType(true);
                                },
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildOptionButton(
                                text: AppText.no,
                                isSelected: !controller.isLastMinute.value,
                                onTap: () {
                                  // Analytics: Log non-hurry tap event
                                  AnalyticsService.instance.logEvent(
                                    name: 'hurry_tap',
                                    parameters: {
                                      'screen_name': 'AppointmentBookingScreen',
                                      'screen_class': 'AppointmentBookingScreen',
                                      'element_text': 'hurry no',
                                      'element_location': 'button_tap_cta',
                                      'page_category': 'wellness',
                                    },
                                  );
                                  controller.toggleAppointmentType(false);
                                },
                              ),
                            ),
                          ],
                        )),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),

                  Obx(() => controller.isLastMinute.value
                      ? Container(
                    color: AppColors.colorF0F0F0,
                    height: 10,
                  )
                      : SizedBox()),

                  Obx(() => controller.isLastMinute.value
                      ? Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppText.selectAvailability,
                          style: AppTextStyles.regularTextStyle(
                            fontSize: 14,
                            color: AppColors.color2D2D2D
                          ),
                        ),
                        SizedBox(height: 8),

                        // Availability Dropdown
                        Obx(() => GestureDetector(
                          onTap: () => _showAvailabilityPicker(),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.color9D9D9D),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  controller.selectedAvailability.value.isEmpty
                                      ? AppText.selectHere
                                      : controller.selectedAvailability.value,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontFamily: 'Rubik',
                                    fontWeight: FontWeight.w400,
                                    color: controller.selectedAvailability.value.isEmpty
                                        ? AppColors.color9D9D9D
                                        : AppColors.black,
                                  ),
                                ),
                                SvgPicture.asset(
                                  AppAssets.arrow_right,
                                  color: AppColors.black,
                                ),
                              ],
                            ),
                          ),
                        )),
                      ],
                    ),
                  )
                      : SizedBox()),




                  Obx(() => controller.isLastMinute.value
                      ? Container(
                    color: AppColors.colorF0F0F0,
                    height: 10,
                  )
                      : SizedBox()),

                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Obx(() => controller.isLastMinute.value
                        ? _buildLastMinuteOptions()
                        : SizedBox.shrink()),
                  ),

                  Obx(() => controller.isLastMinute.value
                      ? Container(
                    color: AppColors.colorF0F0F0,
                    height: 10,
                  )
                      : SizedBox()),


                ],
              ),
            ),
          ),

          // Bottom Fixed Button
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
            ),
            child: SafeArea(
              child: Obx(
                    () => SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (controller.isLastMinute.value) {
                        // Analytics: Log search tap event
                        AnalyticsService.instance.logEvent(
                          name: 'search_tap',
                          parameters: {
                            'screen_name': 'AppointmentBookingScreen',
                            'screen_class': 'AppointmentBookingScreen',
                            'element_text': 'search',
                            'element_location': 'button_tap_cta',
                            'page_category': 'wellness',
                          },
                        );
                        controller.search();
                      } else {
                        // Analytics: Log skip tap event
                        AnalyticsService.instance.logEvent(
                          name: 'hurry_tap',
                          parameters: {
                            'screen_name': 'AppointmentBookingScreen',
                            'screen_class': 'AppointmentBookingScreen',
                            'element_text': 'skip',
                            'element_location': 'button_tap_cta',
                            'page_category': 'wellness',
                          },
                        );
                        controller.skip();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      controller.isLastMinute.value
                          ? AppText.search
                          : AppText.skip,
                      style: AppTextStyles.buttonTextStyle(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor
              : AppColors.colorF1F1F1,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            text,
            style: AppTextStyles.regularTextStyle(
              fontSize: 16,
              color: isSelected ? AppColors.white : AppColors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLastMinuteOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Distance Slider
        Text(
          AppText.distance,
          style: AppTextStyles.regularTextStyle(
              fontSize: 14,
              color: AppColors.color2D2D2D
          ),
        ),
        SizedBox(height: 12),

        Obx(() => Column(
          children: [


            Obx(
                  () => SliderTheme(
                data: SliderThemeData(
                  // padding: EdgeInsets.zero,
                  activeTrackColor: AppColors.primaryColor,
                  inactiveTrackColor: AppColors.color9D9D9D,
                  thumbColor: AppColors.primaryColor,
                  overlayColor: AppColors.primaryColor.withOpacity(0.2),
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 16,
                  ),
                ),
                child: Slider(
                  value: controller.maxDistance.value,
                  min: controller.minDistance,
                  max: controller.maxDistanceLimit,
                  onChanged: controller.setDistance,
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppText.zeroKm,
                    style: AppTextStyles.mediumTextStyle(
                      fontSize: 14,
                      color: AppColors.color2D2D2D,
                    ),
                  ),
                  Text(
                    '${controller.distance.value.round()}mi',
                    style: AppTextStyles.regularTextStyle(
                      fontSize: 14,
                      color: AppColors.color2D2D2D,
                    ),
                  ),
                  Text(
                    AppText.twentyFiveKm,
                    style: AppTextStyles.regularTextStyle(
                      fontSize: 14,
                      color:AppColors.color2D2D2D,
                    ),
                  ),
                ],
              ),
            ),
          ],
        )),

        SizedBox(height: 20), // Extra padding before button
      ],
    );
  }

  void _showAvailabilityPicker() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppText.selectAvailability,
              style: AppTextStyles.boldTextStyle(
                fontSize: 18,
                color: AppColors.black,
              ),
            ),
            SizedBox(height: 20),
            ...[
              AppText.availableInNext3Days,
              AppText.availableInNext7Days,
              AppText.availableInNext10Days,
            ]
                .map((option) => ListTile(
              title: Text(option),
              onTap: () {
                controller.setAvailability(option);
                Get.back();
              },
            ))
                .toList(),
          ],
        ),
      ),
    );
  }
}