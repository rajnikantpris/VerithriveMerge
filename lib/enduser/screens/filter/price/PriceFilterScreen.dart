import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import 'package:verithrive_dev/enduser/utils/app_text_styles.dart';
import 'PriceController.dart';

class PriceFilterScreen extends GetView<PriceController> {
  const PriceFilterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.back(result: {
          'minPrice': controller.priceRangeValues.value.start,
          'maxPrice': controller.priceRangeValues.value.end,
        });
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon: SvgPicture.asset(AppAssets.back),
            onPressed: () => Get.back(result: {
              'minPrice': controller.priceRangeValues.value.start,
              'maxPrice': controller.priceRangeValues.value.end,
            }),
          ),
        title: Text(
          'Price',
          style: AppTextStyles.mediumTextStyle(
            fontSize: 16,
            color: AppColors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Price range',
              style: AppTextStyles.regularTextStyle(
                fontSize: 14,
                color: AppColors.color2D2D2D,
              ),
            ),
          ),

           SizedBox(height: 16),

          // RangeSlider for both min and max
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Obx(
                  () => SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppColors.primaryColor,
                  inactiveTrackColor: AppColors.lightGreyEEEEEE,
                  thumbColor: AppColors.primaryColor,
                  overlayColor: AppColors.primaryColor.withOpacity(0.2),
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 16,
                  ),
                  rangeThumbShape: const RoundRangeSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                  rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
                ),
                child: RangeSlider(
                  values: controller.priceRangeValues.value,
                  min: 0,
                  max: 1000,
                  divisions: 100,
                  onChanged: controller.setPriceRange,
                ),
              ),
            ),
          ),

           SizedBox(height: 24),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildPriceField(
                    label: 'Minimum',
                    controller: controller.minPriceController,
                    onChanged: controller.setMinPrice,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPriceField(
                    label: 'Maximum',
                    controller: controller.maxPriceController,
                    onChanged: controller.setMaxPrice,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildPriceField({
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: AppTextStyles.regularTextStyle(
        fontSize: 16,
        color: AppColors.blueColor,
      ),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: AppTextStyles.mediumTextStyle(
          fontSize: 14,
          color: AppColors.grey,
        ),
        prefixText: '£',
        prefixStyle: AppTextStyles.regularTextStyle(
          fontSize: 16,
          color: AppColors.blueColor,
        ),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.black.withOpacity(0.30),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.lightGreyEEEEEE,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.primaryColor,
            width: 1.5,
          ),
        ),
      ),
      onChanged: onChanged,
    );
  }
}