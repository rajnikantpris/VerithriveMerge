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
class MessagesControllerOld extends BaseController {
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

  @override
  void onInit() {
    super.onInit();
    // Don't check authentication on init - let user navigate first
    // Authentication will be checked when data is actually loaded
  }

  @override
  void fetchData() async {
    print("API Called: Messages Loaded");
    _checkAuthAndFetchMessages();
  }

  // Refresh data method called by MainScreen
  void refreshData() {
    isLoading.value = false;
    _checkAuthAndFetchMessages();
  }

  // Check authentication and fetch messages
  Future<void> _checkAuthAndFetchMessages() async {
    bool canAccess = await AuthService.requireAuth();
    if (canAccess) {
      fetchChatInbox(isInitialLoad: true);
    }
  }

  /// Silent refresh for notification updates - no loading states, no blinking
  Future<void> silentRefreshInbox() async {
    print("Silent refresh triggered for messages");
    
    // Prevent concurrent refreshes
    if (_isRefreshing) {
      print("Already refreshing, skipping silent refresh");
      return;
    }

    _isRefreshing = true;
    // Don't set isLoading.value = true to prevent blinking
    
    var service = _repository.sendGetApiNoParamRequest(chat_inbox);
    
    callDataService(
      service,
      onSuccess: _handleChatInboxSuccess,
      onError: _handleChatInboxError,
      isShowLoading: false,
      onComplete: () {
        _isRefreshing = false;
        // Don't set isLoading.value = false to prevent blinking
      },
    );
  }

  /// Fetch chat inbox from API
  Future<void> fetchChatInbox({bool isInitialLoad = false}) async {
    // Prevent concurrent refreshes
    if (_isRefreshing) {
      return;
    }

    _isRefreshing = true;
    
    // Set loading states appropriately
    if (isInitialLoad) {
      isInitialLoading.value = true;
    } else {
      isLoading.value = true;
    }
    
    var service = _repository.sendGetApiNoParamRequest(chat_inbox);
    
    callDataService(
      service,
      onSuccess: _handleChatInboxSuccess,
      onError: _handleChatInboxError,
      isShowLoading: false, // We're using isLoading observable
      onComplete: () {
        _isRefreshing = false;
        isInitialLoading.value = false;
        isLoading.value = false;
      },
    );
  }

  /// Handle successful API response
  Future<void> _handleChatInboxSuccess(dynamic baseResponse) async {
    try {
      Map<String, dynamic> responseData;
      if (baseResponse != null && baseResponse.data != null) {
        responseData = baseResponse.data is Map<String, dynamic>
            ? baseResponse.data
            : baseResponse.data as Map<String, dynamic>;
      } else if (baseResponse is Map<String, dynamic>) {
        responseData = baseResponse;
      } else {
        conversations.value = [];
        return;
      }

      bool success = responseData['success'] ?? false;
      
      if (success == true) {
        _parseApiResponse(responseData);
      } else {
        conversations.value = [];
      }
    } catch (e) {
      print('Error parsing chat inbox response: $e');
      conversations.value = [];
    }
  }

  /// Handle API error
  void _handleChatInboxError(Exception exception) {
    print('Chat Inbox API Error: $exception');
    conversations.value = [];
    
    if (exception is BaseException) {
      showResponseDialog(
        message: exception.message,
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    }
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
}