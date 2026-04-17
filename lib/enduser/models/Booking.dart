class PriceBreakdown {
  final double serviceAmount;
  final double platformFee;
  final double bookingFixDepositAmount;
  final double refundAmount;

  PriceBreakdown({
    this.serviceAmount = 0.0,
    this.platformFee = 0.0,
    this.bookingFixDepositAmount = 0.0,
    this.refundAmount = 0.0,
  });
}

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
  final String? bookingStatus;
  final String? paymentStatus;
  final PriceBreakdown? priceBreakdown;
  final String? uniqueBookingId;
  final String? uniqueTransactionId;

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
    this.bookingStatus,
    this.paymentStatus,
    this.priceBreakdown,
    this.uniqueBookingId,
    this.uniqueTransactionId,
  });
}
