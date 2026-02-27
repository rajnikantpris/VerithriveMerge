class NotificationModel {
  final String id;
  final String title;
  final String description;
  final String date;
  final bool isRead;
  final bool isSent;
  final String deliveryStatus;

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.isRead = false,
    this.isSent = false,
    this.deliveryStatus = 'pending',
  });
}