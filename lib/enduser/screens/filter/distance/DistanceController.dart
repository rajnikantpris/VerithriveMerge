import 'package:get/get.dart';
import '../../therapy_list/TherapistController.dart';
import '../FilterController.dart';
import 'package:verithrive_dev/services/analytics_service.dart';

class DistanceController extends GetxController {
  // Distance filter
  final RxDouble maxDistance = 13.0.obs; // in miles
  final double minDistance = 0.0;
  final double maxDistanceLimit = 25.0;

  @override
  void onInit() {
    super.onInit();
    AnalyticsService.instance.logScreenView(
      screenName: 'DistanceFilterScreen',
      screenClass: 'DistanceFilterScreen',
      pageCategory: 'filter',
      elementLocation: 'view',
    );
    _loadInitialDistance();
  }

  void _loadInitialDistance() {
    try {
      // First try to load from FilterController (persisted filter value)
      if (Get.isRegistered<FilterController>()) {
        final filterController = Get.find<FilterController>();
        if (filterController.maxDistance.value != 13.0 && filterController.maxDistance.value > 0.0) {
          maxDistance.value = filterController.maxDistance.value;
          print('DistanceController: Loaded distance from FilterController: ${maxDistance.value}');
          return;
        }
      }
      
      // Fallback: Get initial distance from TherapistController if available
      if (Get.isRegistered<TherapistController>()) {
        final therapistController = Get.find<TherapistController>();
        
        // Use selectedDistance if set and valid (> 0 and != 13.0), otherwise use distance from arguments
        if (therapistController.selectedDistance != null && 
            therapistController.selectedDistance.value! > 0.0 && 
            therapistController.selectedDistance.value! != 13.0) {
          maxDistance.value = therapistController.selectedDistance.value!;
          print('DistanceController: Loaded distance from selectedDistance: ${maxDistance.value}');
          return;
        } else if (therapistController.distance != null && 
                   therapistController.distance! > 0.0 && 
                   therapistController.distance! != 13.0) {
          maxDistance.value = therapistController.distance!;
          print('DistanceController: Loaded distance from arguments: ${maxDistance.value}');
          return;
        }
      }
      
      // If no valid distance found, keep default 13.0
      print('DistanceController: Using default distance: ${maxDistance.value}');
    } catch (e) {
      print('DistanceController: Error loading initial distance: $e');
    }
  }

  // Distance filter methods
  void setDistance(double value) {
    maxDistance.value = value;
  }

}


