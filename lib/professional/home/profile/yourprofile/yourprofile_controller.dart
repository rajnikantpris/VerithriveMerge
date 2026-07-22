import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../common/base_controller.dart';
import '../../../../routes/app_routes.dart';
import '../../../../models/profile_details_model.dart';
import '../../../../services/deep_link_service.dart';
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

  void onItemTap(YourProfileItem item, {BuildContext? context}) {
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
      if (!Get.isRegistered<HomeController>()) {
        debugPrint('HomeController not registered, cannot share profile');
        return;
      }
      final profile = Get.find<HomeController>().profileDetails.value;
      if (profile == null) {
        debugPrint('Profile details not loaded, cannot share profile');
        return;
      }
      _shareViaOtherApps(profile, context: context ?? Get.context);
    } else {
      debugPrint('Tapped on ${item.title}');
    }
  }

  Future<void> _shareViaOtherApps(
    ProfileDetailsModel profile, {
    BuildContext? context,
  }) async {
    final String profileId = profile.id ?? '';
    if (profileId.isEmpty) {
      debugPrint('Cannot share profile: missing profile id');
      return;
    }

    final String profileText = _generateProfileText(profile, profileId);

    // iOS (especially iPad) requires a non-zero sharePositionOrigin or the
    // share sheet never appears.
    final Rect origin = _shareOrigin(context);

    try {
      await Share.share(
        profileText,
        subject: 'Professional Profile',
        sharePositionOrigin: origin,
      );
    } catch (e) {
      debugPrint('Share profile failed: $e');
    }
  }

  Rect _shareOrigin(BuildContext? context) {
    try {
      final renderObject = context?.findRenderObject();
      if (renderObject is RenderBox && renderObject.hasSize) {
        return renderObject.localToGlobal(Offset.zero) & renderObject.size;
      }
    } catch (e) {
      debugPrint('Share origin fallback: $e');
    }
    // Safe fallback for ListView / Sliver contexts (not RenderBox).
    return const Rect.fromLTWH(0, 0, 1, 1);
  }

  String _generateProfileText(ProfileDetailsModel profile, String profileId) {
    final StringBuffer buffer = StringBuffer();
    final String profileUrl = DeepLinkService.buildProfileShareUrl(profileId);

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

    if (profile.email?.isNotEmpty == true && !(profile.isEmailHidden ?? false)) {
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
    buffer.writeln('View profile:');
    buffer.writeln(profileUrl);
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
