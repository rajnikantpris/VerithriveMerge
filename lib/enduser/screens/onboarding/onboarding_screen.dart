import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:verithrive_dev/enduser/screens/login/LoginBinding.dart';
import 'package:verithrive_dev/enduser/screens/login/LoginView.dart';
import 'package:verithrive_dev/enduser/screens/register/RegisterView.dart';
import 'package:verithrive_dev/enduser/screens/register/register_binding.dart';
import '../../utils/AppText.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/app_assets.dart';
import 'onboarding_controller.dart';

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: AppColors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Column(
              children: [
                // Progress Indicators //fix in top
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Obx(
                    () => Row(
                      children: List.generate(4, (index) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: _buildIndicator(
                              isActive: index == controller.currentPage.value,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // PageView for onboarding pages - Auto height fills remaining space
                Expanded(
                  child: PageView.builder(
                    controller: controller.pageController,
                    onPageChanged: controller.onPageChanged,
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: _buildOnboardingPage(context, index),
                      );
                    },
                  ),
                ),

                // Fixed bottom section
                const SizedBox(height: 20),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildButton(
                        text: AppText.joinNow,
                        backgroundColor: AppColors.lightGreen,
                        textColor: AppColors.blueColor,
                        onPressed: () {
                          Get.to(
                            () => RegisterView(),
                            binding: RegisterBinding(),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildButton(
                        text: AppText.login,
                        backgroundColor: AppColors.primaryColor,
                        textColor: AppColors.white,
                        onPressed: () {
                          Get.to(
                            () => const LoginView(),
                            binding: LoginBinding(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () {
                    controller.continueAsGuest();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppText.continueAsGuest,
                        style: AppTextStyles.rubikMedium(
                          fontSize: 16,
                          color: AppColors.blueColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        size: 20,
                        color: AppColors.blueColor,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(BuildContext context, int index) {
    final pages = [
      {'image': AppAssets.slider1},
      {'image': AppAssets.slider2},
      {'image': AppAssets.slider3},
      {'image': AppAssets.slider4},
    ];

    return SizedBox.expand(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Illustration Image - Fixed height for all pages
                    Expanded(
                      child: Image.asset(
                        pages[index]['image']!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPageOld(BuildContext context, int index) {
    final pages = [
      {
        'title': AppText.discoverTrustedExperts,
        'subtitle': AppText.discoverTrustedExpertsSubtitle,
        'image': AppAssets.amico,
      },
      {
        'title': AppText.getPersonalizedGuidance,
        'subtitle': AppText.getPersonalizedGuidanceSubtitle,
        'image': AppAssets.cuate,
      },
      {
        'title': AppText.trackYourProgress,
        'subtitle': AppText.trackYourProgressSubtitle,
        'image': AppAssets.amico,
      },
      {
        'title': AppText.startYourJourney,
        'subtitle': AppText.startYourJourneySubtitle,
        'image': AppAssets.amico,
      },
    ];

    return SizedBox.expand(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Illustration Image - Fixed height for all pages
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: Image.asset(
                        pages[index]['image']!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.error_outline,
                            size: 200,
                            color: AppColors.primaryColor,
                          );
                        },
                      ),
                    ),

                    // Title - Fixed spacing
                    Text(
                      pages[index]['title']!,
                      style: AppTextStyles.rubikBold(
                        fontSize: 20,
                        color: AppColors.blueColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Subtitle - Fixed spacing with max lines to maintain consistency
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        pages[index]['subtitle']!,
                        style: AppTextStyles.rubikRegular(
                          fontSize: 14,
                          color: AppColors.blueColor,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator({required bool isActive}) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: isActive ? AppColors.blueColor : AppColors.lightGreen,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(
        text,
        style: AppTextStyles.rubikMedium(fontSize: 16, color: textColor),
      ),
    );
  }
}
