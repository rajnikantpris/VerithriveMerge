import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/routes/app_routes.dart';
import 'package:verithrive_dev/enduser/screens/filter/availability/AvailabilityBinding.dart';
import 'package:verithrive_dev/enduser/screens/filter/availability/AvailabilityFilterScreen.dart';
import 'package:verithrive_dev/enduser/screens/filter/distance/DistanceBinding.dart';
import 'package:verithrive_dev/enduser/screens/filter/distance/DistanceFilterScreen.dart';
import 'package:verithrive_dev/enduser/screens/filter/gender/GenderBinding.dart';
import 'package:verithrive_dev/enduser/screens/filter/gender/GenderFilterScreen.dart';
import 'package:verithrive_dev/enduser/screens/filter/price/PriceBinding.dart';
import 'package:verithrive_dev/enduser/screens/filter/price/PriceFilterScreen.dart';
import 'package:verithrive_dev/enduser/screens/filter/professional/ProfessionalBinding.dart';
import 'package:verithrive_dev/enduser/screens/filter/professional/ProfessionalFilterScreen.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import 'package:verithrive_dev/enduser/utils/app_text_styles.dart';
import '../../../services/analytics_service.dart';
import 'FilterController.dart';

class FilterView extends GetView<FilterController> {
  const FilterView({Key? key, this.pageCategory = 'wellness'}) : super(key: key);
  
  final String pageCategory;

  @override
  Widget build(BuildContext context) {
    controller.logScreenViewOnce(pageCategory);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(AppAssets.back,),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Filters',
          style: AppTextStyles.mediumTextStyle(
            fontSize: 20,
            color: AppColors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(20),
              children: [
                _buildFilterOptionWithCustomIcon(
                  customIcon: SvgPicture.asset(AppAssets.professional),
                  title: 'Professional',
                  onTap: () async {
                    // Analytics: Log filter tap event
                    AnalyticsService.instance.logEvent(
                      name: 'filter_tap',
                      parameters: {
                        'screen_name': 'FilterView',
                        'screen_class': 'FilterView',
                        'element_text': 'Professional',
                        'element_location': 'filter_tap',
                        'page_category': pageCategory,
                      },
                    );
                    final result = await Get.to(
                      () => ProfessionalFilterScreen(),
                      binding: ProfessionalBinding(),
                    );
                    if (result != null && result is Map<String, dynamic>) {
                      if (result['professional'] != null) {
                        bool manuallySelected = result['hasManuallySelected'] ?? false;
                        // Only update FilterController if user manually selected something
                        if (manuallySelected) {
                          controller.setProfessionalSubType(result['professional'] as String, manuallySelected: manuallySelected);
                        }
                      }
                    }
                  },
                ),
                _buildDivider(),
                _buildFilterOption(
                  imagePath: AppAssets.distance,
                  title: 'Distance',
                  onTap: () async {
                    // Analytics: Log filter tap event
                    AnalyticsService.instance.logEvent(
                      name: 'filter_tap',
                      parameters: {
                        'screen_name': 'FilterView',
                        'screen_class': 'FilterView',
                        'element_text': 'Distance',
                        'element_location': 'filter_tap',
                        'page_category': pageCategory,
                      },
                    );
                    final result = await Get.to(
                      () => DistanceFilterScreen(),
                      binding: DistanceBinding(),
                    );
                    if (result != null && result is Map<String, dynamic>) {
                      if (result['distance'] != null) {
                        controller.setDistance(result['distance'] as double);
                      }
                    }
                  },
                ),
                _buildDivider(),
                _buildFilterOptionWithCustomIcon(
                  customIcon: _buildPriceIcon(),
                  title: 'Price',
                  onTap: () async {
                    // Analytics: Log filter tap event
                    AnalyticsService.instance.logEvent(
                      name: 'filter_tap',
                      parameters: {
                        'screen_name': 'FilterView',
                        'screen_class': 'FilterView',
                        'element_text': 'Price',
                        'element_location': 'filter_tap',
                        'page_category': pageCategory,
                      },
                    );
                    final result = await Get.to(
                      () => PriceFilterScreen(),
                      binding: PriceBinding(),
                    );
                    if (result != null && result is Map<String, dynamic>) {
                      if (result['minPrice'] != null && result['maxPrice'] != null) {
                        controller.setPriceRange(
                          result['minPrice'] as double,
                          result['maxPrice'] as double,
                        );
                      }
                    }
                  },
                ),
                _buildDivider(),
                _buildFilterOption(
                  imagePath: AppAssets.availability,
                  title: 'Availability',
                  onTap: () async {
                    // Analytics: Log filter tap event
                    AnalyticsService.instance.logEvent(
                      name: 'filter_tap',
                      parameters: {
                        'screen_name': 'FilterView',
                        'screen_class': 'FilterView',
                        'element_text': 'Availability',
                        'element_location': 'filter_tap',
                        'page_category': pageCategory,
                      },
                    );
                    final result = await Get.to(
                      () => AvailabilityFilterScreen(),
                      binding: AvailabilityBinding(),
                    );
                    if (result != null && result is Map<String, dynamic>) {
                      if (result['availability'] != null) {
                        bool manuallySelected = result['hasManuallySelected'] ?? false;
                        controller.setAvailability(result['availability'] as String, manuallySelected: manuallySelected);
                      }
                    }
                  },
                ),
                _buildDivider(),
                _buildFilterOption(
                  imagePath: AppAssets.service_provider,
                  title: 'Service provider gender',
                  onTap: () async {
                    // Analytics: Log filter tap event
                    AnalyticsService.instance.logEvent(
                      name: 'filter_tap',
                      parameters: {
                        'screen_name': 'FilterView',
                        'screen_class': 'FilterView',
                        'element_text': 'Service provider gender',
                        'element_location': 'filter_tap',
                        'page_category': pageCategory,
                      },
                    );
                    final result = await Get.to(
                      () => GenderFilterScreen(),
                      binding: GenderBinding(),
                    );
                    if (result != null && result is Map<String, dynamic>) {
                      if (result['gender'] != null) {
                        bool manuallySelected = result['hasManuallySelected'] ?? false;
                        controller.setGender(result['gender'] as String, manuallySelected: manuallySelected);
                      }
                    }
                  },
                ),
                _buildDivider(),
              ],
            ),
          ),


          Obx(() =>
           controller.hasFilter.value ? Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => controller.reset(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Clear Filter',
                  style: AppTextStyles.mediumTextStyle(
                    fontSize: 16,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          )
              : SizedBox.shrink()),
          // Apply Filter Button - show only when filters are applied
          Obx(() => controller.hasAnyFilterApplied
              ? Container(
                  padding: EdgeInsets.only(left: 20,right: 20,bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => controller.applyFilters(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Apply Filter',
                        style: AppTextStyles.mediumTextStyle(
                          fontSize: 16,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                )
              : SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildFilterOption({
    required String imagePath,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding:  EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            SvgPicture.asset(imagePath),
             SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.regularTextStyle(
                  fontSize: 14,
                  color: AppColors.black,
                ),
              ),
            ),
            SvgPicture.asset(AppAssets.arrow_right,color: AppColors.black,),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.lightGreyEEEEEE,
    );
  }

  Widget _buildFilterOptionWithCustomIcon({
    required Widget customIcon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding:  EdgeInsets.symmetric( vertical: 16),
        child: Row(
          children: [
            customIcon,
             SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.regularTextStyle(
                  fontSize: 14,
                  color: AppColors.black,
                ),
              ),
            ),
            SvgPicture.asset(AppAssets.arrow_right,color: AppColors.black,)
          ],
        ),
      ),
    );
  }

  Widget _buildPriceIcon() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.black,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          '£',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
      ),
    );
  }
}
