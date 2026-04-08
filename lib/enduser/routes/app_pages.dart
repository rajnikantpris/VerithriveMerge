import 'package:flutter/animation.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/screens/appointment/AppointmentBinding.dart';
import 'package:verithrive_dev/enduser/screens/appointment/AppointmentBookingScreen.dart';
import 'package:verithrive_dev/enduser/screens/cart/CartScreen.dart';
import 'package:verithrive_dev/enduser/screens/change_password/ChangePasswordBinding.dart';
import 'package:verithrive_dev/enduser/screens/change_password/ChangePasswordScreen.dart';
import 'package:verithrive_dev/enduser/screens/consultation/ConsultationBinding.dart';
import 'package:verithrive_dev/enduser/screens/consultation/ConsultationBookingScreen.dart';
import 'package:verithrive_dev/enduser/screens/create_password/CreatePasswordBinding.dart';
import 'package:verithrive_dev/enduser/screens/create_password/CreatePasswordView.dart';
import 'package:verithrive_dev/enduser/screens/filter/FilterBinding.dart';
import 'package:verithrive_dev/enduser/screens/filter/FilterScreen.dart';
import 'package:verithrive_dev/enduser/screens/filter/availability/AvailabilityBinding.dart';
import 'package:verithrive_dev/enduser/screens/filter/availability/AvailabilityFilterScreen.dart';
import 'package:verithrive_dev/enduser/screens/filter/distance/DistanceBinding.dart';
import 'package:verithrive_dev/enduser/screens/filter/distance/DistanceFilterScreen.dart';
import 'package:verithrive_dev/enduser/screens/filter/gender/GenderBinding.dart';
import 'package:verithrive_dev/enduser/screens/filter/price/PriceBinding.dart';
import 'package:verithrive_dev/enduser/screens/filter/price/PriceFilterScreen.dart';
import 'package:verithrive_dev/enduser/screens/filter/professional/ProfessionalBinding.dart';
import 'package:verithrive_dev/enduser/screens/filter/professional/ProfessionalFilterScreen.dart';
import 'package:verithrive_dev/enduser/screens/fitness_goal/FitnessGoalBinding.dart';
import 'package:verithrive_dev/enduser/screens/fitness_goal/FitnessGoalScreen.dart';
import 'package:verithrive_dev/enduser/screens/login/LoginBinding.dart';
import 'package:verithrive_dev/enduser/screens/login/LoginView.dart';
import 'package:verithrive_dev/enduser/screens/notification/NotificationBinding.dart';
import 'package:verithrive_dev/enduser/screens/notification/NotificationScreen.dart';
import 'package:verithrive_dev/enduser/screens/nutrition_goal/NutritionGoalBinding.dart';
import 'package:verithrive_dev/enduser/screens/nutrition_goal/NutritionGoalScreen.dart';
import 'package:verithrive_dev/enduser/screens/otp/OTPBinding.dart';
import 'package:verithrive_dev/enduser/screens/otp/OTPView.dart';
import 'package:verithrive_dev/enduser/screens/payment/PaymentMethodBinding.dart';
import 'package:verithrive_dev/enduser/screens/payment/PaymentMethodScreen.dart';
import 'package:verithrive_dev/enduser/screens/payment_success/PaymentSuccessBinding.dart';
import 'package:verithrive_dev/enduser/screens/payment_success/PaymentSuccessScreen.dart';
import 'package:verithrive_dev/enduser/screens/profile/ProfileBinding.dart';
import 'package:verithrive_dev/enduser/screens/profile/ProfileView.dart';
import 'package:verithrive_dev/enduser/screens/register/RegisterView.dart';
import 'package:verithrive_dev/enduser/screens/register/register_binding.dart';
import 'package:verithrive_dev/enduser/screens/term_condition/TermsConditionBinding.dart';
import 'package:verithrive_dev/enduser/screens/term_condition/TermsView.dart';
import 'package:verithrive_dev/enduser/screens/therapy_details/TherapyDetailBinding.dart';
import 'package:verithrive_dev/enduser/screens/therapy_list/TherapistListingScreen.dart';
import 'package:verithrive_dev/enduser/screens/therapy_list/TherapyBinding.dart';
import 'package:verithrive_dev/enduser/screens/trainer_preference/TrainerPreferenceBinding.dart';
import 'package:verithrive_dev/enduser/screens/trainer_preference/TrainerPreferenceScreen.dart';
import 'package:verithrive_dev/professional/forgot_password/forgot_password_binding.dart';
import 'package:verithrive_dev/professional/forgot_password/forgot_password_view.dart';
import '../screens/cart/CartBinding.dart';
import '../screens/transaction_summary/TransactionSummaryBinding.dart';
import '../screens/transaction_summary/TransactionSummaryScreen.dart';
import '../screens/select_address/SelectAddressMapBinding.dart';
import '../screens/select_address/SelectAddressMapView.dart';
import '../screens/summary/SummaryScreen.dart';
import '../screens/summary/SummaryBinding.dart';
import '../screens/filter/gender/GenderFilterScreen.dart';
import '../screens/home/home_screen.dart';
import '../screens/main/MainScreen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/onboarding/onboarding_binding.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/splash/splash_binding.dart';
import '../screens/therapy_details/TherapistDetailScreen.dart';
import '../screens/sort/SortScreen.dart';
import '../screens/sort/SortBinding.dart';
import '../screens/message/ChatDetailScreen.dart';
import '../screens/message/ChatDetailBinding.dart';
import 'app_routes.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
      binding: OnboardingBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),

    GetPage(
      name: AppRoutes.register,
      page: () =>  RegisterView(),
      binding: RegisterBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),

    GetPage(
      name: AppRoutes.otp,
      page: () =>  OTPView(),
      binding: OTPBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),

    GetPage(
      name: AppRoutes.profile,
      page: () =>  ProfileView(),
      binding: ProfileBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),

    GetPage(
      name: AppRoutes.terms_conditions,
      page: () =>  TermsView(),
      binding: TermsConditionsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),

    GetPage(
      name: AppRoutes.login,
      page: () =>  LoginView(),
      binding: LoginBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),
    GetPage(
      name: AppRoutes.forgot_password,
      page: () =>  ForgotPasswordView(),
      binding: ForgotPasswordBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),
    GetPage(
      name: AppRoutes.create_password,
      page: () =>  CreatePasswordView(),
      binding: CreatePasswordBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),

    GetPage(
      name: AppRoutes.main,
      page: () => MainScreen(),
      transition: Transition.rightToLeft,
      transitionDuration:  Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),

    GetPage(
      name: AppRoutes.appointment,
      page: () => AppointmentBookingScreen(),
      binding: AppointmentBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),

    GetPage(
      name: AppRoutes.notification,
      page: () => NotificationScreen(),
      binding: NotificationBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),

    GetPage(
      name: AppRoutes.therapy_list,
      page: () => TherapistListingScreen(),
      binding: TherapyBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),

    GetPage(
      name: AppRoutes.therapy_detail,
      page: () => TherapistDetailScreen(),
      binding: TherapyDetailBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),

    GetPage(
      name: AppRoutes.consultation_booking,
      page: () => ConsultationBookingScreen(),
      binding: ConsultationBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),

    GetPage(
      name: AppRoutes.cart,
      page: () => CartScreen(),
      binding: CartBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),

    GetPage(
      name: AppRoutes.summary,
      page: () => SummaryScreen(),
      binding: SummaryBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),

    GetPage(
      name: AppRoutes.payment,
      page: () => PaymentMethodScreen(),
      binding: PaymentMethodBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),

    GetPage(
      name: AppRoutes.payment_success,
      page: () => PaymentSuccessScreen(),
      binding: PaymentSuccessBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),

    GetPage(
      name: AppRoutes.therapy_filter,
      page: () => const FilterScreen(),
      binding: FilterBinding(),
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    ),

    GetPage(
      name: AppRoutes.sort,
      page: () => const SortScreen(),
      binding: SortBinding(),
      transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),

    GetPage(
      name: AppRoutes.professional_filter,
      page: () =>  ProfessionalFilterScreen(),
      binding: ProfessionalBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),

    GetPage(
      name: AppRoutes.price_filter,
      page: () =>  PriceFilterScreen(),
      binding: PriceBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),

    GetPage(
      name: AppRoutes.gender_filter,
      page: () =>  GenderFilterScreen(),
      binding: GenderBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),

    GetPage(
      name: AppRoutes.distance_filter,
      page: () =>  DistanceFilterScreen(),
      binding: DistanceBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),



    GetPage(
      name: AppRoutes.availability_filter,
      page: () =>  AvailabilityFilterScreen(),
      binding: AvailabilityBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),

    GetPage(
      name: AppRoutes.fitness_goal,
      page: () => const FitnessGoalScreen(),
      binding: FitnessGoalBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),

    GetPage(
      name: AppRoutes.trainer_preference,
      page: () => const TrainerPreferenceScreen(),
      binding: TrainerPreferenceBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),

    GetPage(
      name: AppRoutes.nutrition_goal,
      page: () => const NutritionGoalScreen(),
      binding: NutritionGoalBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),


    GetPage(
      name: AppRoutes.change_password,
      page: () =>  ChangePasswordScreen(),
      binding: ChangePasswordBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),

    GetPage(
      name: AppRoutes.selectAddressMap,
      page: () =>  SelectAddressMapView(),
      binding: SelectAddressMapBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),

    GetPage(
      name: AppRoutes.chat_detail,
      page: () => ChatDetailScreen(),
      binding: ChatDetailBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),

    GetPage(
      name: AppRoutes.transaction_summary,
      page: () => const TransactionSummaryScreen(),
      binding: TransactionSummaryBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),

    GetPage(name: AppRoutes.home, page: () => const HomeScreen()),
  ];
}
