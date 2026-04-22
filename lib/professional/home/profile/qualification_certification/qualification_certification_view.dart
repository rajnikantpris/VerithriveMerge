import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/base_view.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/fonts.dart';
import '../../../../theme/font_sizes.dart';
import '../../../../theme/hight_width_sizes.dart';
import '../../../../theme/image_paths.dart';
import '../../../../widgets/custom_text_field.dart';
import 'qualification_certification_controller.dart';

class QualificationCertificationView
    extends BaseView<QualificationCertificationController> {
  const QualificationCertificationView({super.key});

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
            'Qualification & certification',
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
    return Obx(
      () => Form(
        key: controller.formKey,
        autovalidateMode: controller.hasValidated.value
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Container(
          color: AppColor.white,
          child: SingleChildScrollView(
            controller: controller.scrollController,
            padding: EdgeInsets.symmetric(
              horizontal: HightWidthSizes.setValue_16,
              vertical: HightWidthSizes.setValue_20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Qualification & certification header with add button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Please add all relevant qualifications',
                            style: TextStyle(
                              fontFamily: AppFonts.rubikMedium,
                              fontWeight: FontWeight.w500,
                              fontSize: FontSizes.setFontValue_15,
                              color: AppColor.color_2D3648,
                            ),
                          ),
                          SizedBox(height: HightWidthSizes.setValue_2),
                          Text(
                            '(Degrees, Professional Certifications, First Aid, Training)',
                            style: TextStyle(
                              fontFamily: AppFonts.rubikRegular,
                              fontWeight: FontWeight.w400,
                              fontSize: FontSizes.setFontValue_9,
                              color: AppColor.color_2D2D2D,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: controller.addQualification,
                      child: Container(
                        padding: EdgeInsets.all(HightWidthSizes.setValue_6),
                        child: AppImages.add_svg(
                          width: HightWidthSizes.setValue_25,
                          height: HightWidthSizes.setValue_25,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: HightWidthSizes.setValue_16),

                // Qualification blocks
                Obx(
                  () {
                    // if (controller.isLoadingCollegesUniversities.value) {
                    //   return const Center(
                    //     child: Padding(
                    //       padding: EdgeInsets.all(20.0),
                    //       child: CircularProgressIndicator(),
                    //     ),
                    //   );
                    // }
                    // Only show "No colleges available" if API call has completed and colleges list is empty
                    if (controller.hasLoadedCollegesUniversities.value &&
                        controller.collegesUniversities.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            'No colleges/universities available',
                            style: TextStyle(
                              fontFamily: AppFonts.rubikRegular,
                              fontSize: FontSizes.setFontValue_14,
                              color: AppColor.color_9D9D9D,
                            ),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: List.generate(controller.qualifications.length,
                          (index) {
                        final item = controller.qualifications[index];
                        final canDelete = controller.qualifications.length > 1;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom:
                                index == controller.qualifications.length - 1
                                    ? HightWidthSizes.setValue_22
                                    : HightWidthSizes.setValue_16,
                          ),
                          child: _buildQualificationCard(
                              context, item, canDelete, index),
                        );
                      }),
                    );
                  },
                ),

                // Experience section
                _buildExperienceCard(),
                SizedBox(height: HightWidthSizes.setValue_20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchableCollegeDropdown(
    BuildContext context,
    QualificationItem qualification,
    int index,
  ) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: qualification.schoolController,
      builder: (context, value, child) {
        final searchText = value.text;

        return Obx(
          () {
            final filteredList =
                controller.getFilteredCollegesUniversities(searchText);
            // Show dropdown if there are filtered results and text doesn't exactly match any item
            final showDropdown = filteredList.isNotEmpty &&
                searchText.isNotEmpty &&
                !filteredList.any(
                    (item) => item.toLowerCase() == searchText.toLowerCase());

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  label: '',
                  hintText: controller.isLoadingCollegesUniversities.value
                      ? 'Loading...'
                      : 'Select or enter here',
                  controller: qualification.schoolController,
                  icon: null,
                  showLabel: false,
                  onChanged: (text) =>
                      controller.onCollegeUniversityTextChanged(
                          qualification, text, index),
                  suffixIcon: searchText.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 18,
                            color: AppColor.color_9D9D9D,
                          ),
                          onPressed: () {
                            qualification.schoolController.clear();
                            controller.setCollegeUniversity(
                                qualification, null, index);
                          },
                        )
                      : Padding(
                          padding: EdgeInsets.only(
                            right: HightWidthSizes.setValue_15,
                            left: HightWidthSizes.setValue_10,
                          ),
                          child: AppImages.right_arrow_image(
                            width: HightWidthSizes.setValue_16,
                            height: HightWidthSizes.setValue_16,
                          ),
                        ),
                  validator: (value) {
                    // Only validate if user has clicked Update details button
                    if (!controller.hasValidated.value) {
                      return null;
                    }
                    return controller.validateNotEmpty(
                        value, 'school/university');
                  },
                ),
                if (showDropdown)
                  Container(
                    margin: EdgeInsets.only(top: HightWidthSizes.setValue_4),
                    decoration: BoxDecoration(
                      color: AppColor.white,
                      borderRadius:
                          BorderRadius.circular(HightWidthSizes.setValue_10),
                      border: Border.all(color: AppColor.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: AppColor.color_000000.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount:
                          filteredList.length > 5 ? 5 : filteredList.length,
                      itemBuilder: (context, dropdownIndex) {
                        final college = filteredList[dropdownIndex];
                        final qualificationIndex =
                            index; // Capture qualification index
                        return InkWell(
                          onTap: () {
                            controller.setCollegeUniversity(
                                qualification, college, qualificationIndex);
                            FocusScope.of(context).unfocus();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: HightWidthSizes.setValue_14,
                              vertical: HightWidthSizes.setValue_12,
                            ),
                            child: Text(
                              college,
                              style: TextStyle(
                                fontFamily: AppFonts.rubikRegular,
                                fontWeight: FontWeight.w400,
                                fontSize: FontSizes.setFontValue_16,
                                color: AppColor.color_2D2D2D,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildQualificationCard(
    BuildContext context,
    QualificationItem qualification,
    bool canDelete,
    int index,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(HightWidthSizes.setValue_14),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(HightWidthSizes.setValue_12),
        border: Border.all(color: AppColor.borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColor.color_000000.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canDelete)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(
                    HightWidthSizes.setValue_16,
                  ),
                  onTap: () => controller.removeQualification(qualification),
                  child: Container(
                    padding: EdgeInsets.all(
                      HightWidthSizes.setValue_8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColor.color_B53232.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: AppImages.delete_account_svg(
                      width: HightWidthSizes.setValue_15,
                      height: HightWidthSizes.setValue_15,
                    ),
                  ),
                ),
              ],
            ),
          _buildQualificationFields(context, qualification, index),
        ],
      ),
    );
  }

  Widget _buildQualificationFields(
    BuildContext context,
    QualificationItem qualification,
    int index,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // School/University field
        Text(
          'School/University*',
          style: TextStyle(
            fontFamily: AppFonts.rubikRegular,
            fontWeight: FontWeight.w400,
            fontSize: FontSizes.setFontValue_14,
            color: AppColor.color_2D2D2D,
          ),
        ),
        SizedBox(height: HightWidthSizes.setValue_6),
        _buildSearchableCollegeDropdown(
          context,
          qualification,
          index,
        ),
        SizedBox(height: HightWidthSizes.setValue_14),

        // Degree/Certificate field
        CustomTextField(
          label: 'Degree/Certificate*',
          hintText: 'Enter here',
          controller: qualification.degreeController,
          validator: (value) {
            // Only validate if user has clicked Update details button
            if (!controller.hasValidated.value) {
              return null;
            }
            return controller.validateNotEmpty(value, 'degree/certificate');
          },
        ),
        SizedBox(height: HightWidthSizes.setValue_14),

        // Expiry date field
        CustomTextField(
          label: 'Expiry date',
          hintText: 'dd/mm/yyyy',
          controller: qualification.qualificationExpiryController,
          readOnly: true,
          onTap: () => controller.pickDate(
            context,
            qualification.qualificationExpiryController,
          ),
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
          // validator: (value) {
          //   // Only validate if user has clicked Update details button
          //   if (!controller.hasValidated.value) {
          //     return null;
          //   }
          //   return controller.validateRequiredDate(value);
          // },
        ),
        SizedBox(height: HightWidthSizes.setValue_14),

        // Upload certificate field
        CustomTextField(
          label: 'Upload certificate*',
          hintText: 'Upload file (PDF or Image)',
          controller: qualification.uploadCertificateController,
          readOnly: true,
          onTap: () => controller.onUploadTap(qualification),
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
            // Only validate if user has clicked Update details button
            if (!controller.hasValidated.value) {
              return null;
            }
            // Check if certificate exists (either file or URL from API)
            if (qualification.certificateFile == null &&
                (qualification.certificateUrl == null ||
                    qualification.certificateUrl!.isEmpty)) {
              return 'Please upload certificate file';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildExperienceCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(HightWidthSizes.setValue_14),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(HightWidthSizes.setValue_12),
        border: Border.all(color: AppColor.borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColor.color_000000.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Experience',
            style: TextStyle(
              fontFamily: AppFonts.rubikMedium,
              fontWeight: FontWeight.w500,
              fontSize: FontSizes.setFontValue_16,
              color: AppColor.color_2D3648,
            ),
          ),
          SizedBox(height: HightWidthSizes.setValue_14),
          CustomTextField(
            label: 'Total years of experience',
            hintText: 'Enter here',
            controller: controller.yearsExperienceController,
            keyboardType: TextInputType.number,
          ),
        ],
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
              onPressed: (controller.hasValidData.value && !controller.isLoading.value)
                  ? controller.onUpdateDetails
                  : null,
              child: controller.isLoading.value
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: HightWidthSizes.setValue_10),
                        Text(
                          'Updating...',
                          style: TextStyle(
                            fontFamily: AppFonts.rubikMedium,
                            fontWeight: FontWeight.w500,
                            color: AppColor.white,
                            fontSize: FontSizes.setFontValue_16,
                          ),
                        ),
                      ],
                    )
                  : Text(
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
    );
  }
}
