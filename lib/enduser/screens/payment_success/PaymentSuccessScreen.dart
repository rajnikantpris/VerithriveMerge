import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import 'package:verithrive_dev/enduser/utils/app_text_styles.dart';
import '../../utils/AppText.dart';
import '../../../services/analytics_service.dart';
import 'PaymentSuccessController.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final PaymentSuccessController controller =
      Get.put(PaymentSuccessController());

  @override
  Widget build(BuildContext context) {
    // Log purchase analytics when successful payment page is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments as Map<String, dynamic>?;
      final category = AnalyticsService.validateCurrency(
                  args?['category'] as String? ?? 'wellness') ==
              'GBP'
          ? (args?['category'] as String? ?? 'wellness')
          : (args?['category'] as String? ?? 'wellness');
      final resolvedCategory = args?['category'] as String? ?? 'wellness';

      final professionalId = args?['professional_id']?.toString() ?? '';
      final serviceName = args?['service_name']?.toString() ?? '';
      final itemPrice = AnalyticsService.validatePrice(args?['price']);
      // booking_id is the canonical transaction ID — consistent with the booking confirmation email
      final transactionId = args?['booking_id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final consultationType = args?['consultation_type']?.toString() ?? '';
      final itemVariant = args?['item_variant']?.toString() ?? '';
      final itemBrand = args?['item_brand']?.toString() ?? '';

      AnalyticsService.instance.logPurchaseEvent(
        item: AnalyticsService.instance.buildItem(
          itemId: professionalId.isNotEmpty ? professionalId : 'unknown',
          itemName: itemVariant.isNotEmpty
              ? itemVariant
              : (serviceName.isNotEmpty ? serviceName : 'unknown'),
          itemCategory: resolvedCategory,
          itemCategory2:
              consultationType.isNotEmpty ? consultationType : serviceName,
          itemVariant:
              consultationType.isNotEmpty ? consultationType : serviceName,
          itemBrand: itemBrand.isNotEmpty
              ? itemBrand
              : (consultationType.isNotEmpty
                  ? consultationType
                  : resolvedCategory),
          price: itemPrice,
          quantity: 1,
        ),
        transactionId: transactionId,
        value: itemPrice,
      );
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      body: _buildSuccessScreen(),
    );
  }

  Widget _buildSuccessScreen() {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(AppAssets.thank_you),
          SizedBox(height: 50),
          Text(
            AppText.paymentSuccessful,
            style: AppTextStyles.popinSemiboldTextStyle(
              fontSize: 24,
              color: AppColors.primaryColor,
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              AppText.allSetPayment,
              style: AppTextStyles.regularTextStyle(
                fontSize: 16,
                color: AppColors.blueColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 20),
          InkWell(
            onTap: () {
              controller.goToHomepage();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppText.homepage,
                  style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 16,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primaryColor,
                      decorationThickness: 1),
                ),
                SizedBox(
                  width: 5,
                ),
                Icon(
                  Icons.arrow_forward,
                  color: AppColors.primaryColor,
                  size: 20,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
