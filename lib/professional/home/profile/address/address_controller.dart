import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../api/api_response.dart';
import '../../../../api/user_api_service.dart';
import '../../../../common/base_controller.dart';
import '../../../../models/address_details_model.dart';
import '../../../../routes/app_routes.dart';
import '../../../../widgets/response_dialog.dart';
import '../../../../services/analytics_service.dart';
import 'package:geocoding/geocoding.dart';

class AddressController extends BaseController {
  final UserApiService _userApiService;

  late final GlobalKey<FormState> formKey;

  // Your address fields
  final yourPostcodeController = TextEditingController();
  final yourAddressController = TextEditingController();
  final isManualYourPostcode = false.obs;
  final isManualYourAddress = false.obs;

  // Work address fields
  final workPostcodeController = TextEditingController();
  final workAddressController = TextEditingController();
  final isManualWorkPostcode = false.obs;
  final isManualWorkAddress = false.obs;

  // Location data
  final selectedLatitude = Rxn<double>();
  final selectedLongitude = Rxn<double>();
  final workLatitude = Rxn<double>();
  final workLongitude = Rxn<double>();
  final fullAddressId = Rxn<String>();
  final workAddressId = Rxn<String>();

  AddressController(this._userApiService);

  @override
  void onInit() {
    super.onInit();
    // Initialize formKey to ensure a new key is created each time
    formKey = GlobalKey<FormState>();
    // Load address details from API
    _loadAddressDetails();
  }

  @override
  void onClose() {
    yourPostcodeController.dispose();
    yourAddressController.dispose();
    workPostcodeController.dispose();
    workAddressController.dispose();
    super.onClose();
  }

  void enableManualYourPostcode() {
    isManualYourPostcode.value = true;
    isManualYourAddress.value = true;
  }

  void enableManualWorkPostcode() {
    isManualWorkPostcode.value = true;
    isManualWorkAddress.value = true;
  }

  /// Navigate to map screen to select address
  Future<void> onYourAddressTap() async {
    final result = await Get.toNamed(Routes.selectAddressMap);
    if (result != null && result is Map<String, dynamic>) {
      selectedLatitude.value = result['latitude'] as double?;
      selectedLongitude.value = result['longitude'] as double?;
      yourAddressController.text = result['address'] as String? ?? '';

      // Auto-fill postcode if available and not manually entered
      if (!isManualYourPostcode.value &&
          result['postcode'] != null &&
          result['postcode'].toString().isNotEmpty) {
        yourPostcodeController.text = result['postcode'] as String;
      }
      // Trigger validation after address is selected
      formKey.currentState?.validate();
    }
  }

  /// Navigate to map screen to select work address
  Future<void> onWorkAddressTap() async {
    final result = await Get.toNamed(Routes.selectAddressMap);
    if (result != null && result is Map<String, dynamic>) {
      workLatitude.value = result['latitude'] as double?;
      workLongitude.value = result['longitude'] as double?;
      workAddressController.text = result['address'] as String? ?? '';

      // Auto-fill postcode if available and not manually entered
      if (!isManualWorkPostcode.value &&
          result['postcode'] != null &&
          result['postcode'].toString().isNotEmpty) {
        workPostcodeController.text = result['postcode'] as String;
      }
      // Trigger validation after work address is selected
      formKey.currentState?.validate();
    }
  }

  /// Load address details from API
  Future<void> _loadAddressDetails() async {
    await callDataService<ApiResponse<dynamic>>(
      _userApiService.getCreateAddressDetails(),
      showLoader: true,
      onSuccess: (response) {
        if (response.success && response.data != null) {
          try {
            final data = response.data as Map<String, dynamic>?;
            if (data != null) {
              // Parse response using model
              final addressDetails = AddressDetailsModel.fromJson(data);

              // Populate main address
              if (addressDetails.postcode != null &&
                  addressDetails.postcode!.isNotEmpty) {
                yourPostcodeController.text = addressDetails.postcode!;
              }
              if (addressDetails.address != null &&
                  addressDetails.address!.isNotEmpty) {
                yourAddressController.text = addressDetails.address!;
              }
              if (addressDetails.latitude != null &&
                  addressDetails.longitude != null) {
                selectedLatitude.value = addressDetails.latitude;
                selectedLongitude.value = addressDetails.longitude;
              }
              // Store full address ID if available
              if (addressDetails.fullAddressId != null &&
                  addressDetails.fullAddressId!.isNotEmpty) {
                fullAddressId.value = addressDetails.fullAddressId;
              }

              // Populate work address (optional)
              if (addressDetails.workPostcode != null &&
                  addressDetails.workPostcode!.isNotEmpty) {
                workPostcodeController.text = addressDetails.workPostcode!;
              }
              if (addressDetails.workAddress != null &&
                  addressDetails.workAddress!.isNotEmpty) {
                workAddressController.text = addressDetails.workAddress!;
              }
              if (addressDetails.workLatitude != null &&
                  addressDetails.workLongitude != null) {
                workLatitude.value = addressDetails.workLatitude;
                workLongitude.value = addressDetails.workLongitude;
              }
              // Store work address ID if available
              if (addressDetails.workAddressId != null &&
                  addressDetails.workAddressId!.isNotEmpty) {
                workAddressId.value = addressDetails.workAddressId;
              }
            }
          } catch (e) {
            // Handle parsing errors
            debugPrint('Error parsing address details: $e');
          }
        }
      },
      onError: (error, stackTrace) {
        debugPrint('Error loading address details: $error');
      },
    );
  }

  void onUpdateAddress() {
    if (formKey.currentState?.validate() ?? false) {
      _updateAddress();
    }
  }

  /// Update address API call
  Future<void> _updateAddress() async {
    final postcode = yourPostcodeController.text.trim();
    final address = yourAddressController.text.trim();
    final workPostcode = workPostcodeController.text.trim();
    final workAddress = workAddressController.text.trim();

    // Prepare full_address array with latitude and longitude
    final fullAddressMap = <String, dynamic>{
      'postcode': postcode,
      'address': address,
    };

    // Add coordinates if available
    if (selectedLatitude.value != null && selectedLongitude.value != null) {
      fullAddressMap['latitude'] = selectedLatitude.value;
      fullAddressMap['longitude'] = selectedLongitude.value;
    }

    // Add _id if available (for update scenario)
    if (fullAddressId.value != null && fullAddressId.value!.isNotEmpty) {
      fullAddressMap['id'] = fullAddressId.value;
    }

    final fullAddress = [fullAddressMap];

    // Prepare work_address array (optional)
    List<Map<String, dynamic>>? workAddressList;
    if (workPostcode.isNotEmpty && workAddress.isNotEmpty) {
      final workAddressMap = <String, dynamic>{
        'postcode': workPostcode,
        'address': workAddress,
      };

      // Add work latitude and longitude if available
      if (workLatitude.value != null && workLongitude.value != null) {
        workAddressMap['latitude'] = workLatitude.value;
        workAddressMap['longitude'] = workLongitude.value;
      }

      // Add work address _id if available (for update scenario)
      if (workAddressId.value != null && workAddressId.value!.isNotEmpty) {
        workAddressMap['id'] = workAddressId.value;
      }

      workAddressList = [workAddressMap];
    }

    await callDataService<ApiResponse<dynamic>>(
      _userApiService.createAddress(
        fullAddress: fullAddress,
        workAddress: workAddressList,
      ),
      showLoader: true,
      onSuccess: (response) async {
        if (response.success) {
          // Track city in analytics when address is updated
          final postcode = yourPostcodeController.text.trim();
          if (postcode.isNotEmpty) {
            AnalyticsService.instance.setUserProfile(
              city: await getCityFromAddress(fullAddress.toString().toLowerCase()),
            );
          }
          
          showResponseDialog(
            title: 'Success',
            message: response.message ?? 'Address updated successfully',
            isError: false,
            showButton: false,
            onOkPressed: () {
              Get.back();
            },
          );
        } else {
          showResponseDialog(
            title: 'Error',
            message: response.errorMessage,
            isError: true,
            showButton: true,
          );
        }
      },
      onError: (error, stack) {
        debugPrint('Error updating address: $error');
        final errorMsg = errorMessage.value.isNotEmpty
            ? errorMessage.value
            : 'Failed to update address. Please try again.';
        showResponseDialog(
          title: 'Error',
          message: errorMsg,
          isError: true,
          showButton: true,
        );
      },
    );
  }

  String? validateNotEmpty(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $label';
    }
    return null;
  }

  Future<String?> getCityFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        double lat = locations.first.latitude;
        double lng = locations.first.longitude;

        List<Placemark> placemarks =
        await placemarkFromCoordinates(lat, lng);

        if (placemarks.isNotEmpty) {
          return placemarks.first.locality!.toLowerCase(); // return city
        }
      }
    } catch (e) {
      print("Error: $e");
    }

    return null;
  }


}
