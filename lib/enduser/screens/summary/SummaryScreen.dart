import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import '../../utils/AppText.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../../services/analytics_service.dart';
import 'SummaryController.dart';
import '../cart/DashedLinePainter.dart';
import '../cart/CartController.dart';

class SummaryScreen extends StatelessWidget {
  final SummaryController controller = Get.put(SummaryController());
  final CartController cartController = Get.find<CartController>(); // Keep for time picker functionality

  @override
  Widget build(BuildContext context) {
    // Log screen view analytics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments as Map<String, dynamic>?;
      final category = args?['category'] as String? ?? 'wellness';
      
      AnalyticsService.instance.logScreenView(
        screenName: 'SummaryScreen',
        screenClass: 'SummaryScreen',
        pageCategory: category,
        elementLocation: 'view',
      );
    });

    // Log view_cart analytics when cart is viewed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments as Map<String, dynamic>?;
      final category = args?['category'] as String? ?? 'wellness';
      final itemVariant = args?['item_variant']?.toString() ?? '';
      final itemBrand = args?['item_brand']?.toString() ?? '';

      AnalyticsService.instance.logViewCartEvent(
        item: AnalyticsService.instance.buildItem(
          itemId: cartController.professionalId.value.isNotEmpty ? cartController.professionalId.value : 'unknown',
          itemName: cartController.serviceName.value.isNotEmpty ? cartController.serviceName.value : 'unknown',
          itemCategory: category,
          itemVariant: itemVariant.isNotEmpty ? itemVariant : cartController.consultationType.value,
          itemBrand: itemBrand.isNotEmpty ? itemBrand : (cartController.consultationType.value.isNotEmpty ? cartController.consultationType.value : category),
          price: cartController.price.value,
          quantity: 1,
        ),
        value: cartController.price.value,
      );
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        scrolledUnderElevation: 4,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          AppText.summary,
          style: AppTextStyles.mediumTextStyle(
            fontSize: 20,
            color: AppColors.black
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Complete Booking Expiry
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
                    fontSize: 15,
                    color: AppColors.blueColor,
                  ),
                  children: [
                    TextSpan(
                      text: '${controller.expiryTime.value}.',
                      style: AppTextStyles.mediumTextStyle(
                        fontSize: 15,
                        color: AppColors.blueColor,
                      )
                    ),
                  ],
                ),
              )),
            ),

            SizedBox(height: 20),

            // Time Selection Display (Read-only)
            Row(
              children: [
                Expanded(
                  child: _buildTimeDisplay(
                    label: AppText.from,
                    time: controller.fromTime,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildTimeDisplay(
                    label: AppText.until,
                    time: controller.untilTime,
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            Card(
              color: AppColors.white,
              elevation: 4,
              child: _buildSummarySection(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildSummarySection() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Name and Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  controller.serviceName.value,
                  style: AppTextStyles.regularTextStyle(
                    fontSize: 16,
                    color: AppColors.black,
                  ),
                ),
              ),
              Text(
                '£${controller.price.value.toStringAsFixed(2)}',
                style: AppTextStyles.popinSemiboldTextStyle(
                  fontSize: 20,
                  color: AppColors.color2D3648,
                ),
              ),
            ],
          ),
      
          SizedBox(height: 16),
      
          // Dashed Divider
          CustomPaint(
            size: Size(double.infinity, 1),
            painter: DashedLinePainter(),
          ),
      
          SizedBox(height: 16),
      
          // Date & Time
          Text(
            AppText.dateTime,
            style: AppTextStyles.popinRegularTextStyle(
              fontSize: 14,
              color: AppColors.color9D9D9D,
            ),
          ),
          SizedBox(height: 4),
          Obx(() => Text(
            controller.getFormattedDateTime(),
            style: AppTextStyles.regularTextStyle(
              fontSize: 14,
              color: AppColors.color2B2B2B,
            ),
          )),
      
          SizedBox(height: 16),
      
          // Location
          Text(
            AppText.location,
            style: AppTextStyles.popinRegularTextStyle(
              fontSize: 14,
              color: AppColors.color9D9D9D,
            ),
          ),
          SizedBox(height: 4),
          Obx(() => Text(
            controller.location.value,
            style: AppTextStyles.regularTextStyle(
              fontSize: 14,
              color: AppColors.color2B2B2B,
            ),
          )),
      
          SizedBox(height: 20),
      
          // Info Box
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(AppAssets.info),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppText.cancelRescheduleInfo,
                    style: AppTextStyles.regularTextStyle(
                      fontSize: 12,
                      color: AppColors.blueColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
      
          SizedBox(height: 20),
      
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.editBooking,
                  icon: SvgPicture.asset(AppAssets.edit),
                  label: Text(
                    'Edit booking',
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 14,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w400,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primaryColor,
                      decorationThickness: 1
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: controller.removeBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.redDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Remove',
                    style: AppTextStyles.regularTextStyle(
                      fontSize: 16,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        onPressed: controller.proceedToPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 15)
        ),
        child: Text(
          AppText.proceedToPayment,
          style: AppTextStyles.mediumTextStyle(
            fontSize: 16,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeDisplay({
    required String label,
    required Rxn<TimeOfDay> time,
  }) {
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
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50, // Slightly different background to indicate read-only
              ),
              child: Row(
                children: [
                  Text(
                    controller.formatTime(time.value).isEmpty
                        ? AppText.defaultTime
                        : controller.formatTime(time.value),
                    style: AppTextStyles.popinRegularTextStyle(
                      fontSize: 14,
                      color: AppColors.blueColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ));
  }
}

