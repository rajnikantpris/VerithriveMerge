import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:verithrive_dev/enduser/routes/app_routes.dart';
import 'package:verithrive_dev/enduser/screens/filter/FilterBinding.dart';
import 'package:verithrive_dev/enduser/screens/filter/FilterScreen.dart';
import 'package:verithrive_dev/enduser/screens/sort/SortBinding.dart';
import 'package:verithrive_dev/enduser/screens/sort/SortScreen.dart';
import 'package:verithrive_dev/enduser/screens/therapy_details/TherapistDetailScreen.dart';
import 'package:verithrive_dev/enduser/screens/therapy_details/TherapyDetailBinding.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import '../../core/widget/animated_loader.dart';
import '../../utils/AppText.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import 'Therapist.dart';
import 'TherapistController.dart';

class TherapistListingScreen extends StatelessWidget {
  final TherapistController controller = Get.put(TherapistController());

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
        title: Obx(() => Text(
          controller.screenTitle.value,
          style: AppTextStyles.mediumTextStyle(
            fontSize: 20,
            color: AppColors.black,
          ),
        )),
      ),
      body: Column(
        children: [
          // Search and Filter
      Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          InkWell(
            onTap: () async {
              final result = await Get.to(
                () => const SortScreen(),
                binding: SortBinding(),
              );
              // Sort is already applied in SortController, no need to do anything here
            },
            child: Row(
              children: [
                SvgPicture.asset(AppAssets.sort),
                SizedBox(width: 3),
                Text(
                  AppText.sort,
                  style: AppTextStyles.regularTextStyle(
                    fontSize: 16,
                    color: AppColors.greyText,
                  ),
                ),
                Obx(() => controller.sortBy.value.isNotEmpty
                    ? Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor, // Green dot
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : SizedBox.shrink()),
              ],
            ),
          ),

          // Vertical Divider
          SizedBox(
            height: 20,
            child: VerticalDivider(
              thickness: 2,
              width: 20,
              color: AppColors.color969696,
            ),
          ),

          InkWell(
            onTap: () async {
              await Get.to(
                () => const FilterScreen(),
                binding: FilterBinding(),
              );
            },
            child: Row(
              children: [
                SvgPicture.asset(AppAssets.filter),
                SizedBox(width: 3),
                Text(
                  AppText.filter,
                  style: AppTextStyles.regularTextStyle(
                    fontSize: 16,
                    color: AppColors.greyText,
                  ),
                ),
                Obx(() {
                  final hasFilter = controller.hasFilter;
                  
                  return hasFilter
                      ? Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor, // Green dot
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : SizedBox.shrink();
                }),
              ],
            ),
          ),
        ],
      ),
    ),

    // Therapist List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(
                  child: AnimatedLoader(
                    assetPath: AppAssets.loader1,
                    width: 80,
                    height: 80,
                    color: AppColors.primaryColor,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
              
              if (controller.filteredTherapists.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async {
                    controller.loadTherapists();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'No professionals found',
                            style: AppTextStyles.regularTextStyle(
                              fontSize: 16,
                              color: AppColors.greyText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
              
              return RefreshIndicator(
                onRefresh: () async {
                  controller.loadTherapists();
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: controller.filteredTherapists.length,
                  itemBuilder: (context, index) {
                    final therapist = controller.filteredTherapists[index];
                    return _buildTherapistCard(therapist);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTherapistCard(Therapist therapist) {
    return GestureDetector(
      onTap: () {
        final category = _getCategoryFromTitle();
        Get.to(
          () => const TherapistDetailScreen(),
          binding: TherapyDetailBinding(),
          arguments: {
            'therapist': therapist,
            'category': category,
          },
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey,width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: therapist.imageUrl.isNotEmpty
                  ? Image.network(
                      therapist.imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey.shade200,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey.shade200,
                          child: Center(
                            child: SizedBox(
                              width: 60,
                              height: 60,
                              child: SvgPicture.asset(
                                AppAssets.profile,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey.shade200,
                      child: Center(
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: SvgPicture.asset(
                            AppAssets.profile,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            therapist.name,
                            style: AppTextStyles.popinSemiboldTextStyle(
                              fontSize: 16,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            controller.toggleFavorite(therapist.id);
                          },
                          child: SvgPicture.asset(
                            AppAssets.wishlist,
                            color: therapist.isFavorite 
                                ? AppColors.primaryColor 
                                : AppColors.greyText,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      therapist.specialty,
                      style: AppTextStyles.regularTextStyle(
                        fontSize: 14,
                        color: AppColors.greyText,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        SvgPicture.asset(AppAssets.location),
                        SizedBox(width: 4),
                        Text(
                          '${therapist.distance} miles',
                          style: AppTextStyles.regularTextStyle(
                            fontSize: 14,
                            color: AppColors.greyText,
                          ),
                        ),
                        SizedBox(width: 12),
                        SvgPicture.asset(AppAssets.rating_selected,height: 10,width: 10,),
                        SizedBox(width: 4),
                        Text(
                          therapist.rating.toString(),
                          style: AppTextStyles.regularTextStyle(
                            fontSize: 14,
                            color: AppColors.greyText,
                          ),
                        ),
                        SizedBox(width:2),
                        Text(
                          '(${therapist.reviewCount} Reviews)',
                          style: AppTextStyles.regularTextStyle(
                            fontSize: 14,
                            color: AppColors.colorC0C0C0,
                          ),
                        ),
                      ],
                    ),
                    Divider(color: AppColors.lightGrey,),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppText.price,
                          style: AppTextStyles.regularTextStyle(
                            fontSize: 14,
                            color: AppColors.black,
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '£${therapist.price}/',
                                style: AppTextStyles.priceSemiboldStyle(),
                              ),
                              TextSpan(
                                text: AppText.perSession,
                                style: AppTextStyles.regularTextStyle(
                                  fontSize: 12,
                                  color: AppColors.color9D9D9D,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _getCategoryFromTitle() {
    final title = controller.screenTitle.value;
    if (title == 'Sport therapists') {
      return 'wellness';
    } else if (title == 'Personal Trainer') {
      return 'fitness';
    } else if (title == 'Nutritionists') {
      return 'food_nutrition';
    }
    return null;
  }
}
