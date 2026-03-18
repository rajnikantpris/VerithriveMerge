import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../../common/base_view.dart';

import '../../../../theme/colors.dart';

import '../../../../theme/fonts.dart';

import '../../../../theme/font_sizes.dart';

import '../../../../theme/hight_width_sizes.dart';

import '../../../../theme/image_paths.dart';

import 'your_services_controller.dart';

class YourServicesView extends BaseView<YourServicesController> {
  const YourServicesView({super.key});

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
            'Your services',
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
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: HightWidthSizes.setValue_20,
          vertical: HightWidthSizes.setValue_20,
        ),
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
                    // Services without sub_services - show as tags/chips with show more/less

                    Wrap(
                      spacing: HightWidthSizes.setValue_10,
                      runSpacing: HightWidthSizes.setValue_10,
                      children: controller.services
                          .where((service) =>
                      service.subServices == null ||
                          service.subServices!.isEmpty)
                          .where((service) =>
                          controller.isServiceVisible(service.id ?? ''))
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

                    // Show more/less button for services

                    if (controller.services.any((service) =>
                    service.subServices == null ||
                        service.subServices!.isEmpty)) ...[
                      SizedBox(height: HightWidthSizes.setValue_12),
                      (controller.shouldShowMoreButton) ?  GestureDetector(
                        onTap: () => controller.toggleShowMore(),
                        child: Text(
                          controller.isShowingMoreServices
                              ? 'Show less'
                              : 'Show more',
                          style: TextStyle(
                            fontFamily: AppFonts.rubikRegular,
                            fontSize: FontSizes.setFontValue_12,
                            fontWeight: FontWeight.w400,
                            color: AppColor.color_2FC4B2,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ) : SizedBox(),
                    ],

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
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
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
                                children: (service.subServices ?? [])
                                    .map((subService) {
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
              () => SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: controller.hasSelectedServices
                    ? AppColor.color_2FC4B2
                    : AppColor.color_BFBFBF,
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
                disabledBackgroundColor: AppColor.color_96E1D8,
              ),
              onPressed: controller.hasSelectedServices
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
