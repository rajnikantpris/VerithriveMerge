class Conversation {
  final String id;
  final String name;
  final String? profileImageUrl;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final bool isHighlighted;
  final String? userId; // User ID of the other person in the conversation

  Conversation({
    required this.id,
    required this.name,
    this.profileImageUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
    this.isHighlighted = false,
    this.userId,
  });
}

