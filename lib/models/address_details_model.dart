class AddressDetailsModel {
  final String? postcode;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? fullAddressId;
  final String? workPostcode;
  final String? workAddress;
  final double? workLatitude;
  final double? workLongitude;
  final String? workAddressId;

  const AddressDetailsModel({
    this.postcode,
    this.address,
    this.latitude,
    this.longitude,
    this.fullAddressId,
    this.workPostcode,
    this.workAddress,
    this.workLatitude,
    this.workLongitude,
    this.workAddressId,
  });

  factory AddressDetailsModel.fromJson(Map<String, dynamic> json) {
    // Handle full_address array
    Map<String, dynamic>? fullAddress;
    if (json['full_address'] != null) {
      if (json['full_address'] is List && (json['full_address'] as List).isNotEmpty) {
        fullAddress = (json['full_address'] as List).first as Map<String, dynamic>?;
      } else if (json['full_address'] is Map<String, dynamic>) {
        fullAddress = json['full_address'] as Map<String, dynamic>;
      }
    }

    // Handle work_address array (optional)
    Map<String, dynamic>? workAddress;
    if (json['work_address'] != null) {
      if (json['work_address'] is List && (json['work_address'] as List).isNotEmpty) {
        workAddress = (json['work_address'] as List).first as Map<String, dynamic>?;
      } else if (json['work_address'] is Map<String, dynamic>) {
        workAddress = json['work_address'] as Map<String, dynamic>;
      }
    }

    return AddressDetailsModel(
      postcode: fullAddress?['postcode'] as String?,
      address: fullAddress?['address'] as String?,
      latitude: fullAddress?['latitude'] != null
          ? (fullAddress!['latitude'] is num
              ? (fullAddress['latitude'] as num).toDouble()
              : double.tryParse(fullAddress['latitude'].toString()))
          : null,
      longitude: fullAddress?['longitude'] != null
          ? (fullAddress!['longitude'] is num
              ? (fullAddress['longitude'] as num).toDouble()
              : double.tryParse(fullAddress['longitude'].toString()))
          : null,
      fullAddressId: fullAddress?['_id'] as String?,
      workPostcode: workAddress?['postcode'] as String?,
      workAddress: workAddress?['address'] as String?,
      workLatitude: workAddress?['latitude'] != null
          ? (workAddress!['latitude'] is num
              ? (workAddress['latitude'] as num).toDouble()
              : double.tryParse(workAddress['latitude'].toString()))
          : null,
      workLongitude: workAddress?['longitude'] != null
          ? (workAddress!['longitude'] is num
              ? (workAddress['longitude'] as num).toDouble()
              : double.tryParse(workAddress['longitude'].toString()))
          : null,
      workAddressId: workAddress?['_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (postcode != null || address != null || latitude != null || longitude != null)
          'full_address': <String, dynamic>{
            if (postcode != null) 'postcode': postcode,
            if (address != null) 'address': address,
            if (latitude != null) 'latitude': latitude,
            if (longitude != null) 'longitude': longitude,
          },
        if (workPostcode != null ||
            workAddress != null ||
            workLatitude != null ||
            workLongitude != null)
          'work_address': <String, dynamic>{
            if (workPostcode != null) 'postcode': workPostcode,
            if (workAddress != null) 'address': workAddress,
            if (workLatitude != null) 'latitude': workLatitude,
            if (workLongitude != null) 'longitude': workLongitude,
          },
      };
}

