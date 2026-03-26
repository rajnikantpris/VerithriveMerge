import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';

import '../../common/base_view.dart';
import '../../theme/colors.dart';
import '../../theme/font_sizes.dart';
import '../../theme/fonts.dart';
import '../../theme/hight_width_sizes.dart';
import 'select_address_map_controller.dart';

class SelectAddressMapView extends BaseView<SelectAddressMapController> {
  const SelectAddressMapView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 1),
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0x1A000000),
              blurRadius: HightWidthSizes.setValue_10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AppBar(
          backgroundColor: AppColor.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: AppColor.color_2D3648,
            ),
            onPressed: () => Get.back(),
          ),
          centerTitle: true,
          title: Text(
            'Select Address',
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
    return Obx(() {
      if (!controller.isMapInitialized.value ||
          controller.initialCameraPosition == null) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      return Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: controller.initialCameraPosition!,
            onMapCreated: controller.onMapCreated,
            onCameraMove: controller.onCameraMove,
            onCameraIdle: controller.onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            markers: controller.markers,
          ),

          // Center Pin (always in center)
          const Center(
            child: Icon(
              Icons.location_on,
              color: AppColor.color_2FC4B2,
              size: 48,
            ),
          ),

          // Search Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius: BorderRadius.circular(
                  HightWidthSizes.setValue_10,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: GooglePlaceAutoCompleteTextField(
                textEditingController: controller.searchController,
                focusNode: controller.searchFocusNode,
                // TODO: Replace with your Google Places API key
                // Get your API key from: https://console.cloud.google.com/
                // Enable "Places API" and "Geocoding API" in your Google Cloud project
                // googleAPIKey: "AIzaSyDIMB5KidUiA91o_6Cny-_txO83w5NUAy4",
                //googleAPIKey: "AIzaSyDIHdFq55OMUeaBaKgsAB1Cpi5r5vEFU8k",
                googleAPIKey: "AIzaSyDjdom-8K5VyqYV_zFUtPX_Zabk3r-C6XQ",
                inputDecoration: InputDecoration(
                  hintText: 'Search address',
                  hintStyle: TextStyle(
                    fontFamily: AppFonts.rubikRegular,
                    fontSize: FontSizes.setFontValue_14,
                    color: AppColor.color_9D9D9D,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColor.color_2D2D2D,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      HightWidthSizes.setValue_10,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColor.white,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: HightWidthSizes.setValue_16,
                    vertical: HightWidthSizes.setValue_12,
                  ),
                ),
                debounceTime: 400,
                countries: const [
                  "uk"
                ], // Add countries as needed
                isLatLngRequired: true,
                getPlaceDetailWithLatLng: (prediction) {
                  // This is called when lat/lng is available from the API
                  controller.onPlaceSelected(prediction,
                      updateSearchText: true);
                },
                itemClick: (prediction) {
                  // This is called when user clicks on a suggestion
                  // The getPlaceDetailWithLatLng will handle the map movement
                  controller.searchController.text =
                      prediction.description ?? '';
                  controller.searchFocusNode.unfocus();
                },
                itemBuilder: (context, index, prediction) {
                  return Container(
                    padding: EdgeInsets.all(HightWidthSizes.setValue_12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColor.color_2FC4B2,
                          size: 24,
                        ),
                        SizedBox(width: HightWidthSizes.setValue_12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prediction.description ?? '',
                                style: TextStyle(
                                  fontFamily: AppFonts.rubikMedium,
                                  fontSize: FontSizes.setFontValue_14,
                                  color: AppColor.color_2D2D2D,
                                ),
                              ),
                              if (prediction
                                      .structuredFormatting?.secondaryText !=
                                  null)
                                Text(
                                  prediction
                                      .structuredFormatting!.secondaryText!,
                                  style: TextStyle(
                                    fontFamily: AppFonts.rubikRegular,
                                    fontSize: FontSizes.setFontValue_12,
                                    color: AppColor.color_9D9D9D,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                seperatedBuilder: const Divider(),
                containerHorizontalPadding: 0,
              ),
            ),
          ),

          // // Current Location Button
          // Positioned(
          //   bottom: 120,
          //   right: 16,
          //   child: FloatingActionButton(
          //     onPressed: controller.moveToCurrentLocation,
          //     backgroundColor: AppColor.white,
          //     child: const Icon(
          //       Icons.my_location,
          //       color: AppColor.color_2FC4B2,
          //     ),
          //   ),
          // ),

          // Selected Address Display and Select Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColor.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(HightWidthSizes.setValue_16),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Address',
                      style: TextStyle(
                        fontFamily: AppFonts.rubikMedium,
                        fontSize: FontSizes.setFontValue_14,
                        color: AppColor.color_2D2D2D,
                      ),
                    ),
                    SizedBox(height: HightWidthSizes.setValue_8),
                    Obx(
                      () => controller.isLoadingAddress.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              controller.selectedAddress.value.isEmpty
                                  ? 'Loading address...'
                                  : controller.selectedAddress.value,
                              style: TextStyle(
                                fontFamily: AppFonts.rubikRegular,
                                fontSize: FontSizes.setFontValue_14,
                                color: AppColor.color_2D2D2D,
                              ),
                            ),
                    ),
                    SizedBox(height: HightWidthSizes.setValue_16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.color_2FC4B2,
                          foregroundColor: AppColor.white,
                          elevation: 0,
                          minimumSize: Size(
                            double.infinity,
                            HightWidthSizes.setValue_45,
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: HightWidthSizes.setValue_12,
                            horizontal: HightWidthSizes.setValue_16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              HightWidthSizes.setValue_10,
                            ),
                          ),
                        ),
                        onPressed: controller.onSelectAddress,
                        child: Text(
                          'Select Address',
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
        ],
      );
    });
  }
}
