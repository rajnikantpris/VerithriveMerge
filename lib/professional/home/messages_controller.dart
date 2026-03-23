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
    // fetchChatInbox();

    print("Call ON init message controller ---");
    if (!_isGuestUser()) {
      if (Get.isRegistered<SocketService>()) {
        Get.delete<SocketService>();
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

      // Check if socket is connected
      if (!_socketService!.connected) {
        // Socket not connected, reconnect it
        final currentUserId = await _getCurrentUserId();
        logInfo(
            'Message UserID:----- ${currentUserId.toString()}' );
        await _socketService!.connect(userId: currentUserId);
      }

      // Setup message listeners
      _setupSocketListeners();

      // Request inbox data if connected
      if (_socketService!.connected) {
        _socketService!.getInbox();
      }
    } catch (e) {
      // Error checking socket, but still setup listeners
      _setupSocketListeners();
    }
  }

  /// Get current user ID from storage
  Future<String?> _getCurrentUserId() async {
    if (!Get.isRegistered<StorageService>()) return null;
    final storage = Get.find<StorageService>();
    return storage.readString('user_id');
  }

  /// Setup Socket.IO event listeners for inbox_data
  void _setupSocketListeners() {
    if (_socketService == null) return;

    // Listen for inbox data - inbox_data event
    _socketService!.onInboxData((data) {
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
      // Handle parsing errors - keep existing data or clear
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
          // If API fails, keep empty list or show error
          messages.clear();
        }
      },
      onError: (error, stack) {
        // Error is already handled by callDataService
        // Keep empty list on error
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
      // Handle different response structures
      List<dynamic>? messagesList;

      if (data is List) {
        messagesList = data;
      } else if (data is Map<String, dynamic>) {
        // Check if data is nested under 'data' key
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
        // If no messages found, clear the list
        messages.clear();
      }
    } catch (e) {
      // Handle parsing errors - keep existing data or clear
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

      // Extract name - check nested user object first, then root level
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

      // Extract last message - try multiple possible field names
      final lastMessage = item['last_message']?.toString() ??
          item['lastMessage']?.toString() ??
          item['message']?.toString() ??
          item['text']?.toString() ??
          item['content']?.toString() ??
          '';

      // Extract time label - try multiple possible field names
      String timeLabel = '';
      if (item['last_message_at'] != null) {
        timeLabel = _formatTimestamp(item['last_message_at']);
      } else if (item['lastMessageAt'] != null) {
        timeLabel = _formatTimestamp(item['lastMessageAt']);
      } else if (item['updated_at'] != null) {
        timeLabel = _formatTimestamp(item['updated_at']);
      } else if (item['updatedAt'] != null) {
        timeLabel = _formatTimestamp(item['updatedAt']);
      } else if (item['last_message_time'] != null) {
        timeLabel = _formatTimestamp(item['last_message_time']);
      } else if (item['lastMessageTime'] != null) {
        timeLabel = _formatTimestamp(item['lastMessageTime']);
      } else if (item['timestamp'] != null) {
        timeLabel = _formatTimestamp(item['timestamp']);
      } else if (item['time'] != null) {
        timeLabel = item['time'].toString();
      } else if (item['timeLabel'] != null) {
        timeLabel = item['timeLabel'].toString();
      }

      // Extract unread count
      final unreadCount = item['unread_count'] as int? ??
          item['unreadCount'] as int? ??
          item['unread'] as int? ??
          0;

      // Extract online status - check nested user object first, then root level
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

      // Extract highlight (e.g., if unread)
      final highlight = unreadCount > 0 ||
          (item['highlight'] as bool? ?? false) ||
          (item['is_pinned'] as bool? ?? false);

      // Extract avatar - check nested user object first, then root level
      String avatarAsset = AppImages.user; // Default to user image
      final profilePicturePath = userObj?['profile_picture']?.toString() ??
          userObj?['profilePicture']?.toString() ??
          item['avatar']?.toString() ??
          item['avatar_url']?.toString() ??
          item['avatarUrl']?.toString() ??
          item['profile_picture']?.toString() ??
          item['profilePicture']?.toString();

      if (profilePicturePath != null && profilePicturePath.isNotEmpty) {
        // Construct full URL if it's a relative path
        if (profilePicturePath.startsWith('http://') ||
            profilePicturePath.startsWith('https://')) {
          avatarAsset = profilePicturePath;
        } else {
          // Construct full URL from base URL
          // Extract server base URL (protocol + host + port) from UserApiService
          final serverBaseUrl = UserApiService.socketBaseUrl;
          // Remove leading 'public/' if present, or use as-is
          final imagePath = profilePicturePath.startsWith('public/')
              ? profilePicturePath.substring(7) // Remove 'public/'
              : profilePicturePath;
          avatarAsset = '$serverBaseUrl/$imagePath';
        }
      }

      // Extract show delivered tick
      final showDeliveredTick = item['show_delivered_tick'] as bool? ??
          item['showDeliveredTick'] as bool? ??
          item['delivered'] as bool? ??
          false;

      // Extract user ID - check nested user object first
      final userId = userObj?['_id']?.toString() ??
          userObj?['id']?.toString() ??
          item['user_id']?.toString() ??
          item['userId']?.toString() ??
          item['_id']?.toString() ??
          item['id']?.toString();

      // Extract chat ID - check room_id first (from API response)
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

  /// Format timestamp to time label (converts UTC to local time)
  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime? dateTime;

      if (timestamp is String) {
        // Try parsing ISO format or common date formats
        if (timestamp.contains('T')) {
          final dateTimeUtc = DateTime.parse(timestamp);
          // Convert UTC to local time
          dateTime = dateTimeUtc.isUtc ? dateTimeUtc.toLocal() : dateTimeUtc;
        } else {
          // Try other formats
          try {
            dateTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse(timestamp);
          } catch (e) {
            try {
              dateTime = DateFormat('yyyy-MM-dd').parse(timestamp);
            } catch (e2) {
              return timestamp; // Return as-is if can't parse
            }
          }
        }
      } else if (timestamp is int) {
        // Assume Unix timestamp (seconds or milliseconds)
        if (timestamp > 1000000000000) {
          // Milliseconds
          dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true)
              .toLocal();
        } else {
          // Seconds
          dateTime =
              DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true)
                  .toLocal();
        }
      }

      if (dateTime == null) return timestamp.toString();

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      // Format based on time difference
      if (difference.inDays == 0) {
        // Today - show time
        return DateFormat('HH.mm').format(dateTime);
      } else if (difference.inDays == 1) {
        // Yesterday
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        // This week - show day name
        return DateFormat('EEEE').format(dateTime);
      } else {
        // Older - show date
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
