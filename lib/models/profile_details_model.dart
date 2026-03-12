class ProfileDetailsModel {
  final String? id;
  final String? professionTypeId;
  final String? professionSubTypeId;
  final String? fullName;
  final String? dob;
  final String? gender;
  final String? profilePicture;
  final bool? isProfileCreated;
  final int? optStatus;

  // Additional fields from get-profile-details API
  final String? timezone;
  final String? email;
  final String? emailVerifiedAt;
  final bool? isEmailVerified;
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
  final bool? isDeleted;
  final bool? isPersonalDetails;
  final bool? isTermCondition;
  final bool? isWorkFull;
  final int? tokenVersion;
  final bool? isPersonalIdentification;
  final bool? isAboutYou;
  final bool? isProfessionalServices;
  final bool? isQualification;
  final bool? isNotification;
  final bool? isPayment;
  final String? createdAt;
  final String? updatedAt;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? postcode;
  final String? description;
  final String? lastLoginAt;
  final String? approvedAt;
  final String? fcmToken;
  final bool? isEmailHidden;
  final String? deletedAt;

  const ProfileDetailsModel({
    this.id,
    this.professionTypeId,
    this.professionSubTypeId,
    this.fullName,
    this.dob,
    this.gender,
    this.profilePicture,
    this.isProfileCreated,
    this.optStatus,
    this.timezone,
    this.email,
    this.emailVerifiedAt,
    this.isEmailVerified,
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
    this.isDeleted,
    this.isPersonalDetails,
    this.isTermCondition,
    this.isWorkFull,
    this.tokenVersion,
    this.isPersonalIdentification,
    this.isAboutYou,
    this.isProfessionalServices,
    this.isQualification,
    this.isNotification,
    this.isPayment,
    this.createdAt,
    this.updatedAt,
    this.address,
    this.latitude,
    this.longitude,
    this.postcode,
    this.description,
    this.lastLoginAt,
    this.approvedAt,
    this.fcmToken,
    this.isEmailHidden,
    this.deletedAt,
  });

  factory ProfileDetailsModel.fromJson(Map<String, dynamic> json) =>
      ProfileDetailsModel(
        id: json['_id'] as String?,
        professionTypeId: json['profession_type_id'] as String? ??
            json['profession_type'] as String?,
        professionSubTypeId: json['profession_sub_type_id'] as String? ??
            json['profession_sub_type'] as String?,
        fullName: json['full_name'] as String?,
        dob: json['dob'] as String?,
        gender: json['gender'] as String?,
        profilePicture: json['profile_picture'] as String?,
        isProfileCreated: json['is_profile_created'] as bool?,
        optStatus: _parseOptStatus(json['opt_status']),
        timezone: json['timezone'] as String?,
        email: json['email'] as String?,
        emailVerifiedAt: json['email_verified_at'] as String?,
        isEmailVerified: json['is_email_verified'] as bool?,
        mobileNumber: json['mobile_number'] as String?,
        userType: json['user_type'] as String?,
        totalExperience: json['total_experience'] as int?,
        isOtpVerified: json['is_otp_verified'] as bool?,
        isActive: json['is_active'] as bool?,
        isApproved: json['is_approved'] as bool?,
        isOnHold: json['is_on_hold'] as bool?,
        isDeclined: json['is_declined'] as bool?,
        isBlocked: json['is_blocked'] as bool?,
        isSocialLogin: json['is_social_login'] as bool?,
        isDeleted: json['is_deleted'] as bool?,
        isPersonalDetails: json['is_personal_details'] as bool?,
        isTermCondition: json['is_term_condition'] as bool?,
        isWorkFull: json['is_work_full'] as bool?,
        tokenVersion: json['token_version'] as int?,
        isPersonalIdentification: json['is_personal_identification'] as bool?,
        isAboutYou: json['is_about_you'] as bool?,
        isProfessionalServices: json['is_professional_services'] as bool?,
        isQualification: json['is_qualification'] as bool?,
        isNotification: json['is_notification'] as bool?,
        isPayment: json['is_payment'] as bool?,
        createdAt: json['createdAt'] as String?,
        updatedAt: json['updatedAt'] as String?,
        address: json['address'] as String?,
        latitude: json['latitude'] as double?,
        longitude: json['longitude'] as double?,
        postcode: json['postcode'] as String?,
        description: json['description'] as String?,
        lastLoginAt: json['last_login_at'] as String?,
        approvedAt: json['approved_at'] as String?,
        fcmToken: json['fcm_token'] as String?,
        isEmailHidden: json['is_email_hidden'] as bool?,
        deletedAt: json['deleted_at'] as String?,
      );

  static int? _parseOptStatus(dynamic optStatus) {
    if (optStatus is int) {
      return optStatus;
    }
    if (optStatus is bool) {
      return optStatus ? 1 : 0;
    }
    return null;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (professionTypeId != null) 'profession_type_id': professionTypeId,
        if (professionSubTypeId != null)
          'profession_sub_type_id': professionSubTypeId,
        if (fullName != null) 'full_name': fullName,
        if (dob != null) 'dob': dob,
        if (gender != null) 'gender': gender,
        if (isProfileCreated != null) 'is_profile_created': isProfileCreated,
        if (timezone != null) 'timezone': timezone,
        if (email != null) 'email': email,
        if (mobileNumber != null) 'mobile_number': mobileNumber,
        if (address != null) 'address': address,
        if (postcode != null) 'postcode': postcode,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (profilePicture != null) 'profile_picture': profilePicture,
        if (description != null) 'description': description,
      };
}
