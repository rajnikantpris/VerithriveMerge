//var bareUrl = 'http://192.168.0.33:4142/api/v2/user/';
//var bareUrl = 'http://27.54.168.101:4142/api/v1/user/';

var bareUrl = 'http://18.135.255.93:4142/api/v2/user/';
var socketUrl = 'https://adminportal.verithrive.co.uk';

// Global variables for Google Sign-In
String? serverClientIdGlb;
String baseURL = bareUrl;
String social_register_login = "social/register-login";

String get socketBaseUrl {
  final uri = Uri.parse(socketUrl);
  return '${uri.scheme}://${uri.host}:${uri.port}';
}

//api
const register = "register";
const verify_otp = "verify-otp";
const forgot_password_send_otp = "forgot-password/send-otp";
const forgot_password_verify_otp = "forgot-password/verify-otp";
const forgot_password_reset = "forgot-password/reset";
const update_personal_details = "update-personal-details";
const get_personal_details = "get-personal-details";
const get_static_pages = "get-static-page";

const send_otp = "send-otp";
const verify_otp_and_register = "verify-otp-and-register";
const login = "login";
const change_password = "change-password";
const delete_account = "delete-account";
const notification = "notification";
const logout = "logout";

const add_card = "add-cards";
const edit_card = "edit-card";
const get_card_details = "get-cards-details";
const delete_card = "delete-card";
const profession_types_all = "profession-types/all";
const professionals_list = "professionals/list";
const professionals_details = "professionals/details";
const save_unsave = "professionals/save-unsave";
const timeslot_availability =
    "professionals/service-format-availability/details";
const create_booking = "create-booking";
const get_services_all = "/get-services/all";
const validate_booking_window = "validate-booking-window";
const bookings_list = "bookings/list";
const notifications_list = "notifications/list";
const update_booking = "update-booking";

const chat_inbox = "chat/inbox";
const chat_messages = "chat/messages/{room_id}";
const chat_room = "chat/room";

const update_device_token = "update-device-token";
const social_signin = "/social/signin";
const professionals_rate_review = "/professionals/rate-review";
const notifications_count = "/notifications/count";
