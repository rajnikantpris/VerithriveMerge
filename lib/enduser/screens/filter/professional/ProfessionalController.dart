import 'package:get/get.dart';
import '../../therapy_list/TherapistController.dart';
import '../FilterController.dart';

class ProfessionalController extends GetxController {

  // Single selection instead of multiple
  final RxString selectedSubTypeId = ''.obs;
  final RxBool hasManuallySelected = false.obs; // Track if user manually selected a value
  
  // Dynamic list of sub_types from API
  List<Map<String, dynamic>> subTypes = [];
  String? selectedSubTypeIdFromArgs;

  @override
  void onInit() {
    super.onInit();
    _loadSubTypesFromTherapistController();
    _loadSelectedSubTypeFromFilterController();
  }

  void _loadSubTypesFromTherapistController() {
    try {
      // Check if TherapistController is registered
      if (Get.isRegistered<TherapistController>()) {
        // Get TherapistController to access sub_types array
        final therapistController = Get.find<TherapistController>();
        
        if (therapistController.subTypesArray != null && 
            therapistController.subTypesArray!.isNotEmpty) {
          subTypes = List<Map<String, dynamic>>.from(therapistController.subTypesArray!);
          print('ProfessionalController: Loaded ${subTypes.length} sub_types');
        } else {
          print('ProfessionalController: No sub_types found in TherapistController, using empty list');
          subTypes = [];
        }
      } else {
        print('ProfessionalController: TherapistController not registered yet');
        subTypes = [];
      }
    } catch (e) {
      print('ProfessionalController: Error loading sub_types: $e');
      subTypes = [];
    }
  }

  void _loadSelectedSubTypeFromFilterController() {
    try {
      // Load selected sub type from FilterController (persisted filter value)
      if (Get.isRegistered<FilterController>()) {
        final filterController = Get.find<FilterController>();
        if (filterController.selectedProfessionalSubType.value.isNotEmpty) {
          selectedSubTypeId.value = filterController.selectedProfessionalSubType.value;
          print('ProfessionalController: Loaded selected sub_type from FilterController: ${selectedSubTypeId.value}');
          return;
        }
      }
      
      // Fallback: Load from TherapistController if FilterController doesn't have it
      if (Get.isRegistered<TherapistController>()) {
        final therapistController = Get.find<TherapistController>();
        if (therapistController.selectedProfessionalSubType != null && 
            therapistController.selectedProfessionalSubType!.isNotEmpty) {
          selectedSubTypeId.value = therapistController.selectedProfessionalSubType.value!;
          print('ProfessionalController: Loaded selected sub_type from TherapistController: ${selectedSubTypeId.value}');
        } else if (therapistController.subTypeId != null && 
                   therapistController.subTypeId!.isNotEmpty) {
          selectedSubTypeId.value = therapistController.subTypeId!;
          selectedSubTypeIdFromArgs = therapistController.subTypeId;
          print('ProfessionalController: Pre-selected sub_type_id from arguments: ${selectedSubTypeId.value}');
        }
      }
    } catch (e) {
      print('ProfessionalController: Error loading selected sub type: $e');
    }
  }

  void selectSubType(String subTypeId) {
    // Single selection - replace previous selection
    selectedSubTypeId.value = subTypeId;
    hasManuallySelected.value = true; // Mark as manually selected
    print('ProfessionalController: Selected sub_type_id: $subTypeId');
  }

  bool isSubTypeSelected(String subTypeId) {
    return selectedSubTypeId.value == subTypeId;
  }

  String? getSubTypeName(String subTypeId) {
    try {
      final subType = subTypes.firstWhere(
        (item) => item['id'] == subTypeId,
        orElse: () => {},
      );
      return subType['sub_type'] as String?;
    } catch (e) {
      return null;
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}


