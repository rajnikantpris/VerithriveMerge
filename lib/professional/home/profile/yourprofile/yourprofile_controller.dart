import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../common/base_controller.dart';
import '../../../../routes/app_routes.dart';
import '../../../../models/profile_details_model.dart';
import '../../home_controller.dart';

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
    } else if (item.title == 'Share profile') {
      if (Get.isRegistered<HomeController>()) {
        _shareViaOtherApps(Get.find<HomeController>().profileDetails.value!);
      } else {
        debugPrint('HomeController not registered, cannot share profile');
      }
    } else {
      // Hook for future navigation or actions per item.
      debugPrint('Tapped on ${item.title}');
    }
  }

  void _shareViaOtherApps(ProfileDetailsModel profile) {
    final String profileText = _generateProfileText(profile);
    Share.share(
      profileText,
      subject: 'Professional Profile',
    );
  }

  String _generateProfileText(ProfileDetailsModel profile) {
    final StringBuffer buffer = StringBuffer();

    buffer.writeln('Professional Profile');
    buffer.writeln('');

    if (profile.fullName?.isNotEmpty == true) {
      buffer.writeln('Name: ${profile.fullName}');
    }

    if (profile.profession_name?.isNotEmpty == true) {
      buffer.writeln('Profession: ${profile.profession_name}');
    }

    if (profile.profession_sub_name?.isNotEmpty == true) {
      buffer.writeln('Specialization: ${profile.profession_sub_name}');
    }

    if (profile.totalExperience != null && profile.totalExperience! > 0) {
      buffer.writeln('Experience: ${profile.totalExperience} years');
    }

    if (profile.email?.isNotEmpty == true && !profile.isEmailHidden!) {
      buffer.writeln('Email: ${profile.email}');
    }

    if (profile.mobileNumber?.isNotEmpty == true) {
      buffer.writeln('Phone: ${profile.mobileNumber}');
    }

    if (profile.address?.isNotEmpty == true) {
      buffer.writeln('Location: ${profile.address}');
    }

    if (profile.description?.isNotEmpty == true) {
      buffer.writeln('');
      buffer.writeln('About:');
      buffer.writeln(profile.description);
    }

    buffer.writeln('');
    buffer.writeln('Shared via Verithrive App');

    return buffer.toString();
  }
}

class YourProfileItem {
  const YourProfileItem({
    required this.title,
  });

  final String title;
}
