class LoginResponseModel {
  final bool? success;
  final String? message;
  final String? token;
  final UserModel? user;

  const LoginResponseModel({
    this.success,
    this.message,
    this.token,
    this.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    // Your API returns:
    // { success, message, data: { token, user: {...} } }
    // But some callers may still pass { token, user } directly.
    final dataNode = json['data'];
    final Map<String, dynamic>? dataMap =
        dataNode is Map<String, dynamic> ? dataNode : null;

    final dynamic tokenNode = dataMap?['token'] ?? json['token'];
    final dynamic userNode = dataMap?['user'] ?? json['user'];

    return LoginResponseModel(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      token: tokenNode is String ? tokenNode : null,
      user: userNode is Map<String, dynamic>
          ? UserModel.fromJson(userNode)
          : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (success != null) 'success': success,
        if (message != null) 'message': message,
        if (token != null) 'token': token,
        if (user != null) 'user': user!.toJson(),
      };
}

class UserModel {
  final String? id;
  final String? email;
  final String? fullName;
  final String? profilePicture;
  final String? timezone;
  final String? emailVerifiedAt;
  final bool? isEmailVerified;
  final bool? isEmailHidden;
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
  final int? tokenVersion;
  final bool? isPersonalDetails;
  final bool? isTermCondition;
  final bool? isProfileCreated;
  final bool? isWorkFull;
  final bool? isProfessionalServices;
  final bool? isQualification;
  final bool? isPersonalIdentification;
  final bool? isAboutYou;
  final bool? isNotification;
  final bool? isPayment;
  final String? mobileNumber;
  final String? createdAt;
  final String? profession_name;
  final String? profession_sub_name;
  final String? updatedAt;
  final String? lastLoginEmail;
  final String? lastLoginType;

  // Extra fields present in the latest login payload
  final String? promoCodeUsedType;
  final String? promoCodeUsedAt;
  final bool? promoCodeUsed;

  final String? fcmToken;
  final bool? isOnline;
  final String? lastSeenAt;

  final String? address;
  final String? dob;
  final String? gender;
  final String? postcode;
  final double? latitude;
  final double? longitude;

  final bool? optStatus;

  final bool? stripeConnectChargesEnabled;
  final bool? stripeConnectPayoutsEnabled;
  final String? stripeConnectStatus;
  final String? stripeConnectAccountId;
  final String? stripeCustomerId;

  final List<dynamic>? reviewMilestones;

  final String? description;
  final String? approvedAt;

  final String? lastProfessionalQualificationNotificationAt;
  final String? lastProfessionalCompletionMilestoneNotificationAt;
  final String? lastProfessionalOnboardingNotificationAt;
  final String? lastProfessionalAvailabilityNotificationAt;

  const UserModel({
    this.id,
    this.email,
    this.fullName,
    this.profilePicture,
    this.timezone,
    this.emailVerifiedAt,
    this.isEmailVerified,
    this.isEmailHidden,
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
    this.tokenVersion,
    this.isPersonalDetails,
    this.isTermCondition,
    this.profession_sub_name,
    this.profession_name,
    this.isProfileCreated,
    this.isWorkFull,
    this.isProfessionalServices,
    this.isQualification,
    this.isPersonalIdentification,
    this.isAboutYou,
    this.isNotification,
    this.isPayment,
    this.mobileNumber,
    this.createdAt,
    this.updatedAt,
    this.lastLoginEmail,
    this.lastLoginType,
    this.promoCodeUsedType,
    this.promoCodeUsedAt,
    this.promoCodeUsed,
    this.fcmToken,
    this.isOnline,
    this.lastSeenAt,
    this.address,
    this.dob,
    this.gender,
    this.postcode,
    this.latitude,
    this.longitude,
    this.optStatus,
    this.stripeConnectChargesEnabled,
    this.stripeConnectPayoutsEnabled,
    this.stripeConnectStatus,
    this.stripeConnectAccountId,
    this.stripeCustomerId,
    this.reviewMilestones,
    this.description,
    this.approvedAt,
    this.lastProfessionalQualificationNotificationAt,
    this.lastProfessionalCompletionMilestoneNotificationAt,
    this.lastProfessionalOnboardingNotificationAt,
    this.lastProfessionalAvailabilityNotificationAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['_id'] as String?,
        email: json['email'] as String?,
        fullName: json['full_name'] as String?,
        profilePicture: json['profile_picture'] as String?,
        timezone: json['timezone'] as String?,
        emailVerifiedAt: json['email_verified_at'] as String?,
        isEmailVerified: json['is_email_verified'] as bool?,
        isEmailHidden: json['is_email_hidden'] as bool?,
        userType: json['user_type'] as String?,
        totalExperience: json['total_experience'] as int?,
        isOtpVerified: json['is_otp_verified'] as bool?,
        isActive: json['is_active'] as bool?,
        isApproved: json['is_approved'] as bool?,
        isOnHold: json['is_on_hold'] as bool?,
        isDeclined: json['is_declined'] as bool?,
        isBlocked: json['is_blocked'] as bool?,
        isSocialLogin: json['is_social_login'] as bool?,
        socialType: json['social_type'] as String?,
        socialId: json['social_id'] as String?,
        registrationType: json['registration_type'] as String?,
        isDeleted: json['is_deleted'] as bool?,
        lastLoginAt: json['last_login_at'] as String?,
        tokenVersion: json['token_version'] as int?,
        isPersonalDetails: json['is_personal_details'] as bool?,
        isTermCondition: json['is_term_condition'] as bool?,
        isProfileCreated: json['is_profile_created'] as bool?,
        isWorkFull: json['is_work_full'] as bool?,
        isProfessionalServices: json['is_professional_services'] as bool?,
        isQualification: json['is_qualification'] as bool?,
        isPersonalIdentification: json['is_personal_identification'] as bool?,
        isAboutYou: json['is_about_you'] as bool?,
        isNotification: json['is_notification'] as bool?,
        isPayment: json['is_payment'] as bool?,
        mobileNumber: json['mobile_number'] as String?,
        createdAt: json['createdAt'] as String?,
        updatedAt: json['updatedAt'] as String?,
        lastLoginEmail: json['last_login_email'] as String?,
        lastLoginType: json['last_login_type'] as String?,
    profession_name: json['profession_name'] as String?,
    profession_sub_name: json['profession_sub_name'] as String?,
        promoCodeUsedType: json['promo_code_used_type'] as String?,
        promoCodeUsedAt: json['promo_code_used_at'] as String?,
        promoCodeUsed: _asBool(json['promo_code_used']),
        fcmToken: json['fcm_token'] as String?,
        isOnline: _asBool(json['is_online']),
        lastSeenAt: json['last_seen_at'] as String?,
        address: json['address'] as String?,
        dob: json['dob'] as String?,
        gender: json['gender'] as String?,
        postcode: json['postcode'] as String?,
        latitude: _asDouble(json['latitude']),
        longitude: _asDouble(json['longitude']),
        optStatus: _asBool(json['opt_status']),
        stripeConnectChargesEnabled:
            _asBool(json['stripe_connect_charges_enabled']),
        stripeConnectPayoutsEnabled:
            _asBool(json['stripe_connect_payouts_enabled']),
        stripeConnectStatus: json['stripe_connect_status'] as String?,
        stripeConnectAccountId: json['stripe_connect_account_id'] as String?,
        stripeCustomerId: json['stripe_customer_id'] as String?,
        reviewMilestones: json['review_milestones'] as List<dynamic>?,
        description: json['description'] as String?,
        approvedAt: json['approved_at'] as String?,
        lastProfessionalQualificationNotificationAt:
            json['last_professional_qualification_notification_at']
                as String?,
        lastProfessionalCompletionMilestoneNotificationAt:
            json['last_professional_completion_milestone_notification_at']
                as String?,
        lastProfessionalOnboardingNotificationAt:
            json['last_professional_onboarding_notification_at'] as String?,
        lastProfessionalAvailabilityNotificationAt:
            json['last_professional_availability_notification_at'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (id != null) '_id': id,
        if (email != null) 'email': email,
        if (fullName != null) 'full_name': fullName,
        if (profilePicture != null) 'profile_picture': profilePicture,
        if (timezone != null) 'timezone': timezone,
        if (emailVerifiedAt != null) 'email_verified_at': emailVerifiedAt,
        if (isEmailVerified != null) 'is_email_verified': isEmailVerified,
        if (isEmailHidden != null) 'is_email_hidden': isEmailHidden,
        if (userType != null) 'user_type': userType,
        if (totalExperience != null) 'total_experience': totalExperience,
        if (isOtpVerified != null) 'is_otp_verified': isOtpVerified,
        if (isActive != null) 'is_active': isActive,
        if (isApproved != null) 'is_approved': isApproved,
        if (isOnHold != null) 'is_on_hold': isOnHold,
        if (isDeclined != null) 'is_declined': isDeclined,
        if (isBlocked != null) 'is_blocked': isBlocked,
        if (isSocialLogin != null) 'is_social_login': isSocialLogin,
        if (socialType != null) 'social_type': socialType,
        if (socialId != null) 'social_id': socialId,
        if (registrationType != null) 'registration_type': registrationType,
        if (isDeleted != null) 'is_deleted': isDeleted,
        if (lastLoginAt != null) 'last_login_at': lastLoginAt,
        if (tokenVersion != null) 'token_version': tokenVersion,
        if (isPersonalDetails != null) 'is_personal_details': isPersonalDetails,
        if (isTermCondition != null) 'is_term_condition': isTermCondition,
        if (isProfileCreated != null) 'is_profile_created': isProfileCreated,
        if (isWorkFull != null) 'is_work_full': isWorkFull,
        if (isProfessionalServices != null)
          'is_professional_services': isProfessionalServices,
        if (isQualification != null) 'is_qualification': isQualification,
        if (isPersonalIdentification != null)
          'is_personal_identification': isPersonalIdentification,
        if (isAboutYou != null) 'is_about_you': isAboutYou,
        if (isNotification != null) 'is_notification': isNotification,
        if (isPayment != null) 'is_payment': isPayment,
        if (mobileNumber != null) 'mobile_number': mobileNumber,
        if (createdAt != null) 'createdAt': createdAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
        if (lastLoginEmail != null) 'last_login_email': lastLoginEmail,
        if (lastLoginType != null) 'last_login_type': lastLoginType,
        if (promoCodeUsedType != null) 'promo_code_used_type': promoCodeUsedType,
        if (promoCodeUsedAt != null) 'promo_code_used_at': promoCodeUsedAt,
        if (promoCodeUsed != null) 'promo_code_used': promoCodeUsed,
        if (fcmToken != null) 'fcm_token': fcmToken,
        if (isOnline != null) 'is_online': isOnline,
        if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
        if (address != null) 'address': address,
        if (dob != null) 'dob': dob,
        if (gender != null) 'gender': gender,
        if (postcode != null) 'postcode': postcode,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (optStatus != null) 'opt_status': optStatus,
        if (stripeConnectChargesEnabled != null)
          'stripe_connect_charges_enabled': stripeConnectChargesEnabled,
        if (stripeConnectPayoutsEnabled != null)
          'stripe_connect_payouts_enabled': stripeConnectPayoutsEnabled,
        if (stripeConnectStatus != null) 'stripe_connect_status': stripeConnectStatus,
        if (stripeConnectAccountId != null)
          'stripe_connect_account_id': stripeConnectAccountId,
        if (stripeCustomerId != null) 'stripe_customer_id': stripeCustomerId,
        if (reviewMilestones != null) 'review_milestones': reviewMilestones,
        if (description != null) 'description': description,
        if (approvedAt != null) 'approved_at': approvedAt,
        if (lastProfessionalQualificationNotificationAt != null)
          'last_professional_qualification_notification_at':
              lastProfessionalQualificationNotificationAt,
        if (lastProfessionalCompletionMilestoneNotificationAt != null)
          'last_professional_completion_milestone_notification_at':
              lastProfessionalCompletionMilestoneNotificationAt,
        if (lastProfessionalOnboardingNotificationAt != null)
          'last_professional_onboarding_notification_at':
              lastProfessionalOnboardingNotificationAt,
        if (lastProfessionalAvailabilityNotificationAt != null)
          'last_professional_availability_notification_at':
              lastProfessionalAvailabilityNotificationAt,
      };
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
