class Booking {
  final String id;
  final String consultationType;
  final double price;
  final DateTime dateTime;
  final String address;
  final String therapistName;
  final String therapistTitle;
  final String? therapistImageUrl;
  final String? dateTimeRange;
  final bool isPast;
  final String? professionalId;
  final String? professionalServiceFormatId; // _id for update-booking API
  final String? serviceFormatId; // service_format_id
  final int? durationMinutes;

  Booking({
    required this.id,
    required this.consultationType,
    required this.price,
    required this.dateTime,
    required this.address,
    required this.therapistName,
    required this.therapistTitle,
    this.therapistImageUrl,
    this.isPast = false,
    this.professionalId,
    this.professionalServiceFormatId,
    this.serviceFormatId,
    this.durationMinutes,
    this.dateTimeRange,
  });
}

