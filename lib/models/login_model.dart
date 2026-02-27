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
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id']?.toString(),
      timezone: json['timezone']?.toString(),
      email: json['email']?.toString(),
      fullName: json['full_name']?.toString(),
      profilePicture: json['profile_picture']?.toString(),
      emailVerifiedAt: json['email_verified_at']?.toString(),
      isEmailVerified: json['is_email_verified'] as bool?,
      isEmailHidden: json['is_email_hidden'] as bool?,
      mobileNumber: json['mobile_number']?.toString(),
      userType: json['user_type']?.toString(),
      totalExperience: json['total_experience'] as int?,
      isOtpVerified: json['is_otp_verified'] as bool?,
      isActive: json['is_active'] as bool?,
      isApproved: json['is_approved'] as bool?,
      isOnHold: json['is_on_hold'] as bool?,
      isDeclined: json['is_declined'] as bool?,
      isBlocked: json['is_blocked'] as bool?,
      isSocialLogin: json['is_social_login'] as bool?,
      socialType: json['social_type']?.toString(),
      socialId: json['social_id']?.toString(),
      registrationType: json['registration_type']?.toString(),
      isDeleted: json['is_deleted'] as bool?,
      lastLoginAt: json['last_login_at']?.toString(),
      lastLoginEmail: json['last_login_email']?.toString(),
      lastLoginType: json['last_login_type']?.toString(),
      isPersonalDetails: json['is_personal_details'] as bool?,
      isTermCondition: json['is_term_condition'] as bool?,
      isProfileCreated: json['is_profile_created'] as bool?,
      isWorkFull: json['is_work_full'] as bool?,
      tokenVersion: json['token_version'] as int?,
      isPersonalIdentification: json['is_personal_identification'] as bool?,
      isAboutYou: json['is_about_you'] as bool?,
      isProfessionalServices: json['is_professional_services'] as bool?,
      isQualification: json['is_qualification'] as bool?,
      isNotification: json['is_notification'] as bool?,
      isPayment: json['is_payment'] as bool?,
      reviewMilestones: json['review_milestones'] as List<dynamic>?,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      v: json['__v'] as int?,
      isOnline: json['is_online'] as bool?,
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
    };
  }
}

