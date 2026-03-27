import 'package:get/get.dart';
import '../message/socket_service.dart';
import '../message/MessagesController.dart';
import 'package:verithrive_dev/services/storage_service.dart';
import '../../core/values/sharePrefrenceConst.dart';

class MainTabController extends GetxController {
  final RxInt currentIndex = 0.obs;
  EndUserSocketService? _socketService;

  @override
  void onInit() {
    super.onInit();
    // Initialize local socket service
    _socketService = EndUserSocketService();
    // Connect socket for authenticated users
    _connectSocket();
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

