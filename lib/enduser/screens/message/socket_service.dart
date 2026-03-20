import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../utils/api_services.dart';
import '../../core/values/sharePrefrenceConst.dart';
import 'package:verithrive_dev/services/storage_service.dart';

/// Socket.IO service for managing real-time chat communication
class SocketService extends GetxService {
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
    if (_isConnected && _socket != null) {
      log('Socket already connected');
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
        log('Cannot connect: User ID not available');
        return;
      }

      _currentUserId = userId;

      // Get token from storage if not provided
      if (token == null) {
        token = await _getAccessToken();
      }

      // Validate token is available
      if (token == null || token.isEmpty) {
        log('Cannot connect: Access token not available');
        return;
      }

      final baseUrl = socketBaseUrl;
      log('Connecting to Socket.IO: $baseUrl');
      log('User ID: $userId');
      log('Token available: true');
      log('Token length: ${token.length}');
      log(
          'Token (first 20 chars): ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      log(
          'Token (last 10 chars): ...${token.substring(token.length > 10 ? token.length - 10 : 0)}');
      log('Full token: $token');

      // Socket.IO options
      // Note: Socket.IO client automatically adds /socket.io path by default
      // Build query parameters with userId and token (server expects token in query)
      // final queryParams = <String, dynamic>{
      //   'userId': userId,
      //   'token': token, // Token is guaranteed to be non-null here
      // };

      final options = IO.OptionBuilder()
          .setTransports(['websocket', 'polling']) // Try both transports
          .disableAutoConnect() // Disable auto-connect to control connection manually
          .setExtraHeaders({
            'auth': token, // Token is guaranteed to be non-null here
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            // iOS-specific headers
            if (Platform.isIOS) ...{
              'User-Agent': 'iOS-Verithrive-App',
              'Connection': 'keep-alive',
            },
          }) // Add userId and token as query parameters
          .setPath('/socket.io') // Explicitly set Socket.IO path
          // iOS-specific configurations
          .enableReconnection() // Enable automatic reconnection
          .setReconnectionAttempts(5) // Limit reconnection attempts
          .setReconnectionDelay(1000) // 1 second delay between reconnections
          .setTimeout(30000) // 30 seconds timeout
          .build();

      log(
          'Socket.IO options configured: path=/socket.io, transports=[websocket, polling]');
      log('Query params: userId=$userId, token=***');

      log('Creating socket with options...');
      _socket = IO.io(baseUrl, options);
      log('Socket instance created');

      // Check socket state immediately after creation
      log(
          'Socket state after creation: connected=${_socket?.connected}, id=${_socket?.id}');

      // Log socket URL being used
      log('Socket URL: $baseUrl');

      _setupEventListeners();
      log('Calling socket.connect()...');
      _socket!.connect();
      log('socket.connect() called, waiting for connection...');
      
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
      
      // iOS-specific error handling
      if (Platform.isIOS) {
        log('iOS socket connection error: $e');
        if (e.toString().contains('Network') || e.toString().contains('Connection')) {
          log('iOS network connection issue - check network settings');
        } else if (e.toString().contains('WebSocket') || e.toString().contains('websocket')) {
          log('iOS WebSocket issue - attempting polling fallback');
          _fallbackToPolling();
        }
      }
    }
  }

  /// Setup Socket.IO event listeners
  void _setupEventListeners() {
    if (_socket == null) {
      log('Cannot setup listeners: Socket is null');
      return;
    }

    log('Setting up socket event listeners...');

    _socket!.onConnect((_) {
      _isConnected = true;
      isConnected.value = true;
      log('✅ Socket.IO connected successfully!');
      log('Socket ID: ${_socket?.id}');
      
      // Clear connection timeout if connected
      _connectionTimeout?.cancel();
      _connectionTimeout = null;
    });

    _socket!.onDisconnect((reason) {
      _isConnected = false;
      isConnected.value = false;
      log('❌ Socket.IO disconnected. Reason: $reason');
    });

    _socket!.onConnectError((error) {
      _isConnected = false;
      isConnected.value = false;
      log('❌ Socket.IO connection error: $error');
      log('Error type: ${error.runtimeType}');
      log('Error details: ${error.toString()}');
      
      // iOS-specific error handling
      if (Platform.isIOS) {
        log('iOS-specific socket error detected');
        if (error.toString().contains('websocket')) {
          log('WebSocket error on iOS, falling back to polling');
          // Try to reconnect with polling only
          _fallbackToPolling();
        }
      }
    });

    _socket!.onError((error) {
      log('❌ Socket.IO error: $error');
      log('Error details: ${error.toString()}');
      
      // iOS-specific error handling
      if (Platform.isIOS) {
        log('iOS socket error: $error');
        if (error.toString().contains('network') || error.toString().contains('connection')) {
          log('Network connection error on iOS, check network availability');
        }
      }
    });

    _socket!.on('connect_error', (error) {
      log('❌ Socket connect_error event: $error');
      log('Error details: ${error.toString()}');
      _isConnected = false;
      isConnected.value = false;
      
      // iOS-specific error handling
      if (Platform.isIOS) {
        log('iOS connect_error: $error');
      }
    });

    // Handle authentication errors
    _socket!.on('error', (error) {
      log('❌ Socket error event: $error');
      if (error is Map && error['message'] == 'NO_TOKEN') {
        log('⚠️ Authentication error: Token not accepted by server');
        _isConnected = false;
        isConnected.value = false;
      }
    });

    // Listen for any socket events for debugging
    _socket!.onAny((event, data) {
      log('📡 Socket event received: $event, data: $data');
    });

    log('Socket event listeners setup complete');
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
    if (_socket == null) {
      log('Cannot listen for messages: Socket not initialized');
      return;
    }

    _socket!.on('receive_message', (data) {
      log('Received message via Socket.IO: $data');
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
    if (_socket == null || !_isConnected) {
      log('Cannot mark read: Socket not connected');
      return;
    }

    final readData = {
      'room_id': roomId,
      if (messageIds != null) 'messageIds': messageIds,
    };

    _socket!.emit('mark_read', readData);
    log('Marked messages as read: $readData');
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
    if (_socket == null) {
      log('Cannot listen for inbox data: Socket not initialized');
      return;
    }

    _socket!.on('inbox_data', (data) {
      log('Received inbox data via Socket.IO: $data');
      if (data is Map<String, dynamic>) {
        callback(data);
      }
    });
  }

  /// Remove inbox_data listener
  void offInboxData() {
    _socket?.off('inbox_data');
  }

  /// Listen for user connection status updates - user_connection_status event
  void onUserConnectionStatus(Function(Map<String, dynamic>) callback) {
    if (_socket == null) {
      log('Cannot listen for user connection status: Socket not initialized');
      return;
    }

    _socket!.on('user_connection_status', (data) {
      log('Received user connection status via Socket.IO: $data');
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
    // Clear connection timeout
    _connectionTimeout?.cancel();
    _connectionTimeout = null;
    
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      isConnected.value = false;
      _currentUserId = null;
      log('Socket.IO disconnected and disposed');
    }
  }

  /// Reset connection completely - used for logout/login scenarios
  void resetConnection() {
    log('Resetting socket connection');
    
    // Clear connection timeout
    _connectionTimeout?.cancel();
    _connectionTimeout = null;
    
    disconnect();
    
    // Force a complete reset by creating a new instance
    _isConnected = false;
    isConnected.value = false;
    _currentUserId = null;
    _socket = null;
    
    log('Socket connection reset complete');
  }

  /// Fallback to polling transport for iOS WebSocket issues
  Future<void> _fallbackToPolling() async {
    try {
      log('Attempting to reconnect with polling transport only...');
      
      // Wait a bit before reconnecting
      await Future.delayed(Duration(seconds: 2));
      
      // Get user credentials again
      final userId = await _getUserId();
      final token = await _getAccessToken();
      
      if (userId == null || token == null) {
        log('Cannot fallback: User credentials not available');
        return;
      }
      
      // Create new options with polling only
      final pollingOptions = IO.OptionBuilder()
          .setTransports(['polling']) // Use polling only
          .disableAutoConnect()
          .setExtraHeaders({
            'auth': token,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (Platform.isIOS) ...{
              'User-Agent': 'iOS-Verithrive-App-Polling',
              'Connection': 'keep-alive',
            },
          })
          .setPath('/socket.io')
          .enableReconnection()
          .setReconnectionAttempts(3)
          .setReconnectionDelay(2000)
          .setTimeout(30000)
          .build();
      
      // Dispose old socket
      _socket?.dispose();
      
      // Create new socket with polling options
      _socket = IO.io(socketBaseUrl, pollingOptions);
      
      // Setup listeners and connect
      _setupEventListeners();
      _socket!.connect();
      
      log('Polling fallback connection initiated');
    } catch (e) {
      log('Error in polling fallback: $e');
    }
  }

  /// Get user ID from storage (matching login screen implementation)
  Future<String?> _getUserId() async {
    try {
      if (!Get.isRegistered<StorageService>()) return null;
      final storage = Get.find<StorageService>();

      final userId = storage.readString(SharePreferenceConst.id);
      if (userId != null && userId.isNotEmpty) {
        return userId;
      }
      
      log('User ID not found in storage');
      return null;
    } catch (e) {
      log('Error getting user ID from storage: $e');
      return null;
    }
  }

  /// Get access token from storage
  Future<String?> _getAccessToken() async {
    try {
      if (!Get.isRegistered<StorageService>()) return null;
      final storage = Get.find<StorageService>();

      final token =
          storage.readString(SharePreferenceConst.access_token) ??
              storage.readString(StorageService.keyToken);
      if (token != null && token.isNotEmpty) {
        return token;
      }

      log('Access token not found in storage');
      return null;
    } catch (e) {
      log('Error getting access token from storage: $e');
      return null;
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
      log('Socket already connected');
      return true;
    }

    final completer = Completer<bool>();
    Timer? timer;
    StreamSubscription? subscription;
    Timer? periodicTimer;

    timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        log('Socket connection timeout after ${timeout.inSeconds} seconds');
        subscription?.cancel();
        periodicTimer?.cancel();
        completer.complete(false);
      }
    });

    subscription = isConnected.listen((connected) {
      if (connected && !completer.isCompleted) {
        log('Socket connected successfully');
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
        log('Socket connected (checked via periodic check)');
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
