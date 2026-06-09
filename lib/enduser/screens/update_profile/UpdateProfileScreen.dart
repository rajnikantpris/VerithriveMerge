import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import 'package:verithrive_dev/enduser/utils/app_text_styles.dart';
import '../../utils/AppText.dart';
import '../../utils/CustomTextField.dart';
import '../../core/widget/animated_loader.dart';
import 'UpdateProfileController.dart';

class UpdateProfileScreen extends StatelessWidget {
  // this is my uncommited code
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UpdateProfileController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 4, // 🔴 Add shadow depth (try 2-8)
        shadowColor: Colors.black.withOpacity(
          0.1,
        ), // Optional: customize shadow color
        scrolledUnderElevation: 4,
        leading: IconButton(
          icon: SvgPicture.asset(AppAssets.back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Your Profile',
          style: AppTextStyles.mediumTextStyle(
              fontSize: 20, color: AppColors.black),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Obx(() {
            if (!controller.isDataLoading.value) {
              return SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),
                        // Profile Picture
                        // Profile Picture
                        Center(
                          child: Stack(
                            children: [
                              Obx(() => Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.lightGreyF5F7F8,
                                    ),
                                    child: controller.profileImage.value != null
                                        ? ClipOval(
                                            child: Image.file(
                                              controller.profileImage.value!,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : controller.profileImageUrl.value
                                                .isNotEmpty
                                            ? ClipOval(
                                                child: Image.network(
                                                  controller
                                                      .profileImageUrl.value,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Center(
                                                      child: SizedBox(
                                                        width: 30,
                                                        height: 30,
                                                        child: SvgPicture.asset(
                                                            AppAssets.profile),
                                                      ),
                                                    );
                                                  },
                                                  loadingBuilder: (context,
                                                      child, loadingProgress) {
                                                    if (loadingProgress == null)
                                                      return child;
                                                    return Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                        value: loadingProgress
                                                                    .expectedTotalBytes !=
                                                                null
                                                            ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                            : null,
                                                        strokeWidth: 2,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              )
                                            : Center(
                                                child: SizedBox(
                                                  width: 30,
                                                  height: 30,
                                                  child: SvgPicture.asset(
                                                      AppAssets.profile),
                                                ),
                                              ),
                                  )),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: controller.showImagePickerOptions,
                                  child: Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightGreyF5F7F8,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: AppColors.white, width: 2),
                                    ),
                                    child: SvgPicture.asset(AppAssets.camera),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 32),
                        // Personal details title
                        Text(
                          AppText.personalDetails,
                          style: AppTextStyles.mediumTextStyle(
                            fontSize: 16,
                            color: AppColors.blueColor,
                          ),
                        ),
                        SizedBox(height: 20),
                        // Full name
                        CustomTextField(
                          controller: controller.fullNameController,
                          label: AppText.fullName,
                          hint: AppText.enterFullName,
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          validator: controller.validateFullName,
                        ),
                        SizedBox(height: 16),
                        // Date of birth
                        CustomTextField(
                          formFieldKey: controller.dobFieldKey,
                          controller: controller.dobController,
                          label: AppText.dateOfBirth,
                          hint: AppText.dobFormat,
                          readOnly: true,
                          onTap: () => controller.selectDateOfBirth(context),
                          suffixIcon: SvgPicture.asset(AppAssets.calendar),
                          validator: controller.validateDOB,
                        ),
                        SizedBox(height: 16),
                        // Gender
                        _buildGenderField(controller),
                        SizedBox(height: 16),
                        // Marketing
                        _buildMarketingField(controller),
                        SizedBox(height: 16),
                        // Postcode
                        _postcodeField(
                          controller,
                          controller.postcodeController,
                          hint: AppText.postcodeExample,
                          onManualPressed: controller.enterManually,
                          validator: controller.validatePostcode,
                        ),

                        SizedBox(height: 16),

                        // Address
                        _pickerField(
                          controller,
                          controller.addressController,
                          'Select address',
                          label: AppText.address,
                          onTap: controller.selectAddress,
                          validator: controller.validateAddress,
                        ),
                        SizedBox(height: 32),
                        // Update Profile Button
                        Obx(() => SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: controller.isLoading.value
                                    ? null
                                    : controller.updateProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                  disabledBackgroundColor:
                                      AppColors.primaryColor.withOpacity(0.6),
                                ),
                                child: controller.isLoading.value
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Update profile',
                                        style: AppTextStyles.buttonTextStyle(),
                                      ),
                              ),
                            )),
                        SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              );
            }
            return SizedBox.shrink();
          }),
          Obx(() {
            if (controller.isDataLoading.value) {
              return Center(
                child: AnimatedLoader(
                  assetPath: AppAssets.loader1,
                ),
              );
            }
            return SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildGenderField(UpdateProfileController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppText.gender,
          style: AppTextStyles.labelStyle(),
        ),
        SizedBox(height: 8),
        Obx(() => GestureDetector(
              onTap: controller.openGenderBottomSheet,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: controller.genderError.value.isNotEmpty
                        ? Colors.red
                        : AppColors.lightGrey,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      controller.selectedGender.value.isEmpty
                          ? AppText.selectGender
                          : controller.selectedGender.value,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Rubik',
                        fontWeight: FontWeight.w400,
                        color: controller.selectedGender.value.isEmpty
                            ? AppColors.grey
                            : AppColors.color2D2D2D,
                      ),
                    ),
                    SvgPicture.asset(AppAssets.arrow_right),
                  ],
                ),
              ),
            )),
        Obx(() => controller.genderError.value.isNotEmpty
            ? Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  controller.genderError.value,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontFamily: 'Rubik',
                  ),
                ),
              )
            : SizedBox.shrink()),
      ],
    );
  }

  Widget _buildMarketingField(UpdateProfileController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Marketing',
              style: AppTextStyles.labelStyle(),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: controller.showMarketingInfo,
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.grey,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Obx(() => GestureDetector(
              onTap: controller.openMarketingBottomSheet,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.lightGrey,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      controller.selectedMarketingPreference.value.isEmpty
                          ? 'Select Marketing Preference'
                          : controller.selectedMarketingPreference.value,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Rubik',
                        fontWeight: FontWeight.w400,
                        color:
                            controller.selectedMarketingPreference.value.isEmpty
                                ? AppColors.grey
                                : AppColors.color2D2D2D,
                      ),
                    ),
                    SvgPicture.asset(AppAssets.arrow_right),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _pickerField(
    UpdateProfileController controller,
    TextEditingController textController,
    String hint, {
    String? label,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label ?? '',
          style: AppTextStyles.labelStyle(),
        ),
        SizedBox(height: 8),
        Obx(() => controller.isManualAddress.value
            ? CustomTextField(
                controller: textController,
                focusNode: controller.addressFocusNode,
                label: '',
                hint: 'Enter address',
                validator: validator,
                showLabel: false,
                textColor: AppColors.color0E1027,
                suffixIcon: GestureDetector(
                  onTap: onTap,
                  child: Padding(
                    padding: EdgeInsets.only(right: 15, left: 10),
                    child:
                        Icon(Icons.location_on, color: AppColors.color2FC4B2),
                  ),
                ),
              )
            : GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: controller.addressError.value.isNotEmpty
                          ? Colors.red
                          : AppColors.lightGrey,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          controller.selectedAddress.value.isNotEmpty
                              ? controller.selectedAddress.value
                              : (textController.text.isNotEmpty
                                  ? textController.text
                                  : hint),
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                controller.selectedAddress.value.isNotEmpty ||
                                        textController.text.isNotEmpty
                                    ? AppColors.black
                                    : AppColors.grey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.location_on, color: AppColors.color2FC4B2),
                    ],
                  ),
                ),
              )),
        Obx(() => controller.addressError.value.isNotEmpty
            ? Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  controller.addressError.value,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              )
            : SizedBox.shrink()),
      ],
    );
  }

  Widget _postcodeField(
    UpdateProfileController controller,
    TextEditingController textController, {
    String hint = 'LS12AA',
    VoidCallback? onManualPressed,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppText.postcode,
              style: AppTextStyles.labelStyle(),
            ),
            TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onManualPressed,
              child: Text(
                'Enter manually',
                style: TextStyle(
                  fontFamily: "Rubik",
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: AppColors.color2D2D2D,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Obx(() => controller.isManualEntry.value
            ? CustomTextField(
                controller: textController,
                focusNode: controller.postcodeFocusNode,
                label: '',
                hint: hint,
                textCapitalization: TextCapitalization.characters,
                validator: validator,
                showLabel: false,
                textColor: AppColors.color0E1027,
                readOnly: true, // Keep read-only to prevent manual typing
                onTap: () {
                  // Always open address screen, even in manual mode
                  controller.selectAddress();
                },
              )
            : GestureDetector(
                onTap: () {
                  // Always open address screen
                  controller.selectAddress();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.lightGrey),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Obx(() => Text(
                              controller.selectedPostcode.value.isEmpty
                                  ? hint
                                  : controller.selectedPostcode.value,
                              style: TextStyle(
                                fontSize: 14,
                                color: controller.selectedPostcode.value.isEmpty
                                    ? AppColors.grey
                                    : AppColors.black,
                              ),
                            )),
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildAddressField(UpdateProfileController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppText.address,
          style: AppTextStyles.labelStyle(),
        ),
        SizedBox(height: 8),
        Obx(() => GestureDetector(
              onTap: controller.selectAddress,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: controller.addressError.value.isNotEmpty
                        ? Colors.red
                        : AppColors.lightGrey,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        controller.selectedAddress.value.isEmpty
                            ? AppText.selectAddress
                            : controller.selectedAddress.value,
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Rubik',
                          fontWeight: FontWeight.w400,
                          color: controller.selectedAddress.value.isEmpty
                              ? AppColors.grey
                              : AppColors.color0E1027,
                        ),
                      ),
                    ),
                    SvgPicture.asset(AppAssets.arrow_right),
                  ],
                ),
              ),
            )),
        Obx(() => controller.addressError.value.isNotEmpty
            ? Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  controller.addressError.value,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontFamily: 'Rubik',
                  ),
                ),
              )
            : SizedBox.shrink()),
      ],
    );
  }
}
