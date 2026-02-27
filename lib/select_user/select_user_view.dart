import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../enduser/core/values/app_colors.dart';
import '../enduser/utils/app_assets.dart';
import '../enduser/utils/app_text_styles.dart';
import 'select_user_controller.dart';

class SelectUserView extends GetView<SelectUserController> {
  const SelectUserView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
        
              Image.asset(
                AppAssets.app_logo_splash,
                width: MediaQuery.of(context).size.width * 0.6,
                fit: BoxFit.contain,
                errorBuilder:
                    (BuildContext context, Object error, StackTrace? stackTrace) {
                  return Icon(
                    Icons.error_outline,
                    size: 200,
                  );
                },
              ),
        
              SizedBox(height: 30,),
        
              Text(
                "How Would You Like to Continue?",
                style: AppTextStyles.titleStyle(fontSize: 20),
              ),
        
              SizedBox(height: 30,),
        
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.openProfessional,
                  child: const Text('Professional'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.openEndUser,
                  child: const Text('End User'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
