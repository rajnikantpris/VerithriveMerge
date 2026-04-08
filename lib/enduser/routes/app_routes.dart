class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String profile = '/profile';
  static const String terms_conditions = '/terms_conditions';
  static const String login = '/login';
  static const String forgot_password = '/forgot_password';
  static const String create_password = '/create_password';
  static const String main = '/main';
  static const String appointment = '/appointment';
  static const String notification = '/notification';
  static const String therapy_list = '/therapy_list';
  static const String therapy_detail = '/therapy_detail';
  static const String consultation_booking = '/consultation_booking';
  static const String cart = '/cart';
  static const String summary = '/summary';
  static const String payment = '/payment';
  static const String payment_success = '/payment_success';
  static const String therapy_filter = '/therapy_filter';
  static const String sort = '/sort';
  static const String professional_filter = '/professional_filter';
  static const String price_filter = '/price_filter';
  static const String availability_filter = '/availability_filter';
  static const String distance_filter = '/distance_filter';
  static const String gender_filter = '/gender_filter';
  static const String fitness_goal = '/fitness_goal';
  static const String nutrition_goal = '/nutrition_goal';
  static const String trainer_preference = '/trainer_preference';
  static const String change_password = '/change_password';
  static const String orderDetail = '/order_detail';
  static const String selectAddressMap = '/select_address_map';
  static const String chat_detail = '/chat_detail';
  static const String transaction_summary = '/transaction_summary';

  // Alias for compatibility with notification code
  static const String ORDERDETAIL = orderDetail;
  static const String HOME = home;
  static const String chat = chat_detail; // Alias for reference code compatibility
}

// Alias class for compatibility with notification code that uses Routes
class   Routes {
  static const String ORDERDETAIL = AppRoutes.ORDERDETAIL;
  static const String HOME = AppRoutes.HOME;
}
