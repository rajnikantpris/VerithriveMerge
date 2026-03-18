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
import 'signup_profile_wizard_controller.dart';

class SignupProfileWizardView extends BaseView<SignupProfileWizardController> {
  const SignupProfileWizardView({super.key});

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
        onPressed: controller.previousStep,
      ),
    );
  }

  @override
  Widget buildView(BuildContext context) {
    return Container(
      color: AppColor.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Obx(
                () => _buildStepIndicator(controller.currentStep.value),
              ),
            ),
            Expanded(
              child: PageView(
                controller: controller.pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildCreateProfile(context),
                  _buildAddAddress(context),
                  _buildServices(context),
                  _buildQualifications(context),
                  _buildIdentification(context),
                  _buildAboutYou(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget? bottomNavigationBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Obx(
          () {
            final isLast =
                controller.currentStep.value == controller.totalSteps - 1;
            final isIdentificationStep = controller.currentStep.value == 4;
            final isServicesStep = controller.currentStep.value == 2;

            // Check if services are selected for step 2
            final hasSelectedServices = isServicesStep
                ? controller.selectedServiceIds.isNotEmpty ||
                    controller.selectedSubServiceIds.isNotEmpty
                : true;

            final isEnabled = isIdentificationStep
                ? controller.confirmRightToWork.value
                : isServicesStep
                    ? hasSelectedServices
                    : true;

            return _nextButton(
              isLast: isLast,
              isEnabled: isEnabled,
            );
          },
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int activeIndex) {
    final steps = [
      'Create profile',
      'Add address',
      'Showcase your services',
      'Qualifications & Certifications',
      'Personal identification',
      'About you',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(steps.length, (index) {
            final isActive = index <= activeIndex;
            return Expanded(
              child: Container(
                height: HightWidthSizes.setValue_6,
                margin: EdgeInsets.only(
                  right: index == steps.length - 1
                      ? 0
                      : HightWidthSizes.setValue_8,
                ),
                decoration: BoxDecoration(
                  color:
                      isActive ? AppColor.color_2FC4B2 : AppColor.progressTrack,
                  borderRadius: BorderRadius.circular(
                    HightWidthSizes.setValue_12,
                  ),
                ),
              ),
            );
          }),
        ),
        SizedBox(height: HightWidthSizes.setValue_12),
        Text(
          steps[activeIndex],
          style: TextStyle(
            fontFamily: AppFonts.rubikBold,
            fontWeight: FontWeight.w700,
            fontSize: FontSizes.setFontValue_20,
            color: AppColor.color_2D2D2D,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateProfile(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Obx(
        () => Form(
          key: controller.formKey,
          autovalidateMode: controller.hasValidated.value
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: HightWidthSizes.setValue_8),
              _label('What sector are you in?*'),
              SizedBox(height: HightWidthSizes.setValue_6),
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
                  validator: (_) {
                    if (controller.selectedProfessionType.value == null) {
                      return 'Please select profession type';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: HightWidthSizes.setValue_16),
              _label('Select profession*'),
              SizedBox(height: HightWidthSizes.setValue_6),
              Obx(
                () => DropdownButtonFormField2<String>(
                  isExpanded: true,
                  isDense: true,
                  alignment: AlignmentDirectional.centerStart,
                  value: controller.selectedProfessionSubType.value,
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
                    controller.isLoadingProfessionSubTypes.value
                        ? 'Loading...'
                        : controller.selectedProfessionType.value == null
                            ? 'Select profession type first'
                            : 'Select here',
                    style: TextStyle(
                      fontFamily: AppFonts.rubikRegular,
                      fontWeight: FontWeight.w400,
                      fontSize: FontSizes.setFontValue_16,
                      color: AppColor.color_9D9D9D,
                    ),
                  ),
                  items: controller.professionSubTypes
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
                  onChanged: controller.isLoadingProfessionSubTypes.value ||
                          controller.selectedProfessionType.value == null
                      ? null
                      : controller.setProfessionSubType,
                  validator: (_) {
                    if (controller.selectedProfessionSubType.value == null) {
                      return 'Please select profession';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: HightWidthSizes.setValue_16),
              CustomTextField(
                label: 'Full name*',
                hintText: 'Enter full name',
                controller: controller.fullNameController,
                icon: null,
                textInputAction: TextInputAction.done,
                validator: (value) =>
                    controller.validateNotEmpty(value, 'full name'),
              ),
              SizedBox(height: HightWidthSizes.setValue_16),
              CustomTextField(
                label: 'Date of birth*',
                hintText: 'dd/mm/yyyy',
                controller: controller.dobController,
                icon: null,
                readOnly: true,
                onTap: () => controller.pickDobDate(context),
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
                validator: (value) =>
                    controller.validateNotEmpty(value, 'date of birth'),
              ),
              SizedBox(height: HightWidthSizes.setValue_16),
              _label('Gender*'),
              SizedBox(height: HightWidthSizes.setValue_6),
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
              SizedBox(height: HightWidthSizes.setValue_28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddAddress(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Obx(
        () => Form(
          key: controller.addressFormKey,
          autovalidateMode: controller.addressHasValidated.value
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: HightWidthSizes.setValue_8),
              Text(
                'Your address',
                style: TextStyle(
                  fontFamily: AppFonts.rubikMedium,
                  fontWeight: FontWeight.w500,
                  fontSize: FontSizes.setFontValue_16,
                  color: AppColor.color_2D3648,
                ),
              ),
              SizedBox(height: HightWidthSizes.setValue_14),
              _postcodeField(
                controller.postcodeController,
                onManualPressed: controller.enableManualPostcode,
                validator: (value) =>
                    controller.validateNotEmpty(value, 'postcode'),
              ),
              SizedBox(height: HightWidthSizes.setValue_14),
              _pickerField(
                controller.addressController,
                'Select address',
                onTap: () => controller.navigateToMapScreen(),
                validator: (value) =>
                    controller.validateNotEmpty(value, 'address'),
              ),
              SizedBox(height: HightWidthSizes.setValue_24),
              _buildSectionTitleWithOptional('Work address'),
              SizedBox(height: HightWidthSizes.setValue_14),
              _postcodeField(
                controller.workPostcodeController,
                hint: 'Eg. EC1 2AB',
                onManualPressed: controller.enableManualWorkPostcode,
                validator: (value) {
                  final workPostcode = value?.trim() ?? '';
                  final workAddress =
                      controller.workAddressController.text.trim();
                  if (workPostcode.isNotEmpty && workAddress.isEmpty) {
                    return 'Please select work address';
                  }
                  return null;
                },
              ),
              SizedBox(height: HightWidthSizes.setValue_14),
              _pickerField(
                controller.workAddressController,
                'Select address',
                onTap: () => controller.navigateToWorkMapScreen(),
                validator: (value) {
                  final workAddress = value?.trim() ?? '';
                  final workPostcode =
                      controller.workPostcodeController.text.trim();
                  if (workAddress.isNotEmpty && workPostcode.isEmpty) {
                    return 'Please enter work postcode';
                  }
                  return null;
                },
              ),
              SizedBox(height: HightWidthSizes.setValue_28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitleWithOptional(String title) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: title,
            style: TextStyle(
              fontFamily: AppFonts.rubikMedium,
              fontWeight: FontWeight.w500,
              fontSize: FontSizes.setFontValue_15,
              color: AppColor.color_2D3648,
            ),
          ),
          TextSpan(
            text: ' (optional)',
            style: TextStyle(
              fontFamily: AppFonts.rubikRegular,
              fontWeight: FontWeight.w400,
              fontSize: FontSizes.setFontValue_14,
              color: AppColor.color_9D9D9D,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServices(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: HightWidthSizes.setValue_8),
          Obx(
            () {
              if (controller.isLoadingServices.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              // Only show "No services available" if API call has completed and services list is empty
              if (controller.hasLoadedServices.value &&
                  controller.services.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'No services available',
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Services without sub_services - show as tags/chips
                  Wrap(
                    spacing: HightWidthSizes.setValue_10,
                    runSpacing: HightWidthSizes.setValue_10,
                    children: controller.services
                        .where((service) =>
                            service.subServices == null ||
                            service.subServices!.isEmpty)
                        .map((service) {
                      final isSelected = controller.selectedServices.contains(
                        service.serviceName ?? '',
                      );
                      return GestureDetector(
                        onTap: () => controller.toggleService(
                            service.serviceName ?? '', service.id ?? ''),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColor.color_2FC4B2
                                : AppColor.color_F5F7F8,
                            borderRadius: BorderRadius.circular(
                              HightWidthSizes.setValue_10,
                            ),
                          ),
                          child: Text(
                            service.serviceName ?? '',
                            style: TextStyle(
                              fontFamily: AppFonts.rubikRegular,
                              fontSize: FontSizes.setFontValue_14,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? AppColor.white
                                  : AppColor.color_2D2D2D,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  // Services with sub_services - show as expandable categories
                  ...controller.services
                      .where((service) =>
                          service.subServices != null &&
                          service.subServices!.isNotEmpty)
                      .map((service) {
                    final isExpanded =
                        controller.isServiceExpanded(service.id ?? '');
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: HightWidthSizes.setValue_12),
                        GestureDetector(
                          onTap: () => controller
                              .toggleServiceExpansion(service.id ?? ''),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: HightWidthSizes.setValue_16,
                              vertical: HightWidthSizes.setValue_14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColor.color_F8F8F8,
                              borderRadius: BorderRadius.circular(
                                HightWidthSizes.setValue_10,
                              ),
                              border: Border.all(
                                color: AppColor.color_F5F7F8,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    service.serviceName ?? '',
                                    style: TextStyle(
                                      fontFamily: AppFonts.rubikRegular,
                                      fontSize: FontSizes.setFontValue_16,
                                      fontWeight: FontWeight.w400,
                                      color: AppColor.color_32435F,
                                    ),
                                  ),
                                ),
                                isExpanded
                                    ? AppImages.add_down_arrow_svg(
                                        width: HightWidthSizes.setValue_18,
                                        height: HightWidthSizes.setValue_18,
                                        color: AppColor.color_9D9D9D,
                                      )
                                    : AppImages.profile_right_arrow_svg(
                                        width: HightWidthSizes.setValue_24,
                                        height: HightWidthSizes.setValue_24,
                                        color: AppColor.color_9D9D9D,
                                      ),
                              ],
                            ),
                          ),
                        ),
                        if (isExpanded) ...[
                          SizedBox(height: HightWidthSizes.setValue_8),
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:
                                  (service.subServices ?? []).map((subService) {
                                final isSubSelected =
                                    controller.selectedServices.contains(
                                  subService.subServiceName ?? '',
                                );
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: HightWidthSizes.setValue_8,
                                  ),
                                  child: GestureDetector(
                                    onTap: () => controller.toggleSubService(
                                        subService.subServiceName ?? '',
                                        subService.id ?? '',
                                        service.id ?? ''),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSubSelected
                                            ? AppColor.color_2FC4B2
                                            : AppColor.color_F5F7F8,
                                        borderRadius: BorderRadius.circular(
                                          HightWidthSizes.setValue_10,
                                        ),
                                      ),
                                      child: Text(
                                        subService.subServiceName ?? '',
                                        style: TextStyle(
                                          fontFamily: AppFonts.rubikRegular,
                                          fontSize: FontSizes.setFontValue_14,
                                          fontWeight: FontWeight.w400,
                                          color: isSubSelected
                                              ? AppColor.white
                                              : AppColor.color_2D2D2D,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    );
                  }).toList(),
                ],
              );
            },
          ),
          SizedBox(height: HightWidthSizes.setValue_28),
        ],
      ),
    );
  }

  Widget _buildQualifications(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      controller: controller.qualificationsScrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: HightWidthSizes.setValue_8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Text(
                //   'Qualification & certification',
                //   style: TextStyle(
                //     fontFamily: AppFonts.rubikMedium,
                //     fontWeight: FontWeight.w500,
                //     fontSize: FontSizes.setFontValue_16,
                //     color: AppColor.color_2D3648,
                //   ),
                // ),
                Text(
                  'Please add all relevant qualifications',
                  style: TextStyle(
                    fontFamily: AppFonts.rubikMedium,
                    fontWeight: FontWeight.w500,
                    fontSize: FontSizes.setFontValue_15,
                    color: AppColor.color_2D3648,
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
            ...List.generate(controller.qualifications.length, (index) {
              final item = controller.qualifications[index];
              final canDelete = controller.qualifications.length > 1;
              // Ensure form key exists for this qualification
              if (index >= controller.qualificationFormKeys.length) {
                controller.qualificationFormKeys.add(GlobalKey<FormState>());
              }
              final formKey = controller.qualificationFormKeys[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == controller.qualifications.length - 1
                      ? HightWidthSizes.setValue_22
                      : HightWidthSizes.setValue_16,
                ),
                child: _card(
                  child: Obx(
                    () => Form(
                      key: formKey,
                      autovalidateMode:
                          controller.qualificationsHasValidated.value
                              ? AutovalidateMode.onUserInteraction
                              : AutovalidateMode.disabled,
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
                                  onTap: () =>
                                      controller.removeQualification(item),
                                  child: Container(
                                    padding: EdgeInsets.all(
                                      HightWidthSizes.setValue_8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColor.color_B53232
                                          .withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: AppImages.delete_account_svg(
                                        width: HightWidthSizes.setValue_15,
                                        height: HightWidthSizes.setValue_15),
                                  ),
                                ),
                              ],
                            ),
                          _qualificationFields(context, item, index),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            Obx(
              () => Form(
                key: controller.experienceFormKey,
                autovalidateMode: controller.qualificationsHasValidated.value
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                child: _card(
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
                        label: 'Total years of experience*',
                        hintText: 'Enter here',
                        controller: controller.yearsExperienceController,
                        icon: null,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          // Only validate if user has clicked Next button
                          if (!controller.qualificationsHasValidated.value) {
                            return null;
                          }
                          return controller.validateNotEmpty(
                              value, 'total years of experience');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: HightWidthSizes.setValue_28),
          ],
        ),
      ),
    );
  }

  Widget _qualificationFields(
    BuildContext context,
    QualificationItem qualification,
    int index,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('School/University*'),
        SizedBox(height: HightWidthSizes.setValue_6),
        _buildSearchableCollegeDropdown(
          context,
          qualification,
          index,
        ),
        SizedBox(height: HightWidthSizes.setValue_14),
        CustomTextField(
          label: 'Degree/Certificate*',
          hintText: 'Enter here',
          controller: qualification.degreeController,
          icon: null,
          validator: (value) {
            // Only validate if user has clicked Next button
            if (!controller.qualificationsHasValidated.value) {
              return null;
            }
            return controller.validateNotEmpty(value, 'degree/certificate');
          },
          onChanged: (value) =>
              controller.onDegreeCertificateChanged(value, index),
        ),
        SizedBox(height: HightWidthSizes.setValue_14),
        CustomTextField(
          label: 'Expiry date',
          hintText: 'dd/mm/yyyy',
          controller: qualification.qualificationExpiryController,
          icon: null,
          readOnly: true,
          onTap: () => controller.pickIdExpiryDate(
            context,
            qualification.qualificationExpiryController,
            qualificationIndex: index,
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
    /*      validator: (value) {
            // Only validate if user has clicked Next button
            if (!controller.qualificationsHasValidated.value) {
              return null;
            }
            return controller.validateRequiredDate(value);
          },*/
        ),
        Padding(
          padding: EdgeInsets.only(left: HightWidthSizes.setValue_4,top: HightWidthSizes.setValue_4),
          child: Text(
            'Please leave blank if your qualification does not have an expiration date.',
            style: TextStyle(
              fontFamily: AppFonts.rubikRegular,
              fontWeight: FontWeight.w400,
              fontSize: FontSizes.setFontValue_10,
              color: AppColor.color_898989,
              height: 1.4,
            ),
          ),
        ),
        SizedBox(height: HightWidthSizes.setValue_14),
        _uploadField(
          context,
          qualification.uploadCertificateController,
          'Upload certificate*',
          onTap: () =>
              controller.pickCertificateFile(context, qualification, index),
          validator: (value) {
            // Only validate if user has clicked Next button
            if (!controller.qualificationsHasValidated.value) {
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

  Widget _card({required Widget child}) {
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
      child: child,
    );
  }

  Widget _buildIdentification(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Obx(
        () => Form(
          key: controller.identificationFormKey,
          autovalidateMode: controller.identificationHasValidated.value
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: HightWidthSizes.setValue_8),
              _label('Select ID*'),
              SizedBox(height: HightWidthSizes.setValue_6),
              Obx(
                () => DropdownButtonFormField2<String>(
                  isExpanded: true,
                  isDense: true,
                  alignment: AlignmentDirectional.centerStart,
                  value: controller.selectedIdType.value.isEmpty
                      ? null
                      : controller.selectedIdType.value,
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
                    'Select here',
                    style: TextStyle(
                      fontFamily: AppFonts.rubikRegular,
                      fontWeight: FontWeight.w400,
                      fontSize: FontSizes.setFontValue_16,
                      color: AppColor.color_9D9D9D,
                    ),
                  ),
                  items: controller.idTypes
                      .map(
                        (idType) => DropdownMenuItem<String>(
                          value: idType,
                          child: Text(
                            idType,
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
                  onChanged: controller.setIdType,
                  validator: (_) {
                    // Only validate if user has clicked Next button
                    if (!controller.identificationHasValidated.value) {
                      return null;
                    }
                    if (controller.selectedIdType.value.isEmpty) {
                      return 'Please select ID type';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: HightWidthSizes.setValue_16),
              CustomTextField(
                label: 'Expiry date*',
                hintText: 'dd/mm/yyyy',
                controller: controller.idExpiryController,
                icon: null,
                readOnly: true,
                onTap: () => controller.pickIdExpiryDate(
                    context, controller.idExpiryController),
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
                validator: (value) {
                  // Only validate if user has clicked Next button
                  if (!controller.identificationHasValidated.value) {
                    return null;
                  }
                  return controller.validateRequiredDate(value);
                },
              ),
              // Padding(
              //   padding: EdgeInsets.only(left: HightWidthSizes.setValue_4,top: HightWidthSizes.setValue_4),
              //   child: Text(
              //     'Please leave blank if your qualification does not have an expiration date.',
              //     style: TextStyle(
              //       fontFamily: AppFonts.rubikRegular,
              //       fontWeight: FontWeight.w400,
              //       fontSize: FontSizes.setFontValue_10,
              //       color: AppColor.color_898989,
              //       height: 1.4,
              //     ),
              //   ),
              // ),
              SizedBox(height: HightWidthSizes.setValue_16),
              _uploadField(
                context,
                controller.idUploadController,
                'Upload ID*',
                onTap: () => controller.pickIdFile(context),
                validator: (value) {
                  // Only validate if user has clicked Next button
                  if (!controller.identificationHasValidated.value) {
                    return null;
                  }
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
                                ? AppColor.color_32435F
                                : const Color(0x99000000), // #00000099
                            width: HightWidthSizes.setValue_1,
                          ),
                          color: controller.confirmRightToWork.value
                              ? AppColor.color_32435F
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
                   /*   Expanded(
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
              SizedBox(height: HightWidthSizes.setValue_24),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildAboutYou(BuildContext context) {
  //   return SingleChildScrollView(
  //     keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
  //     padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
  //     child: Obx(
  //       () => Form(
  //         key: controller.aboutYouFormKey,
  //         autovalidateMode: controller.aboutYouHasValidated.value
  //             ? AutovalidateMode.onUserInteraction
  //             : AutovalidateMode.disabled,
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             SizedBox(height: HightWidthSizes.setValue_8),
  //             Text(
  //               'You can write about yourself, experience, skills etc. This information will be seen by other users.',
  //               style: TextStyle(
  //                 fontFamily: AppFonts.rubikRegular,
  //                 fontWeight: FontWeight.w400,
  //                 fontSize: FontSizes.setFontValue_12,
  //                 color: AppColor.color_2D2D2D,
  //               ),
  //             ),
  //             SizedBox(height: HightWidthSizes.setValue_14),
  //             Column(
  //               crossAxisAlignment: CrossAxisAlignment.end,
  //               children: [
  //                 Container(
  //                   decoration: BoxDecoration(
  //                     borderRadius:
  //                         BorderRadius.circular(HightWidthSizes.setValue_10),
  //                     border: Border.all(color: AppColor.borderColor),
  //                   ),
  //                   padding: EdgeInsets.symmetric(
  //                     horizontal: HightWidthSizes.setValue_12,
  //                     vertical: HightWidthSizes.setValue_8,
  //                   ),
  //                   child: TextFormField(
  //                     controller: controller.aboutYouController,
  //                     maxLines: 6,
  //                     onChanged: controller.onAboutYouChanged,
  //                     validator: (value) {
  //                       if (value == null || value.trim().isEmpty) {
  //                         return 'Please enter description';
  //                       }
  //                       return null;
  //                     },
  //                     decoration: InputDecoration(
  //                       border: InputBorder.none,
  //                       hintText: 'Enter here',
  //                       errorBorder: InputBorder.none,
  //                       focusedErrorBorder: InputBorder.none,
  //                       errorStyle: TextStyle(
  //                         fontFamily: AppFonts.rubikRegular,
  //                         fontWeight: FontWeight.w400,
  //                         fontSize: FontSizes.setFontValue_12,
  //                         color: Colors.red,
  //                         height: 1.4,
  //                       ),
  //                       errorMaxLines: 2,
  //                     ),
  //                     style: TextStyle(
  //                       fontFamily: AppFonts.rubikRegular,
  //                       fontWeight: FontWeight.w400,
  //                       fontSize: FontSizes.setFontValue_14,
  //                       color: AppColor.color_0E1027,
  //                     ),
  //                   ),
  //                 ),
  //                 SizedBox(height: HightWidthSizes.setValue_6),
  //                 Obx(
  //                   () => Text(
  //                     '${controller.aboutYouCharacterCount.value}/500 characters',
  //                     style: TextStyle(
  //                       fontFamily: AppFonts.rubikRegular,
  //                       fontWeight: FontWeight.w400,
  //                       fontSize: FontSizes.setFontValue_12,
  //                       color: AppColor.color_9D9D9D,
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             SizedBox(height: HightWidthSizes.setValue_20),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
  Widget _buildAboutYou(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Obx(
          () => Form(
            key: controller.aboutYouFormKey,
            autovalidateMode: controller.aboutYouHasValidated.value
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: HightWidthSizes.setValue_8),
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter description';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter here',
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          errorStyle: TextStyle(
                            fontFamily: AppFonts.rubikRegular,
                            fontWeight: FontWeight.w400,
                            fontSize: FontSizes.setFontValue_12,
                            color: Colors.red,
                            height: 1.4,
                          ),
                          errorMaxLines: 2,
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
                        '${controller.aboutYouCharacterCount.value}/500 characters',
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

  Widget _pickerField(
    TextEditingController controller,
    String hint, {
    String? label,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return CustomTextField(
      label: label ?? '',
      hintText: hint,
      controller: controller,
      icon: null,
      showLabel: label != null,
      readOnly: true,
      onTap: onTap,
      validator: validator,
      suffixIcon: Padding(
        padding: EdgeInsets.only(
          right: HightWidthSizes.setValue_15,
          left: HightWidthSizes.setValue_10,
        ),
        child: AppImages.right_arrow_image(
          width: HightWidthSizes.setValue_16,
          height: HightWidthSizes.setValue_16,
        ),
      ),
    );
  }

  Widget _postcodeField(
    TextEditingController controller, {
    String hint = 'LS12AA',
    VoidCallback? onManualPressed,
    String? Function(String?)? validator,
  }) {
    final isWorkPostcode = controller == this.controller.workPostcodeController;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _label('Postcode*'),
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
        SizedBox(height: HightWidthSizes.setValue_6),
        Obx(
          () => CustomTextField(
            label: 'Postcode',
            hintText: hint,
            controller: controller,
            icon: null,
            showLabel: false,
            readOnly: onManualPressed != null
                ? !(isWorkPostcode
                    ? this.controller.isManualWorkPostcode.value
                    : this.controller.isManualPostcode.value)
                : false,
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _uploadField(
    BuildContext context,
    TextEditingController controller,
    String label, {
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: CustomTextField(
        label: label,
        hintText: 'Upload file (PDF or Image)',
        controller: controller,
        icon: null,
        readOnly: true,
        onTap: onTap,
        validator: validator,
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
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppFonts.rubikRegular,
        fontWeight: FontWeight.w400,
        fontSize: FontSizes.setFontValue_14,
        color: AppColor.color_2D2D2D,
      ),
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
                  validator: (value) {
                    // Only validate if user has clicked Next button
                    if (!controller.qualificationsHasValidated.value) {
                      return null;
                    }
                    return controller.validateNotEmpty(
                        value, 'school/university');
                  },
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

  Widget _nextButton({bool isLast = false, bool isEnabled = true}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.color_2FC4B2,
          disabledBackgroundColor: AppColor.color_96E1D8,
          foregroundColor: AppColor.white,
          disabledForegroundColor: AppColor.white.withOpacity(0.9),
          elevation: 0,
          minimumSize: Size(double.infinity, HightWidthSizes.setValue_45),
          padding: EdgeInsets.symmetric(
              vertical: HightWidthSizes.setValue_12,
              horizontal: HightWidthSizes.setValue_16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HightWidthSizes.setValue_10),
          ),
        ),
        onPressed: isEnabled ? controller.nextStep : null,
        child: Text(
          isLast ? 'Save & create profile' : 'Next',
          style: TextStyle(
            fontFamily: AppFonts.rubikMedium,
            fontWeight: FontWeight.w500,
            color: AppColor.white,
            fontSize: FontSizes.setFontValue_16,
          ),
        ),
      ),
    );
  }
}
