import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import 'package:verithrive_dev/enduser/utils/app_text_styles.dart';
import '../../utils/AppText.dart';
import 'PaymentSuccessController.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final PaymentSuccessController controller = Get.put(PaymentSuccessController());

  @override
  Widget build(BuildContext context) {
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
                    decorationThickness: 1
                  ),
                ),
                SizedBox(width: 5,),
                Icon(Icons.arrow_forward, color: AppColors.primaryColor,size: 20,)
              ],
            ),
          ),

        ],
      ),
    );
  }
}