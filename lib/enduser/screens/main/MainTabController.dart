import 'package:get/get.dart';
import '../message/socket_service.dart';
import '../message/MessagesController.dart';
import 'package:verithrive_dev/services/storage_service.dart';

class MainTabController extends GetxController {
  final RxInt currentIndex = 0.obs;

  // Get SocketService if available
  SocketService? get _socketService =>
      Get.isRegistered<SocketService>() ? Get.find<SocketService>() : null;

  @override
  void onInit() {
    super.onInit();
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
}

