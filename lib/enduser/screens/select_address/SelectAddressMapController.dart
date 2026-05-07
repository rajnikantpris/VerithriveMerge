import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_places_flutter/model/prediction.dart';

import '../../core/base/base_controller.dart';
import '../../utils/location_permission_service.dart';

class SelectAddressMapController extends BaseController {
  final LocationPermissionService _locationPermissionService =
      LocationPermissionService();

  // Google Maps Controller
  GoogleMapController? mapController;

  // Current position
  final currentPosition = Rxn<LatLng>();
  final selectedPosition = Rxn<LatLng>();
  final selectedAddress = ''.obs;
  final selectedPostcode = ''.obs;
  final isLoadingAddress = false.obs;

  // Search controller
  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();

  // Camera position
  CameraPosition? initialCameraPosition;
  final isMapInitialized = false.obs;

  // Debounce timer for reverse geocoding
  Timer? _geocodeTimer;

  // Marker
  final Set<Marker> markers = <Marker>{}.obs;

  // Initial coordinates passed from profile
  final initialLatitude = Rxn<double>();
  final initialLongitude = Rxn<double>();
  
  // Flag to track if user has interacted with map
  final hasUserInteracted = false.obs;

  // Flag to show/hide select address button
  final showSelectAddressButton = false.obs;

  // Flag to hide entire bottom section (from profile screen)
  final hideSelectButton = false.obs;

  // Flag to track if map is fully initialized (to prevent initial camera move from triggering interaction)
  final isMapFullyInitialized = false.obs;
  
  // Existing address from profile
  final existingAddress = ''.obs;

  @override
  void onInit() {
    super.onInit();

    // Get initial coordinates from arguments if passed
    final arguments = Get.arguments as Map<String, dynamic>?;
    debugPrint('=== Map onInit START ===');
    debugPrint('Map arguments received: $arguments');

    if (arguments != null) {
      initialLatitude.value = arguments['latitude'] as double?;
      initialLongitude.value = arguments['longitude'] as double?;

      debugPrint('Map initial coordinates: lat=${initialLatitude.value}, lng=${initialLongitude.value}');

      // Check if hideSelectButton flag is set (from profile screen)
      final hideSelectButtonFlag = arguments['hideSelectButton'] as bool? ?? false;
      hideSelectButton.value = hideSelectButtonFlag;
      debugPrint('Hide select button flag: $hideSelectButtonFlag, hideSelectButton.value=${hideSelectButton.value}');

      // Get existing address from profile
      final address = arguments['existingAddress'] as String? ?? '';
      existingAddress.value = address;
      debugPrint('Existing address from profile: "$address", existingAddress.value="${existingAddress.value}"');

      // Debug: Check visibility condition
      final shouldHide = hideSelectButtonFlag && address.isEmpty;
      debugPrint('Bottom section visibility check: hideSelectButton=$hideSelectButtonFlag, existingAddress.isEmpty=${address.isEmpty}, shouldHide=$shouldHide');
    } else {
      debugPrint('No arguments passed to map screen');
    }

    _initializeMap();
    debugPrint('=== Map onInit END ===');
  }

  @override
  void onClose() {
    _geocodeTimer?.cancel();
    searchController.dispose();
    searchFocusNode.dispose();
    mapController?.dispose();
    super.onClose();
  }

  Future<void> _initializeMap() async {
    try {
      debugPrint('=== _initializeMap START ===');
      // Request location permission
      bool hasPermission =
          await _locationPermissionService.checkLocationPermissionStatus();

      // If not granted, request permission
      if (!hasPermission) {
        hasPermission =
            await _locationPermissionService.requestLocationPermission();
      }

      LatLng targetPosition;
      
      // Use initial coordinates if available, otherwise get current location
      if (initialLatitude.value != null && initialLongitude.value != null) {
        targetPosition = LatLng(initialLatitude.value!, initialLongitude.value!);
        currentPosition.value = targetPosition;
        selectedPosition.value = targetPosition;
        
        initialCameraPosition = CameraPosition(
          target: targetPosition,
          zoom: 16.0,
        );
        isMapInitialized.value = true;
        
        debugPrint('Using initial coordinates: $targetPosition');
        debugPrint('Before reverse geocode: hideSelectButton=${hideSelectButton.value}, existingAddress="${existingAddress.value}"');

        // Reverse geocode to get address for initial coordinates
        await _reverseGeocode(targetPosition);

        debugPrint('After reverse geocode: selectedAddress="${selectedAddress.value}"');

        // If we have existing address from profile, use it instead of reverse geocoded address
        if (existingAddress.value.isNotEmpty) {
          selectedAddress.value = existingAddress.value;
          debugPrint('Using existing address from profile: ${existingAddress.value}');
        }

        debugPrint('After _initializeMap: hideSelectButton=${hideSelectButton.value}, existingAddress="${existingAddress.value}"');
      } else if (hasPermission) {
        await _getCurrentLocation();
      } else {
        // Default to a location (London, UK)
        final defaultPosition = const LatLng(51.5074, -0.1278);
        currentPosition.value = defaultPosition;
        selectedPosition.value = defaultPosition;
        initialCameraPosition = CameraPosition(
          target: defaultPosition,
          zoom: 14.0,
        );
        isMapInitialized.value = true;
        await _reverseGeocode(defaultPosition);
      }
      debugPrint('=== _initializeMap END ===');
    } catch (e) {
      debugPrint('Error initializing map: $e');
      // Default to a location on error
      final defaultPosition = const LatLng(51.5074, -0.1278);
      currentPosition.value = defaultPosition;
      selectedPosition.value = defaultPosition;
      initialCameraPosition = CameraPosition(
        target: defaultPosition,
        zoom: 14.0,
      );
      isMapInitialized.value = true;
      await _reverseGeocode(defaultPosition);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(position.latitude, position.longitude);
      currentPosition.value = latLng;
      selectedPosition.value = latLng;

      initialCameraPosition = CameraPosition(
        target: latLng,
        zoom: 14.0,
      );
      isMapInitialized.value = true;

      // Move camera to current location
      if (mapController != null) {
        await mapController!.animateCamera(
          CameraUpdate.newCameraPosition(initialCameraPosition!),
        );
      }

      await _reverseGeocode(latLng);
    } catch (e) {
      debugPrint('Error getting current location: $e');
      Get.snackbar(
        'Error',
        'Failed to get current location',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    // Mark map as fully initialized after a short delay to prevent initial camera moves from triggering interaction
    Future.delayed(const Duration(milliseconds: 500), () {
      isMapFullyInitialized.value = true;
      debugPrint('Map fully initialized');
    });
  }

  // Handle map errors
  void onMapError(String error) {
    debugPrint('Google Maps Error: $error');
    Get.snackbar(
      'Map Error',
      'Failed to load map. Please check your API key and ensure Maps SDK is enabled.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
    );
  }

  void onCameraMove(CameraPosition position) {
    // Update selected position as camera moves
    selectedPosition.value = position.target;

    // Mark that user has interacted with the map (only after map is fully initialized)
    // Only if the position has actually changed from the initial position
    if (!hasUserInteracted.value && isMapFullyInitialized.value) {
      // Check if position has changed significantly from initial position
      if (initialLatitude.value != null && initialLongitude.value != null) {
        final distance = Geolocator.distanceBetween(
          initialLatitude.value!,
          initialLongitude.value!,
          position.target.latitude,
          position.target.longitude,
        );
        // Only treat as user interaction if moved at least 10 meters
        if (distance > 10) {
          hasUserInteracted.value = true;
          showSelectAddressButton.value = true;
          hideSelectButton.value = false;
          debugPrint('User interacted with map - showing bottom section (moved $distance meters)');
        }
      } else {
        // No initial position, treat any move as interaction
        hasUserInteracted.value = true;
        showSelectAddressButton.value = true;
        hideSelectButton.value = false;
        debugPrint('User interacted with map - showing bottom section');
      }
    }
  }

  void onCameraIdle() {
    // When map stops moving, perform reverse geocoding
    if (selectedPosition.value != null) {
      _debouncedReverseGeocode(selectedPosition.value!);
    }
  }

  void _debouncedReverseGeocode(LatLng position) {
    // Cancel previous timer
    _geocodeTimer?.cancel();

    // Start new timer (wait 500ms after map stops moving)
    _geocodeTimer = Timer(const Duration(milliseconds: 500), () {
      _reverseGeocode(position);
    });
  }

  Future<void> _reverseGeocode(LatLng position) async {
    try {
      isLoadingAddress.value = true;
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final addressParts = <String>[];

        if (placemark.street != null && placemark.street!.isNotEmpty) {
          addressParts.add(placemark.street!);
        }
        if (placemark.subThoroughfare != null &&
            placemark.subThoroughfare!.isNotEmpty) {
          addressParts.insert(0, placemark.subThoroughfare!);
        }
        if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          addressParts.add(placemark.locality!);
        }

        // Extract postcode separately
        if (placemark.postalCode != null && placemark.postalCode!.isNotEmpty) {
          selectedPostcode.value = placemark.postalCode!;
          addressParts.add(placemark.postalCode!);
        } else {
          selectedPostcode.value = '';
        }

        if (placemark.country != null && placemark.country!.isNotEmpty) {
          addressParts.add(placemark.country!);
        }

        selectedAddress.value = addressParts.join(', ');
      } else {
        selectedAddress.value = 'Address not found';
        selectedPostcode.value = '';
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
      selectedAddress.value = 'Failed to get address';
      selectedPostcode.value = '';
    } finally {
      isLoadingAddress.value = false;
    }
  }

  Future<void> moveToCurrentLocation() async {
    final hasPermission =
        await _locationPermissionService.requestLocationPermission();
    if (!hasPermission) {
      Get.snackbar(
        'Permission Required',
        'Location permission is required to use this feature',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await _getCurrentLocation();
  }

  void onPlaceSelected(Prediction prediction,
      {bool updateSearchText = false}) async {
    try {
      // Mark that user has interacted with the map
      if (!hasUserInteracted.value) {
        hasUserInteracted.value = true;
        showSelectAddressButton.value = true;
      }
      
      // Override hideSelectButton flag when user searches and selects an address
      if (hideSelectButton.value) {
        hideSelectButton.value = false;
        debugPrint('Override hideSelectButton flag due to address search and selection');
      }
      
      if (updateSearchText) {
        searchController.text = prediction.description ?? '';
        searchFocusNode.unfocus();
      }

      // Check if prediction has lat/lng directly
      if (prediction.lat != null && prediction.lng != null) {
        final latLng = LatLng(
          double.parse(prediction.lat!),
          double.parse(prediction.lng!),
        );

        selectedPosition.value = latLng;

        // Move camera to selected location
        final cameraPosition = CameraPosition(
          target: latLng,
          zoom: 16.0,
        );

        if (mapController != null) {
          await mapController!.animateCamera(
            CameraUpdate.newCameraPosition(cameraPosition),
          );
        }

        // Reverse geocode to get full address
        await _reverseGeocode(latLng);
      } else {
        // Fallback: Geocode the selected place by description
        final locations =
            await locationFromAddress(prediction.description ?? '');
        if (locations.isNotEmpty) {
          final location = locations.first;
          final latLng = LatLng(location.latitude, location.longitude);

          selectedPosition.value = latLng;

          // Move camera to selected location
          final cameraPosition = CameraPosition(
            target: latLng,
            zoom: 16.0,
          );

          if (mapController != null) {
            await mapController!.animateCamera(
              CameraUpdate.newCameraPosition(cameraPosition),
            );
          }

          // Reverse geocode to get full address
          await _reverseGeocode(latLng);
        }
      }
    } catch (e) {
      debugPrint('Error selecting place: $e');
      Get.snackbar(
        'Error',
        'Failed to load selected location',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void onSelectAddress() {
    if (selectedPosition.value != null && selectedAddress.value.isNotEmpty) {
      Get.back(
        result: {
          'latitude': selectedPosition.value!.latitude,
          'longitude': selectedPosition.value!.longitude,
          'address': selectedAddress.value,
          'postcode': selectedPostcode.value,
        },
      );
    } else {
      Get.snackbar(
        'Error',
        'Please select a valid address',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
