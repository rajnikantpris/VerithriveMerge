import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/screens/filter/availability/AvailabilityController.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import 'package:verithrive_dev/enduser/utils/app_text_styles.dart';

class AvailabilityFilterScreen extends GetView<AvailabilityController> {
  const AvailabilityFilterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.back(result: {
          'availability': controller.selectedAvailability.value,
          'hasManuallySelected': controller.hasManuallySelected.value,
        });
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon: SvgPicture.asset(AppAssets.back,),
            onPressed: () => Get.back(result: {
              'availability': controller.selectedAvailability.value,
              'hasManuallySelected': controller.hasManuallySelected.value,
            }),
          ),
        title: Text(
          'Availability',
          style: AppTextStyles.mediumTextStyle(
            fontSize: 20,
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
              'Select availability',
              style: AppTextStyles.regularTextStyle(
                fontSize: 14,
                color: AppColors.color2D2D2D,
              ),
            ),
            const SizedBox(height: 5),
            Obx(
              () => InkWell(
                onTap: () => _showAvailabilityPicker(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.grey,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          controller.selectedAvailability.value,
                          style: AppTextStyles.regularTextStyle(
                            fontSize: 16,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      SvgPicture.asset(AppAssets.arrow_right,color: AppColors.black,),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _showAvailabilityPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: controller.availabilityOptions.map((option) {
            return Obx(
              () => ListTile(
                title: Text(
                  option,
                  style: AppTextStyles.mediumTextStyle(
                    fontSize: 16,
                    color: AppColors.black,
                  ),
                ),
                trailing: controller.selectedAvailability.value == option
                    ? Icon(
                        Icons.check,
                        color: AppColors.primaryColor,
                      )
                    : null,
                onTap: () {
                  controller.setAvailability(option);
                  Get.back();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

