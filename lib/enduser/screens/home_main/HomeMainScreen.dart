import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/screens/login/LoginBinding.dart';
import 'package:verithrive_dev/enduser/screens/login/LoginView.dart';
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

  // ── Map category type name → text color ───────────────────────────────────
  Color _textColorForType(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('wellness')) return AppColors.wellnessTextColor;
    if (lower.contains('fitness')) return AppColors.fitnessTextColor;
    if (lower.contains('food') || lower.contains('nutrition')) return AppColors.foodnutritionTextColor;
    return AppColors.color4c4c4c;
  }

  // ── Map category type name → card background color ────────────────────────
  Color _bgColorForType(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('wellness')) return AppColors.wellnessBgColor;
    if (lower.contains('fitness')) return AppColors.fitnessBgColor;
    if (lower.contains('food') || lower.contains('nutrition')) return AppColors.foodnutritionBgColor;
    return AppColors.white;
  }

  // ── Map category type name to route key for onCardTap ────────────────────
  String _categoryKeyForType(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('wellness')) return 'wellness';
    if (lower.contains('fitness')) return 'fitness';
    if (lower.contains('food') || lower.contains('nutrition')) return 'food_nutrition';
    return lower;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        scrolledUnderElevation: 4,
        title: Row(children: [Image.asset(AppAssets.home_logo, height: 32)]),
        actions: [
          Obx(() => Stack(
            children: [
              IconButton(
                icon: SvgPicture.asset(AppAssets.proicons_bell),
                onPressed: () {
                  if (!controller.isGuest.value) {
                    Get.to(
                          () => NotificationScreen(),
                      binding: NotificationBinding(),
                    );
                  } else {
                    // CommonUtils.getIntance().toastMessage("Please login to access notifications");
                    Get.to(
                          () => LoginView(),
                      binding: LoginBinding(),
                    );
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
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      controller.unreadCount.value > 99
                          ? '99+'
                          : controller.unreadCount.value.toString(),
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

              // ── Fully dynamic: one section per category in API order ──
              Obx(() {
                if (controller.professionCategories.isEmpty) {
                  return SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: controller.professionCategories.map((category) {
                    return _buildDynamicSection(
                      category.type,                          // title from API
                      _textColorForType(category.type),
                      category.subTypes,                      // sub_types in API order
                      _categoryKeyForType(category.type),
                      _bgColorForType(category.type),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section builder ────────────────────────────────────────────────────────
  Widget _buildDynamicSection(
      String title,
      Color textColor,
      List<SubTypeModel> subTypes,
      String categoryKey,
      Color bgColor,
      ) {
    if (subTypes.isEmpty) return SizedBox.shrink();

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
          children: subTypes
              .map((subType) => _dynamicCard(categoryKey, subType, bgColor))
              .toList(),
        ),
        SizedBox(height: 32),
      ],
    );
  }

  // ── Card builder ───────────────────────────────────────────────────────────
  Widget _dynamicCard(
      String categoryKey,
      SubTypeModel subType,
      Color bgColor,
      ) {
    return InkWell(
      onTap: () => controller.onCardTap(categoryKey, subType.subType, subType.id),
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

  // ── Image builder: network only ───────────────────────────────────────────
  Widget _buildImageWidget(String? imageUrl, String subTypeName) {
    // Normalise URL: ensure https so iOS/Android don't block http
    String? url = imageUrl?.trim();
    if (url != null && url.isNotEmpty && url.startsWith('http://')) {
      url = url.replaceFirst('http://', 'https://');
    }

    if (url != null && url.isNotEmpty) {
      if (url.toLowerCase().endsWith('.svg')) {
        return SvgPicture.network(
          url,
          height: 60,
          width: 60,
          fit: BoxFit.contain,
          placeholderBuilder: (context) => SizedBox(
            height: 40,
            width: 40,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      } else {
        return Image.network(
          url,
          height: 60,
          width: 60,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              height: 40,
              width: 40,
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
            print('Image load error for $url: $error');
            return SizedBox(height: 40, width: 40); // empty box, no asset fallback
          },
        );
      }
    }

    // No URL at all — render empty box
    return SizedBox(height: 40, width: 40);
  }

  // ── Local asset fallback ───────────────────────────────────────────────────
  Widget _getFallbackImage(String subTypeName) {
    return SvgPicture.asset(_getAssetPathForSubType(subTypeName));
  }

  String _getAssetPathForSubType(String subTypeName) {
    final lower = subTypeName.toLowerCase();
    if (lower.contains('chiropractor')) return AppAssets.chiro;
    if (lower.contains('physiotherapist') || lower.contains('physiotherapy')) return AppAssets.physio_therapy;
    if (lower.contains('sports therapist') || lower.contains('sports therapy')) return AppAssets.sports_therapy;
    if (lower.contains('osteopath')) return AppAssets.chiro;
    if (lower.contains('personal trainer')) return AppAssets.personal_trainer;
    if (lower.contains('fitness instructor')) return AppAssets.fitness_instructor;
    if (lower.contains('fitness coach')) return AppAssets.fitness_coach;
    if (lower.contains('nutritionist')) return AppAssets.nutritionist;
    if (lower.contains('dietician')) return AppAssets.Dietician;
    if (lower.contains('private chef')) return AppAssets.private_chef;
    return AppAssets.chiro; // ultimate fallback
  }
}