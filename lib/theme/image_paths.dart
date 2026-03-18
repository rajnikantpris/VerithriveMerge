import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Central place for image asset paths and small helpers.
class AppImages {
  AppImages._();

  // Raster assets
  static const String appLogoSplash = 'assets/images/app_logo_splash.png';
  static const String slider1 = 'assets/images/slider1.png';
  static const String slider2 = 'assets/images/slider2.png';
  static const String slider3 = 'assets/images/slider3.png';
  static const String slider4 = 'assets/images/slider4.png';
  static const String google = 'assets/images/google.png';
  static const String iphone = 'assets/images/logoApple.png';
  static const String camera = 'assets/images/camera.png';
  static const String calendar = 'assets/images/calendar.png';
  static const String calendar1 = 'assets/images/calender1.svg';
  static const String upload = 'assets/images/upload.svg';
  static const String add = 'assets/images/add.svg';
  static const String right_arrow = 'assets/images/right_arrow.png';
  static const String home_logo = 'assets/images/home_logo.png';
  static const String notification = 'assets/images/notification.svg';
  static const String bottom_chat = 'assets/images/bottom_chat.svg';
  static const String bottom_home = 'assets/images/bottom_home.svg';
  static const String bottom_user = 'assets/images/bottom_user.svg';
  static const String down_arrow = 'assets/images/down_arrow.svg';
  static const String bottom_calender = 'assets/images/bottom_calender.svg';
  static const String bottom_chat_selected =
      'assets/images/bottom_chat_selected.svg';
  static const String bottom_home_selected =
      'assets/images/bottom_home_selected.svg';
  static const String bottom_user_selected =
      'assets/images/bottom_user_selected.svg';
  static const String bottom_calender_selected =
      'assets/images/bottom_calender_selected.svg';
  static const String monthly = 'assets/images/Monthly.svg';
  static const String quarterly = 'assets/images/Quarterly.svg';
  static const String yearly = 'assets/images/yearly.svg';
  static const String user = 'assets/images/user.png';
  static const String verificationAwait = 'assets/images/cuate.png';
  static const String paypal = 'assets/images/paypal.svg';
  static const String googlepay = 'assets/images/googlepay.svg';
  static const String googlepayPng = 'assets/images/googlepay_png.png';
  static const String iphonepay = 'assets/images/iphonepay.svg';
  static const String iphonepayPng = 'assets/images/iphonepay_png.png';
  static const String mastercard = 'assets/images/mastercard.svg';
  static const String chatList = 'assets/images/chat_list.svg';
  static const String chatSend = 'assets/images/chat_send.svg';
  static const String calenderList = 'assets/images/calender_list.svg';
  static const String clockList = 'assets/images/clock_list.svg';
  static const String userList = 'assets/images/user_list.svg';
  static const String deleteList = 'assets/images/delete_list.svg';
  static const String refreshList = 'assets/images/refresh_list.svg';
  static const String profileBank = 'assets/images/profile_bank.svg';
  static const String profileUser = 'assets/images/profile_user.svg';
  static const String profileLogout = 'assets/images/profile_logout.svg';
  static const String profileTicket = 'assets/images/profile_ticket.svg';
  static const String profileSettings = 'assets/images/profile_settings.svg';
  static const String profileRightArrow =
      'assets/images/profile_right_arrow.svg';
  static const String profileNotification =
      'assets/images/profile_notitification.svg';
  static const String deleteAccount = 'assets/images/delete_account.svg';
  static const String editOutline = 'assets/images/basil_edit-outline.svg';
  static const String availabilityClock = 'assets/images/availability_clock.svg';
  static const String availabilityCalender = 'assets/images/availability_calender.svg';
  static const String bxsOffer = 'assets/images/bxs_offer.svg';

  /// Convenience for loading the splash logo image.

  static Image user_image({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
  }) {
    return Image.asset(user, width: width, height: height, fit: fit);
  }

  static Image calender_image({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
  }) {
    return Image.asset(calendar, width: width, height: height, fit: fit);
  }

  static Widget calender1_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(calendar1, width: width, height: height, fit: fit, color: color);
  }

  static Image right_arrow_image({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
  }) {
    return Image.asset(right_arrow, width: width, height: height, fit: fit);
  }

  static Image home_logo_image({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
  }) {
    return Image.asset(home_logo, width: width, height: height, fit: fit);
  }

  static Image camera_image({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
  }) {
    return Image.asset(camera, width: width, height: height, fit: fit);
  }

  static Widget upload_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(upload, width: width, height: height, fit: fit, color: color);
  }

  static Widget add_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(add, width: width, height: height, fit: fit, color: color);
  }

  static Widget add_down_arrow_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(down_arrow,
        width: width, height: height, fit: fit, color: color);
  }

  static Widget notification_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(
      notification,
      width: width,
      height: height,
      fit: fit,
      color: color,
    );
  }

  static Widget bottom_chat_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(
      bottom_chat,
      width: width,
      height: height,
      fit: fit,
      color: color,
    );
  }

  static Widget bottom_home_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(
      bottom_home,
      width: width,
      height: height,
      fit: fit,
      color: color,
    );
  }

  static Widget bottom_user_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(
      bottom_user,
      width: width,
      height: height,
      fit: fit,
      color: color,
    );
  }

  static Widget bottom_calender_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(
      bottom_calender,
      width: width,
      height: height,
      fit: fit,
      color: color,
    );
  }

  static Widget bottom_chat_selected_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(
      bottom_chat_selected,
      width: width,
      height: height,
      fit: fit,
      color: color,
    );
  }

  static Widget bottom_home_selected_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(
      bottom_home_selected,
      width: width,
      height: height,
      fit: fit,
      color: color,
    );
  }

  static Widget bottom_user_selected_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(
      bottom_user_selected,
      width: width,
      height: height,
      fit: fit,
      color: color,
    );
  }

  static Widget bottom_calender_selected_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(
      bottom_calender_selected,
      width: width,
      height: height,
      fit: fit,
      color: color,
    );
  }

  static Widget monthly_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(monthly, width: width, height: height, fit: fit, color: color);
  }

  static Widget quarterly_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(quarterly, width: width, height: height, fit: fit, color: color);
  }

  static Widget yearly_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(yearly, width: width, height: height, fit: fit, color: color);
  }

  static Image verificationAwaitImage({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
  }) {
    return Image.asset(
      verificationAwait,
      width: width,
      height: height,
      fit: fit,
    );
  }

  static Widget paypal_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(paypal, width: width, height: height, fit: fit, color: color);
  }

  static Widget googlepay_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(googlepay, width: width, height: height, fit: fit, color: color);
  }

  static Widget iphonepay_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(iphonepay, width: width, height: height, fit: fit, color: color);
  }

  static Widget mastercard_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(
      mastercard,
      width: width,
      height: height,
      fit: fit,
      color: color,
    );
  }

  static Widget chat_list_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(chatList, width: width, height: height, fit: fit, color: color);
  }

  static Widget chat_send_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(chatSend, width: width, height: height, fit: fit, color: color);
  }

  static Widget calender_list_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(
      calenderList,
      width: width,
      height: height,
      fit: fit,
      color: color,
    );
  }

  static Widget clock_list_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(clockList, width: width, height: height, fit: fit, color: color);
  }

  static Widget user_list_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(userList, width: width, height: height, fit: fit, color: color);
  }

  static Widget delete_list_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(
      deleteList,
      width: width,
      height: height,
      fit: fit,
      color: color,
    );
  }

  static Widget refresh_list_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(
      refreshList,
      width: width,
      height: height,
      fit: fit,
      color: color,
    );
  }

  static Widget profile_bank_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(
      profileBank,
      width: width,
      height: height,
      fit: fit,
      color: color,
    );
  }

  static Widget profile_user_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(
      profileUser,
      width: width,
      height: height,
      fit: fit,
      color: color,
    );
  }

  static Widget profile_logout_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(
      profileLogout,
      width: width,
      height: height,
      fit: fit,
      color: color,
    );
  }

  static Widget profile_ticket_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(
      profileTicket,
      width: width,
      height: height,
      fit: fit,
      color: color,
    );
  }

  static Widget profile_settings_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(
      profileSettings,
      width: width,
      height: height,
      fit: fit,
      color: color,
    );
  }

  static Widget profile_right_arrow_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(
      profileRightArrow,
      width: width,
      height: height,
      fit: fit,
      color: color,
    );
  }

  static Widget profile_notification_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(
      profileNotification,
      width: width,
      height: height,
      fit: fit,
      color: color,
    );
  }

  static Widget delete_account_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(
      deleteAccount,
      width: width,
      height: height,
      fit: fit,
      color: color,
    );
  }

  static Widget edit_outline_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(
      editOutline,
      width: width,
      height: height,
      fit: fit,
      color: color,
    );
  }

  static Widget availability_clock_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(
      availabilityClock,
      width: width,
      height: height,
      fit: fit,
      color: color,
    );
  }

  static Widget availability_calender_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(
      availabilityCalender,
      width: width,
      height: height,
      fit: fit,
      color: color,
    );
  }

  static Widget bxs_offer_svg({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return svg(
      bxsOffer,
      width: width,
      height: height,
      fit: fit,
      color: color,
    );
  }

  static Image google_image({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
  }) {
    return Image.asset(google, width: width, height: height, fit: fit);
  }

  static Image apple_image({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
  }) {
    return Image.asset(iphone, width: width, height: height, fit: fit);
  }

  static Image splash({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
  }) {
    return Image.asset(appLogoSplash, width: width, height: height, fit: fit);
  }

  static Image sliderImage1({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
  }) {
    return Image.asset(slider1, width: width, height: height, fit: fit);
  }

  static Image sliderImage2({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
  }) {
    return Image.asset(slider2, width: width, height: height, fit: fit);
  }

  static Image sliderImage3({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
  }) {
    return Image.asset(slider3, width: width, height: height, fit: fit);
  }

  static Image sliderImage4({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
  }) {
    return Image.asset(slider4, width: width, height: height, fit: fit);
  }

  /// Generic helper for loading an SVG asset.
  static Widget svg(
    String asset, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? color,
  }) {
    return SvgPicture.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      color: color,
    );
  }
}
