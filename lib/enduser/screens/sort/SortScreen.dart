import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import 'package:verithrive_dev/enduser/utils/app_text_styles.dart';
import 'SortController.dart';

class SortScreen extends GetView<SortController> {
  const SortScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            AppAssets.back,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Sort',
          style: AppTextStyles.mediumTextStyle(
            fontSize: 20,
            color: AppColors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(20),
        itemCount: controller.sortOptions.length,
        itemBuilder: (context, index) {
          final option = controller.sortOptions[index];
          return Obx(
            () => Column(
              children: [
                ListTile(
                  leading: SvgPicture.asset(AppAssets.sort_item),
                  horizontalTitleGap: 5,
                  title: Text(
                    option.title,
                    style: AppTextStyles.regularTextStyle(
                      fontSize: 14,
                      color: AppColors.black,
                    ),
                  ),
                  trailing: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(width: 24, height: 24),
                    visualDensity: const VisualDensity(horizontal: -4, vertical: -2),
                    onPressed: () => controller.selectSortOption(option.value),
                    icon: controller.isSelected(option.value)
                        ? SvgPicture.asset(AppAssets.check)
                        : SvgPicture.asset(AppAssets.uncheck),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 0,
                  ),
                ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    endIndent: 6,
                    color: AppColors.lightGreyEEEEEE,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

