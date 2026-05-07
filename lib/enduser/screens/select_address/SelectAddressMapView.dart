import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import '../../utils/app_colors.dart';
import 'SelectAddressMapController.dart';

class SelectAddressMapView extends GetView<SelectAddressMapController> {
  const SelectAddressMapView({super.key});

  /*@override
  PreferredSizeWidget? appBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 1),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0x1A000000),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon:  Icon(
              Icons.arrow_back,
              color: AppColors.color2D3648,
            ),
            onPressed: () => Get.back(),
          ),
          centerTitle: true,
          title: Text(
            'Select Address',
            style: TextStyle(
              fontFamily: "Rubik",
              fontWeight: FontWeight.w500,
              fontSize: 18,
              color: AppColors.color2D3648,
            ),
          ),
        ),
      ),
    );
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.color2D3648,
          ),
          onPressed: () => Get.back(),
        ),
        centerTitle: true,
        title: Text(
          'Select Address',
          style: TextStyle(
            fontFamily: "Rubik",
            fontWeight: FontWeight.w500,
            fontSize: 18,
            color: AppColors.color2D3648,
          ),
        ),
      ),
      body: Obx(() {
        if (!controller.isMapInitialized.value ||
            controller.initialCameraPosition == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Initializing map...',
                    style: TextStyle(
                      fontFamily: "Rubik",
                      fontSize: 14,
                      color: AppColors.color2D2D2D,
                    ),
                  ),
                ],
              ),
            ),
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

          // Center Pin (always shown)
          const Center(
            child: Icon(
              Icons.location_on,
              color: AppColors.color2FC4B2,
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
                color: AppColors.white,
                borderRadius: BorderRadius.circular(
                  10,
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
                //googleAPIKey: "AIzaSyDO6ilx7mj6JJfShMT3yB0dDnEwGuu0qfA",
                googleAPIKey: "AIzaSyDjdom-8K5VyqYV_zFUtPX_Zabk3r-C6XQ",
                inputDecoration: InputDecoration(
                  hintText: 'Search address',
                  hintStyle: TextStyle(
                    fontFamily: "Rubik",
                    fontSize: 14,
                    color: AppColors.color9D9D9D,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.color2D2D2D,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      10,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
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
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColors.color2FC4B2,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prediction.description ?? '',
                                style: TextStyle(
                                  fontFamily: "Rubik",
                                  fontSize: 14,
                                  color: AppColors.color2D2D2D,
                                ),
                              ),
                              if (prediction
                                      .structuredFormatting?.secondaryText !=
                                  null)
                                Text(
                                  prediction
                                      .structuredFormatting!.secondaryText!,
                                  style: TextStyle(
                                    fontFamily: "Rubik",
                                    fontSize: 12,
                                    color: AppColors.color9D9D9D,
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
          Obx(
            () {
              final shouldHide = controller.hideSelectButton.value && controller.existingAddress.value.isEmpty;
              debugPrint('View visibility check: hideSelectButton=${controller.hideSelectButton.value}, existingAddress="${controller.existingAddress.value}", shouldHide=$shouldHide');
              return shouldHide
                  ? SizedBox.shrink() // Hide when hideSelectButton is true AND no existing address
                  : Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(16),
                        child: SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected Address',
                              style: TextStyle(
                                fontFamily: "Rubik",
                                fontSize:14,
                                color: AppColors.color2D2D2D,
                              ),
                            ),
                            SizedBox(height: 8),
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
                                            fontFamily: "Rubik",
                                            fontSize: 14,
                                            color: AppColors.color2D2D2D,
                                          ),
                                        ),
                            ),
                            SizedBox(height: 16),
                            Obx(
                              () => controller.showSelectAddressButton.value
                                  ? SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.color2FC4B2,
                                              foregroundColor: AppColors.white,
                                              elevation: 0,
                                              minimumSize: Size(
                                                double.infinity,
                                                45,
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                vertical: 12,
                                                horizontal: 16,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(
                                                  10,
                                                ),
                                              ),
                                            ),
                                            onPressed: controller.onSelectAddress,
                                            child: Text(
                                              'Select Address',
                                              style: TextStyle(
                                                fontFamily: "Rubik",
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.white,
                                                fontSize: 16,
                                              ),
                                            ),
                                          )
                                        )
                                  : SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
            },
          ),
        ],
      );
      }),
    );
  }
}
