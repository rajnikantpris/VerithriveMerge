import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/base_view.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/fonts.dart';
import '../../../../theme/font_sizes.dart';
import '../../../../theme/hight_width_sizes.dart';
import '../../../../theme/image_paths.dart';
import '../../../../widgets/custom_text_field.dart';
import 'personal_identification_controller.dart';

class PersonalIdentificationView
    extends BaseView<PersonalIdentificationController> {
  const PersonalIdentificationView({super.key});

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
            'Personal identification',
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
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: HightWidthSizes.setValue_16,
            vertical: HightWidthSizes.setValue_20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Select ID field
              Text(
                'Select ID*',
                style: TextStyle(
                  fontFamily: AppFonts.rubikRegular,
                  fontWeight: FontWeight.w400,
                  fontSize: FontSizes.setFontValue_14,
                  color: AppColor.color_2D2D2D,
                ),
              ),
              SizedBox(height: HightWidthSizes.setValue_5),
              CustomTextField(
                label: '',
                hintText: 'Select ID',
                controller: controller.idTypeController,
                showLabel: false,
                readOnly: true,
                onTap: controller.onIdTypeTap,
                suffixIcon: Padding(
                  padding: EdgeInsets.only(
                    right: HightWidthSizes.setValue_15,
                    left: HightWidthSizes.setValue_10,
                  ),
                  child: AppImages.profile_right_arrow_svg(
                    width: HightWidthSizes.setValue_20,
                    height: HightWidthSizes.setValue_20,
                  ),
                ),
                validator: (value) =>
                    controller.validateNotEmpty(value, 'ID type'),
              ),
              SizedBox(height: HightWidthSizes.setValue_16),

              // Expiry date field
              CustomTextField(
                label: 'Expiry date*',
                hintText: 'dd/mm/yyyy',
                controller: controller.idExpiryController,
                readOnly: true,
                onTap: () => controller.pickDate(context),
                suffixIcon: Padding(
                  padding: EdgeInsets.only(
                    right: HightWidthSizes.setValue_15,
                    left: HightWidthSizes.setValue_25,
                  ),
                  child: AppImages.calender1_svg(
                    width: HightWidthSizes.setValue_18,
                    height: HightWidthSizes.setValue_18,
                  ),
                ),
                validator: (value) => controller.validateRequiredDate(value),
              ),
              SizedBox(height: HightWidthSizes.setValue_16),

              // Upload ID field
              CustomTextField(
                label: 'Upload ID*',
                hintText: 'Upload file (PDF or Image)',
                controller: controller.idUploadController,
                readOnly: true,
                onTap: controller.onUploadTap,
                suffixIcon: Padding(
                  padding: EdgeInsets.only(
                    right: HightWidthSizes.setValue_12,
                    left: HightWidthSizes.setValue_10,
                  ),
                  child: AppImages.upload_svg(
                    width: HightWidthSizes.setValue_18,
                    height: HightWidthSizes.setValue_18,
                  ),
                ),
                validator: (value) {
                  // Check if document exists (either file or URL from API)
                  if (controller.idFile == null &&
                      (controller.idDocumentUrl == null ||
                          controller.idDocumentUrl!.isEmpty)) {
                    return 'Please upload ID file';
                  }
                  return null;
                },
              ),
              SizedBox(height: HightWidthSizes.setValue_18),
              Obx(
                () => InkWell(
                  onTap: () => controller.confirmRightToWork.value =
                      !controller.confirmRightToWork.value,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: HightWidthSizes.setValue_20,
                        height: HightWidthSizes.setValue_20,
                        margin:
                            EdgeInsets.only(top: HightWidthSizes.setValue_2),
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(
                            HightWidthSizes.setValue_4,
                          ),
                          border: Border.all(
                            color: controller.confirmRightToWork.value
                                ? AppColor.color_2FC4B2
                                : const Color(0x99000000), // #00000099
                            width: HightWidthSizes.setValue_1,
                          ),
                          color: controller.confirmRightToWork.value
                              ? AppColor.color_2FC4B2
                              : Colors.transparent,
                        ),
                        child: controller.confirmRightToWork.value
                            ? Icon(
                                Icons.check,
                                size: HightWidthSizes.setValue_14,
                                color: AppColor.white,
                              )
                            : null,
                      ),
                      SizedBox(width: HightWidthSizes.setValue_12),
                      Expanded(
                        child: Text(
                          'By checking this box, you confirm that you have the legal right to work in the United Kingdom.',
                          style: TextStyle(
                            fontFamily: AppFonts.rubikRegular,
                            fontWeight: FontWeight.w400,
                            fontSize: FontSizes.setFontValue_12,
                            color: AppColor.color_2D2D2D,
                          ),
                        ),
                      ),
                     /* Expanded(
                        child: Text(
                          'By clicking, you confirm that you have legal right to work in the UK.',
                          style: TextStyle(
                            fontFamily: AppFonts.rubikRegular,
                            fontWeight: FontWeight.w400,
                            fontSize: FontSizes.setFontValue_12,
                            color: AppColor.color_2D2D2D,
                          ),
                        ),
                      ),*/
                    ],
                  ),
                ),
              ),
              SizedBox(height: HightWidthSizes.setValue_20),
            ],
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
                backgroundColor: controller.confirmRightToWork.value
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
              onPressed: controller.confirmRightToWork.value
                  ? controller.onUpdateDetails
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
