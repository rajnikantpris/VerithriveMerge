class BookingsListResponse {
  final bool? success;
  final String? message;
  final BookingsListData? data;

  const BookingsListResponse({
    this.success,
    this.message,
    this.data,
  });

  factory BookingsListResponse.fromJson(Map<String, dynamic> json) =>
      BookingsListResponse(
        success: json['success'] as bool?,
        message: json['message'] as String?,
        data: json['data'] is Map<String, dynamic>
            ? BookingsListData.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (success != null) 'success': success,
        if (message != null) 'message': message,
        if (data != null) 'data': data!.toJson(),
      };
}

class BookingsListData {
  final String? timezone;
  final String? dateSelected;
  final BookingsList? upcomingBookings;
  final BookingsList? cancelledBookings;
  final BookingsList? pastBookings;

  const BookingsListData({
    this.timezone,
    this.dateSelected,
    this.upcomingBookings,
    this.cancelledBookings,
    this.pastBookings,
  });

  factory BookingsListData.fromJson(Map<String, dynamic> json) {
    // Handle both formats: array directly or wrapped in object with items/total
    BookingsList? parseBookingsList(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        // Array format: convert to BookingsList with items
        return BookingsList(
          items: value
              .whereType<Map<String, dynamic>>()
              .map((item) => BookingItem.fromJson(item))
              .toList(),
          total: value.length,
        );
      } else if (value is Map<String, dynamic>) {
        // Object format: parse normally
        return BookingsList.fromJson(value);
      }
      return null;
    }

    return BookingsListData(
      timezone: json['timezone'] as String?,
      dateSelected: json['date_selected'] as String?,
      upcomingBookings: parseBookingsList(json['upcoming_bookings']),
      cancelledBookings: parseBookingsList(json['cancelled_bookings']),
      pastBookings: parseBookingsList(json['past_bookings']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (timezone != null) 'timezone': timezone,
        if (dateSelected != null) 'date_selected': dateSelected,
        if (upcomingBookings != null)
          'upcoming_bookings': upcomingBookings!.toJson(),
        if (cancelledBookings != null)
          'cancelled_bookings': cancelledBookings!.toJson(),
        if (pastBookings != null) 'past_bookings': pastBookings!.toJson(),
      };
}

class BookingsList {
  final List<BookingItem>? items;
  final int? total;

  const BookingsList({
    this.items,
    this.total,
  });

  factory BookingsList.fromJson(Map<String, dynamic> json) => BookingsList(
        items: json['items'] is List
            ? (json['items'] as List)
                .map((item) =>
                    BookingItem.fromJson(item as Map<String, dynamic>))
                .toList()
            : null,
        total: json['total'] as int?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (items != null)
          'items': items!.map((item) => item.toJson()).toList(),
        if (total != null) 'total': total,
      };
}

class BookingItem {
  final String? id;
  final String? professionalId;
  final String? userId;
  final String? userName;
  final String? bookingStart;
  final String? bookingEnd;
  final String? bookingDateLocal;
  final String? timezone;
  final String? serviceFormatId;
  final ServiceFormatSnapshot? serviceFormatSnapshot;
  final String? availabilityId;
  final AvailabilitySnapshot? availabilitySnapshot;
  final String? status;
  final bool? isDeleted;
  final String? createdAt;
  final String? updatedAt;
  final int? v;
  final String? localEnd;
  final String? localEndMoment;
  final String? bookingTimeRange;

  const BookingItem({
    this.id,
    this.professionalId,
    this.userId,
    this.userName,
    this.bookingStart,
    this.bookingEnd,
    this.bookingDateLocal,
    this.timezone,
    this.serviceFormatId,
    this.serviceFormatSnapshot,
    this.availabilityId,
    this.availabilitySnapshot,
    this.status,
    this.isDeleted,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.localEnd,
    this.localEndMoment,
    this.bookingTimeRange,
  });

  factory BookingItem.fromJson(Map<String, dynamic> json) {
    // Extract user_id and user name from user object if present
    String? userId;
    String? userName;
    if (json['user'] is Map<String, dynamic>) {
      final userObj = json['user'] as Map<String, dynamic>;
      userId = userObj['_id'] as String?;
      userName = userObj['full_name'] as String?;
    } else {
      userId = json['user_id'] as String?;
      userName = json['user_name'] as String?;
    }

    // booking_time_range will be stored directly and parsed in the controller
    // No need to parse it here since we're storing the raw value

    // Handle service_format_name and duration_minutes directly
    ServiceFormatSnapshot? serviceFormatSnapshot;
    if (json['service_format_snapshot'] is Map<String, dynamic>) {
      serviceFormatSnapshot = ServiceFormatSnapshot.fromJson(
        json['service_format_snapshot'] as Map<String, dynamic>,
      );
    } else if (json['service_format_name'] != null ||
        json['duration_minutes'] != null) {
      // Create snapshot from direct fields
      serviceFormatSnapshot = ServiceFormatSnapshot(
        name: json['service_format_name'] as String?,
        durationMinutes: json['duration_minutes'] as int?,
        price: json['price'] as int?,
      );
    }

    return BookingItem(
      id: json['_id'] as String?,
      professionalId: json['professional_id'] as String?,
      userId: userId,
      userName: userName,
      bookingStart: json['booking_start'] as String?,
      bookingEnd: json['booking_end'] as String?,
      bookingDateLocal: json['booking_date_local'] as String?,
      timezone: json['timezone'] as String?,
      serviceFormatId: json['service_format_id'] as String?,
      serviceFormatSnapshot: serviceFormatSnapshot,
      availabilityId: json['availability_id'] as String?,
      availabilitySnapshot:
          json['availability_snapshot'] is Map<String, dynamic>
              ? AvailabilitySnapshot.fromJson(
                  json['availability_snapshot'] as Map<String, dynamic>)
              : null,
      status: json['status'] as String?,
      isDeleted: json['is_deleted'] as bool?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      v: json['__v'] as int?,
      localEnd: json['local_end'] as String?,
      localEndMoment: json['local_end_moment'] as String?,
      bookingTimeRange: json['booking_time_range'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (id != null) '_id': id,
        if (professionalId != null) 'professional_id': professionalId,
        if (userId != null) 'user_id': userId,
        if (userName != null) 'user_name': userName,
        if (bookingStart != null) 'booking_start': bookingStart,
        if (bookingEnd != null) 'booking_end': bookingEnd,
        if (bookingDateLocal != null) 'booking_date_local': bookingDateLocal,
        if (timezone != null) 'timezone': timezone,
        if (serviceFormatId != null) 'service_format_id': serviceFormatId,
        if (serviceFormatSnapshot != null)
          'service_format_snapshot': serviceFormatSnapshot!.toJson(),
        if (availabilityId != null) 'availability_id': availabilityId,
        if (availabilitySnapshot != null)
          'availability_snapshot': availabilitySnapshot!.toJson(),
        if (status != null) 'status': status,
        if (isDeleted != null) 'is_deleted': isDeleted,
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
        if (v != null) '__v': v,
        if (localEnd != null) 'local_end': localEnd,
        if (localEndMoment != null) 'local_end_moment': localEndMoment,
        if (bookingTimeRange != null) 'booking_time_range': bookingTimeRange,
      };
}

class ServiceFormatSnapshot {
  final ServiceFormatId? serviceFormatId;
  final String? name;
  final int? durationMinutes;
  final int? price;
  final bool? isBundle;
  final String? offerText;
  final String? serviceFormatDateLocal;
  final String? timezone;

  const ServiceFormatSnapshot({
    this.serviceFormatId,
    this.name,
    this.durationMinutes,
    this.price,
    this.isBundle,
    this.offerText,
    this.serviceFormatDateLocal,
    this.timezone,
  });

  factory ServiceFormatSnapshot.fromJson(Map<String, dynamic> json) =>
      ServiceFormatSnapshot(
        serviceFormatId: json['service_format_id'] is Map<String, dynamic>
            ? ServiceFormatId.fromJson(
                json['service_format_id'] as Map<String, dynamic>)
            : null,
        name: json['name'] as String?,
        durationMinutes: json['duration_minutes'] as int?,
        price: json['price'] as int?,
        isBundle: json['is_bundle'] as bool?,
        offerText: json['offer_text'] as String?,
        serviceFormatDateLocal: json['service_format_date_local'] as String?,
        timezone: json['timezone'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (serviceFormatId != null)
          'service_format_id': serviceFormatId!.toJson(),
        if (name != null) 'name': name,
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
        if (price != null) 'price': price,
        if (isBundle != null) 'is_bundle': isBundle,
        if (offerText != null) 'offer_text': offerText,
        if (serviceFormatDateLocal != null)
          'service_format_date_local': serviceFormatDateLocal,
        if (timezone != null) 'timezone': timezone,
      };
}

class ServiceFormatId {
  final String? id;
  final String? name;

  const ServiceFormatId({
    this.id,
    this.name,
  });

  factory ServiceFormatId.fromJson(Map<String, dynamic> json) =>
      ServiceFormatId(
        id: json['_id'] as String?,
        name: json['name'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (id != null) '_id': id,
        if (name != null) 'name': name,
      };
}

class AvailabilitySnapshot {
  final String? availableFrom;
  final String? availableUntil;
  final List<UnavailableTime>? unavailableTimes;
  final String? timezone;

  const AvailabilitySnapshot({
    this.availableFrom,
    this.availableUntil,
    this.unavailableTimes,
    this.timezone,
  });

  factory AvailabilitySnapshot.fromJson(Map<String, dynamic> json) =>
      AvailabilitySnapshot(
        availableFrom: json['available_from'] as String?,
        availableUntil: json['available_until'] as String?,
        unavailableTimes: json['unavailable_times'] is List
            ? (json['unavailable_times'] as List)
                .map((item) =>
                    UnavailableTime.fromJson(item as Map<String, dynamic>))
                .toList()
            : null,
        timezone: json['timezone'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (availableFrom != null) 'available_from': availableFrom,
        if (availableUntil != null) 'available_until': availableUntil,
        if (unavailableTimes != null)
          'unavailable_times':
              unavailableTimes!.map((item) => item.toJson()).toList(),
        if (timezone != null) 'timezone': timezone,
      };
}

class UnavailableTime {
  final String? from;
  final String? to;

  const UnavailableTime({
    this.from,
    this.to,
  });

  factory UnavailableTime.fromJson(Map<String, dynamic> json) =>
      UnavailableTime(
        from: json['from'] as String?,
        to: json['to'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      };
}
