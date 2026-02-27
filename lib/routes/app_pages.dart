import 'package:get/get.dart';

import '../api/dio_client.dart';
import '../api/user_api_service.dart';
import '../professional/forgot_password/forgot_password_binding.dart';
import '../professional/forgot_password/forgot_password_view.dart';
import '../professional/login/login_binding.dart';
import '../professional/login/login_view.dart';
import '../professional/onboarding/onboarding_binding.dart';
import '../professional/onboarding/onboarding_view.dart';
import '../professional/create_new_password/create_new_password_binding.dart';
import '../professional/create_new_password/create_new_password_view.dart';
import '../professional/signup/signup_binding.dart';
import '../professional/signup/signup_view.dart';
import '../professional/signup_person_details/signup_person_details_binding.dart';
import '../professional/signup_person_details/signup_person_details_view.dart';
import '../professional/signup_terms_conditions/signup_terms_conditions_binding.dart';
import '../professional/signup_terms_conditions/signup_terms_conditions_view.dart';
import '../professional/signup_profile_wizard/signup_profile_wizard_binding.dart';
import '../professional/signup_profile_wizard/signup_profile_wizard_view.dart';
import '../professional/subscription/subscription_binding.dart';
import '../professional/subscription/subscription_view.dart';
import '../professional/payment_method/payment_method_binding.dart';
import '../professional/payment_method/payment_method_view.dart';
import '../professional/processing_payment/processing_payment_binding.dart';
import '../professional/processing_payment/processing_payment_view.dart';
import '../professional/verification/verification_binding.dart';
import '../professional/verification/verification_view.dart';
import '../professional/verify_email/verify_email_binding.dart';
import '../professional/verify_email/verify_email_view.dart';
import '../professional/home/chat/chat_binding.dart';
import '../professional/home/chat/chat_view.dart';
import '../professional/home/home_binding.dart';
import '../professional/home/home_view.dart';
import '../professional/home/profile/yourprofile/yourprofile_binding.dart';
import '../professional/home/profile/yourprofile/yourprofile_view.dart';
import '../professional/home/profile/personal_details/personal_details_binding.dart';
import '../professional/home/profile/personal_details/personal_details_view.dart';
import '../professional/home/profile/address/address_binding.dart';
import '../professional/home/profile/address/address_view.dart';
import '../professional/home/profile/your_services/your_services_binding.dart';
import '../professional/home/profile/your_services/your_services_view.dart';
import '../professional/home/profile/personal_identification/personal_identification_binding.dart';
import '../professional/home/profile/personal_identification/personal_identification_view.dart';
import '../professional/home/profile/about_you/about_you_binding.dart';
import '../professional/home/profile/about_you/about_you_view.dart';
import '../professional/home/profile/qualification_certification/qualification_certification_binding.dart';
import '../professional/home/profile/qualification_certification/qualification_certification_view.dart';
import '../professional/home/profile/bank_account/bank_account_binding.dart';
import '../professional/home/profile/bank_account/bank_account_view.dart';
import '../professional/home/profile/notification_settings/notification_settings_binding.dart';
import '../professional/home/profile/notification_settings/notification_settings_view.dart';
import '../professional/home/profile/account/account_binding.dart';
import '../professional/home/profile/account/account_view.dart';
import '../professional/home/profile/change_password/change_password_binding.dart';
import '../professional/home/profile/change_password/change_password_view.dart';
import '../professional/home/profile/profile_subscription/profile_subscription_binding.dart';
import '../professional/home/profile/profile_subscription/profile_subscription_view.dart';
import '../professional/home/reschedule_session/reschedule_session_binding.dart';
import '../professional/home/reschedule_session/reschedule_session_view.dart';
import '../professional/home/service_format/service_format_binding.dart';
import '../professional/home/service_format/service_format_view.dart';
import '../professional/home/service_format/add_service_format_binding.dart';
import '../professional/home/service_format/add_service_format_view.dart';
import '../professional/home/service_format/edit_service_format_binding.dart';
import '../professional/home/service_format/edit_service_format_view.dart';
import '../professional/home/create_availability/create_availability_binding.dart';
import '../professional/home/create_availability/create_availability_view.dart';
import '../professional/home/create_availability/edit_availability_binding.dart';
import '../professional/home/create_availability/edit_availability_view.dart';
import '../professional/splash/splash_binding.dart';
import '../professional/splash/splash_view.dart';
import '../professional/notification/notification_binding.dart';
import '../professional/notification/notification_view.dart';
import '../professional/select_address_map/select_address_map_binding.dart';
import '../professional/select_address_map/select_address_map_view.dart';
import '../select_user/select_user_binding.dart';
import '../select_user/select_user_view.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import 'app_routes.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.putAsync<StorageService>(
      () => StorageService().init(),
      permanent: true,
    );
    Get.put(DioClient(), permanent: true);
    Get.put(UserApiService(Get.find<DioClient>()), permanent: true);
    Get.put(NotificationService(), permanent: true);
  }
}

class AppPages {
  AppPages._();

  static const initial = Routes.splash;
  static final initialBinding = AppBinding();

  static final routes = <GetPage>[
    GetPage<SplashBinding>(
      name: Routes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage<SelectUserBinding>(
      name: Routes.selectUser,
      page: () => const SelectUserView(),
      binding: SelectUserBinding(),
    ),
    GetPage<LoginBinding>(
      name: Routes.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage<ForgotPasswordBinding>(
      name: Routes.forgotPassword,
      page: () => const ForgotPasswordView(),
      binding: ForgotPasswordBinding(),
    ),
    GetPage<SignupBinding>(
      name: Routes.signup,
      page: () => const SignupView(),
      binding: SignupBinding(),
    ),
    GetPage<VerifyEmailBinding>(
      name: Routes.verifyEmail,
      page: () => const VerifyEmailView(),
      binding: VerifyEmailBinding(),
    ),
    GetPage<CreateNewPasswordBinding>(
      name: Routes.createNewPassword,
      page: () => const CreateNewPasswordView(),
      binding: CreateNewPasswordBinding(),
    ),
    GetPage<SignupPersonDetailsBinding>(
      name: Routes.signupPersonDetails,
      page: () => const SignupPersonDetailsView(),
      binding: SignupPersonDetailsBinding(),
    ),
    GetPage<SignupTermsConditionsBinding>(
      name: Routes.signupTermsConditions,
      page: () => const SignupTermsConditionsView(),
      binding: SignupTermsConditionsBinding(),
    ),
    GetPage<SignupProfileWizardBinding>(
      name: Routes.signupProfileWizard,
      page: () => const SignupProfileWizardView(),
      binding: SignupProfileWizardBinding(),
    ),
    GetPage<SubscriptionBinding>(
      name: Routes.subscription,
      page: () => const SubscriptionView(),
      binding: SubscriptionBinding(),
    ),
    GetPage<PaymentMethodBinding>(
      name: Routes.paymentMethod,
      page: () => const PaymentMethodView(),
      binding: PaymentMethodBinding(),
    ),
    GetPage<ProcessingPaymentBinding>(
      name: Routes.processingPayment,
      page: () => const ProcessingPaymentView(),
      binding: ProcessingPaymentBinding(),
    ),
    GetPage<VerificationBinding>(
      name: Routes.verification,
      page: () => const VerificationView(),
      binding: VerificationBinding(),
    ),
    GetPage<NotificationBinding>(
      name: Routes.notifications,
      page: () => const NotificationView(),
      binding: NotificationBinding(),
    ),
    GetPage<ChatBinding>(
      name: Routes.chat,
      page: () => const ChatView(),
      binding: ChatBinding(),
    ),
    GetPage<HomeBinding>(
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage<YourProfileBinding>(
      name: Routes.yourProfile,
      page: () => const YourProfileView(),
      binding: YourProfileBinding(),
    ),
    GetPage<PersonalDetailsBinding>(
      name: Routes.personalDetails,
      page: () => const PersonalDetailsView(),
      binding: PersonalDetailsBinding(),
    ),
    GetPage<AddressBinding>(
      name: Routes.address,
      page: () => const AddressView(),
      binding: AddressBinding(),
    ),
    GetPage<YourServicesBinding>(
      name: Routes.yourServices,
      page: () => const YourServicesView(),
      binding: YourServicesBinding(),
    ),
    GetPage<PersonalIdentificationBinding>(
      name: Routes.personalIdentification,
      page: () => const PersonalIdentificationView(),
      binding: PersonalIdentificationBinding(),
    ),
    GetPage<AboutYouBinding>(
      name: Routes.aboutYou,
      page: () => const AboutYouView(),
      binding: AboutYouBinding(),
    ),
    GetPage<QualificationCertificationBinding>(
      name: Routes.qualificationCertification,
      page: () => const QualificationCertificationView(),
      binding: QualificationCertificationBinding(),
    ),
    GetPage<BankAccountBinding>(
      name: Routes.bankAccount,
      page: () => const BankAccountView(),
      binding: BankAccountBinding(),
    ),
    GetPage<NotificationSettingsBinding>(
      name: Routes.notificationSettings,
      page: () => const NotificationSettingsView(),
      binding: NotificationSettingsBinding(),
    ),
    GetPage<AccountBinding>(
      name: Routes.account,
      page: () => const AccountView(),
      binding: AccountBinding(),
    ),
    GetPage<ChangePasswordBinding>(
      name: Routes.changePassword,
      page: () => const ChangePasswordView(),
      binding: ChangePasswordBinding(),
    ),
    GetPage<ProfileSubscriptionBinding>(
      name: Routes.profileSubscription,
      page: () => const ProfileSubscriptionView(),
      binding: ProfileSubscriptionBinding(),
    ),
    GetPage<RescheduleSessionBinding>(
      name: Routes.rescheduleSession,
      page: () => const RescheduleSessionView(),
      binding: RescheduleSessionBinding(),
    ),
    GetPage<ServiceFormatBinding>(
      name: Routes.serviceFormat,
      page: () => const ServiceFormatView(),
      binding: ServiceFormatBinding(),
    ),
    GetPage<AddServiceFormatBinding>(
      name: Routes.addServiceFormat,
      page: () => const AddServiceFormatView(),
      binding: AddServiceFormatBinding(),
    ),
    GetPage<EditServiceFormatBinding>(
      name: Routes.editServiceFormat,
      page: () => const EditServiceFormatView(),
      binding: EditServiceFormatBinding(),
    ),
    GetPage<CreateAvailabilityBinding>(
      name: Routes.createAvailability,
      page: () => const CreateAvailabilityView(),
      binding: CreateAvailabilityBinding(),
    ),
    GetPage<EditAvailabilityBinding>(
      name: Routes.editAvailability,
      page: () => const EditAvailabilityView(),
      binding: EditAvailabilityBinding(),
    ),
    GetPage<SelectAddressMapBinding>(
      name: Routes.selectAddressMap,
      page: () => const SelectAddressMapView(),
      binding: SelectAddressMapBinding(),
    ),
  ];
}
