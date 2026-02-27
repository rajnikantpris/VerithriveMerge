import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/base_controller.dart';
import '../../../../routes/app_routes.dart';

class YourProfileController extends BaseController {
  /// Static list representing the your profile menu options.
  final List<YourProfileItem> items = const [
    YourProfileItem(title: 'Personal details'),
    YourProfileItem(title: 'Address'),
    YourProfileItem(title: 'Your services'),
    YourProfileItem(title: 'Qualifications & certifications'),
    YourProfileItem(title: 'Personal identification'),
    YourProfileItem(title: 'About you'),
    YourProfileItem(title: 'Share profile'),
  ];

  void onItemTap(YourProfileItem item) {
    if (item.title == 'Personal details') {
      Get.toNamed(Routes.personalDetails);
    } else if (item.title == 'Address') {
      Get.toNamed(Routes.address);
    } else if (item.title == 'Your services') {
      Get.toNamed(Routes.yourServices);
    } else if (item.title == 'Qualifications & certifications') {
      Get.toNamed(Routes.qualificationCertification);
    } else if (item.title == 'Personal identification') {
      Get.toNamed(Routes.personalIdentification);
    } else if (item.title == 'About you') {
      Get.toNamed(Routes.aboutYou);
    } else {
      // Hook for future navigation or actions per item.
      debugPrint('Tapped on ${item.title}');
    }
  }
}

class YourProfileItem {
  const YourProfileItem({
    required this.title,
  });

  final String title;
}
