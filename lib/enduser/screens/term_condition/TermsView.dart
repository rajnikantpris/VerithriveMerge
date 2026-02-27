import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_text_styles.dart';


import '../../utils/AppText.dart';

import '../../utils/app_colors.dart';
import 'TermsController.dart';

class TermsView extends GetView<TermsController> {
  const TermsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.white,
        elevation: 4, // 🔴 Add shadow depth (try 2-8)
        shadowColor: Colors.black.withOpacity(
          0.1,
        ), // Optional: customize shadow color
        scrolledUnderElevation: 4,
        leading: IconButton(
          icon: SvgPicture.asset(AppAssets.back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          AppText.termsConditions,
          style: AppTextStyles.appBarTitleTextStyle(),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Scrollable Content
          Expanded(
            child: Obx(
              () => controller.isContentLoading.value
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title - Display HTML content with styling
                          if (controller.termsTitle.value.isNotEmpty)
                            Html(
                              data: controller.termsTitle.value,
                              style: {
                                "body": Style(
                                  color: Colors.black,
                                  fontSize: FontSize.medium,
                                ),
                              },
                            ),
                          SizedBox(height: 16),
                          // Content - Display HTML content with styling
                          if (controller.termsContent.value.isNotEmpty)
                            Html(
                              data: controller.termsContent.value,
                              style: {
                                "body": Style(
                                  color: Colors.black,
                                  fontSize: FontSize.medium,
                                ),
                              },
                            ),
                        ],
                      ),
                    ),
            ),
          ),

          // Fixed Bottom Section
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Checkbox
                Obx(
                  () => Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: Checkbox(
                          value: controller.isAccepted.value,
                          onChanged: controller.toggleAcceptance,
                          activeColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: BorderSide(color: AppColors.grey, width: 1.5),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tick if you would like to receive marketing emails from VERITHRIVE to keep you upto date about latest offers and trends.',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Rubik',
                            fontWeight: FontWeight.w400,
                            color: AppColors.black,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Accept Button
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.acceptAndContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: AppColors.primaryColor
                            .withOpacity(0.6),
                      ),
                      child: controller.isLoading.value
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Accept & continue',
                              style: AppTextStyles.buttonTextStyle(
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
