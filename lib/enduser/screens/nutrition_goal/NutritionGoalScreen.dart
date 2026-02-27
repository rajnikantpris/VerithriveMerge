import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import 'package:verithrive_dev/enduser/utils/app_text_styles.dart';
import 'NutritionGoalController.dart';

class NutritionGoalScreen extends GetView<NutritionGoalController> {
  const NutritionGoalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(AppAssets.back),
          onPressed: () => Get.back(),
        ),
        title: const Text(''),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'What are your goals...',
                style: AppTextStyles.popinSemiboldTextStyle(
                  fontSize: 24,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: Obx(() {
                    if (controller.isLoadingServices.value) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      );
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Show message when no data, otherwise show services list
                          if (controller.services.isEmpty && controller.apiMessage.value.isNotEmpty)
                            SizedBox(
                              height: 400, // Fixed height to center the message
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Text(
                                    controller.apiMessage.value,
                                    style: AppTextStyles.regularTextStyle(
                                      fontSize: 16,
                                      color: AppColors.greyText,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            )
                          else if (controller.services.isNotEmpty)
                            ...controller.services.asMap().entries.map((entry) {
                              int index = entry.key;
                              var service = entry.value;
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index < controller.services.length - 1 ? 12 : 0,
                                ),
                                child: _buildServiceItem(service),
                              );
                            }),
                        ],
                      );
                    }
                  }),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: controller.onSkip,
                  child: Obx(() => Text(
                    controller.getButtonText(),
                    style: AppTextStyles.mediumTextStyle(
                      fontSize: 14,
                      color: AppColors.white,
                    ),
                  )),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildServiceItem(dynamic service) {
    return Obx(() {
      bool isExpanded = controller.isServiceExpanded(service.id);
      bool hasSubServices = service.subServices.isNotEmpty;
      bool isSelected = hasSubServices ? false : controller.isServiceSelected(service.id);
      
      return Column(
        children: [
          // Parent Service Item
          GestureDetector(
            onTap: hasSubServices 
                ? () => controller.toggleServiceExpansion(service.id) 
                : () => controller.toggleServiceSelection(service.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryColor.withOpacity(0.1) : AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      service.serviceName,
                      style: AppTextStyles.regularTextStyle(
                        fontSize: 16,
                        color: isSelected ? AppColors.primaryColor : AppColors.black,
                      ),
                    ),
                  ),
                  if (hasSubServices)
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: AppColors.black,
                    )
                  else if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
          
          // Sub-services (expanded)
          if (hasSubServices && isExpanded) ...[
            const SizedBox(height: 8),
            ...service.subServices.map((subService) => _buildSubServiceItem(subService, service.id)),
            const SizedBox(height: 8),
          ],
        ],
      );
    });
  }
  
  Widget _buildSubServiceItem(dynamic subService, String serviceId) {
    return Obx(() {
      bool isSelected = controller.isSubServiceSelected(subService.id);
      
      return GestureDetector(
        onTap: () => controller.toggleSubServiceSelection(subService.id, serviceId),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryColor.withOpacity(0.1) : AppColors.colorE2F3F2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primaryColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  subService.subServiceName,
                  style: AppTextStyles.regularTextStyle(
                    fontSize: 14,
                    color: isSelected ? AppColors.primaryColor : AppColors.black,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
            ],
          ),
        ),
      );
    });
  }
}

