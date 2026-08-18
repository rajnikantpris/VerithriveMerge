import 'package:get/get.dart';
import '../message/socket_service.dart';
import '../message/MessagesController.dart';
import 'package:verithrive_dev/services/storage_service.dart';
import 'package:verithrive_dev/services/analytics_service.dart';
import '../../core/values/sharePrefrenceConst.dart';

class MainTabController extends GetxController {
  final RxInt currentIndex = 0.obs;
  EndUserSocketService? _socketService;
  int? _lastLoggedTabIndex;

  @override
  void onInit() {
    super.onInit();
    // Initialize local socket service
    _socketService = EndUserSocketService();
    // Connect socket for authenticated users
    _connectSocket();
    _logTabScreenView(currentIndex.value);
  }

  void setTab(int index) {
    if (index == 2) {
      // Check and reconnect socket when Messages tab is selected
      if (Get.isRegistered<MessagesController>()) {
        final messagesController = Get.find<MessagesController>();
        messagesController.checkAndReconnectSocket();
      }
    }
    currentIndex.value = index;
    _logTabScreenView(index);
  }

  void _logTabScreenView(int index) {
    if (_lastLoggedTabIndex == index) return;
    _lastLoggedTabIndex = index;

    switch (index) {
      case 0:
        AnalyticsService.instance.logScreenView(
          screenName: 'HomeMainScreen',
          screenClass: 'HomeMainScreen',
          pageCategory: 'home',
          elementLocation: 'view',
        );
        break;
      case 1:
        AnalyticsService.instance.logScreenView(
          screenName: 'BookingsScreen',
          screenClass: 'BookingsScreen',
          pageCategory: 'booking',
          elementLocation: 'view',
        );
        break;
      case 2:
        AnalyticsService.instance.logScreenView(
          screenName: 'MessagesScreen',
          screenClass: 'MessagesScreen',
          pageCategory: 'messaging',
          elementLocation: 'view',
        );
        break;
      case 3:
        AnalyticsService.instance.logScreenView(
          screenName: 'SavedScreen',
          screenClass: 'SavedScreen',
          pageCategory: 'saved',
          elementLocation: 'view',
        );
        break;
    }
  }

  /// Connect Socket.IO for authenticated users
  Future<void> _connectSocket() async {
    if (_socketService == null) return;

    // Get current user ID (end-user specific)
    String? userId;
    String? token;
    if (Get.isRegistered<StorageService>()) {
      final storage = Get.find<StorageService>();
      // Try end-user specific keys first
      userId = storage.readString(SharePreferenceConst.id); // Fallback to professional key
          
      token = storage.readString('access_token') ;
    }

    print('MainTabController - Connecting socket with User ID: $userId');
    
    // Connect socket with user ID and token
    await _socketService!.connect(userId: userId, token: token);
  }

  @override
  void onClose() {
    // Disconnect socket service
    _socketService?.disconnect();
    _socketService = null;
    super.onClose();
  }
}

