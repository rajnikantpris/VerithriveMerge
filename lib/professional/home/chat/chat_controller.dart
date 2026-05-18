import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../api/user_api_service.dart';
import '../../../common/base_controller.dart';
import '../../../services/socket_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/analytics_service.dart';
import '../messages_controller.dart';

class ChatController extends BaseController {
  final scrollController = ScrollController();
  final inputController = TextEditingController();

  late final Rx<MessageItem> peer;
  final messages = <ChatMessage>[].obs;

  SocketService? _socketService;
  String? _currentUserId;
  String? _chatId;
  Worker? _messagesWorker;

  // Get UserApiService if available
  UserApiService? get _userApiService =>
      Get.isRegistered<UserApiService>() ? Get.find<UserApiService>() : null;

  @override
  void onInit() {
    super.onInit();
    peer = _resolvePeer().obs;
    _initializeChat();

    // Keep peer (online/offline, avatar, etc.) in sync with inbox list
    _setupInboxSyncListener();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      markMessagesAsRead();
      // Refresh messages inbox when chat opens
      _refreshMessagesInbox();
    });
  }

  @override
  void onClose() {
    _cleanupSocket();
    _messagesWorker?.dispose();
    // Refresh messages inbox when returning from chat
    _refreshMessagesInbox();
    inputController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  /// Initialize chat - create room, get messages, and setup socket
  Future<void> _initializeChat() async {
    await _checkAndCreateChatRoom();
    await Future.delayed(const Duration(milliseconds: 200));
    await _initializeSocket();
    await _fetchMessages();
  }

  /// Check socket connection and reconnect if needed
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

      // Check if socket is connected
      if (!_socketService!.connected) {
        // Socket not connected, reconnect it
        await _socketService!.connect(userId: _currentUserId);
      }

      // Setup message listeners
      _setupSocketListeners();
    } catch (e) {
      debugPrint('Error checking socket connection: $e');
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
      // Check if message belongs to current chat room
      final roomId = data['room_id']?.toString() ??
          data['roomId']?.toString() ??
          data['chat_id']?.toString() ??
          data['chatId']?.toString();

      if (_chatId != null && roomId != null && roomId != _chatId) {
        debugPrint(
            'Ignoring message from different room: $roomId (current: $_chatId)');
        return;
      }

      final messageText = data['message']?.toString() ??
          data['text']?.toString() ??
          data['content']?.toString() ??
          '';

      if (messageText.isEmpty) return;

      final senderId = _extractSenderId(
        data['senderId'] ?? data['sender_id'],
      );

      final isMine = senderId == _currentUserId;

      final timestamp = data['timestamp']?.toString() ??
          data['created_at']?.toString() ??
          data['createdAt']?.toString();

      final messageId = data['messageId']?.toString() ??
          data['message_id']?.toString() ??
          data['_id']?.toString() ??
          data['id']?.toString();

      final timeLabel =
          timestamp != null ? _formatTimestamp(timestamp) : _formatNow();

      // Check for duplicate messages (prevent adding same message twice)
      if (messageId != null && messageId.isNotEmpty) {
        final existingMessage = messages.firstWhereOrNull(
          (msg) => msg.messageId == messageId,
        );
        if (existingMessage != null) {
          debugPrint('Message already exists, skipping: $messageId');
          return;
        }
      }

      final message = ChatMessage(
        messageId: messageId,
        text: messageText,
        isMine: isMine,
        timeLabel: timeLabel,
        timestamp:
            timestamp != null ? _parseUtcToLocal(timestamp) : DateTime.now(),
        senderId: senderId,
      );

      messages.add(message);
      _scrollToBottom();

      // Mark as read when receiving message
      if (_chatId != null) {
        final idsToMark = messageId != null && messageId.isNotEmpty
            ? [messageId]
            : <String>[];
        _markMessagesAsRead(idsToMark);
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

    if (_socketService == null) {
      await _initializeSocket();
    }

    // Check if socket is connected, reconnect if needed
    if (!_socketService!.connected) {
      if (_currentUserId == null) {
        _currentUserId = await _getCurrentUserId();
      }

      debugPrint('Socket not connected, reconnecting...');
      await _socketService!.connect(userId: _currentUserId);
    }

    // Check if chat ID is available
    if (_chatId == null || _chatId!.isEmpty) {
      debugPrint('Warning: Chat ID not available');
      return;
    }

    // Send via Socket.IO - send_message event
    debugPrint(
        'Sending message via socket: room_id=$_chatId, receiver_id=${peer.value.userId}');
    _socketService!.sendMessage(
      message: text,
      receiverId: peer.value.userId ?? '',
      chatId: _chatId,
    );

    // Analytics: Log message sent tap event
    AnalyticsService.instance.logEvent(
      name: 'message_sent_tap',
      parameters: {
        'screen_name': 'ProfessionalChatScreen',
        'screen_class': 'ChatView',
        'element_text': 'message',
        'element_location': 'button_tap_cta',
        'page_category': 'messaging',
      },
    );

    // Mark messages as read after sending
    if (_chatId != null) {
      _markMessagesAsRead([]);
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
        .where((msg) => !msg.isMine && !msg.isRead)
        .map((msg) => msg.messageId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();

    if (unreadMessageIds.isNotEmpty) {
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

  /// Get current user ID from storage
  Future<String?> _getCurrentUserId() async {
    if (!Get.isRegistered<StorageService>()) return null;
    final storage = Get.find<StorageService>();
    return storage.readString('user_id') ??
        storage.readString('userId') ??
        storage.readString('_id');
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

  /// Check if chat room API needs to be called and create/get room if needed
  Future<void> _checkAndCreateChatRoom() async {
    // Set chat ID from peer if available
    if (peer.value.chatId != null && peer.value.chatId!.isNotEmpty) {
      _chatId = peer.value.chatId;
      return;
    }

    // If receiverId is not available, skip API call
    if (peer.value.userId == null || peer.value.userId!.isEmpty) {
      return;
    }

    // Call API to create/get chat room
    final apiService = _userApiService;
    if (apiService == null) {
      return;
    }

    await callDataService(
      apiService.createOrGetChatRoom(receiverId: peer.value.userId!),
      onSuccess: (response) {
        try {
          if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            final roomId = data['_id']?.toString() ??
                data['room_id']?.toString() ??
                data['roomId']?.toString() ??
                data['chat_id']?.toString() ??
                data['chatId']?.toString() ??
                data['id']?.toString();

            if (roomId != null && roomId.isNotEmpty) {
              _chatId = roomId;
            }

            // Try to extract user details from response to update peer name
            // Check for receiver_id or receiver object in response
            final receiverData = data['receiver_id'] ??
                data['receiverId'] ??
                data['receiver'] ??
                data['user'] ??
                data['peer'];

            if (receiverData is Map<String, dynamic>) {
              final fullName = receiverData['full_name']?.toString() ??
                  receiverData['fullName']?.toString() ??
                  receiverData['name']?.toString();

              if (fullName != null &&
                  fullName.isNotEmpty &&
                  peer.value.name == 'New chat') {
                // Update peer name if it's still the default
                peer.value = MessageItem(
                  name: fullName,
                  lastMessage: peer.value.lastMessage,
                  timeLabel: peer.value.timeLabel,
                  unreadCount: peer.value.unreadCount,
                  isOnline: receiverData['is_online'] as bool? ??
                      receiverData['isOnline'] as bool? ??
                      peer.value.isOnline,
                  avatarAsset: peer.value.avatarAsset,
                  userId: peer.value.userId,
                  chatId: peer.value.chatId,
                );
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing chat room response: $e');
        }
      },
      onError: (error, stack) {
        debugPrint('Error creating/getting chat room: $error');
      },
    );
  }

  MessageItem _resolvePeer() {
    final arg = Get.arguments;

    if (arg is MessageItem) {
      return arg;
    }

    if (arg is Map<String, dynamic>) {
      // Support both 'name' and 'full_name' for backward compatibility
      final name = arg['name'] as String? ?? arg['full_name'] as String?;
      final lastMessage = arg['lastMessage'] as String?;
      return MessageItem(
        name: name ?? 'New chat',
        lastMessage: lastMessage ?? 'Let\'s chat',
        timeLabel: arg['timeLabel'] as String? ?? '',
        unreadCount: 0,
        isOnline: arg['isOnline'] as bool? ?? false,
        avatarAsset: arg['avatarAsset'] as String? ?? '',
        userId: arg['userId'] as String? ?? arg['user_id'] as String?,
        chatId: arg['chatId'] as String? ?? arg['chat_id'] as String?,
      );
    }

    return MessageItem(
      name: 'New chat',
      lastMessage: 'Let\'s chat',
      timeLabel: '',
      unreadCount: 0,
      isOnline: false,
      avatarAsset: '',
    );
  }

  /// Fetch messages from API
  Future<void> _fetchMessages() async {
    if (_chatId == null || _chatId!.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (_chatId == null || _chatId!.isEmpty) {
        return;
      }
    }

    final apiService = _userApiService;
    if (apiService == null) {
      return;
    }

    if (_currentUserId == null) {
      _currentUserId = await _getCurrentUserId();
    }

    await callDataService(
      apiService.getChatMessages(roomId: _chatId!),
      showLoader: true,
      onSuccess: (response) {
        try {
          List<dynamic> messagesList = [];

          if (response.data is List) {
            messagesList = response.data as List<dynamic>;
          } else if (response.data is Map<String, dynamic>) {
            final data = response.data as Map<String, dynamic>;
            messagesList = data['messages'] as List<dynamic>? ??
                data['data'] as List<dynamic>? ??
                [];
          }

          final fetchedMessages = <ChatMessage>[];

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
                  messageData['messageId']?.toString();

              final timeLabel = timestamp != null
                  ? _formatTimestamp(timestamp)
                  : _formatNow();

              final message = ChatMessage(
                messageId: messageId,
                text: messageText,
                isMine: isMine,
                timeLabel: timeLabel,
                timestamp: timestamp != null
                    ? _parseUtcToLocal(timestamp)
                    : DateTime.now(),
                senderId: senderId,
                isRead: messageData['is_read'] as bool? ??
                    messageData['isRead'] as bool? ??
                    false,
              );

              fetchedMessages.add(message);
            }
          }

          // Sort messages by timestamp (oldest first)
          fetchedMessages.sort((a, b) {
            final aTime = a.timestamp ?? DateTime(1970);
            final bTime = b.timestamp ?? DateTime(1970);
            return aTime.compareTo(bTime);
          });

          messages.assignAll(fetchedMessages);

          // Scroll to bottom after messages are loaded
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });

          // Mark messages as read after fetching
          if (_chatId != null) {
            _markMessagesAsRead([]);
          }
        } catch (e) {
          debugPrint('Error parsing chat messages: $e');
        }
      },
      onError: (error, stack) {
        debugPrint('Error fetching chat messages: $error');
      },
    );
  }

  String _formatNow() {
    final now = TimeOfDay.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour.$minute';
  }

  /// Format timestamp string to time label (converts UTC to local time)
  String _formatTimestamp(String timestamp) {
    try {
      // Parse UTC timestamp and convert to local time
      final dateTimeUtc = DateTime.parse(timestamp);
      final dateTime = dateTimeUtc.isUtc ? dateTimeUtc.toLocal() : dateTimeUtc;
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        final hour = dateTime.hour.toString().padLeft(2, '0');
        final minute = dateTime.minute.toString().padLeft(2, '0');
        return '$hour.$minute';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        const days = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday'
        ];
        return days[dateTime.weekday - 1];
      } else {
        final day = dateTime.day.toString().padLeft(2, '0');
        final month = dateTime.month.toString().padLeft(2, '0');
        final year = dateTime.year.toString();
        return '$day/$month/$year';
      }
    } catch (e) {
      return _formatNow();
    }
  }

  /// Parse UTC timestamp and convert to local DateTime
  DateTime? _parseUtcToLocal(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return null;
    try {
      final dateTimeUtc = DateTime.parse(timestamp);
      return dateTimeUtc.isUtc ? dateTimeUtc.toLocal() : dateTimeUtc;
    } catch (e) {
      return null;
    }
  }

  void _scrollToBottom() {
    if (!scrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      final target = scrollController.position.maxScrollExtent + 80;
      scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  /// Format date header for date separators (Today, Yesterday, or date/day)
  String formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      final difference = today.difference(messageDate).inDays;
      if (difference < 7) {
        const days = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday'
        ];
        return days[date.weekday - 1];
      } else {
        final day = date.day.toString().padLeft(2, '0');
        final month = date.month.toString().padLeft(2, '0');
        final year = date.year.toString();
        return '$day/$month/$year';
      }
    }
  }

  /// Check if two messages are on different days
  bool isDifferentDay(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;
    final d1 = DateTime(date1.year, date1.month, date1.day);
    final d2 = DateTime(date2.year, date2.month, date2.day);
    return d1 != d2;
  }

  /// Refresh messages inbox in MessagesController
  void _refreshMessagesInbox() {
    try {
      // Check if MessagesController is registered
      if (Get.isRegistered<MessagesController>()) {
        final messagesController = Get.find<MessagesController>();
        // Refresh the inbox data
        messagesController.checkAndReconnectSocket();
      }
    } catch (e) {
      debugPrint('Error refreshing messages inbox: $e');
    }
  }

  /// Listen to inbox changes and update peer online/offline status (and related data)
  void _setupInboxSyncListener() {
    try {
      if (!Get.isRegistered<MessagesController>()) return;

      final messagesController = Get.find<MessagesController>();

      _messagesWorker =
          ever<List<MessageItem>>(messagesController.messages, (inbox) {
        _updatePeerFromInbox(inbox);
      });
    } catch (e) {
      debugPrint('Error setting up inbox sync listener: $e');
    }
  }

  /// Update peer model from latest inbox data so UI (e.g. Online label) stays fresh
  void _updatePeerFromInbox(List<MessageItem> inboxMessages) {
    if (inboxMessages.isEmpty) return;

    final currentPeer = peer.value;

    // Try to match by userId first, then by chatId
    final updated = inboxMessages.firstWhereOrNull((item) {
      final sameUser = currentPeer.userId != null &&
          currentPeer.userId!.isNotEmpty &&
          item.userId == currentPeer.userId;
      final sameChat = currentPeer.chatId != null &&
          currentPeer.chatId!.isNotEmpty &&
          item.chatId == currentPeer.chatId;
      return sameUser || sameChat;
    });

    if (updated == null) return;

    // If nothing important changed, skip
    final shouldUpdate = updated.isOnline != currentPeer.isOnline ||
        updated.avatarAsset != currentPeer.avatarAsset ||
        updated.name != currentPeer.name;

    if (!shouldUpdate) return;

    peer.value = MessageItem(
      name: updated.name,
      lastMessage: currentPeer.lastMessage,
      timeLabel: currentPeer.timeLabel,
      unreadCount: currentPeer.unreadCount,
      isOnline: updated.isOnline,
      avatarAsset:
          updated.avatarAsset.isNotEmpty ? updated.avatarAsset : currentPeer.avatarAsset,
      highlight: currentPeer.highlight,
      showDeliveredTick: currentPeer.showDeliveredTick,
      userId: currentPeer.userId ?? updated.userId,
      chatId: currentPeer.chatId ?? updated.chatId,
    );
  }
}

class ChatMessage {
  ChatMessage({
    required this.text,
    required this.isMine,
    required this.timeLabel,
    this.messageId,
    this.timestamp,
    this.senderId,
    this.isRead = false,
  });

  final String text;
  final bool isMine;
  final String timeLabel;
  final String? messageId;
  final DateTime? timestamp;
  final String? senderId;
  final bool isRead;
}
