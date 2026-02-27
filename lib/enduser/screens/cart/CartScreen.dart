import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import '../../utils/AppText.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import 'CartController.dart';

class CartScreen extends StatelessWidget {
  final bool showSummary;

  CartScreen({this.showSummary = false});
  
  final controller = Get.put(CartController());

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
          icon: Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          showSummary ? AppText.summary : AppText.consultationInPerson,
          style: AppTextStyles.mediumTextStyle(
            fontSize: 20,
            color: AppColors.black
          ),
        ),
        centerTitle: showSummary,
      ),
      bottomNavigationBar: _buildContinueButton(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreyF5F7F8,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Obx(() => Text.rich(
                    TextSpan(
                      text: AppText.completeBookingExpiry,
                      style: AppTextStyles.regularTextStyle(
                        fontSize: 14,
                        color: AppColors.blueColor,
                      ),
                      children: [
                        TextSpan(
                          text: '${controller.expiryTime.value}.',
                          style: AppTextStyles.mediumTextStyle(
                            fontSize: 14,
                            color: AppColors.blueColor,
                          )
                        ),
                      ],
                    ),
                  )),
                ),
            
                SizedBox(height: 20),
            
                // Time Selection
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeSelector(
                        context,
                        label: AppText.from,
                        time: controller.fromTime,
                        onTap: () => controller.selectFromTime(context),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildTimeSelector(
                        context,
                        label: AppText.until,
                        time: controller.untilTime,
                        onTap: null, // Disabled - until time is auto-calculated
                        showIcon: false,
                      ),
                    ),
                  ],
                ),
            
              ],
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(
    BuildContext context, {
    required String label,
    required Rxn<TimeOfDay> time,
    required VoidCallback? onTap,
    bool showIcon = true,
  }) {
    final bool isEnabled = onTap != null;
    
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.regularTextStyle(
                fontSize: 14,
                color: AppColors.color2D2D2D,
              ),
            ),
            SizedBox(height: 8),
            GestureDetector(
              onTap: isEnabled ? onTap : null,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: isEnabled ? Colors.transparent : Colors.grey.shade50,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      controller.formatTime(time.value).isEmpty
                          ? AppText.defaultTime
                          : controller.formatTime(time.value),
                      style: AppTextStyles.popinRegularTextStyle(
                        fontSize: 14,
                        color: isEnabled ? AppColors.blueColor : AppColors.greyText,
                      ),
                    ),
                    if (showIcon && isEnabled)
                      SvgPicture.asset(AppAssets.time),
                  ],
                ),
              ),
            ),
          ],
        ));
  }

  Widget _buildContinueButton() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        onPressed: controller.continueBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 15)
        ),
        child: Text(
          AppText.continueText,
          style: AppTextStyles.mediumTextStyle(
            fontSize: 16,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}
