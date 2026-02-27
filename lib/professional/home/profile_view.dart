import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/font_sizes.dart';
import '../../theme/fonts.dart';
import '../../theme/hight_width_sizes.dart';
import '../../theme/image_paths.dart';
import 'profile_controller.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key, required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColor.white,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(
          horizontal: HightWidthSizes.setValue_16,
          vertical: HightWidthSizes.setValue_12,
        ),
        itemCount: controller.items.length,
        separatorBuilder: (_, __) => Divider(
          height: HightWidthSizes.setValue_1,
          color: AppColor.color_ECECEC,
        ),
        itemBuilder: (context, index) {
          final item = controller.items[index];
          return InkWell(
            onTap: () => controller.onItemTap(item),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: HightWidthSizes.setValue_14,
              ),
              child: Row(
                children: [
                  AppImages.svg(
                    item.asset,
                    width: HightWidthSizes.setValue_22,
                    height: HightWidthSizes.setValue_22,
                  ),
                  SizedBox(width: HightWidthSizes.setValue_12),
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        fontFamily: AppFonts.rubikRegular,
                        fontWeight: FontWeight.w400,
                        fontSize: FontSizes.setFontValue_16,
                        color: AppColor.color_2D3648,
                      ),
                    ),
                  ),
                  AppImages.profile_right_arrow_svg(
                      width: HightWidthSizes.setValue_20,
                      height: HightWidthSizes.setValue_20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
