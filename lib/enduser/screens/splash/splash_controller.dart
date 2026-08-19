import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../core/values/sharePrefrenceConst.dart';
import 'package:verithrive_dev/services/storage_service.dart';
import 'package:verithrive_dev/services/analytics_service.dart';

class SplashController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();

  @override
  void onInit() {
    super.onInit();
    AnalyticsService.instance.logScreenView(
      screenName: 'SplashScreen',
      screenClass: 'SplashScreen',
      pageCategory: 'splash',
      elementLocation: 'view',
    );
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    
    // Check if user is logged in
    bool isLoggedIn =
        _storageService.readBool(SharePreferenceConst.isLogin) ?? false;
    
    if (isLoggedIn) {
      // Check if personal details are completed
      bool isPersonalDetailsCompleted =
          _storageService.readBool(SharePreferenceConst.isPersonalDetails) ??
              false;
      
      if (isPersonalDetailsCompleted) {
        // Navigate to main screen if personal details are completed
        Get.offAllNamed(AppRoutes.main);
      } else {
        // Navigate to profile screen to complete personal details
        Get.offAllNamed(AppRoutes.profile);
      }
    } else {
      // Navigate to onboarding if not logged in
      Get.offAllNamed(AppRoutes.onboarding);
    }
  }
}
