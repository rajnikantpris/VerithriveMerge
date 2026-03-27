import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../../../../common/base_view.dart';
import '../../../../models/subscription_plan_model.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/fonts.dart';
import '../../../../theme/font_sizes.dart';
import '../../../../theme/hight_width_sizes.dart';
import 'profile_subscription_controller.dart';

class ProfileSubscriptionView extends BaseView<ProfileSubscriptionController> {
  const ProfileSubscriptionView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 1),
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000), // #0000001A
              blurRadius: HightWidthSizes.setValue_10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: AppBar(
          backgroundColor: AppColor.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: AppColor.color_2D3648,
            ),
            onPressed: () => Get.back(),
          ),
          centerTitle: true,
          title: Text(
            'Subscription',
            style: TextStyle(
              fontFamily: AppFonts.rubikMedium,
              fontWeight: FontWeight.w500,
              fontSize: FontSizes.setFontValue_18,
              color: AppColor.color_2D3648,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildView(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final appBarHeight = kToolbarHeight + 1; // AppBar height + shadow
    final safeAreaTop = mediaQuery.padding.top;
    final safeAreaBottom = mediaQuery.padding.bottom;
    // Calculate available height: screen height - app bar - safe areas
    final availableHeight =
        screenHeight - appBarHeight - safeAreaTop - safeAreaBottom;
    // Use maximum height constraint but allow cards to be smaller
    final maxCardHeight = availableHeight * 0.85;

    return Container(
      color: AppColor.white,
      child: SafeArea(
        child: Center(
          child: Obx(() {
            if (controller.plans.isEmpty) {
              if (controller.isInitialFetchDone.value) {
                return Center(
                  child: Text(
                    'No subscription plans available',
                    style: TextStyle(
                      fontFamily: AppFonts.rubikRegular,
                      fontSize: FontSizes.setFontValue_14,
                      color: AppColor.color_9D9D9D,
                    ),
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                // Calculate reasonable card height based on available space
                // Cards will size to content but carousel needs a fixed height
                final cardHeight = constraints.maxHeight > 0
                    ? constraints.maxHeight * 0.8
                    : maxCardHeight;

                return CarouselSlider.builder(
                  carouselController: controller.carouselController,
                  itemCount: controller.plans.length,
                  itemBuilder: (context, index, realIndex) {
                    final plan = controller.plans[index];
                    return Container(
                      padding: EdgeInsets.all(10),
                      height: cardHeight,
                      child: _SubscriptionPlanCard(
                        plan: plan,
                      ),
                    );
                  },
                  options: CarouselOptions(
                    height: cardHeight,
                    viewportFraction: 0.75,
                    initialPage: controller.initialPage,
                    enableInfiniteScroll: false,
                    enlargeCenterPage: true,
                    enlargeStrategy: CenterPageEnlargeStrategy.scale,
                    onPageChanged: (index, reason) {
                      controller.onPageChanged(index);
                    },
                    scrollPhysics: BouncingScrollPhysics(),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

class _SubscriptionPlanCard extends StatelessWidget {
  const _SubscriptionPlanCard({
    required this.plan,
  });

  final SubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(HightWidthSizes.setValue_10),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: HightWidthSizes.setValue_10,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: EdgeInsets.all(HightWidthSizes.setValue_20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Plan name
          Text(
            plan.name,
            style: TextStyle(
              fontFamily: AppFonts.rubikMedium,
              fontWeight: FontWeight.w500,
              fontSize: FontSizes.setFontValue_20,
              color: plan.isCurrentPlan
                  ? AppColor.color_32435F
                  : AppColor.color_32435F.withOpacity(0.5),
            ),
          ),
          SizedBox(height: HightWidthSizes.setValue_12),

          // Price - Use highlight_label from API
          Text(
            plan.highlightLabel,
            style: TextStyle(
              fontFamily: AppFonts.rubikMedium,
              fontWeight: FontWeight.w500,
              fontSize: FontSizes.setFontValue_30,
              color: plan.isCurrentPlan
                  ? AppColor.color_2D3648
                  : AppColor.color_1E1E1E.withOpacity(0.5),
            ),
          ),
          SizedBox(height: HightWidthSizes.setValue_16),

          // Divider
          Divider(
            height: HightWidthSizes.setValue_1,
            color: plan.isCurrentPlan
                ? AppColor.color_2D3648
                : AppColor.color_000000.withOpacity(0.1),
          ),
          SizedBox(height: HightWidthSizes.setValue_16),

          // Features header
          Text(
            'Everything in ${plan.name} plan you need:',
            style: plan.isCurrentPlan
                ? TextStyle(
                    fontFamily: AppFonts.rubikRegular,
                    fontWeight: FontWeight.w400,
                    fontSize: FontSizes.setFontValue_12,
                    color: AppColor.color_9D9D9D,
                  )
                : TextStyle(
                    fontFamily: AppFonts.rubikRegular,
                    fontWeight: FontWeight.w400,
                    fontSize: FontSizes.setFontValue_12,
                    color: AppColor.color_9D9D9D,
                  ),
          ),
          SizedBox(height: HightWidthSizes.setValue_12),

          // Features list - Flexible to take available space
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...plan.features.map((feature) => Padding(
                        padding:
                            EdgeInsets.only(bottom: HightWidthSizes.setValue_8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                top: HightWidthSizes.setValue_6,
                                right: HightWidthSizes.setValue_8,
                              ),
                              child: Container(
                                width: HightWidthSizes.setValue_6,
                                height: HightWidthSizes.setValue_6,
                                decoration: BoxDecoration(
                                  color: AppColor.color_2D3648,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                feature,
                                style: TextStyle(
                                  fontFamily: AppFonts.rubikRegular,
                                  fontWeight: FontWeight.w400,
                                  fontSize: FontSizes.setFontValue_14,
                                  color: plan.isCurrentPlan
                                      ? AppColor.color_0E1027
                                      : AppColor.color_0E1027.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),

          SizedBox(height: HightWidthSizes.setValue_16),

          // Current plan indicator
          if (plan.isCurrentPlan)
            Padding(
              padding: EdgeInsets.only(bottom: HightWidthSizes.setValue_12),
              child: Center(
                  child: Text(
                'Current plan',
                style: TextStyle(
                  fontFamily: AppFonts.rubikRegular,
                  fontWeight: FontWeight.w400,
                  fontSize: FontSizes.setFontValue_18,
                  color: AppColor.color_2FC4B2,
                ),
              )),
            ),

          // Buy Now button (only for non-current plans)
          if (!plan.isCurrentPlan)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final controller = Get.find<ProfileSubscriptionController>();
                  controller.onBuyNow(plan);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.color_2FC4B2,
                  foregroundColor: AppColor.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    vertical: HightWidthSizes.setValue_14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      HightWidthSizes.setValue_10,
                    ),
                  ),
                ),
                child: Text(
                  'Buy Now',
                  style: TextStyle(
                    fontFamily: AppFonts.rubikMedium,
                    fontWeight: FontWeight.w500,
                    fontSize: FontSizes.setFontValue_16,
                    color: AppColor.white,
                  ),
                ),
              ),
            ),

          // Cancel subscription button (only for current plan)
          // if (plan.isCurrentPlan)
          //   SizedBox(
          //     width: double.infinity,
          //     child: ElevatedButton(
          //       onPressed: () {
          //         final controller =
          //             Get.find<ProfileSubscriptionController>();
          //         controller.onCancelSubscription();
          //       },
          //       style: ElevatedButton.styleFrom(
          //         backgroundColor: AppColor.color_B53232,
          //         foregroundColor: AppColor.white,
          //         elevation: 0,
          //         padding: EdgeInsets.symmetric(
          //           vertical: HightWidthSizes.setValue_14,
          //         ),
          //         shape: RoundedRectangleBorder(
          //           borderRadius: BorderRadius.circular(
          //             HightWidthSizes.setValue_10,
          //           ),
          //         ),
          //       ),
          //       child: Text(
          //         'Cancel subscription',
          //         style: TextStyle(
          //           fontFamily: AppFonts.rubikMedium,
          //           fontWeight: FontWeight.w500,
          //           fontSize: FontSizes.setFontValue_16,
          //           color: AppColor.white,
          //         ),
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }
}
