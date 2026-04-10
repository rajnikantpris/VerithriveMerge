import 'dart:async';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/storage_service.dart';
import '../utils/logger.dart';
import '../api/user_api_service.dart';

/// Socket.IO service for managing real-time chat communication
class SocketService extends GetxService {
  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;
  String? _currentToken;

  // Socket connection status
  final isConnected = false.obs;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }

  /// Initialize and connect to Socket.IO server
  Future<void> connect({String? userId, String? token}) async {
    // Get user ID and token from storage if not provided
    userId ??= await _getUserId();
    token ??= await _getAccessToken();

    if (userId == null || userId.isEmpty || token == null || token.isEmpty) {
      logInfo('Cannot connect: User ID or Access token not available');
      return;
    }

    // If user or token changed, force a complete disconnect and reset
    if (_socket != null && (_currentUserId != userId || _currentToken != token)) {
      logInfo('User or Token changed. Forcing fresh socket connection.');
      disconnect();
    }

    // If already connected to the same user/token, just return
    if (_isConnected && _socket != null && _socket!.connected && _currentUserId == userId && _currentToken == token) {
      logInfo('Socket already connected to this user');
      return;
    }

    try {
      _currentUserId = userId;
      _currentToken = token;

      final userType = await _getUserType();
      final baseUrl = UserApiService.socketBaseUrl;

      logInfo('Connecting to Socket.IO: $baseUrl for User: $userId');

      // Configure options for a fresh, non-multiplexed connection
      final options = IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setExtraHeaders({
            'auth': token,
            'userType': userType ?? 'professional',
          })
          // Modern Socket.IO servers often prefer token in the auth object
          .setAuth({'token': token})
          .setPath('/socket.io')
          .enableForceNew()     // Force creation of a new connection
          .disableMultiplex()   // Prevent sharing connection with other instances
          .disableAutoConnect()
          // Add this to ensure we don't try to use secure connection for HTTP URLs
          .setQuery({'secure': baseUrl.startsWith('https') ? 'true' : 'false'})
          .build();

      _socket = IO.io(baseUrl, options);
      _setupEventListeners();
      _socket!.connect();
    } catch (e) {
      logError('Error connecting to Socket.IO', error: e);
      _isConnected = false;
      isConnected.value = false;
    }
  }

  void _setupEventListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      _isConnected = true;
      isConnected.value = true;
      logInfo('✅ Socket.IO connected: ${_socket?.id} for user: $_currentUserId');
    });

    _socket!.onDisconnect((reason) {
      _isConnected = false;
      isConnected.value = false;
      logInfo('❌ Socket.IO disconnected: $reason');
    });

    _socket!.onConnectError((error) => logError('Socket connection error', error: error));

    _socket!.on('user_connection_status', (data) {
      if (_isConnected) getInbox();
    });

    _socket!.onAny((event, data) {
      // debugPrint('📡 Socket Event: $event');
    });
  }

  void getInbox() {
    if (_socket == null || !_isConnected) return;
    _socket!.emit('get_inbox');
    logInfo('Sent get_inbox event');
  }

  void onInboxData(Function(Map<String, dynamic>) callback) {
    _socket?.on('inbox_data', (data) {
      if (data is Map<String, dynamic>) callback(data);
    });
  }

  void markRead({
    required String roomId,
    List<String>? messageIds,
  }) {
    if (_socket == null || !_isConnected) {
      logInfo('Cannot mark read: Socket not connected');
      return;
    }

    final readData = {
      'room_id': roomId,
      if (messageIds != null) 'messageIds': messageIds,
    };

    _socket!.emit('mark_read', readData);
    logInfo('Marked messages as read: $readData');
  }

  void sendMessage({
    required String message,
    required String receiverId,
    String? chatId,
  }) {
    if (_socket == null || !_isConnected) return;

    final messageData = {
      'room_id': chatId,
      'receiver_id': receiverId,
      'message': message,
    };

    _socket!.emit('send_message', messageData);
  }

  void onReceiveMessage(Function(Map<String, dynamic>) callback) {
    if (_socket == null) {
      logInfo('Cannot listen for messages: Socket not initialized');
      return;
    }
    _socket!.on('receive_message', (data) {
      logInfo('Received message via Socket.IO: $data');
      if (data is Map<String, dynamic>) {
        callback(data);
      }
    });
  }

  void offReceiveMessage() {
    _socket?.off('receive_message');
  }

  void offInboxData() => _socket?.off('inbox_data');

  void disconnect() {
    if (_socket != null) {
      _socket!.clearListeners(); // Remove all listeners
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _isConnected = false;
    isConnected.value = false;
    _currentUserId = null;
    _currentToken = null;
    logInfo('Socket fully disconnected and disposed');
  }

  Future<String?> _getUserId() async {
    if (!Get.isRegistered<StorageService>()) return null;
    return Get.find<StorageService>().readString('user_id');
  }

  Future<String?> _getAccessToken() async {
    if (!Get.isRegistered<StorageService>()) return null;
    return Get.find<StorageService>().readString('access_token');
  }

  Future<String?> _getUserType() async {
    if (!Get.isRegistered<StorageService>()) return null;
    final storage = Get.find<StorageService>();
    return storage.readString('userType') ?? storage.readString('user_type');
  }

  bool get connected => _isConnected && (_socket?.connected ?? false);
}
