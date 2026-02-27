import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import 'package:verithrive_dev/enduser/utils/app_text_styles.dart';
import 'NotificationsController.dart';

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationsController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(AppAssets.back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Notifications',
          style: AppTextStyles.mediumTextStyle(
            fontSize: 20,
            color: AppColors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Obx(
                  () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notifications',
                    style: AppTextStyles.regularTextStyle(
                      fontSize: 16,
                      color: AppColors.black,
                    ),
                  ),
                  Transform.scale(
                    scale: 0.7, // 👈 try 0.7–0.85
                    child: Switch(
                      value: controller.notificationsEnabled.value,
                      onChanged: controller.toggleNotifications,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      thumbColor: MaterialStateProperty.resolveWith<Color>(
                            (states) => states.contains(MaterialState.selected)
                            ? Colors.white
                            : Colors.grey.shade400,
                      ),
                      trackColor: MaterialStateProperty.resolveWith<Color>(
                            (states) => states.contains(MaterialState.selected)
                            ? AppColors.primaryColor
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10,),
          Divider(height: 1, color: AppColors.lightGrey),
        ],
      ),
    );
  }
}

