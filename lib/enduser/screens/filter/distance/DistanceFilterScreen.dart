import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/screens/filter/distance/DistanceController.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import 'package:verithrive_dev/enduser/utils/app_text_styles.dart';

class DistanceFilterScreen extends GetView<DistanceController> {
  const DistanceFilterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.back(result: {'distance': controller.maxDistance.value});
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon: SvgPicture.asset(AppAssets.back,),
            onPressed: () => Get.back(result: {'distance': controller.maxDistance.value}),
          ),
        title: Text(
          'Distance',
          style: AppTextStyles.mediumTextStyle(
            fontSize: 16,
            color: AppColors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distance',
              style: AppTextStyles.regularTextStyle(
                fontSize: 16,
                color: AppColors.color2D2D2D,
              ),
            ),
            const SizedBox(height: 10),

            // Slider
            Obx(
                  () => SliderTheme(
                data: SliderThemeData(
                  // padding: EdgeInsets.zero,
                  activeTrackColor: AppColors.primaryColor,
                  inactiveTrackColor: Colors.grey.shade300,
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

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Stack(
                children: [
                  // Full width container for positioning
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Start Label (0)
                      Text(
                        '${controller.minDistance.toStringAsFixed(0)}',
                        style: AppTextStyles.regularTextStyle(
                          fontSize: 14,
                          color: AppColors.color2D2D2D,
                        ),
                      ),

                      // End Label (25mi)
                      Text(
                        '${controller.maxDistanceLimit.toStringAsFixed(0)}mi',
                        style: AppTextStyles.regularTextStyle(
                          fontSize: 14,
                          color: AppColors.color2D2D2D,
                        ),
                      ),
                    ],
                  ),

                  // Current Value Label (centered based on slider position)
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Calculate the position of the current value
                        final double range = controller.maxDistanceLimit - controller.minDistance;
                        final double position = (controller.maxDistance.value - controller.minDistance) / range;
                        final double leftPosition = constraints.maxWidth * position;
                        
                        // Ensure the label doesn't go off-screen
                        // Clamp the position to keep text visible (accounting for 40px width)
                        final double clampedLeft = (leftPosition - 20).clamp(0.0, constraints.maxWidth - 40);

                        return Stack(
                          children: [
                            Positioned(
                              left: clampedLeft, // Offset to center the text, clamped to stay on screen
                              child: Container(
                                width: 40,
                                alignment: Alignment.center,
                                child: Obx(() => Text(
                                  '${controller.maxDistance.value.toStringAsFixed(0)}mi',
                                  style: AppTextStyles.regularTextStyle(
                                    fontSize: 14,
                                    color: AppColors.color2D2D2D,
                                  ),
                                ),),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
      ),
    );
  }
}