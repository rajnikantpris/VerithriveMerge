import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import 'package:verithrive_dev/enduser/utils/app_text_styles.dart';
import 'ProfessionalController.dart';

class ProfessionalFilterScreen extends GetView<ProfessionalController> {
  const ProfessionalFilterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.back(result: {
          'professional': controller.selectedSubTypeId.value,
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
            icon: SvgPicture.asset(
              AppAssets.back,
            ),
            onPressed: () => Get.back(result: {
              'professional': controller.selectedSubTypeId.value,
              'hasManuallySelected': controller.hasManuallySelected.value,
            }),
          ),
        title: Text(
          'Professional',
          style: AppTextStyles.mediumTextStyle(
            fontSize: 20,
            color: AppColors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: Obx(
        () => controller.subTypes.isEmpty
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No professionals available',
                    style: AppTextStyles.regularTextStyle(
                      fontSize: 14,
                      color: AppColors.greyText,
                    ),
                  ),
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20),
                itemCount: controller.subTypes.length,
                itemBuilder: (context, index) {
                  final subType = controller.subTypes[index];
                  final subTypeId = subType['id'] as String? ?? '';
                  final subTypeName = subType['sub_type'] as String? ?? '';
                  
                  return Column(
                    children: [
                      ListTile(
                        title: Text(
                          subTypeName,
                          style: AppTextStyles.regularTextStyle(
                            fontSize: 14,
                            color: AppColors.black,
                          ),
                        ),
                        trailing: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(width: 24, height: 24),
                          visualDensity: const VisualDensity(horizontal: -4, vertical: -2),
                          onPressed: () => controller.selectSubType(subTypeId),
                          icon: controller.isSubTypeSelected(subTypeId)
                              ? SvgPicture.asset(AppAssets.check)
                              : SvgPicture.asset(AppAssets.uncheck),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        endIndent: 6,
                        color: AppColors.lightGreyEEEEEE,
                      ),
                    ],
                  );
                },
              ),
      ),
      ),
    );
  }
}

