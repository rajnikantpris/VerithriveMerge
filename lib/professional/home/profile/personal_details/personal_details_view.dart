import 'dart:io';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../common/base_view.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/fonts.dart';
import '../../../../theme/font_sizes.dart';
import '../../../../theme/hight_width_sizes.dart';
import '../../../../theme/image_paths.dart';
import '../../../../widgets/custom_text_field.dart';
import 'personal_details_controller.dart';

class PersonalDetailsView extends BaseView<PersonalDetailsController> {
  const PersonalDetailsView({super.key});

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
            'Personal details',
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
        child: Column(
          children: [
            Expanded(
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
                      // Profile Picture Section
                      _buildProfilePictureSection(context),
                      SizedBox(height: HightWidthSizes.setValue_24),

                      // You are in field
                      Text(
                        'What sector are you in?*',
                        style: TextStyle(
                          fontFamily: AppFonts.rubikRegular,
                          fontWeight: FontWeight.w400,
                          fontSize: FontSizes.setFontValue_14,
                          color: AppColor.color_2D2D2D,
                        ),
                      ),
                      SizedBox(height: HightWidthSizes.setValue_5),
                      Obx(
                        () => DropdownButtonFormField2<String>(
                          isExpanded: true,
                          isDense: true,
                          alignment: AlignmentDirectional.centerStart,
                          value: controller.selectedProfessionType.value,
                          decoration: _dropdownDecoration(),
                          dropdownStyleData: DropdownStyleData(
                            decoration: BoxDecoration(
                              color: AppColor.white,
                              borderRadius: BorderRadius.circular(
                                  HightWidthSizes.setValue_10),
                            ),
                          ),
                          iconStyleData: IconStyleData(
                            icon: AppImages.right_arrow_image(
                              width: HightWidthSizes.setValue_16,
                              height: HightWidthSizes.setValue_16,
                            ),
                          ),
                          hint: Text(
                            controller.isLoadingProfessionTypes.value
                                ? 'Loading...'
                                : 'Select here',
                            style: TextStyle(
                              fontFamily: AppFonts.rubikRegular,
                              fontWeight: FontWeight.w400,
                              fontSize: FontSizes.setFontValue_16,
                              color: AppColor.color_9D9D9D,
                            ),
                          ),
                          items: controller.professionTypes
                              .map(
                                (type) => DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(
                                    type,
                                    style: TextStyle(
                                      fontFamily: AppFonts.rubikRegular,
                                      fontWeight: FontWeight.w400,
                                      fontSize: FontSizes.setFontValue_16,
                                      color: AppColor.color_2D2D2D,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: controller.isLoadingProfessionTypes.value
                              ? null
                              : controller.setProfessionType,
                        ),
                      ),
                      SizedBox(height: HightWidthSizes.setValue_16),

                      // Select profession field
                      Text(
                        'Select profession*',
                        style: TextStyle(
                          fontFamily: AppFonts.rubikRegular,
                          fontWeight: FontWeight.w400,
                          fontSize: FontSizes.setFontValue_14,
                          color: AppColor.color_2D2D2D,
                        ),
                      ),
                      SizedBox(height: HightWidthSizes.setValue_5),
                      Obx(
                        () {
                          // Get unique sub-types to avoid duplicates
                          final uniqueSubTypes =
                              controller.professionSubTypes.toSet().toList();

                          // Ensure selected value is in the list, otherwise set to null
                          final selectedValue =
                              controller.selectedProfessionSubType.value;
                          final validValue = selectedValue != null &&
                                  uniqueSubTypes.contains(selectedValue)
                              ? selectedValue
                              : null;

                          return DropdownButtonFormField2<String>(
                            isExpanded: true,
                            isDense: true,
                            alignment: AlignmentDirectional.centerStart,
                            value: validValue,
                            decoration: _dropdownDecoration(),
                            dropdownStyleData: DropdownStyleData(
                              decoration: BoxDecoration(
                                color: AppColor.white,
                                borderRadius: BorderRadius.circular(
                                    HightWidthSizes.setValue_10),
                              ),
                            ),
                            iconStyleData: IconStyleData(
                              icon: AppImages.right_arrow_image(
                                width: HightWidthSizes.setValue_16,
                                height: HightWidthSizes.setValue_16,
                              ),
                            ),
                            hint: Text(
                              controller.isLoadingProfessionSubTypes.value
                                  ? 'Loading...'
                                  : controller.selectedProfessionType.value ==
                                          null
                                      ? 'Select profession type first'
                                      : 'Select here',
                              style: TextStyle(
                                fontFamily: AppFonts.rubikRegular,
                                fontWeight: FontWeight.w400,
                                fontSize: FontSizes.setFontValue_16,
                                color: AppColor.color_9D9D9D,
                              ),
                            ),
                            items: uniqueSubTypes
                                .map(
                                  (subType) => DropdownMenuItem<String>(
                                    value: subType,
                                    child: Text(
                                      subType,
                                      style: TextStyle(
                                        fontFamily: AppFonts.rubikRegular,
                                        fontWeight: FontWeight.w400,
                                        fontSize: FontSizes.setFontValue_16,
                                        color: AppColor.color_2D2D2D,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: controller
                                        .isLoadingProfessionSubTypes.value ||
                                    controller.selectedProfessionType.value ==
                                        null
                                ? null
                                : controller.setProfessionSubType,
                          );
                        },
                      ),
                      SizedBox(height: HightWidthSizes.setValue_16),

                      // Full Name field
                      CustomTextField(
                        label: 'Full Name',
                        hintText: 'Enter full name',
                        controller: controller.fullNameController,
                        validator: (value) =>
                            controller.validateNotEmpty(value, 'full name'),
                      ),
                      SizedBox(height: HightWidthSizes.setValue_16),

                      // Phone Number field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phone number',
                            style: TextStyle(
                              fontFamily: AppFonts.rubikRegular,
                              fontWeight: FontWeight.w400,
                              fontSize: FontSizes.setFontValue_14,
                              color: AppColor.color_2D2D2D,
                            ),
                          ),
                          SizedBox(height: HightWidthSizes.setValue_5),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                constraints: BoxConstraints(
                                    minHeight: HightWidthSizes.setValue_45),
                                decoration: BoxDecoration(
                                  color: AppColor.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(
                                      HightWidthSizes.setValue_10,
                                    ),
                                    bottomLeft: Radius.circular(
                                      HightWidthSizes.setValue_10,
                                    ),
                                  ),
                                  border: Border(
                                    left: BorderSide(
                                      color: AppColor.borderColor,
                                      width: HightWidthSizes.setValue_1,
                                    ),
                                    top: BorderSide(
                                      color: AppColor.borderColor,
                                      width: HightWidthSizes.setValue_1,
                                    ),
                                    bottom: BorderSide(
                                      color: AppColor.borderColor,
                                      width: HightWidthSizes.setValue_1,
                                    ),
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: HightWidthSizes.setValue_12,
                                  vertical: HightWidthSizes.setValue_14,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.phone_outlined,
                                      color: AppColor.color_9D9D9D,
                                      size: HightWidthSizes.setValue_16,
                                    ),
                                    SizedBox(width: HightWidthSizes.setValue_8),
                                    Text(
                                      '+44',
                                      style: TextStyle(
                                        fontFamily: AppFonts.rubikRegular,
                                        fontWeight: FontWeight.w400,
                                        fontSize: FontSizes.setFontValue_15_5,
                                        color: AppColor.color_2D2D2D,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: CustomTextField(
                                  label: '',
                                  hintText: 'Phone number',
                                  controller: controller.phoneController,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  showLabel: false,
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(
                                      HightWidthSizes.setValue_10,
                                    ),
                                    bottomRight: Radius.circular(
                                      HightWidthSizes.setValue_10,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: HightWidthSizes.setValue_16),

                      // Date of Birth field
                      CustomTextField(
                        label: 'Date of Birth',
                        hintText: 'dd/mm/yyyy',
                        controller: controller.dobController,
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
                        validator: (value) => controller.validateAge(value),
                      ),
                      SizedBox(height: HightWidthSizes.setValue_16),

                      // Gender field
                      Text(
                        'Gender',
                        style: TextStyle(
                          fontFamily: AppFonts.rubikRegular,
                          fontWeight: FontWeight.w400,
                          fontSize: FontSizes.setFontValue_14,
                          color: AppColor.color_2D2D2D,
                        ),
                      ),
                      SizedBox(height: HightWidthSizes.setValue_5),
                      Obx(
                        () => DropdownButtonFormField2<String>(
                          isExpanded: true,
                          isDense: true,
                          alignment: AlignmentDirectional.centerStart,
                          value: controller.selectedGender.value.isEmpty
                              ? null
                              : controller.selectedGender.value,
                          decoration: _dropdownDecoration(),
                          dropdownStyleData: DropdownStyleData(
                            decoration: BoxDecoration(
                              color: AppColor.white,
                              borderRadius: BorderRadius.circular(
                                  HightWidthSizes.setValue_10),
                            ),
                          ),
                          iconStyleData: IconStyleData(
                            icon: AppImages.right_arrow_image(
                              width: HightWidthSizes.setValue_16,
                              height: HightWidthSizes.setValue_16,
                            ),
                          ),
                          hint: Text(
                            'Select gender',
                            style: TextStyle(
                              fontFamily: AppFonts.rubikRegular,
                              fontWeight: FontWeight.w400,
                              fontSize: FontSizes.setFontValue_16,
                              color: AppColor.color_9D9D9D,
                            ),
                          ),
                          items: controller.genders
                              .map(
                                (gender) => DropdownMenuItem<String>(
                                  value: gender,
                                  child: Text(
                                    gender,
                                    style: TextStyle(
                                      fontFamily: AppFonts.rubikRegular,
                                      fontWeight: FontWeight.w400,
                                      fontSize: FontSizes.setFontValue_16,
                                      color: AppColor.color_2D2D2D,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: controller.setGender,
                        ),
                      ),
                      SizedBox(height: HightWidthSizes.setValue_16),

                      // Marketing Preferences field
                      _buildMarketingField(),
                      SizedBox(height: HightWidthSizes.setValue_20),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.color_2FC4B2,
              foregroundColor: AppColor.white,
              elevation: 0,
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
            onPressed: controller.onUpdateProfile,
            child: Text(
              'Update profile',
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

  Widget _buildProfilePictureSection(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          Obx(
            () => Container(
              width: HightWidthSizes.setValue_100,
              height: HightWidthSizes.setValue_100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: controller.selectedImage.value != null
                    ? Image.file(
                        controller.selectedImage.value!,
                        fit: BoxFit.cover,
                      )
                    : controller.profilePictureUrl.value != null &&
                            controller.profilePictureUrl.value!.isNotEmpty
                        ? Image.network(
                            controller.profilePictureUrl.value!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColor.color_E2F3F2,
                                child: Icon(
                                  Icons.person,
                                  size: HightWidthSizes.setValue_50,
                                  color: AppColor.color_2FC4B2,
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: AppColor.color_E2F3F2,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    strokeWidth: 2,
                                    color: AppColor.color_2FC4B2,
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: AppColor.color_E2F3F2,
                            child: Icon(
                              Icons.person,
                              size: HightWidthSizes.setValue_50,
                              color: AppColor.color_2FC4B2,
                            ),
                          ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => controller.onProfilePictureTap(context),
              child: Container(
                width: HightWidthSizes.setValue_32,
                height: HightWidthSizes.setValue_32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColor.color_32435F,
                  border: Border.all(
                    color: AppColor.white,
                    width: HightWidthSizes.setValue_2,
                  ),
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: HightWidthSizes.setValue_18,
                  color: AppColor.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketingField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Marketing',
              style: TextStyle(
                fontFamily: AppFonts.rubikRegular,
                fontWeight: FontWeight.w400,
                fontSize: FontSizes.setFontValue_14,
                color: AppColor.color_2D2D2D,
              ),
            ),
            SizedBox(width: HightWidthSizes.setValue_8),
            GestureDetector(
              onTap: controller.showMarketingInfo,
              child: Icon(
                Icons.info_outline,
                size: HightWidthSizes.setValue_16,
                color: AppColor.color_9D9D9D,
              ),
            ),
          ],
        ),
        SizedBox(height: HightWidthSizes.setValue_5),
        Obx(
          () => DropdownButtonFormField2<String>(
            isExpanded: true,
            isDense: true,
            alignment: AlignmentDirectional.centerStart,
            value: controller.selectedMarketingPreference.value.isEmpty
                ? null
                : controller.selectedMarketingPreference.value,
            decoration: _dropdownDecoration(),
            dropdownStyleData: DropdownStyleData(
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius:
                    BorderRadius.circular(HightWidthSizes.setValue_10),
              ),
            ),
            iconStyleData: IconStyleData(
              icon: AppImages.right_arrow_image(
                width: HightWidthSizes.setValue_16,
                height: HightWidthSizes.setValue_16,
              ),
            ),
            hint: Text(
              'Select preference',
              style: TextStyle(
                fontFamily: AppFonts.rubikRegular,
                fontWeight: FontWeight.w400,
                fontSize: FontSizes.setFontValue_16,
                color: AppColor.color_9D9D9D,
              ),
            ),
            items: controller.marketingOptions
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(
                      option,
                      style: TextStyle(
                        fontFamily: AppFonts.rubikRegular,
                        fontWeight: FontWeight.w400,
                        fontSize: FontSizes.setFontValue_16,
                        color: AppColor.color_2D2D2D,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: controller.setMarketingPreference,
          ),
        ),
      ],
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppColor.white,
      contentPadding: EdgeInsets.only(
        right: HightWidthSizes.setValue_14,
        left: HightWidthSizes.setValue_1,
        top: HightWidthSizes.setValue_14,
        bottom: HightWidthSizes.setValue_14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HightWidthSizes.setValue_10),
        borderSide: BorderSide(
          color: AppColor.borderColor,
          width: HightWidthSizes.setValue_1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HightWidthSizes.setValue_10),
        borderSide: BorderSide(
          color: AppColor.borderColor,
          width: HightWidthSizes.setValue_1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HightWidthSizes.setValue_10),
        borderSide: BorderSide(
          color: AppColor.color_32435F,
          width: HightWidthSizes.setValue_1,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HightWidthSizes.setValue_10),
        borderSide: BorderSide(
          color: AppColor.borderColor,
          width: HightWidthSizes.setValue_1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HightWidthSizes.setValue_10),
        borderSide: BorderSide(
          color: AppColor.color_32435F,
          width: HightWidthSizes.setValue_1,
        ),
      ),
    );
  }
}
