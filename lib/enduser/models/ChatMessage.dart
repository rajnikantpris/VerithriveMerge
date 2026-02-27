class ChatMessage {
  final String id;
  final String conversationId;
  final String message;
  final DateTime timestamp;
  final bool isSentByMe;
  final String? senderName;
  final String? senderImageUrl;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.message,
    required this.timestamp,
    required this.isSentByMe,
    this.senderName,
    this.senderImageUrl,
  });
}

