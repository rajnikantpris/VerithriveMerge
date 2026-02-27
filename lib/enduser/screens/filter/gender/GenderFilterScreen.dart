import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/screens/filter/gender/GenderController.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import 'package:verithrive_dev/enduser/utils/app_text_styles.dart';

class GenderFilterScreen extends GetView<GenderController> {
  const GenderFilterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.back(result: {
          'gender': controller.selectedGender.value,
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
              'gender': controller.selectedGender.value,
              'hasManuallySelected': controller.hasManuallySelected.value,
            }),
          ),
        title: Text(
          'Service provider gender',
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
              'Select Gender',
              style: AppTextStyles.regularTextStyle(
                fontSize: 14,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 5),
            Obx(
              () => InkWell(
                onTap: () => _showGenderPicker(context),
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
                          controller.selectedGender.value,
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

  void _showGenderPicker(BuildContext context) {
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
          children: controller.genderOptions.map((gender) {
            return Obx(
              () => ListTile(
                title: Text(
                  gender,
                  style: AppTextStyles.mediumTextStyle(
                    fontSize: 16,
                    color: AppColors.black,
                  ),
                ),
                trailing: controller.selectedGender.value == gender
                    ? Icon(
                        Icons.check,
                        color: AppColors.primaryColor,
                      )
                    : null,
                onTap: () {
                  controller.setGender(gender);
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

