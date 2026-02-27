class NotificationPayloadModel {
  final String? notificationType;
  final String? order_id;
  final String? sound;
  final String? loop;
  final String? is_show_popup;
  final Map<String, dynamic>? orderData;
  
  // Chat message specific fields
  final String? roomId;
  final String? fullName;
  final String? profilePicture;
  final String? body;
  final String? title;
  final String? senderId;
  final String? timestamp;
  final String? clickAction;

  NotificationPayloadModel({
    this.notificationType,
    this.order_id,
    this.sound,
    this.loop,
    this.is_show_popup,
    this.orderData,
    this.roomId,
    this.fullName,
    this.profilePicture,
    this.body,
    this.title,
    this.senderId,
    this.timestamp,
    this.clickAction,
  });

  factory NotificationPayloadModel.fromJson(Map<String, dynamic> json) {
    return NotificationPayloadModel(
      notificationType: json['type']?.toString() ?? json['notification_type']?.toString(),
      order_id: json['order_id']?.toString(),
      sound: json['sound']?.toString(),
      loop: json['loop']?.toString(),
      is_show_popup: json['is_show_popup']?.toString(),
      orderData: json['orderData'] is Map
          ? json['orderData'] as Map<String, dynamic>
          : json['orderData'] is String
              ? {}
              : json['orderData'],
      // Chat message fields from payload
      roomId: json['room_id']?.toString(),
      fullName: json['full_name']?.toString(),
      profilePicture: json['profile_picture']?.toString(),
      body: json['body']?.toString(),
      title: json['title']?.toString(),
      senderId: json['sender_id']?.toString(),
      timestamp: json['timestamp']?.toString(),
      clickAction: json['click_action']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_type': notificationType,
      'order_id': order_id,
      'sound': sound,
      'loop': loop,
      'is_show_popup': is_show_popup,
      'orderData': orderData,
      'room_id': roomId,
      'full_name': fullName,
      'profile_picture': profilePicture,
      'body': body,
      'title': title,
      'sender_id': senderId,
      'timestamp': timestamp,
      'click_action': clickAction,
    };
  }
}

