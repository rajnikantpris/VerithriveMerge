import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/base_view.dart';
import '../../theme/colors.dart';
import '../../theme/font_sizes.dart';
import '../../theme/fonts.dart';
import '../../theme/hight_width_sizes.dart';
import '../../theme/image_paths.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_text_field.dart';
import 'signup_person_details_controller.dart';

class SignupPersonDetailsView extends BaseView<SignupPersonDetailsController> {
  const SignupPersonDetailsView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return CustomAppBar(
      appBarTitleText: '',
      isBackButtonEnabled: true,
      isCenterTitle: false,
      titleColor: AppColor.color000000,
      titleFontSize: FontSizes.setFontValue_18,
      titlefontFamily: AppFonts.rubikMedium,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColor.color000000),
        onPressed: controller.onBackPressed,
      ),
    );
  }

  @override
  Widget buildView(BuildContext context) {
    return Container(
      color: AppColor.white,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Obx(
            () => Form(
              key: controller.formKey,
              autovalidateMode: controller.hasValidated.value
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: HightWidthSizes.setValue_12),
                  Center(child: _buildAvatar(context)),
                  SizedBox(height: HightWidthSizes.setValue_24),
                  Text(
                    'Personal details',
                    style: TextStyle(
                      fontFamily: AppFonts.rubikBold,
                      fontWeight: FontWeight.w700,
                      fontSize: FontSizes.setFontValue_20,
                      color: AppColor.color_2D2D2D,
                    ),
                  ),
                  SizedBox(height: HightWidthSizes.setValue_20),
                  Obx(
                    () => controller.shouldShowFullNameField
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomTextField(
                                label: 'Full name',
                                hintText: 'Enter full name',
                                controller: controller.fullNameController,
                                icon: null,
                                validator: controller.validateFullName,
                              ),
                              SizedBox(height: HightWidthSizes.setValue_16),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  _buildDateField(context),
                  SizedBox(height: HightWidthSizes.setValue_16),
                  _buildGenderField(context),
                  SizedBox(height: HightWidthSizes.setValue_16),
                  _buildPostcodeField(),
                  SizedBox(height: HightWidthSizes.setValue_16),
                  CustomTextField(
                    label: 'Address',
                    hintText: 'Select address',
                    controller: controller.addressController,
                    icon: null,
                    readOnly: !controller.isManualAddress.value,
                    //onTap: controller.isManualAddress.value ? null : () => controller.navigateToManualAddressScreen(),
                    suffixIcon: GestureDetector(
                      onTap: () => controller.navigateToMapScreen(),
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: HightWidthSizes.setValue_15,
                          left: HightWidthSizes.setValue_10,
                        ),
                        child: Icon(Icons.location_on,color: AppColor.color_2FC4B2,),
                    /*    child: AppImages.right_arrow_image(
                          width: HightWidthSizes.setValue_16,
                          height: HightWidthSizes.setValue_16,
                        ),*/
                      ),
                    ),
                    showLabel: false,
                    validator: (value) =>
                        controller.validateNotEmpty(value, 'address'),
                  ),
                  SizedBox(height: HightWidthSizes.setValue_16),
                  // Promo Code Section (Social Login Only)
                  Obx(() => controller.isSocialLogin.value
                      ? _buildPromoCodeSection()
                      : const SizedBox.shrink()),
                  SizedBox(height: HightWidthSizes.setValue_30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.color_2FC4B2,
                        disabledBackgroundColor: AppColor.color_96E1D8,
                        foregroundColor: AppColor.white,
                        disabledForegroundColor:
                            AppColor.white.withOpacity(0.9),
                        elevation: 0,
                        minimumSize:
                            Size(double.infinity, HightWidthSizes.setValue_45),
                        padding: EdgeInsets.symmetric(
                            vertical: HightWidthSizes.setValue_12,
                            horizontal: HightWidthSizes.setValue_16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            HightWidthSizes.setValue_10,
                          ),
                        ),
                      ),
                      onPressed: controller.onNext,
                      child: Text(
                        'Next',
                        style: TextStyle(
                          fontFamily: AppFonts.rubikMedium,
                          fontWeight: FontWeight.w500,
                          color: AppColor.white,
                          fontSize: FontSizes.setFontValue_16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Obx(
              () {
                final avatarImage = controller.avatarImageProvider;
                return GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: HightWidthSizes.setValue_100,
                    height: HightWidthSizes.setValue_100,
                    decoration: BoxDecoration(
                      color: AppColor.color_F5F7F8,
                      shape: BoxShape.circle,
                      image: avatarImage != null
                          ? DecorationImage(
                              image: avatarImage,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: avatarImage == null
                        ? Center(
                            child: AppImages.user_image(
                              fit: BoxFit.contain,
                              width: HightWidthSizes.setValue_50,
                              height: HightWidthSizes.setValue_50,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
            GestureDetector(
              onTap: () => controller.pickProfileImage(context),
              child: Container(
                padding: EdgeInsets.all(HightWidthSizes.setValue_6),
                decoration: BoxDecoration(
                  color: AppColor.color_F5F7F8,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColor.white,
                    width: HightWidthSizes.setValue_2,
                  ),
                ),
                child: AppImages.camera_image(
                  width: HightWidthSizes.setValue_16,
                  height: HightWidthSizes.setValue_16,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: HightWidthSizes.setValue_8),
        GestureDetector(
          onTap: () {},
          child: Text(
            'Upload profile picture',
            style: TextStyle(
              fontFamily: AppFonts.rubikRegular,
              fontWeight: FontWeight.w400,
              fontSize: FontSizes.setFontValue_14,
              color: AppColor.color_2D2D2D,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        SizedBox(height: HightWidthSizes.setValue_2),
        Text(
          'Max file size 5MB',
          style: TextStyle(
            fontFamily: AppFonts.rubikRegular,
            fontWeight: FontWeight.w400,
            fontSize: FontSizes.setFontValue_12,
            color: AppColor.color_B3B3B3,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context) {
    return CustomTextField(
      label: 'Date of birth',
      hintText: 'dd/mm/yyyy',
      controller: controller.dobController,
      icon: null,
      readOnly: true,
      onTap: () => controller.pickDate(context),
      suffixIcon: Padding(
        padding: EdgeInsets.only(
          right: HightWidthSizes.setValue_15,
          left: HightWidthSizes.setValue_25,
        ),
        child: AppImages.calender_image(
          width: HightWidthSizes.setValue_18,
          height: HightWidthSizes.setValue_18,
        ),
      ),
      validator: (value) =>
          controller.validateAge(value),
    );
  }

  Widget _buildGenderField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              borderRadius: BorderRadius.circular(HightWidthSizes.setValue_10),
            )),
            iconStyleData: IconStyleData(
                icon: AppImages.right_arrow_image(
              width: HightWidthSizes.setValue_16,
              height: HightWidthSizes.setValue_16,
            )),
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
            validator: (_) {
              if (controller.selectedGender.value.isEmpty) {
                return 'Please select gender';
              }
              return null;
            },
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
          bottom: HightWidthSizes.setValue_14),
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

  Widget _buildPostcodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Postcode',
              style: TextStyle(
                fontFamily: AppFonts.rubikRegular,
                fontWeight: FontWeight.w400,
                fontSize: FontSizes.setFontValue_14,
                color: AppColor.color_2D2D2D,
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: controller.enableManualPostcode,
              child: Text(
                'Enter manually',
                style: TextStyle(
                  fontFamily: AppFonts.rubikRegular,
                  fontWeight: FontWeight.w400,
                  fontSize: FontSizes.setFontValue_14,
                  color: AppColor.color_2D2D2D,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: HightWidthSizes.setValue_5),
        CustomTextField(
          label: 'Postcode',
          hintText: 'Eg. EC1 2AB',
          controller: controller.postcodeController,
          icon: null,
          readOnly: true,
          // readOnly: !controller.isManualPostcode.value,
          onTap: () => controller.navigateToMapScreen(),
          showLabel: false,
          validator: (value) =>
              controller.validateNotEmpty(value, 'postcode'),
        )
      ],
    );
  }

  Widget _buildPromoCodeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter promo code',
          style: TextStyle(
            fontFamily: AppFonts.rubikRegular,
            fontWeight: FontWeight.w400,
            fontSize: FontSizes.setFontValue_14,
            color: AppColor.color_2D2D2D,
          ),
        ),
        SizedBox(height: HightWidthSizes.setValue_5),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HightWidthSizes.setValue_10),
            border: Border.all(
              color: controller.isPromoCodeApplied.value
                  ? AppColor.color_2FC4B2
                  : AppColor.borderColor,
              width: HightWidthSizes.setValue_1,
            ),
            color: controller.isPromoCodeApplied.value
                ? AppColor.color_D7F1EB.withOpacity(0.3)
                : AppColor.white,
          ),
          child: Column(
            children: [
              if (!controller.isPromoCodeApplied.value) ...[
                // Input field with apply button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller.promoCodeController,
                        style: TextStyle(
                          fontFamily: AppFonts.rubikRegular,
                          fontSize: FontSizes.setFontValue_16,
                          color: AppColor.color_2D2D2D,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter promo code',
                          hintStyle: TextStyle(
                            fontFamily: AppFonts.rubikRegular,
                            fontSize: FontSizes.setFontValue_16,
                            color: AppColor.color_9D9D9D,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: HightWidthSizes.setValue_15,
                            vertical: HightWidthSizes.setValue_14,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: HightWidthSizes.setValue_8),
                      child: TextButton(
                        onPressed: controller.checkPromoCode,
                        style: TextButton.styleFrom(
                          backgroundColor: AppColor.color_2FC4B2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(HightWidthSizes.setValue_8),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: HightWidthSizes.setValue_16,
                            vertical: HightWidthSizes.setValue_10,
                          ),
                        ),
                        child: Text(
                          'Apply',
                          style: TextStyle(
                            fontFamily: AppFonts.rubikMedium,
                            fontWeight: FontWeight.w500,
                            fontSize: FontSizes.setFontValue_14,
                            color: AppColor.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Applied state
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: HightWidthSizes.setValue_15,
                    vertical: HightWidthSizes.setValue_12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColor.color_2FC4B2,
                        size: HightWidthSizes.setValue_20,
                      ),
                      SizedBox(width: HightWidthSizes.setValue_10),
                      Expanded(
                        child: Text(
                          controller.promoCodeController.text,
                          style: TextStyle(
                            fontFamily: AppFonts.rubikMedium,
                            fontWeight: FontWeight.w500,
                            fontSize: FontSizes.setFontValue_16,
                            color: AppColor.color_2D2D2D,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: controller.removePromoCode,
                        child: Icon(
                          Icons.close,
                          color: AppColor.color_9D9D9D,
                          size: HightWidthSizes.setValue_20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        // Success/Error Message
        if (controller.promoCodeMessage.value.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
              top: HightWidthSizes.setValue_6,
              left: HightWidthSizes.setValue_4,
            ),
            child: Text(
              controller.promoCodeMessage.value,
              style: TextStyle(
                fontFamily: AppFonts.rubikRegular,
                fontSize: FontSizes.setFontValue_12,
                color: controller.isPromoCodeValid.value
                    ? AppColor.color_2FC4B2
                    : AppColor.color_E64646,
              ),
            ),
          ),
      ],
    );
  }
}
