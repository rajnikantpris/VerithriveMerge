import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/utils/CustomTextField.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_text_styles.dart';
import '../../utils/AppText.dart';
import '../../utils/app_colors.dart';
import 'ProfileController.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(AppAssets.back),
          onPressed: controller.onBackPressed,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),

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
                                : controller.profileImageUrl.value.isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          controller.profileImageUrl.value,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Center(
                                              child: SizedBox(
                                                width: 30,
                                                height: 30,
                                                child: SvgPicture.asset(
                                                    AppAssets.profile),
                                              ),
                                            );
                                          },
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Center(
                                              child: CircularProgressIndicator(
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
                              border:
                                  Border.all(color: AppColors.white, width: 2),
                            ),
                            child: SvgPicture.asset(AppAssets.camera),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12),

                // Upload text
                Center(
                  child: Column(
                    children: [
                      Text(
                        AppText.uploadProfilePicture,
                        style: AppTextStyles.rubikRegular(
                          fontSize: 14,
                          color: AppColors.color2D2D2D,
                        ).copyWith(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      Text(
                        AppText.maxFileSize,
                        style: AppTextStyles.rubikRegular(
                          fontSize: 12,
                          color: AppColors.colorb3b3b3,
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
                      fontSize: 24, color: AppColors.color2D3648),
                ),

                SizedBox(height: 20),

                Obx(() => controller.shouldShowFullNameField
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextField(
                            controller: controller.fullNameController,
                            label: AppText.fullName,
                            hint: AppText.enterFullName,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            validator: controller.validateFullName,
                          ),
                          SizedBox(height: 16),
                        ],
                      )
                    : const SizedBox.shrink()),

                // Date of birth
                CustomTextField(
                  formFieldKey: controller.dobFieldKey,
                  controller: controller.dobController,
                  label: AppText.dateOfBirth,
                  hint: AppText.dobFormat,
                  readOnly: true,
                  onTap: () => controller.selectDateOfBirth(context),
                  suffixIcon: SizedBox(
                      height: 24,
                      width: 24,
                      child: SvgPicture.asset(AppAssets.calendar)),
                  validator: controller.validateDOB,
                ),

                SizedBox(height: 16),

                // Gender
                _buildGenderField(),

                SizedBox(height: 16),

                // Postcode
                _postcodeField(
                  controller.postcodeController,
                  hint: AppText.postcodeExample,
                  onManualPressed: controller.enterManually,
                  validator: controller.validatePostcode,
                ),

                SizedBox(height: 16),

                // Address
                _pickerField(
                  controller.addressController,
                  'Select address',
                  label: 'Address',
                  onTap: controller.selectAddress,
                  validator: controller.validateAddress,
                ),

                SizedBox(height: 32),

                // Next Button
                Obx(() => SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.saveProfile,
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
                                  color: AppColors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(AppText.next,
                                style: AppTextStyles.buttonTextStyle()),
                      ),
                    )),

                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderField() {
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
                        color: controller.selectedGender.value.isEmpty
                            ? AppColors.grey
                            : AppColors.black,
                      ),
                    ),
                    SvgPicture.asset(AppAssets.arrow_right),
                  ],
                ),
              ),
            )),
        Obx(() => controller.genderError.value.isNotEmpty
            ? Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  controller.genderError.value,
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

  Widget _pickerField(
    TextEditingController controller,
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
        Obx(() => this.controller.isManualAddress.value
            ? CustomTextField(
                controller: controller,
                focusNode: this.controller.addressFocusNode,
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
                      color: this.controller.addressError.value.isNotEmpty
                          ? Colors.red
                          : AppColors.lightGrey,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          this.controller.selectedAddress.value.isNotEmpty
                              ? this.controller.selectedAddress.value
                              : (controller.text.isNotEmpty
                                  ? controller.text
                                  : hint),
                          style: TextStyle(
                            fontSize: 14,
                            color: this
                                        .controller
                                        .selectedAddress
                                        .value
                                        .isNotEmpty ||
                                    controller.text.isNotEmpty
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
        Obx(() => this.controller.addressError.value.isNotEmpty
            ? Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  this.controller.addressError.value,
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
    TextEditingController controller, {
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
        Obx(() => this.controller.isManualEntry.value
            ? CustomTextField(
                controller: controller,
                focusNode: this.controller.postcodeFocusNode,
                label: '',
                hint: hint,
                textCapitalization: TextCapitalization.characters,
                validator: validator,
                showLabel: false,
                textColor: AppColors.color0E1027,
                readOnly: true, // Keep read-only to prevent manual typing
                onTap: () {
                  // Always open address screen, even in manual mode
                  this.controller.selectAddress();
                },
              )
            : GestureDetector(
                onTap: () {
                  // Always open address screen
                  this.controller.selectAddress();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: this.controller.postcodeError.value.isNotEmpty
                          ? Colors.red
                          : AppColors.lightGrey,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Obx(() => Text(
                              this.controller.selectedPostcode.value.isEmpty
                                  ? hint
                                  : this.controller.selectedPostcode.value,
                              style: TextStyle(
                                fontSize: 14,
                                color: this
                                        .controller
                                        .selectedPostcode
                                        .value
                                        .isEmpty
                                    ? AppColors.grey
                                    : AppColors.black,
                              ),
                            )),
                      ),
                    ],
                  ),
                ),
              )),
        Obx(() => !this.controller.isManualEntry.value &&
                this.controller.postcodeError.value.isNotEmpty
            ? Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  this.controller.postcodeError.value,
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

  Widget _buildAddressField() {
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
                        controller.selectedAddress.value.isNotEmpty
                            ? controller.selectedAddress.value
                            : (controller.addressController.text.isNotEmpty
                                ? controller.addressController.text
                                : AppText.selectAddress),
                        style: TextStyle(
                          fontSize: 14,
                          color: controller.selectedAddress.value.isNotEmpty ||
                                  controller.addressController.text.isNotEmpty
                              ? AppColors.black
                              : AppColors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SvgPicture.asset(AppAssets.arrow_right),
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
}
