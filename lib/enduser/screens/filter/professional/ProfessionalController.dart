import 'package:get/get.dart';
import '../../therapy_list/TherapistController.dart';
import '../FilterController.dart';
import 'package:verithrive_dev/services/analytics_service.dart';

class ProfessionalController extends GetxController {
  final RxList<String> selectedSubTypeIds = <String>[].obs;
  final RxBool hasManuallySelected = false.obs;

  List<Map<String, dynamic>> subTypes = [];

  @override
  void onInit() {
    super.onInit();
    AnalyticsService.instance.logScreenView(
      screenName: 'ProfessionalFilterScreen',
      screenClass: 'ProfessionalFilterScreen',
      pageCategory: 'filter',
      elementLocation: 'view',
    );
    _loadSubTypesFromTherapistController();
    _loadSelectedSubTypes();
  }

  void _loadSubTypesFromTherapistController() {
    try {
      if (Get.isRegistered<TherapistController>()) {
        final therapistController = Get.find<TherapistController>();

        if (therapistController.subTypesArray != null &&
            therapistController.subTypesArray!.isNotEmpty) {
          subTypes = List<Map<String, dynamic>>.from(
              therapistController.subTypesArray!);
          print('ProfessionalController: Loaded ${subTypes.length} sub_types');
        } else {
          print(
              'ProfessionalController: No sub_types found in TherapistController, using empty list');
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

  void _loadSelectedSubTypes() {
    try {
      if (Get.isRegistered<FilterController>()) {
        final filterController = Get.find<FilterController>();
        if (filterController.selectedProfessionalSubTypes.isNotEmpty) {
          selectedSubTypeIds
              .assignAll(filterController.selectedProfessionalSubTypes);
          print(
              'ProfessionalController: Loaded selected sub_types from FilterController: $selectedSubTypeIds');
          return;
        }
      }

      if (Get.isRegistered<TherapistController>()) {
        final therapistController = Get.find<TherapistController>();
        if (therapistController.selectedProfessionalSubTypes.isNotEmpty) {
          selectedSubTypeIds
              .assignAll(therapistController.selectedProfessionalSubTypes);
          print(
              'ProfessionalController: Loaded selected sub_types from TherapistController: $selectedSubTypeIds');
        } else if (therapistController.subTypeId != null &&
            therapistController.subTypeId!.isNotEmpty) {
          selectedSubTypeIds.assign(therapistController.subTypeId!);
          print(
              'ProfessionalController: Pre-selected sub_type_id from arguments: ${therapistController.subTypeId}');
        }
      }
    } catch (e) {
      print('ProfessionalController: Error loading selected sub types: $e');
    }
  }

  void toggleSubType(String subTypeId) {
    if (subTypeId.isEmpty) return;
    if (selectedSubTypeIds.contains(subTypeId)) {
      selectedSubTypeIds.remove(subTypeId);
    } else {
      selectedSubTypeIds.add(subTypeId);
    }
    hasManuallySelected.value = true;
    print('ProfessionalController: Selected sub_type_ids: $selectedSubTypeIds');
  }

  bool isSubTypeSelected(String subTypeId) {
    return selectedSubTypeIds.contains(subTypeId);
  }

  List<String> selectedSubTypeNames() {
    final names = <String>[];
    for (final id in selectedSubTypeIds) {
      for (final item in subTypes) {
        final itemId = item['id']?.toString() ?? '';
        if (itemId == id) {
          final name = item['sub_type']?.toString().trim() ?? '';
          if (name.isNotEmpty) names.add(name);
          break;
        }
      }
    }
    return names;
  }
}
