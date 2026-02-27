import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import 'package:verithrive_dev/enduser/utils/app_text_styles.dart';
import 'CardDetailsController.dart';
import 'CardModel.dart';

class CardDetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CardDetailsController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
          'Card Details',
          style: AppTextStyles.mediumTextStyle(
            fontSize: 20,
            color: AppColors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() => controller.isLoading.value
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: controller.cards.isEmpty
                      ? Center(
                          child: Text(
                            'No cards saved',
                            style: AppTextStyles.regularTextStyle(
                              fontSize: 16,
                              color: AppColors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: controller.cards.length,
                          itemBuilder: (context, index) {
                            final card = controller.cards[index];
                            return _buildCardItem(card, controller, index);
                          },
                        ),
                ),
                // Add new card button
                Container(
                  padding: EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => controller.showAddCardDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Add new card',
                        style: AppTextStyles.buttonTextStyle(),
                      ),
                    ),
                  ),
                ),
              ],
            )),
    );
  }

  Widget _buildCardItem(CardModel card, CardDetailsController controller, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGreyF5F7F8,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Debit card',
                style: AppTextStyles.popinMediumTextStyle(
                  fontSize: 14,
                  color: AppColors.color313131,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => controller.showEditCardDialog(Get.context!, card, index),
                    child: Row(
                      children: [
                        SvgPicture.asset(AppAssets.edit_1, width: 14, height: 14),
                        SizedBox(width: 5),
                        Text(
                          'Edit',
                          style: AppTextStyles.popinRegularTextStyle(
                            fontSize: 12,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => controller.showRemoveCardDialog(Get.context!, index),
                    child: Row(
                      children: [
                        SvgPicture.asset(AppAssets.delete_border),
                        SizedBox(width: 4),
                        Text(
                          'Remove',
                          style: AppTextStyles.popinRegularTextStyle(
                            fontSize: 12,
                            color: AppColors.redDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(AppAssets.visa),
                  SizedBox(width: 20),
                  Text(
                    card.maskedNumber,
                    style: AppTextStyles.popinRegularTextStyle(
                      fontSize: 14,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              Obx(() => Radio(
                value: index,
                groupValue: controller.selectedCardIndex.value,
                onChanged: (value) => controller.selectCard(value as int),
                activeColor: AppColors.primaryColor,
              )),
            ],
          ),
        ],
      ),
    );
  }
}

