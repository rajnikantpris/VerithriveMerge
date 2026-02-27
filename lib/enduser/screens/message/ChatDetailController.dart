import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/base/base_controller.dart';
import '../../data/repository/project_repository.dart';
import '../../models/Conversation.dart';
import '../../models/ChatMessage.dart';
import '../../utils/api_services.dart';
import '../../core/values/sharePrefrenceConst.dart';
import 'socket_service.dart';
import 'MessagesController.dart';
import 'package:verithrive_dev/services/storage_service.dart';

class ChatDetailController extends BaseController {
  final ProjectRepository _repository = Get.find(tag: (ProjectRepository).toString());
  final StorageService _storageService = Get.find<StorageService>();
  
  final ScrollController scrollController = ScrollController();
  final TextEditingController inputController = TextEditingController();
  
  final messages = <ChatMessage>[].obs;
  var isLoading = false.obs;
  
  SocketService? _socketService;
  String? _currentUserId;
  String? _chatId;
  String? _receiverUserId;

  Conversation? _conversationArg;

  @override
  void onInit() {
    super.onInit();
    _conversationArg = _resolveConversation();
    _chatId = _conversationArg?.id;
    _receiverUserId = _conversationArg?.userId;
    
    // Debug logging for notification data
    print("=== ChatDetailController Init ===");
    print("Conversation ID: ${_conversationArg?.id}");
    print("Conversation Name: ${_conversationArg?.name}");
    print("Conversation ProfileImageUrl: ${_conversationArg?.profileImageUrl}");
    print("Conversation UserId: ${_conversationArg?.userId}");
    
    // Log notification data if available
    final notificationData = this.notificationData;
    if (notificationData != null) {
      print("Notification Data Available:");
      print("  - full_name: ${notificationData['full_name']}");
      print("  - profile_picture: ${notificationData['profile_picture']}");
      print("  - sender_id: ${notificationData['sender_id']}");
      print("  - room_id: ${notificationData['room_id']}");
    }
    
    _initializeChat();
  }

  @override
  void onClose() {
    _cleanupSocket();
    _refreshMessagesInbox();
    inputController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  /// Get conversation (for external access)
  Conversation get conversation1 {
    return _conversationArg ?? Conversation(
      id: '',
      name: 'Unknown',
      lastMessage: '',
      lastMessageTime: DateTime.now(),
    );
  }

  /// Initialize chat - create room, get messages, and setup socket
  Future<void> _initializeChat() async {
    await _checkAndCreateChatRoom();
    await Future.delayed(const Duration(milliseconds: 200));
    await _initializeSocket();
    await _fetchMessages();
    
    // Scroll to bottom after messages are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        _scrollToBottom(force: true);
        markMessagesAsRead();
      });
    });
  }

  /// Initialize Socket.IO connection
  Future<void> _initializeSocket() async {
    try {
      // Get or create SocketService
      if (Get.isRegistered<SocketService>()) {
        _socketService = Get.find<SocketService>();
      } else {
        _socketService = Get.put(SocketService());
      }

      // Get current user ID
      _currentUserId = await _getCurrentUserId();

      if (_currentUserId == null || _currentUserId!.isEmpty) {
        debugPrint('Cannot initialize socket: User ID not available');
        return;
      }

      // Connect to socket
      await _socketService!.connect(userId: _currentUserId);

      // Wait for connection
      await Future.delayed(const Duration(milliseconds: 500));

      // Setup message listeners
      _setupSocketListeners();
    } catch (e) {
      debugPrint('Error initializing socket: $e');
    }
  }

  /// Setup Socket.IO event listeners - receive_message only
  void _setupSocketListeners() {
    if (_socketService == null) return;

    // Listen for incoming messages - receive_message event
    _socketService!.onReceiveMessage((data) {
      _handleReceivedMessage(data);
    });
  }

  /// Handle received message from Socket.IO - receive_message event
  void _handleReceivedMessage(Map<String, dynamic> data) {
    try {
      debugPrint('=== RECEIVED MESSAGE ===');
      debugPrint('Full data: $data');
      debugPrint('Current chat ID: $_chatId');
      
      // Check if message belongs to current chat room
      final roomId = data['room_id']?.toString() ??
          data['roomId']?.toString() ??
          data['chat_id']?.toString() ??
          data['chatId']?.toString();

      debugPrint('Message room_id: $roomId');
      debugPrint('Current chat ID: $_chatId');
      debugPrint('Room match: ${roomId == _chatId}');
      
      // TEMPORARY FIX: If room_id equals receiver_id, this might be a special case
      // Allow messages that match either the current chat ID or the receiver user ID
      final isMatchingRoom = roomId == _chatId || roomId == _receiverUserId;
      debugPrint('Is matching room (including receiver check): $isMatchingRoom');

      if (_chatId != null && roomId != null && !isMatchingRoom) {
        debugPrint('Ignoring message from different room: $roomId (current: $_chatId, receiver: $_receiverUserId)');
        return;
      }

      final messageText = data['message']?.toString() ??
          data['text']?.toString() ??
          data['content']?.toString() ??
          '';

      debugPrint('Message text: "$messageText"');

      if (messageText.isEmpty) {
        debugPrint('Empty message, returning');
        return;
      }

      final senderId = _extractSenderId(
        data['senderId'] ?? data['sender_id'] ?? data['user_id'] ?? data['userId'],
      );

      debugPrint('Sender ID: $senderId');
      debugPrint('Current user ID: $_currentUserId');

      final isMine = senderId == _currentUserId;
      debugPrint('Is my message: $isMine');

      final timestamp = data['timestamp']?.toString() ??
          data['created_at']?.toString() ??
          data['createdAt']?.toString();

      final messageId = data['messageId']?.toString() ??
          data['message_id']?.toString() ??
          data['_id']?.toString() ??
          data['id']?.toString();

      debugPrint('Message ID: $messageId');
      debugPrint('Timestamp: $timestamp');

      // Check for duplicate messages (prevent adding same message twice)
      // Check by message ID first
      if (messageId != null && messageId.isNotEmpty) {
        final existingById = messages.firstWhereOrNull(
          (msg) => msg.id == messageId,
        );
        if (existingById != null) {
          debugPrint('Message already exists (by ID), skipping: $messageId');
          return;
        }
      }
      
      // Also check for duplicate by content + timestamp + sender (for optimistic messages)
      final parsedTimestamp = timestamp != null
          ? _parseUtcToLocal(timestamp)
          : DateTime.now();
      
      final existingByContent = messages.firstWhereOrNull(
        (msg) => msg.message == messageText &&
            msg.isSentByMe == isMine &&
            (msg.timestamp.difference(parsedTimestamp).inSeconds.abs() < 5), // Within 5 seconds
      );
      
      if (existingByContent != null) {
        debugPrint('Message already exists (by content), removing optimistic and adding real: $messageId');
        // Remove the optimistic message and add the real one
        messages.remove(existingByContent);
      }

      final message = ChatMessage(
        id: messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: _chatId ?? conversation.id,
        message: messageText,
        timestamp: parsedTimestamp,
        isSentByMe: isMine,
        senderName: isMine ? null : conversation.name,
        senderImageUrl: isMine ? null : conversation.profileImageUrl,
      );

      debugPrint('=== ADDING MESSAGE TO LIST ===');
      debugPrint('Message: ${message.message}');
      debugPrint('Is mine: ${message.isSentByMe}');
      debugPrint('Current messages count: ${messages.length}');
      
      // Add message and sort to maintain chronological order
      messages.add(message);
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      debugPrint('Messages count after adding: ${messages.length}');
      debugPrint('Last message: ${messages.last.message}');
      
      // Scroll to bottom after adding message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 50), () {
          _scrollToBottom();
        });
      });

      // Mark as read when receiving message
      if (_chatId != null) {
        markMessagesAsRead();
      }

      // Refresh messages inbox after receiving message
      _refreshMessagesInbox();
    } catch (e) {
      debugPrint('Error handling received message: $e');
    }
  }

  /// Send message via Socket.IO - send_message event
  Future<void> sendMessage() async {
    final text = inputController.text.trim();
    if (text.isEmpty) return;

    // Ensure chat room is created before sending message
    if (_chatId == null || _chatId!.isEmpty) {
      debugPrint('Chat ID not available, ensuring chat room creation...');
      await _checkAndCreateChatRoom();
      
      // Wait a bit for the chat room to be created
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (_chatId == null || _chatId!.isEmpty) {
        debugPrint('Failed to create chat room, cannot send message');
        return;
      }
    }

    if (_socketService == null) {
      await _initializeSocket();
    }

    // Ensure socket is connected
    if (!_socketService!.connected) {
      if (_currentUserId == null) {
        _currentUserId = await _getCurrentUserId();
      }

      debugPrint('Attempting to connect socket...');
      await _socketService!.connect(userId: _currentUserId);

      debugPrint('Waiting for socket connection...');
      final connected = await _socketService!.waitForConnection(
        timeout: const Duration(seconds: 10),
      );

      if (!connected) {
        debugPrint('Failed to connect socket within timeout');
        // Still try to send - socket might be connecting
        debugPrint('Attempting to send message anyway...');
      } else {
        debugPrint('Socket connected successfully');
      }
    }

    // Check if chat ID is available
    if (_chatId == null || _chatId!.isEmpty) {
      debugPrint('Warning: Chat ID not available');
      return;
    }

    // Send via Socket.IO - send_message event
    // Note: receiverId might not be available, but socket service can handle it
    debugPrint('=== SENDING MESSAGE ===');
    debugPrint('Chat ID (room_id): $_chatId');
    debugPrint('Receiver ID: $_receiverUserId');
    debugPrint('Message text: "$text"');
    debugPrint('Current user ID: $_currentUserId');
    
    _socketService!.sendMessage(
      message: text,
      receiverId: _receiverUserId ?? '',
      chatId: _chatId,
    );

    // Optimistically add message to UI (will be replaced when socket confirms)
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMessage = ChatMessage(
      id: tempId,
      conversationId: _chatId!,
      message: text,
      timestamp: DateTime.now(),
      isSentByMe: true,
    );
    messages.add(optimisticMessage);
    // Sort to maintain chronological order
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    // Scroll to bottom after adding optimistic message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 50), () {
        _scrollToBottom();
      });
    });

    // Mark messages as read after sending
    if (_chatId != null) {
      markMessagesAsRead();
    }

    inputController.clear();

    // Refresh messages inbox after sending message
    _refreshMessagesInbox();
  }

  /// Mark messages as read - mark_read event
  void markMessagesAsRead() {
    if (_socketService == null ||
        !_socketService!.connected ||
        _chatId == null) {
      return;
    }

    // Get unread message IDs
    final unreadMessageIds = messages
        .where((msg) => !msg.isSentByMe)
        .map((msg) => msg.id)
        .where((id) => id.isNotEmpty)
        .toList();

    if (unreadMessageIds.isNotEmpty || unreadMessageIds.isEmpty) {
      _markMessagesAsRead(unreadMessageIds);
    }
  }

  /// Internal method to mark messages as read - mark_read event
  void _markMessagesAsRead(List<String> messageIds) {
    if (_socketService == null ||
        !_socketService!.connected ||
        _chatId == null) {
      return;
    }

    _socketService!.markRead(
      roomId: _chatId!,
      messageIds: messageIds.isEmpty ? null : messageIds,
    );
  }

  /// Cleanup Socket.IO connection
  void _cleanupSocket() {
    if (_socketService != null) {
      _socketService!.offReceiveMessage();
    }
  }

  /// Get current user ID from storage (matching login screen implementation)
  Future<String?> _getCurrentUserId() async {
    try {
      final userId =
          _storageService.readString(SharePreferenceConst.id);
      if (userId != null && userId.isNotEmpty) {
        return userId;
      }
      
      debugPrint('User ID not found in storage');
      return null;
    } catch (e) {
      debugPrint('Error getting user ID from storage: $e');
      return null;
    }
  }

  /// Extract sender ID from message data (handles both string and object formats)
  String? _extractSenderId(dynamic senderIdData) {
    if (senderIdData == null) return null;

    // If it's already a string, return it
    if (senderIdData is String) {
      return senderIdData;
    }

    // If it's a Map/object, extract the _id field
    if (senderIdData is Map<String, dynamic>) {
      return senderIdData['_id']?.toString() ??
          senderIdData['id']?.toString() ??
          senderIdData['userId']?.toString() ??
          senderIdData['user_id']?.toString();
    }

    // Try to convert to string as fallback
    return senderIdData.toString();
  }

  /// Resolve conversation from arguments
  Conversation _resolveConversation() {
    final arg = Get.arguments;

    if (arg is Conversation) {
      return arg;
    }
    
    // Handle new argument structure from notification
    if (arg is Map<String, dynamic>) {
      final conversation = arg['conversation'] as Conversation?;
      if (conversation != null) {
        return conversation;
      }
    }

    // If no conversation provided, create a default one
    return Conversation(
      id: '',
      name: 'Unknown',
      lastMessage: '',
      lastMessageTime: DateTime.now(),
    );
  }

  /// Get conversation (for external access)
  Conversation get conversation {
    return _conversationArg ?? Conversation(
      id: '',
      name: 'Unknown',
      lastMessage: '',
      lastMessageTime: DateTime.now(),
    );
  }
  
  /// Get notification data if available
  Map<String, dynamic>? get notificationData {
    final arg = Get.arguments;
    if (arg is Map<String, dynamic>) {
      return arg['notificationData'] as Map<String, dynamic>?;
    }
    return null;
  }

  /// Check if chat room API needs to be called and create/get room if needed
  Future<void> _checkAndCreateChatRoom() async {
    debugPrint('=== CHECK AND CREATE CHAT ROOM ===');
    debugPrint('Conversation ID: ${conversation.id}');
    debugPrint('Receiver user ID: $_receiverUserId');
    debugPrint('Current chat ID: $_chatId');
    
    // Set chat ID from conversation if available
    if (conversation.id.isNotEmpty) {
      _chatId = conversation.id;
      debugPrint('Using conversation ID as chat ID: $_chatId');
      return;
    }

    // If no chat ID but we have receiver user ID, create/get room
    if (_receiverUserId != null && _receiverUserId!.isNotEmpty) {
      Map<String, dynamic> toJson() {
        final Map<String, dynamic> data = <String, dynamic>{};
        data['receiver_id'] = _receiverUserId;
        debugPrint('Creating chat room with data: $data');
        return data;
      }
      
      var service = _repository.sendPostApiRequest(toJson, chat_room, true);
      
      // Use a Completer to wait for the response
      final completer = Completer<void>();
      
      callDataService(
        service,
        onSuccess: (response) {
          try {
            debugPrint('Chat room API response received');
            Map<String, dynamic> responseData;
            if (response != null && response.data != null) {
              responseData = response.data is Map<String, dynamic>
                  ? response.data
                  : response.data as Map<String, dynamic>;
            } else if (response is Map<String, dynamic>) {
              responseData = response;
            } else {
              debugPrint('Invalid response format');
              completer.complete();
              return;
            }

            debugPrint('Response data: $responseData');
            bool success = responseData['success'] ?? false;
            
            if (success == true && responseData['data'] != null) {
              final data = responseData['data'] as Map<String, dynamic>;
              final roomId = data['_id']?.toString() ??
                  data['room_id']?.toString() ??
                  data['roomId']?.toString() ??
                  data['chat_id']?.toString() ??
                  data['chatId']?.toString() ??
                  data['id']?.toString();

              if (roomId != null && roomId.isNotEmpty) {
                _chatId = roomId;
                debugPrint('✅ Created/got chat room: $_chatId');
              } else {
                debugPrint('❌ No room ID found in response');
              }
            } else {
              debugPrint('❌ Chat room creation failed: ${responseData['message']}');
            }
          } catch (e) {
            debugPrint('Error parsing chat room response: $e');
          }
          completer.complete();
        },
        onError: (error) {
          debugPrint('Error creating/getting chat room: $error');
          completer.complete();
        },
        isShowLoading: false,
      );
      
      // Wait for the API call to complete
      await completer.future;
    } else {
      debugPrint('No chat ID or receiver user ID available');
    }
  }

  /// Fetch messages from API
  Future<void> _fetchMessages() async {
    if (_chatId == null || _chatId!.isEmpty) {
      // Use conversation ID as fallback
      _chatId = conversation.id;
      if (_chatId == null || _chatId!.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (_chatId == null || _chatId!.isEmpty) {
          debugPrint('Cannot fetch messages: Chat ID not available');
          return;
        }
      }
    }

    isLoading.value = true;

    // Replace {room_id} in the API endpoint
    String apiEndpoint = chat_messages.replaceAll('{room_id}', _chatId!);
    
    // If replacement didn't work (endpoint doesn't have {room_id}), append room_id as query param
    if (apiEndpoint == chat_messages) {
      apiEndpoint = '$chat_messages?room_id=$_chatId';
    }

    Map<String, dynamic> toJson() {
      final Map<String, dynamic> data = <String, dynamic>{};
      return data;
    }

    var service = _repository.sendGetApiWithParamRequest(toJson, apiEndpoint, true);

    callDataService(
      service,
      onSuccess: (response) async {
        try {
          List<dynamic> messagesList = [];

          if (response.data is List) {
            // If response.data is directly a list
            messagesList = response.data as List<dynamic>;
          } else if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            // Check for 'data' key first (as per API response structure)
            if (data['data'] is List) {
              messagesList = data['data'] as List<dynamic>;
            } else if (data['messages'] is List) {
              messagesList = data['messages'] as List<dynamic>;
            } else {
              messagesList = [];
            }
          }

          final fetchedMessages = <ChatMessage>[];

          // Ensure we have current user ID before parsing
          if (_currentUserId == null) {
            _currentUserId = await _getCurrentUserId();
          }

          _parseMessages(messagesList, fetchedMessages);

          // Sort messages by timestamp (oldest first)
          fetchedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          // Remove any optimistic messages that might have been added
          messages.removeWhere((msg) => msg.id.startsWith('temp_'));
          
          messages.assignAll(fetchedMessages);
          
          // Force scroll to bottom after messages are assigned
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 300), () {
              _scrollToBottom(force: true);
            });
          });

          // Mark messages as read after fetching
          if (_chatId != null) {
            markMessagesAsRead();
          }
        } catch (e) {
          debugPrint('Error parsing chat messages: $e');
        }
        isLoading.value = false;
      },
      onError: (error) {
        debugPrint('Error fetching chat messages: $error');
        isLoading.value = false;
      },
      isShowLoading: false,
    );
  }

  /// Parse messages from API response
  void _parseMessages(List<dynamic> messagesList, List<ChatMessage> fetchedMessages) {
    for (var messageData in messagesList) {
      if (messageData is Map<String, dynamic>) {
        final messageText = messageData['message']?.toString() ??
            messageData['text']?.toString() ??
            messageData['content']?.toString() ??
            '';

        if (messageText.isEmpty) continue;

        final senderId = _extractSenderId(
          messageData['sender_id'] ??
              messageData['senderId'] ??
              messageData['user_id'] ??
              messageData['userId'],
        );

        final isMine = senderId == _currentUserId;

        final timestamp = messageData['created_at']?.toString() ??
            messageData['createdAt']?.toString() ??
            messageData['timestamp']?.toString();

        final messageId = messageData['_id']?.toString() ??
            messageData['id']?.toString() ??
            messageData['message_id']?.toString() ??
            messageData['messageId']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString();

        final parsedTimestamp = timestamp != null
            ? _parseUtcToLocal(timestamp)
            : DateTime.now();

        final message = ChatMessage(
          id: messageId,
          conversationId: _chatId ?? conversation.id,
          message: messageText,
          timestamp: parsedTimestamp,
          isSentByMe: isMine,
          senderName: isMine ? null : conversation.name,
          senderImageUrl: isMine ? null : conversation.profileImageUrl,
        );

        fetchedMessages.add(message);
      }
    }
  }

  /// Parse UTC timestamp and convert to local DateTime
  DateTime _parseUtcToLocal(String timestamp) {
    try {
      final dateTimeUtc = DateTime.parse(timestamp);
      return dateTimeUtc.isUtc ? dateTimeUtc.toLocal() : dateTimeUtc;
    } catch (e) {
      return DateTime.now();
    }
  }

  void _scrollToBottom({bool force = false}) {
    // With reverse: true, ListView automatically starts at bottom
    // We just need to ensure it stays at bottom when new messages arrive
    if (!scrollController.hasClients) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      
      try {
        // With reverse: true, position 0 is at the bottom
        // We want to scroll to position 0 to show newest messages
        if (force || scrollController.position.pixels > 50) {
          scrollController.jumpTo(0);
        }
      } catch (e) {
        debugPrint('Error scrolling to bottom: $e');
      }
    });
  }

  /// Refresh messages inbox in MessagesController
  void _refreshMessagesInbox() {
    try {
      // Check if MessagesController is registered
      if (Get.isRegistered<MessagesController>(tag: 'messages')) {
        final messagesController = Get.find<MessagesController>(tag: 'messages');
        // Use silent refresh to prevent blinking in messages list
        messagesController.silentRefreshInbox();
      }
    } catch (e) {
      debugPrint('Error refreshing messages inbox: $e');
    }
  }
}
