import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../utils/logger.dart';
import '../../utils/api_services.dart';
import '../../core/values/sharePrefrenceConst.dart';
import 'package:verithrive_dev/services/storage_service.dart';

/// Socket.IO service for managing real-time chat communication (End User version)
class EndUserSocketService extends GetxService {
  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;
  Timer? _connectionTimeout;

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
    try {
      // Get user ID from storage if not provided
      if (userId == null) {
        userId = await _getUserId();
      }

      if (userId == null || userId.isEmpty) {
        log('Cannot connect: User ID not available');
        return;
      }

      // Get token from storage if not provided
      if (token == null) {
        token = await _getAccessToken();
      }

      // Validate token is available
      if (token == null || token.isEmpty) {
        log('Cannot connect: Access token not available');
        return;
      }

      // If socket exists and is connected to the same user, don't reconnect
      if (_socket != null && _isConnected && _currentUserId == userId) {
        log('Socket already connected for user: $userId. Skipping reconnection.');
        return;
      }

      // If socket exists but connected to a DIFFERENT user, disconnect and dispose
      if (_socket != null) {
        log('Disposing previous socket (different user or disconnected) before new connection attempt');
        _socket!.disconnect();
        _socket!.dispose();
        _socket = null;
      }

      _isConnected = false;
      isConnected.value = false;
      _currentUserId = userId;

      // Get user type for identification
      final userType = await _getUserType();
      log('Connecting End-User Socket - UserID: $userId, Type: $userType');

      final baseUrl = socketUrl;
      log('Connecting to Socket.IO: $baseUrl');

      // Log partial token for verification without exposing full credential
      if (token.length > 10) {
        log('Token verified: ...${token.substring(token.length - 8)}');
      }

      // Socket.IO options
      final options = IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .enableForceNew() // Force a new connection to avoid session bleeding
          .setExtraHeaders({
            'auth': token,
            'userType': userType ?? 'normal',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (Platform.isIOS) ...{
              'User-Agent': 'iOS-Verithrive-App',
              'Connection': 'keep-alive',
            },
          })
          // Modern Socket.IO servers often prefer token in the auth object
          .setAuth({'token': token})
          .setPath('/socket.io')
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .setTimeout(30000)
          // Add this to ensure we don't try to use secure connection for HTTP URLs
          .setQuery({'secure': baseUrl.startsWith('https') ? 'true' : 'false'})
          .build();

      log('Creating fresh socket instance...');
      _socket = IO.io(baseUrl, options);

      _setupEventListeners();
      _socket!.connect();

      // Add connection timeout for iOS
      if (Platform.isIOS) {
        _connectionTimeout = Timer(Duration(seconds: 30), () {
          if (!_isConnected) {
            log('iOS socket connection timeout - attempting polling fallback');
            _fallbackToPolling();
          }
        });
      }
    } catch (e) {
      log('Error connecting to Socket.IO: $e');
      _isConnected = false;
      isConnected.value = false;
    }
  }

  /// Setup Socket.IO event listeners
  void _setupEventListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      _isConnected = true;
      isConnected.value = true;
      log('✅ End-User Socket.IO connected successfully! ID: ${_socket?.id}');
      _connectionTimeout?.cancel();
      _connectionTimeout = null;
    });

    _socket!.onDisconnect((reason) {
      _isConnected = false;
      isConnected.value = false;
      log('❌ End-User Socket.IO disconnected. Reason: $reason');
    });

    _socket!.onConnectError((error) {
      _isConnected = false;
      isConnected.value = false;
      log('❌ End-User Socket.IO connection error: $error');

      if (Platform.isIOS && error.toString().contains('websocket')) {
        _fallbackToPolling();
      }
    });

    _socket!.onError((data) {
      log('❌ End-User Socket.IO error: $data');
    });

    _socket!.onAny((event, data) {
      log('📡 End-User Socket event: $event, Data: $data');
    });
  }

  /// Send a message via Socket.IO - send_message event
  void sendMessage({
    required String message,
    required String receiverId,
    String? chatId,
  }) {
    if (_socket == null || !_isConnected) {
      log('Cannot send message: Socket not connected');
      return;
    }

    if (chatId == null || chatId.isEmpty) {
      log('Cannot send message: Chat ID (room_id) not provided');
      return;
    }

    final messageData = {
      'room_id': chatId,
      'receiver_id': receiverId,
      'message': message,
    };

    _socket!.emit('send_message', messageData);
    log('Sent message via Socket.IO: $messageData');
  }

  /// Listen for incoming messages - receive_message event
  void onReceiveMessage(Function(Map<String, dynamic>) callback) {
    if (_socket == null) return;
    _socket!.on('receive_message', (data) {
      if (data is Map<String, dynamic>) {
        callback(data);
      }
    });
  }

  /// Remove receive_message listener
  void offReceiveMessage() {
    _socket?.off('receive_message');
  }

  /// Mark messages as read - mark_read event
  void markRead({
    required String roomId,
    List<String>? messageIds,
  }) {
    if (_socket == null || !_isConnected) return;
    final readData = {
      'room_id': roomId,
      if (messageIds != null) 'messageIds': messageIds,
    };
    _socket!.emit('mark_read', readData);
  }

  /// Get inbox data - get_inbox event
  void getInbox() {
    if (_socket == null || !_isConnected) {
      log('Cannot get inbox: Socket not connected');
      return;
    }
    _socket!.emit('get_inbox');
    log('Requested inbox data via Socket.IO');
  }

  /// Listen for inbox data - inbox_data event
  void onInboxData(Function(Map<String, dynamic>) callback) {
    if (_socket == null) return;
    _socket!.on('inbox_data', (data) {
      if (data is Map<String, dynamic>) {
        callback(data);
      }
    });
    _socket!.on('get_inbox', (data) {
      if (data is Map<String, dynamic>) {
        callback(data);
      }
    });
  }

  /// Remove inbox_data listener
  void offInboxData() {
    _socket?.off('inbox_data');
    _socket?.off('get_inbox');
  }

  /// Listen for user connection status updates - user_connection_status event
  void onUserConnectionStatus(Function(Map<String, dynamic>) callback) {
    if (_socket == null) return;
    _socket!.on('user_connection_status', (data) {
      if (data is Map<String, dynamic>) {
        callback(data);
      }
    });
  }

  /// Remove user_connection_status listener
  void offUserConnectionStatus() {
    _socket?.off('user_connection_status');
  }

  /// Disconnect from Socket.IO server
  void disconnect() {
    _connectionTimeout?.cancel();
    _connectionTimeout = null;

    if (_socket != null) {
      log('Disconnecting and disposing socket...');
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      isConnected.value = false;
      _currentUserId = null;
    }
  }

  /// Reset connection completely - used for logout/login scenarios
  void resetConnection() {
    log('Resetting socket connection');
    disconnect();
  }

  /// Fallback to polling transport for iOS WebSocket issues
  Future<void> _fallbackToPolling() async {
    try {
      log('Attempting to reconnect with polling transport only...');
      await Future.delayed(Duration(seconds: 2));

      final userId = await _getUserId();
      final token = await _getAccessToken();
      final userType = await _getUserType();

      if (userId == null || token == null) return;

      disconnect();

      final baseUrl = socketUrl;
      final options = IO.OptionBuilder()
          .setTransports(['polling'])
          .enableForceNew()
          .setExtraHeaders({
            'auth': token,
            'userType': userType ?? 'normal',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          })
          .setPath('/socket.io')
          .build();

      _socket = IO.io(baseUrl, options);
      _setupEventListeners();
      _socket!.connect();
    } catch (e) {
      log('Error during polling fallback: $e');
    }
  }

  /// Get user ID from storage
  Future<String?> _getUserId() async {
    if (!Get.isRegistered<StorageService>()) return null;
    final storage = Get.find<StorageService>();
    return storage.readString(SharePreferenceConst.id) ??
        storage.readString('id') ??
        storage.readString('_id');
  }

  /// Get access token from storage
  Future<String?> _getAccessToken() async {
    if (!Get.isRegistered<StorageService>()) return null;
    final storage = Get.find<StorageService>();
    return storage.readString('access_token');
  }

  /// Get user type from storage
  Future<String?> _getUserType() async {
    try {
      if (!Get.isRegistered<StorageService>()) return null;
      final storage = Get.find<StorageService>();
      return storage.readString('userType') ??
          storage.readString('user_type') ??
          storage.readString(SharePreferenceConst.userType) ??
          'normal';
    } catch (e) {
      return 'normal';
    }
  }

  /// Check if socket is connected
  bool get connected {
    if (_socket == null) return false;
    return _isConnected && _socket!.connected;
  }
}
