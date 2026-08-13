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
  final List<dynamic>? reviewMilestones;
  final bool? isOnline;
  final String? promoCodeUsedType;
  final String? promoCodeUsedAt;
  final String? promoCodeUsed;
  final String? createdAt;
  final String? updatedAt;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? postcode;
  final String? description;
  final String? lastProfessionalQualificationNotificationAt;
  final String? lastProfessionalOnboardingNudgeNotificationAt;
  final String? lastSeenAt;
  final String? lastLoginAt;
  final String? approvedAt;
  final String? lastProfessionalOnboardingNotificationAt;
  final String? lastProfessionalAvailabilityNotificationAt;
  final String? lastProfessionalCompletionMilestoneNotificationAt;
  final String? fcmToken;
  final bool? isEmailHidden;
  final String? deletedAt;
  final String? stripeCustomerId;
  final bool? stripeConnectChargesEnabled;
  final bool? stripeConnectPayoutsEnabled;
  final String? stripeConnectStatus;
  final String? stripeConnectAccountId;
  final String? onboardingLink;
  final String? stripeDetailsConnectStatus;
  final String? profession_name;
  final String? profession_sub_name;
  final bool? stripeDetailsConnectChargesEnabled;
  final bool? stripeDetailsConnectPayoutsEnabled;
  final String? stripeDetailsConnectAccountId;
  final String? stripeDetailsOnboardingLink;
  final bool? hasServiceFormatToday;
  final bool? hasAvailabilityToday;
  final bool? isSubscription;
  final String? registrationType;
  final String? planNameSnapshot;

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
    this.profession_name,
    this.profession_sub_name,
    this.reviewMilestones,
    this.isOnline,
    this.promoCodeUsedType,
    this.promoCodeUsedAt,
    this.promoCodeUsed,
    this.createdAt,
    this.updatedAt,
    this.address,
    this.latitude,
    this.longitude,
    this.postcode,
    this.description,
    this.lastProfessionalQualificationNotificationAt,
    this.lastProfessionalOnboardingNudgeNotificationAt,
    this.lastSeenAt,
    this.lastLoginAt,
    this.approvedAt,
    this.lastProfessionalOnboardingNotificationAt,
    this.lastProfessionalAvailabilityNotificationAt,
    this.lastProfessionalCompletionMilestoneNotificationAt,
    this.fcmToken,
    this.isEmailHidden,
    this.deletedAt,
    this.stripeCustomerId,
    this.stripeConnectChargesEnabled,
    this.stripeConnectPayoutsEnabled,
    this.stripeConnectStatus,
    this.stripeConnectAccountId,
    this.onboardingLink,
    this.stripeDetailsConnectStatus,
    this.stripeDetailsConnectChargesEnabled,
    this.stripeDetailsConnectPayoutsEnabled,
    this.stripeDetailsConnectAccountId,
    this.stripeDetailsOnboardingLink,
    this.hasServiceFormatToday,
    this.hasAvailabilityToday,
    this.isSubscription,
    this.registrationType,
    this.planNameSnapshot,
  });

  factory ProfileDetailsModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map<String, dynamic>)
        ? (json['data'] as Map<String, dynamic>)
        : json;
    final stripeDetails = data['stripeDetails'] as Map<String, dynamic>?;

    return ProfileDetailsModel(
      id: data['_id'] as String?,
      professionTypeId: data['profession_type_id'] as String? ??
          data['profession_type'] as String?,
      professionSubTypeId: data['profession_sub_type_id'] as String? ??
          data['profession_sub_type'] as String?,
      fullName: data['full_name'] as String?,
      dob: data['dob']?.toString(),
      gender: data['gender'] as String?,
      profilePicture: _cleanWrappedString(data['profile_picture']),
      isProfileCreated: data['is_profile_created'] as bool?,
      optStatus: _parseOptStatus(data['opt_status']),
      timezone: data['timezone'] as String?,
      email: data['email'] as String?,
      emailVerifiedAt: data['email_verified_at']?.toString(),
      isEmailVerified: data['is_email_verified'] as bool?,
      mobileNumber: data['mobile_number'] as String?,
      userType: data['user_type'] as String?,
      totalExperience: (data['total_experience'] as num?)?.toInt(),
      isOtpVerified: data['is_otp_verified'] as bool?,
      isActive: data['is_active'] as bool?,
      isApproved: data['is_approved'] as bool?,
      isOnHold: data['is_on_hold'] as bool?,
      isDeclined: data['is_declined'] as bool?,
      isBlocked: data['is_blocked'] as bool?,
      isSocialLogin: data['is_social_login'] as bool?,
      isDeleted: data['is_deleted'] as bool?,
      isPersonalDetails: data['is_personal_details'] as bool?,
      isTermCondition: data['is_term_condition'] as bool?,
      isWorkFull: data['is_work_full'] as bool?,
      tokenVersion: (data['token_version'] as num?)?.toInt(),
      isPersonalIdentification: data['is_personal_identification'] as bool?,
      isAboutYou: data['is_about_you'] as bool?,
      isProfessionalServices: data['is_professional_services'] as bool?,
      isQualification: data['is_qualification'] as bool?,
      isNotification: data['is_notification'] as bool?,
      isPayment: data['is_payment'] as bool?,
      reviewMilestones: data['review_milestones'] as List<dynamic>?,
      isOnline: data['is_online'] as bool?,
      promoCodeUsedType: data['promo_code_used_type'] as String?,
      promoCodeUsedAt: data['promo_code_used_at']?.toString(),
      promoCodeUsed: data['promo_code_used'] as String?,
      profession_name: data['profession_name'] as String?,
      profession_sub_name: data['profession_sub_name'] as String?,
      createdAt: data['createdAt']?.toString(),
      updatedAt: data['updatedAt']?.toString(),
      address: data['address'] as String?,
      latitude: _parseDouble(data['latitude']),
      longitude: _parseDouble(data['longitude']),
      postcode: data['postcode'] as String?,
      description: data['description'] as String?,
      lastProfessionalQualificationNotificationAt:
          data['last_professional_qualification_notification_at']?.toString(),
      lastProfessionalOnboardingNudgeNotificationAt:
          data['last_professional_onboarding_nudge_notification_at']
              ?.toString(),
      lastSeenAt: data['last_seen_at']?.toString(),
      lastLoginAt: data['last_login_at']?.toString(),
      approvedAt: data['approved_at']?.toString(),
      lastProfessionalOnboardingNotificationAt:
          data['last_professional_onboarding_notification_at']?.toString(),
      lastProfessionalAvailabilityNotificationAt:
          data['last_professional_availability_notification_at']?.toString(),
      lastProfessionalCompletionMilestoneNotificationAt:
          data['last_professional_completion_milestone_notification_at']
              ?.toString(),
      fcmToken: data['fcm_token'] as String?,
      isEmailHidden: data['is_email_hidden'] as bool?,
      deletedAt: data['deleted_at']?.toString(),
      stripeCustomerId: data['stripe_customer_id'] as String?,
      stripeConnectChargesEnabled: data['stripe_connect_charges_enabled'] as bool?,
      stripeConnectPayoutsEnabled: data['stripe_connect_payouts_enabled'] as bool?,
      stripeConnectStatus: _cleanWrappedString(data['stripe_connect_status']),
      stripeConnectAccountId: data['stripe_connect_account_id'] as String?,
      onboardingLink: _cleanWrappedString(
        stripeDetails?['onboarding_link'] ?? data['onboarding_link'],
      ),
      stripeDetailsConnectStatus:
          _cleanWrappedString(stripeDetails?['stripe_connect_status']),
      stripeDetailsConnectChargesEnabled:
          stripeDetails?['stripe_connect_charges_enabled'] as bool?,
      stripeDetailsConnectPayoutsEnabled:
          stripeDetails?['stripe_connect_payouts_enabled'] as bool?,
      stripeDetailsConnectAccountId:
          stripeDetails?['stripe_connect_account_id'] as String?,
      stripeDetailsOnboardingLink:
          _cleanWrappedString(stripeDetails?['onboarding_link']),
      hasServiceFormatToday: data['has_service_format_today'] as bool?,
      hasAvailabilityToday: data['has_availability_today'] as bool?,
      isSubscription: data['is_subscription'] as bool?,
      registrationType: data['registration_type'] as String?,
      planNameSnapshot: _planNameSnapshotFrom(data['subscription']),
    );
  }

  static int? _parseOptStatus(dynamic optStatus) {
    if (optStatus is int) {
      return optStatus;
    }
    if (optStatus is bool) {
      return optStatus ? 1 : 0;
    }
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String? _cleanWrappedString(dynamic value) {
    final raw = value?.toString();
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final withoutTicks = trimmed.replaceAll('`', '').trim();
    return withoutTicks.isEmpty ? null : withoutTicks;
  }

  static String? _planNameSnapshotFrom(dynamic subscription) {
    if (subscription is! Map<String, dynamic>) return null;
    final snapshot = subscription['plan_name_snapshot']?.toString().trim();
    if (snapshot != null && snapshot.isNotEmpty) return snapshot;
    final nested = subscription['subscription_id'];
    if (nested is Map<String, dynamic>) {
      final planName = nested['plan_name']?.toString().trim();
      if (planName != null && planName.isNotEmpty) return planName;
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
        if (stripeCustomerId != null) 'stripe_customer_id': stripeCustomerId,
        if (stripeConnectChargesEnabled != null)
          'stripe_connect_charges_enabled': stripeConnectChargesEnabled,
        if (stripeConnectPayoutsEnabled != null)
          'stripe_connect_payouts_enabled': stripeConnectPayoutsEnabled,
        if (stripeConnectStatus != null)
          'stripe_connect_status': stripeConnectStatus,
        if (stripeConnectAccountId != null)
          'stripe_connect_account_id': stripeConnectAccountId,
        if (onboardingLink != null) 'onboarding_link': onboardingLink,
        if (stripeDetailsConnectStatus != null ||
            stripeDetailsConnectChargesEnabled != null ||
            stripeDetailsConnectPayoutsEnabled != null ||
            stripeDetailsConnectAccountId != null ||
            stripeDetailsOnboardingLink != null)
          'stripeDetails': <String, dynamic>{
            if (stripeDetailsConnectStatus != null)
              'stripe_connect_status': stripeDetailsConnectStatus,
            if (stripeDetailsConnectChargesEnabled != null)
              'stripe_connect_charges_enabled': stripeDetailsConnectChargesEnabled,
            if (stripeDetailsConnectPayoutsEnabled != null)
              'stripe_connect_payouts_enabled': stripeDetailsConnectPayoutsEnabled,
            if (stripeDetailsConnectAccountId != null)
              'stripe_connect_account_id': stripeDetailsConnectAccountId,
            if (stripeDetailsOnboardingLink != null)
              'onboarding_link': stripeDetailsOnboardingLink,
          },
        if (hasServiceFormatToday != null)
          'has_service_format_today': hasServiceFormatToday,
        if (hasAvailabilityToday != null)
          'has_availability_today': hasAvailabilityToday,
        if (isSubscription != null)
          'is_subscription': isSubscription,
        if (registrationType != null)
          'registration_type': registrationType,
        if (planNameSnapshot != null)
          'plan_name_snapshot': planNameSnapshot,
      };
}
