class Therapist {
  final String id;
  final String name;
  final String imageUrl;
  final String specialty;
  final double distance;
  final double rating;
  final int reviewCount;
  final double price;
  final bool isFavorite;
  final String availability;
  final int ratingsCount;
  final int yearsExperience;
  final int bookingsCount;
  final List<String> services;
  final List<ServicePackage> packages;

  Therapist({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.specialty,
    required this.distance,
    required this.rating,
    required this.reviewCount,
    required this.price,
    this.isFavorite = false,
    this.availability = '',
    this.ratingsCount = 50,
    this.yearsExperience = 8,
    this.bookingsCount = 200,
    required this.services,
    required this.packages,
  });
}

class ServicePackage {
  final String title;
  final String duration;
  final double price;
  final String? discount;
  final String? service_format_date;
  final String? serviceFormatId; // service_format_id for summary screen
  final String? professionalServiceFormatId; // _id for create-booking API

  ServicePackage({
    required this.title,
    required this.duration,
    required this.price,
    this.discount,
    this.serviceFormatId,
    this.professionalServiceFormatId,
    this.service_format_date,
  });
}