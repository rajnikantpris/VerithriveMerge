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
    if (_isConnected && _socket != null) {
      logInfo('Socket already connected');
      return;
    }

    // If socket exists but not connected, dispose it first
    if (_socket != null && !_isConnected) {
      _socket!.dispose();
      _socket = null;
    }

    try {
      // Get user ID from storage if not provided
      if (userId == null) {
        userId = await _getUserId();
      }

      if (userId == null || userId.isEmpty) {
        logInfo('Cannot connect: User ID not available');
        return;
      }

      _currentUserId = userId;

      // Get token from storage if not provided
      if (token == null) {
        token = await _getAccessToken();
      }

      // Validate token is available
      if (token == null || token.isEmpty) {
        logInfo('Cannot connect: Access token not available');
        return;
      }

      // Get user type for professional identification
      final userType = await _getUserType();
      logInfo('User type: $userType');

      final baseUrl = UserApiService.socketBaseUrl;
      logInfo('Connecting to Socket.IO: $baseUrl');
      logInfo('User ID: $userId');
      logInfo('User Type: $userType');
      logInfo('Token available: true');
      logInfo('Token length: ${token.length}');
      logInfo(
          'Token (first 20 chars): ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      logInfo(
          'Token (last 10 chars): ...${token.substring(token.length > 10 ? token.length - 10 : 0)}');
      logInfo('Full token: $token');

      // Socket.IO options
      // Note: Socket.IO client automatically adds /socket.io path by default
      // User type and token are sent in headers for server identification
      final options = IO.OptionBuilder()
          .setTransports(['websocket', 'polling']) // Try both transports
          .disableAutoConnect() // Disable auto-connect to control connection manually
          .setExtraHeaders({
            'auth': token, // Token is guaranteed to be non-null here
            'userType': userType ?? 'professional', // Add user type to headers
          }) // Add userId and token as query parameters
          .setPath('/socket.io') // Explicitly set Socket.IO path
          .build();

      logInfo(
          'Socket.IO options configured: path=/socket.io, transports=[websocket, polling]');
      logInfo('Query params: userId=$userId, token=***');

      logInfo('Creating socket with options...');
      _socket = IO.io(baseUrl, options);
      logInfo('Socket instance created');

      // Check socket state immediately after creation
      logInfo(
          'Socket state after creation: connected=${_socket?.connected}, id=${_socket?.id}');

      // Log socket URL being used
      logInfo('Socket URL: $baseUrl');

      _setupEventListeners();
      logInfo('Calling socket.connect()...');
      _socket!.connect();
      logInfo('socket.connect() called, waiting for connection...');
    } catch (e) {
      logInfo('Error connecting to Socket.IO: $e');
      _isConnected = false;
      isConnected.value = false;
    }
  }

  /// Setup Socket.IO event listeners
  void _setupEventListeners() {
    if (_socket == null) {
      logInfo('Cannot setup listeners: Socket is null');
      return;
    }

    logInfo('Setting up socket event listeners...');

    _socket!.onConnect((_) {
      _isConnected = true;
      isConnected.value = true;
      logInfo('✅ Socket.IO connected successfully!');
      logInfo('Socket ID: ${_socket?.id}');
      // Automatically request online users list when socket connects
      // getOnlineUsers();
    });

    _socket!.onDisconnect((reason) {
      _isConnected = false;
      isConnected.value = false;
      logInfo('❌ Socket.IO disconnected. Reason: $reason');
    });

    _socket!.onConnectError((error) {
      _isConnected = false;
      isConnected.value = false;
      logInfo('❌ Socket.IO connection error: $error');
      logInfo('Error type: ${error.runtimeType}');
      logInfo('Error details: ${error.toString()}');
    });

    _socket!.onError((error) {
      logInfo('❌ Socket.IO error: $error');
      logInfo('Error details: ${error.toString()}');
    });

    _socket!.on('connect_error', (error) {
      logInfo('❌ Socket connect_error event: $error');
      logInfo('Error details: ${error.toString()}');
      _isConnected = false;
      isConnected.value = false;
    });

    // Handle authentication errors
    _socket!.on('error', (error) {
      logInfo('❌ Socket error event: $error');
      if (error is Map && error['message'] == 'NO_TOKEN') {
        logInfo('⚠️ Authentication error: Token not accepted by server');
        _isConnected = false;
        isConnected.value = false;
      }
    });

    // Listen for user connection status updates (online / offline)
    _socket!.on('user_connection_status', (data) {
      logInfo('👤 User connection status changed: $data');

      // Optionally, you could inspect `data['online_status']`
      // to do something only on online / offline specifically.
      //
      // For now, whenever a user goes online/offline we refresh
      // the inbox so that online indicators and last activity
      // are up to date.
      if (_isConnected) {
        getInbox();
      }
    });

    // Listen for any socket events for debugging
    _socket!.onAny((event, data) {
      logInfo('📡 Socket event received: $event, data: $data');
    });

    logInfo('Socket event listeners setup complete');
  }

  /// Request online users list - get_online_users event
  ///
  /// The server will determine the current user from the authenticated
  /// socket connection, so we don't need to pass a user_id here.
  // void getOnlineUsers() {
  //   if (_socket == null || !_isConnected) {
  //     logInfo('Cannot request online users: Socket not connected');
  //     return;
  //   }

  //   _socket!.emit('user_connection_status');
  //   logInfo('Requested online users via Socket.IO (get_online_users event)');
  // }

  /// Request inbox data - get_inbox event
  ///
  /// The server will determine the current user from the authenticated
  /// socket connection, so we don't need to pass a user_id here.
  void getInbox() {
    if (_socket == null || !_isConnected) {
      logInfo('Cannot request inbox: Socket not connected');
      return;
    }

    _socket!.emit('get_inbox');
    logInfo('Requested inbox via Socket.IO (get_inbox event)');
  }

  /// Send a message via Socket.IO - send_message event
  void sendMessage({
    required String message,
    required String receiverId,
    String? chatId,
  }) {
    if (_socket == null || !_isConnected) {
      logInfo('Cannot send message: Socket not connected');
      return;
    }

    if (chatId == null || chatId.isEmpty) {
      logInfo('Cannot send message: Chat ID (room_id) not provided');
      return;
    }

    final messageData = {
      'room_id': chatId,
      'receiver_id': receiverId,
      'message': message,
    };

    _socket!.emit('send_message', messageData);
    logInfo('Sent message via Socket.IO: $messageData');
  }

  /// Listen for incoming messages - receive_message event
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

  /// Remove receive_message listener
  void offReceiveMessage() {
    _socket?.off('receive_message');
  }

  /// Listen for inbox data - inbox_data event
  void onInboxData(Function(Map<String, dynamic>) callback) {
    if (_socket == null) {
      logInfo('Cannot listen for inbox data: Socket not initialized');
      return;
    }

    _socket!.on('inbox_data', (data) {
      logInfo('Received inbox data via Socket.IO: $data');
      if (data is Map<String, dynamic>) {
        callback(data);
      }
    });
  }

  /// Remove inbox_data listener
  void offInboxData() {
    _socket?.off('inbox_data');
  }

  /// Mark messages as read - mark_read event
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

  /// Disconnect from Socket.IO server
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      isConnected.value = false;
      _currentUserId = null;
      logInfo('Socket.IO disconnected and disposed');
    }
  }

  /// Reset connection completely - used for logout/login scenarios
  void resetConnection() {
    logInfo('Resetting socket connection');
    disconnect();

    // Force a complete reset by creating a new instance
    _isConnected = false;
    isConnected.value = false;
    _currentUserId = null;
    _socket = null;

    logInfo('Socket connection reset complete');
  }

  /// Get user ID from storage
  Future<String?> _getUserId() async {
    if (!Get.isRegistered<StorageService>()) return null;
    final storage = Get.find<StorageService>();
    return storage.readString('user_id') ??
        storage.readString('userId') ??
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

      // Try multiple possible keys for user type
      final userType = storage.readString('userType') ??
          storage.readString('user_type') ??
          'professional'; // Default to 'professional' for professional users

      logInfo('Retrieved user type: $userType');
      return userType;
    } catch (e) {
      logInfo('Error getting user type from storage: $e');
      return 'professional'; // Default to 'professional' for professional users
    }
  }

  /// Check if socket is connected
  bool get connected {
    if (_socket == null) return false;
    // Check both our internal flag and socket's native connected property
    return _isConnected && _socket!.connected;
  }

  /// Wait for socket connection with timeout
  Future<bool> waitForConnection(
      {Duration timeout = const Duration(seconds: 10)}) async {
    if (connected) {
      logInfo('Socket already connected');
      return true;
    }

    final completer = Completer<bool>();
    Timer? timer;
    StreamSubscription? subscription;
    Timer? periodicTimer;

    timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        logInfo('Socket connection timeout after ${timeout.inSeconds} seconds');
        subscription?.cancel();
        periodicTimer?.cancel();
        completer.complete(false);
      }
    });

    subscription = isConnected.listen((connected) {
      if (connected && !completer.isCompleted) {
        logInfo('Socket connected successfully');
        timer?.cancel();
        subscription?.cancel();
        periodicTimer?.cancel();
        completer.complete(true);
      }
    });

    // Also check connection status periodically as fallback
    periodicTimer =
        Timer.periodic(const Duration(milliseconds: 200), (checkTimer) {
      if (completer.isCompleted) {
        checkTimer.cancel();
        return;
      }
      // Check socket's native connected property
      if (_socket != null && _socket!.connected) {
        // Update our internal state if socket is connected
        if (!_isConnected) {
          _isConnected = true;
          isConnected.value = true;
        }
        logInfo('Socket connected (checked via periodic check)');
        timer?.cancel();
        subscription?.cancel();
        checkTimer.cancel();
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
    });

    final result = await completer.future;
    return result;
  }
}
