import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:verithrive_dev/utils/logger.dart';

import '../../api/api_response.dart';
import '../../api/user_api_service.dart';
import '../../common/base_controller.dart';
import '../../services/socket_service.dart';
import '../../services/storage_service.dart';
import '../../theme/image_paths.dart';

/// Controller backing the messages tab. Holds sample data and search state.
class MessagesController extends BaseController {
  MessagesController(this._userApiService);

  final UserApiService _userApiService;

  final searchQuery = ''.obs;
  final messages = <MessageItem>[].obs;
  bool _isRefreshing = false;

  SocketService? _socketService;

  /// Check if the current user is a guest (no access token)
  bool _isGuestUser() {
    if (!Get.isRegistered<StorageService>()) {
      return true; // No storage service means guest
    }
    final storage = Get.find<StorageService>();
    final token = storage.readString('access_token');
    return token == null || token.isEmpty;
  }

  @override
  void onInit() {
    super.onInit();
    
    // 1. Explicitly clear messages on initialization
    messages.clear();
    
    print("MessagesController onInit - messages cleared. Count: ${messages.length}");

    if (!_isGuestUser()) {
      // 2. Force a completely fresh SocketService for the new user
      if (Get.isRegistered<SocketService>()) {
        final socket = Get.find<SocketService>();
        socket.disconnect();
        Get.delete<SocketService>();
        print("Existing SocketService deleted in MessagesController onInit");
      }
      
      checkAndReconnectSocket();
    }
  }

  @override
  void onClose() {
    _cleanupSocketListeners();
    super.onClose();
  }

  /// Check socket connection and reconnect if needed
  Future<void> checkAndReconnectSocket() async {
    try {
      // Get or create SocketService
      if (Get.isRegistered<SocketService>()) {
        _socketService = Get.find<SocketService>();
      } else {
        _socketService = Get.put(SocketService());
      }

      // 3. Always call connect with current credentials to ensure fresh session
      final currentUserId = await _getCurrentUserId();
      final currentToken = await _getCurrentToken();
      
      logInfo('MessagesController: Connecting socket for UserID: $currentUserId');
      
      // We pass both ID and Token to ensure SocketService uses the LATEST credentials
      await _socketService!.connect(userId: currentUserId, token: currentToken);

      // Setup message listeners
      _setupSocketListeners();

      // Request inbox data if connected
      if (_socketService!.connected) {
        _socketService!.getInbox();
      }
    } catch (e) {
      logError('Error in checkAndReconnectSocket', error: e);
      _setupSocketListeners();
    }
  }

  /// Get current user ID from storage
  Future<String?> _getCurrentUserId() async {
    if (!Get.isRegistered<StorageService>()) return null;
    final storage = Get.find<StorageService>();
    return storage.readString('user_id');
  }

  /// Get current token from storage
  Future<String?> _getCurrentToken() async {
    if (!Get.isRegistered<StorageService>()) return null;
    final storage = Get.find<StorageService>();
    return storage.readString('access_token');
  }

  /// Setup Socket.IO event listeners for inbox_data
  void _setupSocketListeners() {
    if (_socketService == null) return;

    // Listen for inbox data - inbox_data event
    _socketService!.onInboxData((data) {
      logInfo('MessagesController: Received inbox_data event');
      _handleInboxData(data);
    });
  }

  /// Cleanup Socket.IO event listeners
  void _cleanupSocketListeners() {
    _socketService?.offInboxData();
  }

  /// Handle inbox data from Socket.IO - inbox_data event
  void _handleInboxData(Map<String, dynamic> data) {
    try {
      // Parse the inbox data and update messages list
      _parseApiResponse(data);
    } catch (e) {
      logError('Error handling inbox data', error: e);
      messages.clear();
    }
  }

  /// Fetch chat inbox from API
  Future<void> fetchChatInbox() async {
    // Prevent concurrent refreshes
    if (_isRefreshing) {
      return;
    }

    _isRefreshing = true;
    await callDataService(
      _userApiService.getChatInbox(),
      useShimmer: true,
      onSuccess: (ApiResponse<dynamic> response) {
        if (response.success && response.data != null) {
          _parseApiResponse(response.data);
        } else {
          messages.clear();
        }
      },
      onError: (error, stack) {
        messages.clear();
      },
      onComplete: () {
        _isRefreshing = false;
      },
    );
  }

  /// Parse API response and update messages list
  void _parseApiResponse(dynamic data) {
    try {
      List<dynamic>? messagesList;

      if (data is List) {
        messagesList = data;
      } else if (data is Map<String, dynamic>) {
        if (data['data'] is List) {
          messagesList = data['data'] as List;
        } else if (data['inbox'] is List) {
          messagesList = data['inbox'] as List;
        } else if (data['messages'] is List) {
          messagesList = data['messages'] as List;
        } else if (data['chats'] is List) {
          messagesList = data['chats'] as List;
        }
      }

      if (messagesList != null) {
        final parsedMessages = messagesList
            .map((item) {
              if (item is Map<String, dynamic>) {
                return _parseMessageItem(item);
              }
              return null;
            })
            .whereType<MessageItem>()
            .toList();

        messages.value = parsedMessages;
      } else {
        messages.clear();
      }
    } catch (e) {
      messages.clear();
    }
  }

  /// Parse a single message item from API response
  MessageItem? _parseMessageItem(Map<String, dynamic> item) {
    try {
      // Handle nested user object structure
      Map<String, dynamic>? userObj;
      if (item['user'] is Map<String, dynamic>) {
        userObj = item['user'] as Map<String, dynamic>;
      }

      final name = userObj?['full_name']?.toString() ??
          userObj?['fullName']?.toString() ??
          userObj?['name']?.toString() ??
          item['name']?.toString() ??
          item['user_name']?.toString() ??
          item['username']?.toString() ??
          item['sender_name']?.toString() ??
          item['receiver_name']?.toString() ??
          item['contact_name']?.toString() ??
          'Unknown';

      final lastMessage = item['last_message']?.toString() ??
          item['lastMessage']?.toString() ??
          item['message']?.toString() ??
          item['text']?.toString() ??
          item['content']?.toString() ??
          '';

      String timeLabel = '';
      if (item['last_message_at'] != null) {
        timeLabel = _formatTimestamp(item['last_message_at']);
      } else if (item['lastMessageAt'] != null) {
        timeLabel = _formatTimestamp(item['lastMessageAt']);
      } else if (item['updated_at'] != null) {
        timeLabel = _formatTimestamp(item['updated_at']);
      } else if (item['updatedAt'] != null) {
        timeLabel = _formatTimestamp(item['updatedAt']);
      }

      final unreadCount = item['unread_count'] as int? ??
          item['unreadCount'] as int? ??
          item['unread'] as int? ??
          0;

      bool? isOnlineFromUser;
      if (userObj != null) {
        isOnlineFromUser = userObj['is_online'] as bool? ??
            userObj['isOnline'] as bool? ??
            userObj['online'] as bool? ??
            (userObj['online_status']?.toString().toLowerCase() == 'online');
      }
      final isOnline = isOnlineFromUser ??
          item['is_online'] as bool? ??
          item['isOnline'] as bool? ??
          item['online'] as bool? ??
          false;

      final highlight = unreadCount > 0 ||
          (item['highlight'] as bool? ?? false) ||
          (item['is_pinned'] as bool? ?? false);

      String avatarAsset = AppImages.user;
      final profilePicturePath = userObj?['profile_picture']?.toString() ??
          userObj?['profilePicture']?.toString() ??
          item['avatar']?.toString() ??
          item['avatar_url']?.toString() ??
          item['avatarUrl']?.toString() ??
          item['profile_picture']?.toString() ??
          item['profilePicture']?.toString();

      if (profilePicturePath != null && profilePicturePath.isNotEmpty) {
        if (profilePicturePath.startsWith('http://') ||
            profilePicturePath.startsWith('https://')) {
          avatarAsset = profilePicturePath;
        } else {
          final serverBaseUrl = UserApiService.socketBaseUrl;
          final imagePath = profilePicturePath.startsWith('public/')
              ? profilePicturePath.substring(7)
              : profilePicturePath;
          avatarAsset = '$serverBaseUrl/$imagePath';
        }
      }

      final showDeliveredTick = item['show_delivered_tick'] as bool? ??
          item['showDeliveredTick'] as bool? ??
          item['delivered'] as bool? ??
          false;

      final userId = userObj?['_id']?.toString() ??
          userObj?['id']?.toString() ??
          item['user_id']?.toString() ??
          item['userId']?.toString() ??
          item['_id']?.toString() ??
          item['id']?.toString();

      final chatId = item['room_id']?.toString() ??
          item['roomId']?.toString() ??
          item['chat_id']?.toString() ??
          item['chatId']?.toString() ??
          item['conversation_id']?.toString() ??
          item['conversationId']?.toString();

      return MessageItem(
        name: name,
        lastMessage: lastMessage,
        timeLabel: timeLabel,
        unreadCount: unreadCount,
        isOnline: isOnline,
        highlight: highlight,
        avatarAsset: avatarAsset,
        showDeliveredTick: showDeliveredTick,
        userId: userId,
        chatId: chatId,
      );
    } catch (e) {
      return null;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime? dateTime;

      if (timestamp is String) {
        if (timestamp.contains('T')) {
          final dateTimeUtc = DateTime.parse(timestamp);
          dateTime = dateTimeUtc.isUtc ? dateTimeUtc.toLocal() : dateTimeUtc;
        } else {
          try {
            dateTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse(timestamp);
          } catch (e) {
            try {
              dateTime = DateFormat('yyyy-MM-dd').parse(timestamp);
            } catch (e2) {
              return timestamp;
            }
          }
        }
      } else if (timestamp is int) {
        if (timestamp > 1000000000000) {
          dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true)
              .toLocal();
        } else {
          dateTime =
              DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true)
                  .toLocal();
        }
      }

      if (dateTime == null) return timestamp.toString();

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return DateFormat('HH.mm').format(dateTime);
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return DateFormat('EEEE').format(dateTime);
      } else {
        return DateFormat('dd/MM/yyyy').format(dateTime);
      }
    } catch (e) {
      return timestamp.toString();
    }
  }

  void updateSearch(String value) {
    searchQuery(value);
  }

  List<MessageItem> get filteredMessages {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return messages;
    return messages
        .where((item) =>
            item.name.toLowerCase().contains(query) ||
            item.lastMessage.toLowerCase().contains(query))
        .toList();
  }
}

class MessageItem {
  MessageItem({
    required this.name,
    required this.lastMessage,
    required this.timeLabel,
    required this.unreadCount,
    required this.isOnline,
    required this.avatarAsset,
    this.highlight = false,
    this.showDeliveredTick = false,
    this.userId,
    this.chatId,
  });

  final String name;
  final String lastMessage;
  final String timeLabel;
  final int unreadCount;
  final bool isOnline;
  final bool highlight;
  final bool showDeliveredTick;
  final String avatarAsset;
  final String? userId;
  final String? chatId;
}
