import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:verithrive_dev/enduser/screens/consultation/ConsultationBinding.dart';
import 'package:verithrive_dev/enduser/screens/consultation/ConsultationBookingScreen.dart';
import 'package:verithrive_dev/enduser/screens/login/LoginBinding.dart';
import 'package:verithrive_dev/enduser/screens/login/LoginView.dart';
import 'package:verithrive_dev/enduser/screens/message/ChatDetailBinding.dart';
import 'package:verithrive_dev/enduser/screens/message/ChatDetailScreen.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import '../../core/widget/animated_loader.dart';
import '../../utils/AppText.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../models/Conversation.dart';
import '../../../services/analytics_service.dart';
import '../../../services/deep_link_service.dart';
import 'TherapistDetailController.dart';

class TherapistDetailScreen extends StatelessWidget {
  const TherapistDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Put controller and pass the therapist via arguments from listing screen
    final TherapistDetailController controller =
    Get.put(TherapistDetailController());

    // Log screen view analytics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments as Map<String, dynamic>?;
      final category = args?['category'] as String? ?? 'wellness';
      
      AnalyticsService.instance.logScreenView(
        screenName: 'TherapistDetailScreen',
        screenClass: 'TherapistDetailScreen',
        pageCategory: category,
        elementLocation: 'view',
      );
    });

    // Log view_item analytics when therapist details are displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments as Map<String, dynamic>?;
      final category = args?['category'] as String? ?? 'wellness';
      final therapistArg = args?['therapist'];
      final therapistId = therapistArg?.id?.toString() ?? controller.therapist.value.id;
      final therapistName = controller.therapist.value.name.isNotEmpty
          ? controller.therapist.value.name
          : (therapistArg?.name?.toString() ?? '');
      final therapistSpecialty = controller.therapist.value.specialty.isNotEmpty
          ? controller.therapist.value.specialty
          : (therapistArg?.specialty?.toString() ?? '');
      final therapistServices = controller.therapist.value.services;
      final therapistPrice = AnalyticsService.validatePrice(
          controller.therapist.value.price > 0 ? controller.therapist.value.price : (therapistArg?.price ?? 0.0));

      AnalyticsService.instance.logViewItemEvent(
        item: AnalyticsService.instance.buildItem(
          itemId: therapistId.isNotEmpty ? therapistId : '',
          itemName: therapistSpecialty.isNotEmpty ? therapistSpecialty : (therapistName.isNotEmpty ? therapistName : ''),
          itemCategory: category,
          itemVariant: therapistSpecialty,
          itemBrand: therapistServices.isNotEmpty ? therapistServices.first : therapistSpecialty,
          price: therapistPrice,
          quantity: 1,
        ),
        value: therapistPrice,
      );
    });

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
        actions: [
          IconButton(
            icon: SvgPicture.asset(AppAssets.share),
            onPressed: () async {
              final id = controller.professionalId ??
                  controller.therapist.value.id;
              if (id.isEmpty) return;
              final name = controller.therapist.value.name;
              final url = DeepLinkService.buildProfileShareUrl(id);
              final box = context.findRenderObject() as RenderBox?;
              final origin = (box != null && box.hasSize)
                  ? box.localToGlobal(Offset.zero) & box.size
                  : const Rect.fromLTWH(0, 0, 1, 1);
              await Share.share(
                name.isNotEmpty
                    ? 'Check out $name on Verithrive:\n$url'
                    : 'Check out this professional on Verithrive:\n$url',
                subject: 'Professional Profile',
                sharePositionOrigin: origin,
              );
            },
          ),
        ],
      ),
      body: Obx(() => controller.isLoading.value
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === Therapist Header Card ===
                  _buildHeaderCard(controller),
                  _buildTabsSection(controller),
                ],
              ),
            )),
      bottomNavigationBar: _buildBottomChatButton(),
    );
  }

  Widget _buildHeaderCard(TherapistDetailController controller) {
    return Obx(() {
      final therapist = controller.therapist.value;
      return Container(
      padding:  EdgeInsets.all(10),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.lightGreyF5F7F8,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: controller.therapist.value.imageUrl.isNotEmpty
                    ? Image.network(
                        controller.therapist.value.imageUrl,
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            therapist.name,
                            style: AppTextStyles.popinSemiboldTextStyle(
                              fontSize: 20,
                              color: AppColors.blueColor
                            ),
                          ),
                        ),
                      /*  SvgPicture.asset(
                          AppAssets.verified,
                          colorFilter: ColorFilter.mode(
                            controller.category == 'wellness'
                                ? AppColors.colorFFB54D
                                : AppColors.color00AAD9,
                            BlendMode.srcIn,
                          ),
                        ),*/

                        SvgPicture.asset(
                          AppAssets.verified,
                          colorFilter: ColorFilter.mode(
                                AppColors.colorFFB54D,BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      therapist.specialty,
                      style: AppTextStyles.regularTextStyle(
                          fontSize: 14, color: AppColors.greyText),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SvgPicture.asset(AppAssets.location),
                        const SizedBox(width: 4),
                        Text(
                          '${therapist.distance} miles',
                          style: AppTextStyles.regularTextStyle(
                              fontSize: 14, color: AppColors.greyText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        SvgPicture.asset(AppAssets.green_dot),
                        const SizedBox(width: 4),
                        Text(
                          controller.availability_text.toString(),
                          style: AppTextStyles.regularTextStyle(
                              fontSize: 12, color: AppColors.greenText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.lightGreyEEEEEE),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                iconPath: AppAssets.star_black,
                value: controller.ratingCount.value > 0
                    ? controller.averageRating.value.toStringAsFixed(1)
                    : therapist.rating.toString(),
                label: AppText.ratings,
              ),
              _buildStatItem(
                iconPath: AppAssets.experience,
                value: controller.totalExperience.value > 0
                    ? '${controller.totalExperience.value} ${AppText.years}'
                    : '${therapist.yearsExperience} ${AppText.years}',
                label: AppText.experience,
              ),
              _buildStatItem(
                iconPath: AppAssets.booking_user,
                value: '${controller.booking_count}+',
                label: AppText.bookings,
              ),
            ],
          ),
        ],
      ),
    );
    });
  }

  Widget _buildTabsSection(TherapistDetailController controller) {
    return Container(
      padding:  EdgeInsets.all(10),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.lightGreyF5F7F8,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.lightGreyEEEEEE,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: controller.tabController,
              labelColor: AppColors.black,
              unselectedLabelColor: AppColors.greyText,
              indicator: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              isScrollable: false, // Make tabs equal width
              tabAlignment: TabAlignment.fill, // Fill available space equally
              labelPadding: EdgeInsets.symmetric(horizontal: 8),
              labelStyle: AppTextStyles.mediumTextStyle(fontSize: 14,color: AppColors.blueColor),
              unselectedLabelStyle: AppTextStyles.regularTextStyle(fontSize: 12,color: AppColors.greyText),
              tabs: const [
                Tab(text: AppText.services),
                Tab(text: AppText.about),
                Tab(text: AppText.qualifications),
              ],
            ),
          ),
          SizedBox(height: 20),
          // Use LayoutBuilder to get available height, but let content expand naturally
          Obx(() {
            int selectedIndex = controller.selectedTabIndex.value;
            return IndexedStack(
              index: selectedIndex,
              children: [
                _buildServicesTab(controller),
                _buildAboutTab(controller),
                _buildQualificationsTab(controller),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildServicesTab(TherapistDetailController controller) {
    return Obx(() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: controller.services.map((service) {
              return Container(
                padding:
                 EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      AppAssets.green_dot,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      service.serviceName,
                      style: AppTextStyles.regularTextStyle(
                          fontSize: 14, color: AppColors.black),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          ...controller.packages.map((package) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              package.title,
                              style: AppTextStyles.regularTextStyle(
                                  fontSize: 14, color: AppColors.black),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              package.duration + " mins",
                              style: AppTextStyles.regularTextStyle(
                                  fontSize: 14, color: AppColors.greyText),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        (package.isFree || package.price == 0)
                            ? 'Free'
                            : '£${package.price % 1 == 0 ? package.price.toInt() : package.price.toStringAsFixed(2)}',
                        style: AppTextStyles.mediumTextStyle(fontSize: 16,color: AppColors.black),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          final _bookingArgs = Get.arguments as Map<String, dynamic>?;
                          final _bookingCategory = _bookingArgs?['category'] as String? ?? '';

                          // Analytics: Log select_item event for booking option
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            final detailController = Get.find<TherapistDetailController>();
                            final therapist = detailController.therapist.value;
                            final category = _bookingCategory;

                            AnalyticsService.instance.logSelectItemEvent(
                              item: AnalyticsService.instance.buildItem(
                                itemId: therapist.id.isNotEmpty ? therapist.id : '',
                                itemName: therapist.specialty.isNotEmpty ? therapist.specialty : (therapist.name.isNotEmpty ? therapist.name : ''),
                                itemCategory: category,
                                itemCategory2: package.title,
                                itemVariant: therapist.specialty,
                                itemBrand: therapist.services.isNotEmpty ? therapist.services.first : therapist.specialty,
                                price: AnalyticsService.validatePrice(package.price),
                                quantity: 1,
                              ),
                              itemListId: category,
                              itemListName: category,
                            );
                          });

                          // Parse duration from string (e.g., "45" or "45 mins") to integer
                          int? durationMinutes;
                          try {
                            String durationStr = package.duration.replaceAll(RegExp(r'[^0-9]'), '');
                            durationMinutes = int.tryParse(durationStr);
                          } catch (e) {
                            print('Error parsing duration: $e');
                          }
                          
                          // Build full address
                          String fullAddress = '';
                          if (controller.address.value.isNotEmpty) {
                            fullAddress = controller.address.value;
                            if (controller.postcode.value.isNotEmpty) {
                              fullAddress += ', ${controller.postcode.value}';
                            }
                          }

                          print("Rajnikant testing testing --->"+controller.isGuest.value.toString());

                          if(!controller.isGuest.value) {
                            Get.to(
                              () => ConsultationBookingScreen(),
                              binding: ConsultationBinding(),
                              arguments: {
                                'professional_id': controller.professionalId ??
                                    controller.therapist.value.id,
                                'duration_minutes': durationMinutes ?? 30,
                                // Default to 30 if parsing fails
                                'service_name': package.title,
                                'price': package.price,
                                'selected_date': package.service_format_date,
                                'location': fullAddress,
                                'service_format_id': package.serviceFormatId ??
                                    '',
                                // Pass service_format_id for summary
                                'professional_service_format_id': package
                                    .professionalServiceFormatId ?? '',
                                // Pass _id for create-booking API
                                'category': _bookingCategory,
                                'item_variant': controller.therapist.value.specialty,
                                'item_brand': controller.therapist.value.services.isNotEmpty ? controller.therapist.value.services.first : controller.therapist.value.specialty,
                              },
                            );
                          }else{
                            //CommonUtils.getIntance().toastMessage("Please login to book service");
                            Get.to(
                                  () => const LoginView(),
                              binding: LoginBinding(),
                              arguments: "guest"
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                        ),
                        child: Text(
                          AppText.book,
                          style: AppTextStyles.mediumTextStyle(
                              fontSize: 14, color: AppColors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: AppColors.lightGreyEEEEEE),
                  if (package.discount != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLightColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(AppAssets.save_info),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              package.discount!,
                              style: AppTextStyles.regularTextStyle(
                                  fontSize: 14, color: AppColors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ],
      ));
  }

  Widget _buildAboutTab(TherapistDetailController controller) {
    return Obx(() => Text(
        controller.description.value.isNotEmpty
            ? controller.description.value
            : 'No description available.',
        style: AppTextStyles.regularTextStyle(
          fontSize: 14,
          color: AppColors.black
        ),
      ));
  }

  Widget _buildQualificationsTab(TherapistDetailController controller) {
    return Obx(() => controller.qualifications.isEmpty
        ? Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No qualifications available',
                style: AppTextStyles.regularTextStyle(
                  fontSize: 14,
                  color: AppColors.greyText,
                ),
              ),
            ),
          )
        : Column(
            children: controller.qualifications.map((qualification) {
              return _buildQualificationItem(
                imagePath: AppAssets.degree,
                title: qualification.schoolOrUniversity,
                subtitle: qualification.degreeOrCertificate,
              );
            }).toList(),
          ));
  }

  Widget _buildQualificationItem({
    required String imagePath,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding:  EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SvgPicture.asset(imagePath),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.mediumTextStyle(
                      fontSize: 16, color: AppColors.blueColor),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.regularTextStyle(
                      fontSize: 12, color: AppColors.color9D9D9D),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String iconPath,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        SvgPicture.asset(iconPath),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.regularTextStyle(
              fontSize: 14, color: AppColors.black),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.regularTextStyle(
              fontSize: 14, color: AppColors.greyText),
        ),
      ],
    );
  }

  Widget _buildBottomChatButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.white,
      ),
      child: ElevatedButton(
        onPressed: () {
          // Analytics: Log chat tap event
          final args = Get.arguments as Map<String, dynamic>?;
          final category = args?['category'] as String? ?? 'wellness';

          AnalyticsService.instance.logEvent(
            name: 'chat_tap',
            parameters: {
              'screen_name': 'TherapistDetailScreen',
              'screen_class': 'TherapistDetailScreen',
              'element_text': 'chat',
              'element_location': 'button_tap_cta',
              'page_category': category,
            },
          );

          final controller = Get.find<TherapistDetailController>();

          if(!controller.isGuest.value) {
            final therapist = controller.therapist.value;
            final conversation = Conversation(
              id: '',
              // Empty ID to let chat system create room
              name: therapist.name,
              profileImageUrl: therapist.imageUrl.isNotEmpty ? therapist
                  .imageUrl : null,
              lastMessage: '',
              lastMessageTime: DateTime.now(),
              userId: therapist.id,
              // Use therapist ID as user ID for other person
              isOnline: controller.availability_text.value
                  .toLowerCase()
                  .contains('available'),
            );

            // Navigate to chat detail screen with conversation data
            Get.to(
              () => ChatDetailScreen(),
              binding: ChatDetailBinding(),
              arguments: conversation,
            );
          }else{
            // CommonUtils.getIntance().toastMessage("Please login to chat");
            Get.to(
                  () => const LoginView(),
              binding: LoginBinding(),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(AppAssets.chat),
            const SizedBox(width: 8),
            Text(
              AppText.chat,
              style: AppTextStyles.buttonTextStyle(),
            ),
          ],
        ),
      ),
    );
  }
}
