import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/Conversation.dart';
import '../../models/ChatMessage.dart';
import '../../core/base/base_controller.dart';
import '../../data/repository/project_repository.dart';
import '../../utils/api_services.dart';
import '../../network/exceptions/base_exception.dart';
import '../../utils/common_dialog.dart';
import '../../utils/auth_service.dart';
import '../../core/values/sharePrefrenceConst.dart';
import 'package:verithrive_dev/services/storage_service.dart';
import 'socket_service.dart';

class MessagesController extends BaseController {
  final ProjectRepository _repository = Get.find(tag: (ProjectRepository).toString());
  
  // Observable list of conversations
  var conversations = <Conversation>[].obs;
  var selectedConversation = Rxn<Conversation>();
  var chatMessages = <ChatMessage>[].obs;
  var messageTextController = ''.obs;
  var searchQuery = ''.obs;
  var isLoading = false.obs;
  var isInitialLoading = false.obs; // Track initial loading separately
  bool _isRefreshing = false;

  SocketService? _socketService;

  @override
  void onInit() {
    super.onInit();
    // Initialize socket connection for real-time updates
    checkAndReconnectSocket();
  }

  @override
  void onClose() {
    _cleanupSocketListeners();
    // Disconnect and dispose local socket service
    _socketService?.disconnect();
    _socketService = null;
    super.onClose();
  }

  @override
  void fetchData() async {
    print("Socket-based: Messages Loaded");
    _checkAuthAndFetchMessages();
  }

  // Refresh data method called by MainScreen - now socket-based
  void refreshData() {
    isLoading.value = false;
    _checkAuthAndFetchMessages();
  }

  // Check authentication and fetch messages via socket
  Future<void> _checkAuthAndFetchMessages() async {
    bool canAccess = await AuthService.requireAuth();
    if (canAccess) {
      checkAndReconnectSocket();
    }
  }

  /// Silent refresh for notification updates - now socket-based
  Future<void> silentRefreshInbox() async {
    print("Silent refresh triggered for messages via socket");
    
    // Prevent concurrent refreshes
    if (_isRefreshing) {
      print("Already refreshing, skipping silent refresh");
      return;
    }

    _isRefreshing = true;
    
    try {
      // Request inbox data via socket if connected
      if (_socketService != null && _socketService!.connected) {
        _socketService!.getInbox();
      } else {
        // Try to reconnect and then get inbox
        await checkAndReconnectSocket();
        // Try again after reconnection
        if (_socketService != null && _socketService!.connected) {
          _socketService!.getInbox();
        }
      }
    } catch (e) {
      print('Error in silent refresh: $e');
    } finally {
      _isRefreshing = false;
    }
  }

  /// Check if the current user is a guest (no access token)
  bool _isGuestUser() {
    if (!Get.isRegistered<StorageService>()) {
      return true; // No storage service means guest
    }
    final storage = Get.find<StorageService>();
    final token = storage.readString('access_token');
    return token == null || token.isEmpty;
  }

  /// Parse API response and update conversations list
  void _parseApiResponse(Map<String, dynamic> data) {
    try {
      // Handle different response structures
      List<dynamic>? conversationsList;

      if (data['data'] is List) {
        conversationsList = data['data'] as List;
      } else if (data['inbox'] is List) {
        conversationsList = data['inbox'] as List;
      } else if (data['messages'] is List) {
        conversationsList = data['messages'] as List;
      } else if (data['chats'] is List) {
        conversationsList = data['chats'] as List;
      }

      if (conversationsList != null) {
        final parsedConversations = conversationsList
            .map((item) {
              if (item is Map<String, dynamic>) {
                return _parseConversationItem(item);
              }
              return null;
            })
            .whereType<Conversation>()
            .toList();

        conversations.value = parsedConversations;
      } else {
        conversations.value = [];
      }
    } catch (e) {
      print('Error parsing conversations: $e');
      conversations.value = [];
    }
  }

  /// Parse a single conversation item from API response
  Conversation? _parseConversationItem(Map<String, dynamic> item) {
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

      // Extract last message time
      DateTime lastMessageTime = DateTime.now();
      if (item['last_message_at'] != null) {
        lastMessageTime = _parseTimestamp(item['last_message_at']);
      } else if (item['lastMessageAt'] != null) {
        lastMessageTime = _parseTimestamp(item['lastMessageAt']);
      } else if (item['updated_at'] != null) {
        lastMessageTime = _parseTimestamp(item['updated_at']);
      } else if (item['updatedAt'] != null) {
        lastMessageTime = _parseTimestamp(item['updatedAt']);
      } else if (item['last_message_time'] != null) {
        lastMessageTime = _parseTimestamp(item['last_message_time']);
      } else if (item['lastMessageTime'] != null) {
        lastMessageTime = _parseTimestamp(item['lastMessageTime']);
      } else if (item['timestamp'] != null) {
        lastMessageTime = _parseTimestamp(item['timestamp']);
      }

      // Extract unread count
      final unreadCount = item['unread_count'] as int? ??
          item['unreadCount'] as int? ??
          item['unread'] as int? ??
          0;

      // Extract online status
      final isOnline = item['is_online'] as bool? ??
          item['isOnline'] as bool? ??
          item['online'] as bool? ??
          false;

      // Extract highlight (e.g., if unread)
      final highlight = unreadCount > 0 ||
          (item['highlight'] as bool? ?? false) ||
          (item['is_pinned'] as bool? ?? false);

      // Extract avatar - check nested user object first, then root level
      String? profileImageUrl;
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
          profileImageUrl = profilePicturePath;
        } else {
          // Construct full URL from base URL
          final baseUrl = 'http://27.54.168.101:4142'; // From api_services.dart
          final imagePath = profilePicturePath.startsWith('public/')
              ? profilePicturePath.substring(7) // Remove 'public/'
              : profilePicturePath;
          profileImageUrl = '$baseUrl/$imagePath';
        }
      }

      // Extract chat ID - check room_id first (from API response)
      final chatId = item['room_id']?.toString() ??
          item['roomId']?.toString() ??
          item['chat_id']?.toString() ??
          item['chatId']?.toString() ??
          item['conversation_id']?.toString() ??
          item['conversationId']?.toString() ??
          item['_id']?.toString() ??
          item['id']?.toString() ??
          '';

      // Extract user ID - check nested user object first, then root level
      final userId = userObj?['_id']?.toString() ??
          userObj?['id']?.toString() ??
          item['user_id']?.toString() ??
          item['userId']?.toString() ??
          item['receiver_id']?.toString() ??
          item['receiverId']?.toString() ??
          item['sender_id']?.toString() ??
          item['senderId']?.toString();

      return Conversation(
        id: chatId,
        name: name,
        profileImageUrl: profileImageUrl,
        lastMessage: lastMessage,
        lastMessageTime: lastMessageTime,
        unreadCount: unreadCount,
        isOnline: isOnline,
        isHighlighted: highlight,
        userId: userId,
      );
    } catch (e) {
      print('Error parsing conversation item: $e');
      return null;
    }
  }

  /// Parse timestamp to DateTime (converts UTC to local time)
  DateTime _parseTimestamp(dynamic timestamp) {
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
              return DateTime.now(); // Return current time if can't parse
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

      return dateTime ?? DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  void loadChatMessages(String conversationId) {
    // Mock chat messages - replace with actual API call
    final conversation = conversations.firstWhereOrNull((c) => c.id == conversationId);
    if (conversation != null) {
      selectedConversation.value = conversation;
      chatMessages.value = [
        ChatMessage(
          id: '1',
          conversationId: conversationId,
          message: 'Can you pleas fill up the form?',
          timestamp: DateTime.now().subtract(Duration(hours: 2)),
          isSentByMe: false,
          senderName: conversation.name,
          senderImageUrl: conversation.profileImageUrl,
        ),
        ChatMessage(
          id: '2',
          conversationId: conversationId,
          message: 'Yeah sure I\'ll do it',
          timestamp: DateTime.now().subtract(Duration(hours: 1)),
          isSentByMe: true,
        ),
      ];
    }
  }

  void sendMessage(String message) {
    if (message.trim().isEmpty || selectedConversation.value == null) return;

    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: selectedConversation.value!.id,
      message: message.trim(),
      timestamp: DateTime.now(),
      isSentByMe: true,
    );

    chatMessages.add(newMessage);
    messageTextController.value = '';

    // Update conversation last message
    final conversation = conversations.firstWhereOrNull(
      (c) => c.id == selectedConversation.value!.id,
    );
    if (conversation != null) {
      final index = conversations.indexOf(conversation);
      conversations[index] = Conversation(
        id: conversation.id,
        name: conversation.name,
        profileImageUrl: conversation.profileImageUrl,
        lastMessage: message.trim(),
        lastMessageTime: DateTime.now(),
        unreadCount: conversation.unreadCount,
        isOnline: conversation.isOnline,
        isHighlighted: conversation.isHighlighted,
      );
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  List<Conversation> get filteredConversations {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) {
      return conversations;
    }
    return conversations.where((conversation) {
      return conversation.name.toLowerCase().contains(query) ||
          conversation.lastMessage.toLowerCase().contains(query);
    }).toList();
  }

  String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // Today - show time in format like "18.31"
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour.$minute';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  /// Check socket connection and reconnect if needed
  Future<void> checkAndReconnectSocket() async {
    try {
      // Check if user is guest, don't connect socket
      if (_isGuestUser()) {
        print('Guest user detected, skipping socket connection');
        return;
      }

      // Get or create local SocketService
      if (_socketService == null) {
        _socketService = SocketService();
      }

      // Check if socket is connected
      if (!_socketService!.connected) {
        // Socket not connected, reconnect it
        final currentUserId = await _getCurrentUserId();
        final token = await _getAccessToken();
        await _socketService!.connect(userId: currentUserId, token: token);
      }

      // Setup message listeners
      _setupSocketListeners();

      // Request inbox data if connected
      if (_socketService!.connected) {
        _socketService!.getInbox();
      }
    } catch (e) {
      print('Error checking socket: $e');
      // Error checking socket, but still setup listeners
      _setupSocketListeners();
    }
  }

  /// Get current user ID from storage
  Future<String?> _getCurrentUserId() async {
    if (!Get.isRegistered<StorageService>()) return null;
    final storage = Get.find<StorageService>();
    return storage.readString('user_id') ??
        storage.readString('userId') ??
        storage.readString('_id');
  }

  /// Get access token from storage
  Future<String?> _getAccessToken() async {
    try {
      if (!Get.isRegistered<StorageService>()) return null;
      final storage = Get.find<StorageService>();
      final token = storage.readString('access_token') ??
          storage.readString('accessToken') ??
          storage.readString('token');
      return token;
    } catch (e) {
      print('Error getting access token from storage: $e');
      return null;
    }
  }

  /// Setup Socket.IO event listeners for inbox_data and user_connection_status
  void _setupSocketListeners() {
    if (_socketService == null) return;

    // Listen for inbox data - inbox_data event
    _socketService!.onInboxData((data) {
      _handleInboxData(data);
    });

    // Listen for user connection status updates - user_connection_status event
    _socketService!.onUserConnectionStatus((data) {
      _handleUserConnectionStatus(data);
    });
  }

  /// Cleanup Socket.IO event listeners
  void _cleanupSocketListeners() {
    _socketService?.offInboxData();
    _socketService?.offUserConnectionStatus();
  }

  /// Handle inbox data from Socket.IO - inbox_data event
  void _handleInboxData(Map<String, dynamic> data) {
    try {
      print('Received inbox data from socket: $data');
      // Parse the inbox data and update conversations list
      _parseApiResponse(data);
    } catch (e) {
      print('Error handling inbox data: $e');
      // Handle parsing errors - keep existing data or clear
      conversations.value = [];
    }
  }

  /// Handle user connection status from Socket.IO - user_connection_status event
  void _handleUserConnectionStatus(Map<String, dynamic> data) {
    try {
      print('Received user connection status from socket: $data');
      
      final userId = data['user_id']?.toString();
      final onlineStatus = data['online_status']?.toString();
      
      if (userId == null || onlineStatus == null) {
        print('Invalid user connection status data, ignoring');
        return;
      }

      final isOnline = onlineStatus.toLowerCase() == 'online';
      print('User $userId status: $onlineStatus (isOnline: $isOnline)');
      
      // Find and update the conversation in the list
      final index = conversations.indexWhere((conv) => conv.userId == userId);
      
      if (index != -1) {
        final conversation = conversations[index];
        // Only update if online status changed
        if (conversation.isOnline != isOnline) {
          conversations[index] = Conversation(
            id: conversation.id,
            name: conversation.name,
            profileImageUrl: conversation.profileImageUrl,
            lastMessage: conversation.lastMessage,
            lastMessageTime: conversation.lastMessageTime,
            unreadCount: conversation.unreadCount,
            isOnline: isOnline, // Update online status
            isHighlighted: conversation.isHighlighted,
            userId: conversation.userId,
          );
          
          // Refresh the list to trigger UI update
          conversations.refresh();
          print('Updated online status for user $userId to $isOnline');
        }
      }
    } catch (e) {
      print('Error handling user connection status: $e');
    }
  }
}