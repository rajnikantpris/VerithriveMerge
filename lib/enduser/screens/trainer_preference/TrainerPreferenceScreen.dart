import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import 'package:verithrive_dev/enduser/utils/app_text_styles.dart';
import 'TrainerPreferenceController.dart';

class TrainerPreferenceScreen extends GetView<TrainerPreferenceController> {
  const TrainerPreferenceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(AppAssets.back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Trainer preference',
          style: AppTextStyles.appBarTitle(
            fontSize: 18,
            color: AppColors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLightColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Trainer preference',
                style: AppTextStyles.appBarTitle(
                  fontSize: 24,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your preferred trainer.',
                style: AppTextStyles.mediumTextStyle(
                  fontSize: 14,
                  color: AppColors.greyText,
                ),
              ),
              const SizedBox(height: 24),
              Obx(
                () => Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: controller.preferences
                      .map(
                        (pref) => GestureDetector(
                          onTap: () => controller.selectPreference(pref),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: controller.selectedPreference.value == pref
                                  ? AppColors.primaryLightColor
                                  : AppColors.lightGreyEEEEEE,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: controller.selectedPreference.value == pref
                                    ? AppColors.primaryColor
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  pref,
                                  style: AppTextStyles.mediumTextStyle(
                                    fontSize: 14,
                                    color: AppColors.blueColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Get.back(result: controller.selectedPreference.value),
                  child: Text(
                    'Skip',
                    style: AppTextStyles.mediumTextStyle(
                      fontSize: 16,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

