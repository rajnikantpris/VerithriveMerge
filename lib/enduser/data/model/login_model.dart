class LoginModel {
  final bool success;
  final String message;
  final LoginData? data;

  LoginModel({
    required this.success,
    required this.message,
    this.data,
  });

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? LoginData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class LoginData {
  final String token;
  final User? user;

  LoginData({
    required this.token,
    this.user,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      token: json['token'] ?? '',
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user?.toJson(),
    };
  }
}

class User {
  final String? id;
  final String? timezone;
  final String? email;
  final String? fullName;
  final String? profilePicture;
  final String? emailVerifiedAt;
  final bool? isEmailVerified;
  final bool? isEmailHidden;
  final String? mobileNumber;
  final String? userType;
  final int? totalExperience;
  final bool? isOtpVerified;
  final bool? isActive;
  final bool? isApproved;
  final bool? isOnHold;
  final bool? isDeclined;
  final bool? isBlocked;
  final bool? isSocialLogin;
  final String? socialType;
  final String? socialId;
  final String? registrationType;
  final bool? isDeleted;
  final String? lastLoginAt;
  final String? lastLoginEmail;
  final String? lastLoginType;
  final bool? isPersonalDetails;
  final bool? isTermCondition;
  final bool? isProfileCreated;
  final bool? isWorkFull;
  final int? tokenVersion;
  final bool? isPersonalIdentification;
  final bool? isAboutYou;
  final bool? isProfessionalServices;
  final bool? isQualification;
  final bool? isNotification;
  final bool? isPayment;
  final List<dynamic>? reviewMilestones;
  final String? createdAt;
  final String? updatedAt;
  final int? v;
  final bool? isOnline;

  // Added missing fields from log
  final String? promoCodeUsedType;
  final String? promoCodeUsedAt;
  final bool? promoCodeUsed;
  final bool? optStatus;
  final bool? stripeConnectChargesEnabled;
  final bool? stripeConnectPayoutsEnabled;
  final String? stripeConnectStatus;
  final String? address;
  final String? dob;
  final String? gender;
  final double? latitude;
  final double? longitude;
  final String? postcode;
  final String? lastSeenAt;
  final String? fcmToken;

  User({
    this.id,
    this.timezone,
    this.email,
    this.fullName,
    this.profilePicture,
    this.emailVerifiedAt,
    this.isEmailVerified,
    this.isEmailHidden,
    this.mobileNumber,
    this.userType,
    this.totalExperience,
    this.isOtpVerified,
    this.isActive,
    this.isApproved,
    this.isOnHold,
    this.isDeclined,
    this.isBlocked,
    this.isSocialLogin,
    this.socialType,
    this.socialId,
    this.registrationType,
    this.isDeleted,
    this.lastLoginAt,
    this.lastLoginEmail,
    this.lastLoginType,
    this.isPersonalDetails,
    this.isTermCondition,
    this.isProfileCreated,
    this.isWorkFull,
    this.tokenVersion,
    this.isPersonalIdentification,
    this.isAboutYou,
    this.isProfessionalServices,
    this.isQualification,
    this.isNotification,
    this.isPayment,
    this.reviewMilestones,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.isOnline,
    this.promoCodeUsedType,
    this.promoCodeUsedAt,
    this.promoCodeUsed,
    this.optStatus,
    this.stripeConnectChargesEnabled,
    this.stripeConnectPayoutsEnabled,
    this.stripeConnectStatus,
    this.address,
    this.dob,
    this.gender,
    this.latitude,
    this.longitude,
    this.postcode,
    this.lastSeenAt,
    this.fcmToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id']?.toString(),
      timezone: json['timezone']?.toString(),
      email: json['email']?.toString(),
      fullName: json['full_name']?.toString(),
      profilePicture: json['profile_picture']?.toString(),
      emailVerifiedAt: json['email_verified_at']?.toString(),
      isEmailVerified: _asBool(json['is_email_verified']),
      isEmailHidden: _asBool(json['is_email_hidden']),
      mobileNumber: json['mobile_number']?.toString(),
      userType: json['user_type']?.toString(),
      totalExperience: json['total_experience'] as int?,
      isOtpVerified: _asBool(json['is_otp_verified']),
      isActive: _asBool(json['is_active']),
      isApproved: _asBool(json['is_approved']),
      isOnHold: _asBool(json['is_on_hold']),
      isDeclined: _asBool(json['is_declined']),
      isBlocked: _asBool(json['is_blocked']),
      isSocialLogin: _asBool(json['is_social_login']),
      socialType: json['social_type']?.toString(),
      socialId: json['social_id']?.toString(),
      registrationType: json['registration_type']?.toString(),
      isDeleted: _asBool(json['is_deleted']),
      lastLoginAt: json['last_login_at']?.toString(),
      lastLoginEmail: json['last_login_email']?.toString(),
      lastLoginType: json['last_login_type']?.toString(),
      isPersonalDetails: _asBool(json['is_personal_details']),
      isTermCondition: _asBool(json['is_term_condition']),
      isProfileCreated: _asBool(json['is_profile_created']),
      isWorkFull: _asBool(json['is_work_full']),
      tokenVersion: json['token_version'] as int?,
      isPersonalIdentification: _asBool(json['is_personal_identification']),
      isAboutYou: _asBool(json['is_about_you']),
      isProfessionalServices: _asBool(json['is_professional_services']),
      isQualification: _asBool(json['is_qualification']),
      isNotification: _asBool(json['is_notification']),
      isPayment: _asBool(json['is_payment']),
      reviewMilestones: json['review_milestones'] as List<dynamic>?,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      v: json['__v'] as int?,
      isOnline: _asBool(json['is_online']),
      promoCodeUsedType: json['promo_code_used_type']?.toString(),
      promoCodeUsedAt: json['promo_code_used_at']?.toString(),
      promoCodeUsed: _asBool(json['promo_code_used']),
      optStatus: _asBool(json['opt_status']),
      stripeConnectChargesEnabled: _asBool(json['stripe_connect_charges_enabled']),
      stripeConnectPayoutsEnabled: _asBool(json['stripe_connect_payouts_enabled']),
      stripeConnectStatus: json['stripe_connect_status']?.toString(),
      address: json['address']?.toString(),
      dob: json['dob']?.toString(),
      gender: json['gender']?.toString(),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      postcode: json['postcode']?.toString(),
      lastSeenAt: json['last_seen_at']?.toString(),
      fcmToken: (json['fcm_token'] ?? json['device_token'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'timezone': timezone,
      'email': email,
      'full_name': fullName,
      'profile_picture': profilePicture,
      'email_verified_at': emailVerifiedAt,
      'is_email_verified': isEmailVerified,
      'is_email_hidden': isEmailHidden,
      'mobile_number': mobileNumber,
      'user_type': userType,
      'total_experience': totalExperience,
      'is_otp_verified': isOtpVerified,
      'is_active': isActive,
      'is_approved': isApproved,
      'is_on_hold': isOnHold,
      'is_declined': isDeclined,
      'is_blocked': isBlocked,
      'is_social_login': isSocialLogin,
      'social_type': socialType,
      'social_id': socialId,
      'registration_type': registrationType,
      'is_deleted': isDeleted,
      'last_login_at': lastLoginAt,
      'last_login_email': lastLoginEmail,
      'last_login_type': lastLoginType,
      'is_personal_details': isPersonalDetails,
      'is_term_condition': isTermCondition,
      'is_profile_created': isProfileCreated,
      'is_work_full': isWorkFull,
      'token_version': tokenVersion,
      'is_personal_identification': isPersonalIdentification,
      'is_about_you': isAboutYou,
      'is_professional_services': isProfessionalServices,
      'is_qualification': isQualification,
      'is_notification': isNotification,
      'is_payment': isPayment,
      'review_milestones': reviewMilestones,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      '__v': v,
      'is_online': isOnline,
      'promo_code_used_type': promoCodeUsedType,
      'promo_code_used_at': promoCodeUsedAt,
      'promo_code_used': promoCodeUsed,
      'opt_status': optStatus,
      'stripe_connect_charges_enabled': stripeConnectChargesEnabled,
      'stripe_connect_payouts_enabled': stripeConnectPayoutsEnabled,
      'stripe_connect_status': stripeConnectStatus,
      'address': address,
      'dob': dob,
      'gender': gender,
      'latitude': latitude,
      'longitude': longitude,
      'postcode': postcode,
      'last_seen_at': lastSeenAt,
      'fcm_token': fcmToken,
    };
  }
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

bool? _asBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value.toString().toLowerCase().trim();
  if (normalized == 'true') return true;
  if (normalized == 'false') return false;
  return null;
}
