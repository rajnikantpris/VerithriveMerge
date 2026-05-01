import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import 'package:verithrive_dev/enduser/utils/app_text_styles.dart';
import 'package:verithrive_dev/services/analytics_service.dart';
import '../../core/widget/animated_loader.dart';
import '../../utils/AppText.dart';
import '../therapy_list/Therapist.dart';
import 'SavedController.dart';

class SavedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SavedController>(tag: 'saved');

    // Log screen view analytics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.logScreenView(
        screenName: 'SavedScreen',
        screenClass: 'SavedScreen',
        pageCategory: 'saved',
        elementLocation: 'view',
      );
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 4, // 🔴 Add shadow depth (try 2-8)
        shadowColor: Colors.black.withOpacity(
          0.1,
        ), // Optional: customize shadow color
        scrolledUnderElevation: 4,
        centerTitle: true,
        title: Text(
          AppText.saved,
          style: AppTextStyles.mediumTextStyle(
            fontSize: 20,
            color: AppColors.black,
          ),
        ),
      ),
      body: Obx(
        () => controller.isLoading.value
            ? Center(
                child: AnimatedLoader(
                  assetPath: AppAssets.loader1,
                  width: 80,
                  height: 80,
                  color: AppColors.primaryColor,
                  duration: const Duration(seconds: 2),
                ),
              )
            : controller.savedTherapists.isEmpty
            ? RefreshIndicator(
                onRefresh: () async {
                  controller.loadSavedTherapists();
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                AppAssets.wishlist,
                                width: 64,
                                height: 64,
                                color: AppColors.grey.withOpacity(0.5),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No saved items yet',
                                style: AppTextStyles.mediumTextStyle(
                                  fontSize: 18,
                                  color: AppColors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Your saved professionals will appear here',
                                style: AppTextStyles.regularTextStyle(
                                  fontSize: 14,
                                  color: AppColors.greyText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  controller.loadSavedTherapists();
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16),
                  itemCount: controller.savedTherapists.length,
                  itemBuilder: (context, index) {
                    final therapist = controller.savedTherapists[index];
                    return _buildSavedCard(context, therapist, controller);
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildSavedCard(
    BuildContext context,
    Therapist therapist,
    SavedController controller,
  ) {
    return GestureDetector(
      onTap: () {
        // Navigate to therapist detail screen
        // Get.to(() => TherapistDetailScreen(therapist: therapist));
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey, width: 0.5),
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
            SizedBox(width: 12),
            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(5),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and saved icon
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
                      GestureDetector(
                        onTap: () => controller.toggleFavorite(therapist.id),
                        child: SvgPicture.asset(
                          AppAssets.wishlist,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  // Specialty
                  Text(
                    therapist.specialty,
                    style: AppTextStyles.regularTextStyle(
                      fontSize: 14,
                      color: AppColors.greyText,
                    ),
                  ),
                  SizedBox(height: 8),
                  // Location and Rating
                  Row(
                    children: [
                      SvgPicture.asset(
                        AppAssets.location,
                        color: AppColors.primaryColor,
                        width: 12,
                        height: 12,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${therapist.distance} miles',
                        style: AppTextStyles.regularTextStyle(
                          fontSize: 14,
                          color: AppColors.greyText,
                        ),
                      ),
                      SizedBox(width: 12),
                      SvgPicture.asset(
                        AppAssets.rating_selected,
                        width: 12,
                        height: 12,
                      ),
                      SizedBox(width: 4),
                      Row(
                        children: [
                          Text(
                            therapist.rating.toString(),
                            style: AppTextStyles.regularTextStyle(
                              fontSize: 14,
                              color: AppColors.greyText,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '(${therapist.reviewCount} Reviews)',
                            style: AppTextStyles.regularTextStyle(
                              fontSize: 14,
                              color: AppColors.colorC0C0C0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Divider(color: AppColors.lightGrey,),
                  SizedBox(height: 8),
                  // Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppText.price,
                        style: AppTextStyles.semiboldTextStyle(
                          fontSize: 14,
                          color: AppColors.black,
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '£${therapist.price.toInt()}/',
                              style: AppTextStyles.boldTextStyle(
                                fontSize: 16,
                                color: AppColors.black,
                              ),
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
}
