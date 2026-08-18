import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/services/analytics_service.dart';
import 'package:verithrive_dev/theme/hight_width_sizes.dart';

import '../../common/base_view.dart';
import '../../theme/colors.dart';
import '../../theme/font_sizes.dart';
import '../../theme/fonts.dart';
import '../../theme/image_paths.dart';
import 'onboarding_controller.dart';

class OnboardingView extends BaseView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget buildView(BuildContext context) {
    return SafeArea(
      child: Container(
        color: AppColor.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            children: [
              Obx(
                () => _OnboardingProgress(
                  totalSteps: controller.totalSteps,
                  currentStep: controller.currentStep.value,
                ),
              ),
              SizedBox(height: HightWidthSizes.setValue_26),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return PageView.builder(
                      controller: controller.pageController,
                      onPageChanged: controller.onPageChanged,
                      itemCount: controller.totalSteps,
                      itemBuilder: (context, index) {
                        final sliderImages = [
                          AppImages.sliderImage1(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            fit: BoxFit.contain,
                          ),
                          AppImages.sliderImage2(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            fit: BoxFit.contain,
                          ),
                          AppImages.sliderImage3(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            fit: BoxFit.contain,
                          ),
                      /*    AppImages.sliderImage4(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            fit: BoxFit.contain,
                          ),*/
                        ];
                        return Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColor.brandMint,
                            borderRadius: BorderRadius.circular(
                              HightWidthSizes.setValue_10,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              HightWidthSizes.setValue_10,
                            ),
                            child: Center(
                              child: sliderImages[index],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: HightWidthSizes.setValue_26),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.color_D7F1EB,
                          foregroundColor: AppColor.color_32435F,
                          elevation: 0,
                          minimumSize:
                              Size(double.infinity, HightWidthSizes.setValue_45),
                          padding: EdgeInsets.symmetric(
                              vertical: HightWidthSizes.setValue_12,
                              horizontal: HightWidthSizes.setValue_16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              HightWidthSizes.setValue_10,
                            ),
                          ),
                        ),
                        onPressed: () {
                          AnalyticsService.instance.logButtonTap(
                            eventName: 'join_tap',
                            screenName: 'ProfessionalOnboardingScreen',
                            screenClass: 'OnboardingView',
                            elementText: 'join now',
                            elementLocation: 'button_tap_cta',
                            pageCategory: 'onboarding',
                          );
                          controller.joinNow();
                        },
                        child: Text(
                          'Join now',
                          style: TextStyle(
                            fontFamily: AppFonts.rubikMedium,
                            fontWeight: FontWeight.w500,
                            fontSize: FontSizes.setFontValue_16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: HightWidthSizes.setValue_10),
                  Expanded(
                    child: SizedBox(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.color_2FC4B2,
                          foregroundColor: AppColor.color_2FC4B2,
                          elevation: 0,
                          minimumSize:
                              Size(double.infinity, HightWidthSizes.setValue_45),
                          padding: EdgeInsets.symmetric(
                              vertical: HightWidthSizes.setValue_12,
                              horizontal: HightWidthSizes.setValue_16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              HightWidthSizes.setValue_10,
                            ),
                          ),
                        ),
                        onPressed: () {
                          AnalyticsService.instance.logButtonTap(
                            eventName: 'login_tap',
                            screenName: 'ProfessionalOnboardingScreen',
                            screenClass: 'OnboardingView',
                            elementText: 'log in',
                            elementLocation: 'button_tap_cta',
                            pageCategory: 'onboarding',
                          );
                          controller.logIn();
                        },
                        child: Text(
                          'Log in',
                          style: TextStyle(
                            fontFamily: AppFonts.rubikMedium,
                            fontWeight: FontWeight.w500,
                            fontSize: FontSizes.setFontValue_16,
                            color: AppColor.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            /*  SizedBox(height: HightWidthSizes.setValue_14),
              TextButton(
                onPressed: () {
                  AnalyticsService.instance.logButtonTap(
                    eventName: 'continue_guest_tap',
                    screenName: 'ProfessionalOnboardingScreen',
                    screenClass: 'OnboardingView',
                    elementText: 'continue as a guest',
                    elementLocation: 'button_tap_cta',
                    pageCategory: 'onboarding',
                  );
                  controller.continueAsGuest();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Continue as a guest',
                      style: TextStyle(
                          color: AppColor.color_32435F,
                          fontSize: FontSizes.setFontValue_14,
                          fontFamily: AppFonts.rubikMedium,
                          fontWeight: FontWeight.w500),
                    ),
                    SizedBox(width: HightWidthSizes.setValue_4),
                    Icon(
                      Icons.arrow_forward,
                      size: HightWidthSizes.setValue_16,
                      color: AppColor.color_32435F,
                    ),
                  ],
                ),
              ),*/
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingProgress extends StatelessWidget {
  const _OnboardingProgress({
    required this.totalSteps,
    required this.currentStep,
  });

  final int totalSteps;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;
        return Expanded(
          child: Container(
            height: HightWidthSizes.setValue_6,
            margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 8),
            decoration: BoxDecoration(
              color: isActive ? AppColor.color_32435F : AppColor.progressTrack,
              borderRadius: BorderRadius.circular(HightWidthSizes.setValue_24),
            ),
          ),
        );
      }),
    );
  }
}
