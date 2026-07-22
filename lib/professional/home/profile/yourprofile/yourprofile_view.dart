import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/base_view.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/fonts.dart';
import '../../../../theme/font_sizes.dart';
import '../../../../theme/hight_width_sizes.dart';
import '../../../../theme/image_paths.dart';
import 'yourprofile_controller.dart';

class YourProfileView extends BaseView<YourProfileController> {
  const YourProfileView({super.key});

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
            'Your profile',
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
            onTap: () => controller.onItemTap(item, context: context),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: HightWidthSizes.setValue_14,
              ),
              child: Row(
                children: [
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
                    height: HightWidthSizes.setValue_20
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
