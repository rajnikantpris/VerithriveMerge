import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/routes/app_routes.dart';
import 'package:verithrive_dev/enduser/screens/notification/NotificationBinding.dart';
import 'package:verithrive_dev/enduser/screens/notification/NotificationScreen.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import 'package:verithrive_dev/enduser/utils/app_text_styles.dart';
import '../../core/widget/animated_loader.dart';
import '../../core/widget/common_widgets.dart';
import '../../utils/AppText.dart';
import 'HomeMainController.dart';
import 'models/ProfessionTypeModel.dart';

class HomeMainScreen extends StatefulWidget {
  const HomeMainScreen({Key? key}) : super(key: key);

  @override
  State<HomeMainScreen> createState() => _HomeMainScreenState();
}

class _HomeMainScreenState extends State<HomeMainScreen> {
  late final HomeMainController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<HomeMainController>(tag: 'home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 4, // 🔴 Add shadow depth (try 2-8)
        shadowColor: Colors.black.withOpacity(
          0.1,
        ), // Optional: customize shadow color
        scrolledUnderElevation: 4,
        title: Row(children: [Image.asset(AppAssets.home_logo, height: 32)]),
        actions: [
          Obx(() => Stack(
            children: [
              IconButton(
                icon: SvgPicture.asset(AppAssets.proicons_bell),
                onPressed: () {
                  if(!controller.isGuest.value){
                    //Get.toNamed(AppRoutes.notification);
                    Get.to(
                          () => NotificationScreen(),
                      binding: NotificationBinding(),
                    );
                  }else{
                    CommonUtils.getIntance().toastMessage("Please login to access notifications");
                  }
                },
              ),
              if (controller.unreadCount.value > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      controller.unreadCount.value > 99 ? '99+' : controller.unreadCount.value.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          )),
        ],
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
            : SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppText.whoCanWeHelp,
                      style: AppTextStyles.boldTextStyle(
                        fontSize: 32,
                        color: AppColors.color4c4c4c,
                      ),
                    ),
                    SizedBox(height: 32),

                    // Wellness Section
                    Obx(() => controller.wellnessTypes.isNotEmpty
                        ? _buildDynamicSection(
                            AppText.wellness,
                            AppColors.wellnessTextColor,
                            controller.wellnessTypes,
                            'wellness',
                            AppColors.wellnessBgColor,
                          )
                        : _buildSection(
                            AppText.wellness,
                            AppColors.wellnessTextColor,
                            [],
                          )),

                    // Fitness Section
                    Obx(() => controller.fitnessTypes.isNotEmpty
                        ? _buildDynamicSection(
                            AppText.fitness,
                            AppColors.fitnessTextColor,
                            controller.fitnessTypes,
                            'fitness',
                            AppColors.fitnessBgColor,
                          )
                        : _buildSection(
                            AppText.fitness,
                            AppColors.fitnessTextColor,
                            [],
                          )),

                    // Food & Nutrition Section
                    Obx(() => controller.foodNutritionTypes.isNotEmpty
                        ? _buildDynamicSection(
                            AppText.foodNutrition,
                            AppColors.foodnutritionTextColor,
                            controller.foodNutritionTypes,
                            'food_nutrition',
                            AppColors.foodnutritionBgColor,
                          )
                        : _buildSection(
                            AppText.foodNutrition,
                            AppColors.foodnutritionTextColor,
                            [],
                          )),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSection(String title, Color textColor, List<Widget> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.homeTitleStyle(color: textColor)),
        SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          childAspectRatio: 0.95,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: cards,
        ),
        SizedBox(height: 32),
      ],
    );
  }

  Widget _buildDynamicSection(
    String title,
    Color textColor,
    List<SubTypeModel> subTypes,
    String category,
    Color bgColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.homeTitleStyle(color: textColor)),
        SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          childAspectRatio: 0.95,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: subTypes.map((subType) => _dynamicCard(
            controller,
            category,
            subType,
            bgColor,
          )).toList(),
        ),
        SizedBox(height: 32),
      ],
    );
  }

  Widget _dynamicCard(
    HomeMainController controller,
    String category,
    SubTypeModel subType,
    Color bgColor,
  ) {
    return InkWell(
      onTap: () => controller.onCardTap(category, subType.subType, subType.id),
      child: Container(
        padding: EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildImageWidget(subType.image, subType.subType),
            SizedBox(height: 3),
            Text(
              subType.subType,
              textAlign: TextAlign.center,
              style: AppTextStyles.homeTextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String? imageUrl, String subTypeName) {
    // If image URL is provided and not empty, use network image
    if (imageUrl != null && imageUrl.isNotEmpty) {
      // Check if it's an SVG
      if (imageUrl.toLowerCase().endsWith('.svg')) {
        return SvgPicture.network(
          imageUrl,
          placeholderBuilder: (context) => _getFallbackImage(subTypeName),
          errorBuilder: (context, error, stackTrace) => _getFallbackImage(subTypeName),
        );
      } else {
        // For other image formats
        return Image.network(
          imageUrl,
          height: 40,
          width: 40,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              height: 40,
              width: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => _getFallbackImage(subTypeName),
        );
      }
    } else {
      // Use fallback image from local assets
      return _getFallbackImage(subTypeName);
    }
  }

  Widget _getFallbackImage(String subTypeName) {
    // Map sub_type names to local asset paths
    String assetPath = _getAssetPathForSubType(subTypeName);
    return SvgPicture.asset(
      assetPath,
    );
  }

  String _getAssetPathForSubType(String subTypeName) {
    // Map API sub_type names to local asset paths
    String lowerName = subTypeName.toLowerCase();
    
    // Wellness
    if (lowerName.contains('chiropractor')) return AppAssets.chiro;
    if (lowerName.contains('physiotherapist') || lowerName.contains('physiotherapy')) return AppAssets.physio_therapy;
    if (lowerName.contains('sports therapist') || lowerName.contains('sports therapy')) return AppAssets.sports_therapy;
    if (lowerName.contains('osteopath')) return AppAssets.chiro; // Fallback to chiro
    
    // Fitness
    if (lowerName.contains('personal trainer')) return AppAssets.personal_trainer;
    if (lowerName.contains('fitness instructor')) return AppAssets.fitness_instructor;
    if (lowerName.contains('fitness coach')) return AppAssets.fitness_coach;
    
    // Food & Nutrition
    if (lowerName.contains('nutritionist')) return AppAssets.nutritionist;
    if (lowerName.contains('dietician')) return AppAssets.Dietician;
    if (lowerName.contains('private chef')) return AppAssets.private_chef;
    
    // Default fallback
    return AppAssets.chiro;
  }

  Widget _card(
    HomeMainController controller,
    String category,
    String label,
    String imagePath,
    Color bgColor,
  ) {
    return InkWell(
      onTap: () => controller.onCardTap(category, label, null),
      child: Container(
        padding: EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon(icon, size: 42, color: Colors.grey[700]),
            SvgPicture.asset(imagePath),
            SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.homeTextStyle(),
            ),
          ],
        ),
      ),
    );
  }
}
