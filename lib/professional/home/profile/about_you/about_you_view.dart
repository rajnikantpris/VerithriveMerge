import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/base_view.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/fonts.dart';
import '../../../../theme/font_sizes.dart';
import '../../../../theme/hight_width_sizes.dart';
import 'about_you_controller.dart';

class AboutYouView extends BaseView<AboutYouController> {
  const AboutYouView({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: super.build(context),
    );
  }

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
            'About you',
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
    return Form(
      key: controller.formKey,
      child: Container(
        color: AppColor.white,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.symmetric(
              horizontal: HightWidthSizes.setValue_16,
              vertical: HightWidthSizes.setValue_20,
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You can write about yourself, experience, skills etc. This information will be seen by other users.',
                style: TextStyle(
                  fontFamily: AppFonts.rubikRegular,
                  fontWeight: FontWeight.w400,
                  fontSize: FontSizes.setFontValue_12,
                  color: AppColor.color_2D2D2D,
                ),
              ),
              SizedBox(height: HightWidthSizes.setValue_14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(HightWidthSizes.setValue_10),
                      border: Border.all(color: AppColor.borderColor),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: HightWidthSizes.setValue_12,
                      vertical: HightWidthSizes.setValue_8,
                    ),
                    child: TextFormField(
                      controller: controller.aboutYouController,
                      maxLines: 6,
                      textInputAction: TextInputAction.done,
                      onChanged: controller.onAboutYouChanged,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).unfocus(),
                      validator: controller.validateAboutYou,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter here',
                        hintStyle: TextStyle(
                          fontFamily: AppFonts.rubikRegular,
                          fontWeight: FontWeight.w400,
                          fontSize: FontSizes.setFontValue_14,
                          color: AppColor.color_9D9D9D,
                        ),
                      ),
                      style: TextStyle(
                        fontFamily: AppFonts.rubikRegular,
                        fontWeight: FontWeight.w400,
                        fontSize: FontSizes.setFontValue_14,
                        color: AppColor.color_0E1027,
                      ),
                    ),
                  ),
                  SizedBox(height: HightWidthSizes.setValue_6),
                  Obx(
                    () => Text(
                      '${controller.aboutYouWordCount.value}/500 words',
                      style: TextStyle(
                        fontFamily: AppFonts.rubikRegular,
                        fontWeight: FontWeight.w400,
                        fontSize: FontSizes.setFontValue_12,
                        color: AppColor.color_9D9D9D,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: HightWidthSizes.setValue_20),
            ],
          ),
        ),
        ),
      ),
    );
  }

  @override
  Widget? bottomNavigationBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: HightWidthSizes.setValue_16,
        vertical: HightWidthSizes.setValue_16,
      ),
      decoration: BoxDecoration(
        color: AppColor.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: HightWidthSizes.setValue_10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Obx(
            () => ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: controller.hasValidData.value
                    ? AppColor.color_2FC4B2
                    : AppColor.color_2FC4B2.withOpacity(0.5),
                foregroundColor: AppColor.white,
                elevation: 0,
                disabledBackgroundColor: AppColor.color_96E1D8,
                minimumSize: Size(double.infinity, HightWidthSizes.setValue_45),
                padding: EdgeInsets.symmetric(
                    vertical: HightWidthSizes.setValue_12,
                    horizontal: HightWidthSizes.setValue_16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    HightWidthSizes.setValue_10,
                  ),
                ),
              ),
              onPressed: controller.hasValidData.value
                  ? () {
                      FocusScope.of(context).unfocus();
                      controller.onUpdateDetails();
                    }
                  : null,
              child: Text(
                'Update details',
                style: TextStyle(
                  fontFamily: AppFonts.rubikMedium,
                  fontWeight: FontWeight.w500,
                  color: AppColor.white,
                  fontSize: FontSizes.setFontValue_16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
