import 'package:get/get.dart';
import '../message/socket_service.dart';
import '../message/MessagesController.dart';
import 'package:verithrive_dev/services/storage_service.dart';

class MainTabController extends GetxController {
  final RxInt currentIndex = 0.obs;
  SocketService? _socketService;

  @override
  void onInit() {
    super.onInit();
    // Initialize local socket service
    _socketService = SocketService();
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

    // Get current user ID
    String? userId;
    String? token;
    if (Get.isRegistered<StorageService>()) {
      final storage = Get.find<StorageService>();
      userId = storage.readString('user_id') ??
          storage.readString('userId') ??
          storage.readString('_id');
      token = storage.readString('access_token') ??
          storage.readString('accessToken') ??
          storage.readString('token');
    }

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

