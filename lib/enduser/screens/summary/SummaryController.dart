import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:verithrive_dev/enduser/network/exceptions/not_found_exception.dart';
import 'package:verithrive_dev/enduser/routes/app_routes.dart';
import 'package:verithrive_dev/enduser/screens/payment/PaymentMethodBinding.dart';
import 'package:verithrive_dev/enduser/screens/payment/PaymentMethodScreen.dart';
import 'package:verithrive_dev/enduser/screens/payment_success/PaymentSuccessBinding.dart';
import 'package:verithrive_dev/enduser/screens/payment_success/PaymentSuccessScreen.dart';
import 'package:verithrive_dev/services/analytics_service.dart';
import '../../core/base/base_controller.dart';
import '../../data/repository/project_repository.dart';
import '../../network/exceptions/app_exception.dart';
import '../../network/exceptions/base_exception.dart';
import '../../utils/api_services.dart';
import '../../utils/common_dialog.dart';
import '../cart/CartController.dart';

class SummaryController extends BaseController {
  // Get cart controller to access booking data
  final CartController cartController = Get.find<CartController>();
  final ProjectRepository _repository =
      Get.find<ProjectRepository>(tag: (ProjectRepository).toString());

  // Booking details from cart
  var selectedDate = DateTime.now().obs;
  var fromTime = Rxn<TimeOfDay>();
  var untilTime = Rxn<TimeOfDay>();
  var serviceName = 'Consultation - in person'.obs;
  var price = 30.0.obs;
  var platformFeePercent = 0.0.obs; // fee_value from API (e.g. 2 = 2%)
  var isPlatformFeeLoading = false.obs;
  var location = 'Lorem Ipsum,*******'.obs;
  var professionalId = ''.obs;
  var professionalServiceFormatId = ''.obs;
  var serviceFormatId = ''.obs; // service_format_id for API call
  var bookingId = ''.obs; // booking_id for update-booking API in edit mode
  var isEditMode = false.obs; // Flag to indicate edit mode

  bool get isFree => price.value == 0;

  /// Platform fee amount = service price × fee_value%
  double get platformFee =>
      (price.value * platformFeePercent.value) / 100;

  double get totalPrice => price.value + platformFee;

  // Timer for booking expiry
  Timer? _expiryTimer;
  var expiryTime = '15:00'.obs; // Display format MM:SS
  var remainingSeconds = 900.obs; // 15 minutes in seconds (15 * 60)

  @override
  void onInit() {
    super.onInit();
    _receiveArguments();
    // Listen to cart controller time changes and sync
    ever(cartController.fromTime, (TimeOfDay? time) {
      if (time != null) {
        fromTime.value = time;
      }
    });
    ever(cartController.untilTime, (TimeOfDay? time) {
      if (time != null) {
        untilTime.value = time;
      }
    });
    // Start the expiry timer when screen opens
    _startExpiryTimer();
    // Fetch platform fee for itemized price breakdown
    if (!isFree && professionalId.value.isNotEmpty) {
      isPlatformFeeLoading.value = true;
      callPlatformFeeAPI();
    }
  }

  // Calculate duration in minutes from fromTime to untilTime
  int _calculateDurationMinutes() {
    if (fromTime.value == null || untilTime.value == null) {
      return 15; // Default to 15 minutes if times are not set
    }

    int fromMinutes = fromTime.value!.hour * 60 + fromTime.value!.minute;
    int untilMinutes = untilTime.value!.hour * 60 + untilTime.value!.minute;

    // Handle case where until time is on next day (shouldn't happen in normal flow)
    int duration = untilMinutes - fromMinutes;
    if (duration < 0) {
      duration += 24 * 60; // Add 24 hours in minutes
    }

    return duration > 0 ? duration : 15; // Default to 15 if invalid
  }

  // Start the expiry timer
  void _startExpiryTimer() {
    // Set timer to 15 minutes (as per requirement)
    remainingSeconds.value = 15 * 60; // 15 minutes in seconds
    _updateExpiryTimeDisplay();

    // Start countdown timer
    _expiryTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
        _updateExpiryTimeDisplay();
      } else {
        // Timer expired - navigate back
        timer.cancel();
        _onTimerExpired();
      }
    });
  }

  // Update expiry time display format (MM:SS)
  void _updateExpiryTimeDisplay() {
    int minutes = remainingSeconds.value ~/ 60;
    int seconds = remainingSeconds.value % 60;
    expiryTime.value =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Handle timer expiration
  void _onTimerExpired() {
    // Show message and navigate back
    showResponseDialog(
      message: 'Your booking session has expired. Please try again.',
      title: 'Session Expired',
      isError: true,
      showButton: true,
      onOkPressed: () {
        Get.back(); // Navigate back to previous screen
      },
    );
  }

  // Cancel timer (call when proceeding to payment or leaving screen)
  void _cancelTimer() {
    _expiryTimer?.cancel();
    _expiryTimer = null;
  }

  void _receiveArguments() {
    final arguments = Get.arguments;
    if (arguments != null && arguments is Map<String, dynamic>) {
      // Set booking details
      if (arguments['selected_date'] != null) {
        selectedDate.value = arguments['selected_date'] as DateTime;
      }
      if (arguments['from_time'] != null) {
        fromTime.value = arguments['from_time'] as TimeOfDay;
      }
      if (arguments['until_time'] != null) {
        untilTime.value = arguments['until_time'] as TimeOfDay;
      }
      if (arguments['service_name'] != null) {
        serviceName.value = arguments['service_name'] as String;
      }
      if (arguments['price'] != null) {
        final rawPrice = arguments['price'];
        if (rawPrice is String && rawPrice.trim().isEmpty) {
          price.value = 0.0;
        } else if (rawPrice is num) {
          price.value = rawPrice.toDouble();
        }
      }
      if (arguments['location'] != null) {
        location.value = arguments['location'] as String;
      }
      if (arguments['professional_id'] != null) {
        professionalId.value = arguments['professional_id'] as String;
      }
      if (arguments['service_format_id'] != null) {
        // Use service_format_id for validate booking window API
        serviceFormatId.value = arguments['service_format_id'] as String;
      }
      if (arguments['professional_service_format_id'] != null) {
        // Store _id for passing to payment screen (for create-booking API)
        professionalServiceFormatId.value =
            arguments['professional_service_format_id'] as String;
      }
      if (arguments['booking_id'] != null) {
        // Store booking_id for passing to payment screen (for update-booking API in edit mode)
        bookingId.value = arguments['booking_id'] as String;
      }
      if (arguments['is_edit_mode'] != null) {
        // Store edit mode flag
        isEditMode.value = arguments['is_edit_mode'] as bool;
      }
    }
  }

  // Format time to string
  String formatTime(TimeOfDay? time) {
    if (time == null) return '';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // Get formatted date and time
  String getFormattedDateTime() {
    final from = fromTime.value ?? TimeOfDay(hour: 14, minute: 0);
    final until = untilTime.value ?? TimeOfDay(hour: 15, minute: 0);
    final date = DateFormat('dd/MM/yyyy').format(selectedDate.value);
    return '$date  ${formatTime(from)}-${formatTime(until)}';
  }

  // Get formatted date
  String getFormattedDate() {
    return DateFormat('dd/MM/yyyy').format(selectedDate.value);
  }

  // Edit booking - go back to cart
  void editBooking() {
    _cancelTimer();
    Get.back();
  }

  // Remove booking
  void removeBooking() {
    // Analytics: Log remove from cart event
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rawArgs = Get.arguments;
      final args = rawArgs is Map ? Map<String, dynamic>.from(rawArgs) : null;
      final category = AnalyticsService.resolvePageCategory(
        args?['category']?.toString(),
        itemBrand: args?['item_brand']?.toString(),
        itemVariant: args?['item_variant']?.toString(),
      );
      final itemPrice =
          AnalyticsService.validatePrice(cartController.price.value);
      final consultationType = cartController.consultationType.value;

      AnalyticsService.instance.logRemoveFromCartEvent(
        item: AnalyticsService.instance.buildItem(
          itemId: cartController.professionalId.value.isNotEmpty
              ? cartController.professionalId.value
              : '',
          itemName: cartController.itemVariant.value.isNotEmpty
              ? cartController.itemVariant.value
              : (cartController.serviceName.value.isNotEmpty
                  ? cartController.serviceName.value
                  : ''),
          itemCategory: category,
          itemCategory2: cartController.serviceName.value,
          itemVariant: consultationType.isNotEmpty
              ? consultationType
              : serviceName.value,
          itemBrand: consultationType.isNotEmpty ? consultationType : category,
          price: itemPrice,
          quantity: 1,
        ),
        value: itemPrice,
        currency: 'GBP',
        screenName: 'SummaryScreen',
        screenClass: 'SummaryScreen',
        pageCategory: category,
      );
    });

    // Cancel timer when removing booking
    _cancelTimer();
    // Implementation for removing booking
    Get.back();
    Get.back(); // Go back to cart, then back to previous screen
  }

  // Proceed to payment - call validate booking window API first
  void proceedToPayment() {
    // Cancel timer when proceeding to payment
    _cancelTimer();
    // Call validate booking window API
    callValidateBookingWindowAPI();
  }

  // GET /professional/platform-fee?professional_id=...
  void callPlatformFeeAPI() {
    if (professionalId.value.isEmpty) return;

    isPlatformFeeLoading.value = true;

    Map<String, dynamic> toJson() {
      final Map<String, dynamic> data = <String, dynamic>{};
      data['professional_id'] = professionalId.value;

      print('========================================');
      print('Platform Fee API Request (GET):');
      print(data);
      print('========================================');

      return data;
    }

    var service = _repository.sendGetApiWithParamRequest(
      toJson,
      professional_platform_fee,
      true,
    );
    callDataService(
      service,
      onSuccess: _handlePlatformFeeSuccess,
      onError: _handlePlatformFeeError,
      isShowLoading: false,
    );
  }

  Future<void> _handlePlatformFeeSuccess(dynamic baseResponse) async {
    try {
      Map<String, dynamic> responseData;
      if (baseResponse != null && baseResponse.data != null) {
        responseData = baseResponse.data is Map<String, dynamic>
            ? baseResponse.data
            : baseResponse.data as Map<String, dynamic>;
      } else if (baseResponse is Map<String, dynamic>) {
        responseData = baseResponse;
      } else {
        return;
      }

      final dynamic data = responseData['data'] ?? responseData;
      if (data is! Map) return;

      final map = Map<String, dynamic>.from(data);

      // fee_value is a percentage (e.g. 2 => 2% of service price)
      final feePercent = _parseAmount(map['fee_value']);
      if (feePercent != null) {
        platformFeePercent.value = feePercent;
      }
    } catch (e) {
      print('Error parsing platform fee response: $e');
    } finally {
      isPlatformFeeLoading.value = false;
    }
  }

  void _handlePlatformFeeError(dynamic e) {
    // Keep existing service price; treat missing fee as 0.
    print('Platform fee API error: $e');
    isPlatformFeeLoading.value = false;
  }

  double? _parseAmount(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[£,\s]'), '');
      return double.tryParse(cleaned);
    }
    return null;
  }

  // Call validate booking window API
  void callValidateBookingWindowAPI() {
    Map<String, dynamic> toJson() {
      final Map<String, dynamic> data = <String, dynamic>{};

      // Format date as DD/MM/YYYY
      String formattedDate =
          DateFormat('dd/MM/yyyy').format(selectedDate.value);

      // Format to_time as HH:mm
      String formattedToTime = '';
      if (untilTime.value != null) {
        final time = untilTime.value!;
        formattedToTime =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      }

      data['professional_id'] = professionalId.value;
      data['service_format_id'] =
          serviceFormatId.value.isNotEmpty ? serviceFormatId.value : "";
      data['date'] = formattedDate;
      data['to_time'] = formattedToTime;

      print('========================================');
      print('Validate Booking Window API Request:');
      print(data);
      print('========================================');

      return data;
    }

    var service =
        _repository.sendPostApiRequest(toJson, validate_booking_window, true);
    callDataService(
      service,
      onSuccess: _handleValidateBookingWindowSuccess,
      onError: _handleValidateBookingWindowError,
      isShowLoading: true,
    );
  }

  Future<void> _handleValidateBookingWindowSuccess(dynamic baseResponse) async {
    try {
      Map<String, dynamic> responseData;
      if (baseResponse != null && baseResponse.data != null) {
        responseData = baseResponse.data is Map<String, dynamic>
            ? baseResponse.data
            : baseResponse.data as Map<String, dynamic>;
      } else if (baseResponse is Map<String, dynamic>) {
        responseData = baseResponse;
      } else {
        throw Exception('Invalid response format');
      }

      bool success = responseData['success'] ?? false;
      String message =
          responseData['message'] ?? 'Booking validated successfully';

      if (success == true) {
        if (isFree) {
          callCreateBookingAPI();
        } else {
          final summaryArgs = Get.arguments as Map<String, dynamic>?;
          Get.to(
            () => PaymentMethodScreen(),
            binding: PaymentMethodBinding(),
            arguments: {
              'selected_date': selectedDate.value,
              'from_time': fromTime.value,
              'until_time': untilTime.value,
              'service_name': serviceName.value,
              'price': totalPrice,
              'service_price': price.value,
              'platform_fee': platformFee,
              'location': location.value,
              'professional_id': professionalId.value,
              'service_format_id': serviceFormatId.value,
              'professional_service_format_id':
                  professionalServiceFormatId.value,
              'booking_id': bookingId.value,
              'is_edit_mode': isEditMode.value,
              'category': summaryArgs?['category'] ?? 'wellness',
              'item_variant': summaryArgs?['item_variant'] ?? '',
              'item_brand': summaryArgs?['item_brand'] ?? '',
            },
          );
        }
      } else {
        // Show error dialog
        showResponseDialog(
          message: message,
          title: 'Error',
          isError: true,
          showButton: true,
          onOkPressed: () {},
        );
      }
    } catch (e) {
      showResponseDialog(
        message: "Error processing response: $e",
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    }
  }

  void _handleValidateBookingWindowErrorOld(dynamic e) {
    String errorMessage = "An error occurred. Please try again.";

    if (e is NotFoundException) {
      errorMessage = e.message;
    } else if (e is Exception) {
      errorMessage = e.toString();
    }

    showResponseDialog(
      message: errorMessage,
      title: 'Error',
      isError: true,
      showButton: true,
      onOkPressed: () {},
    );
  }

  void _handleValidateBookingWindowError(dynamic e) {
    if (e is BaseException) {
      showResponseDialog(
        message: e.message,
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {
          // dispose();
        },
      );
    }
  }

  void callCreateBookingAPI() {
    if (professionalId.value.isEmpty) {
      showResponseDialog(
        message: 'Professional ID is missing',
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
      return;
    }

    if (professionalServiceFormatId.value.isEmpty) {
      showResponseDialog(
        message: 'Service format ID is missing',
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
      return;
    }

    if (fromTime.value == null || untilTime.value == null) {
      showResponseDialog(
        message: 'Please select from and until times',
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
      return;
    }

    Map<String, dynamic> toJson() {
      String formattedDate =
          DateFormat('dd/MM/yyyy').format(selectedDate.value);

      String formatTime24Hour(TimeOfDay time) {
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      }

      final Map<String, dynamic> data = <String, dynamic>{};
      data['professional_id'] = professionalId.value;
      data['professional_service_format_id'] =
          professionalServiceFormatId.value;
      data['date'] = formattedDate;
      data['from_time'] = formatTime24Hour(fromTime.value!);
      data['to_time'] = formatTime24Hour(untilTime.value!);

      print('========================================');
      print('Create Booking API Request:');
      print(data);
      print('========================================');

      return data;
    }

    var service = _repository.sendPostApiRequest(toJson, create_booking, true);
    callDataService(
      service,
      onSuccess: _handleCreateBookingSuccess,
      onError: _handleCreateBookingError,
      isShowLoading: true,
    );
  }

  Future<void> _handleCreateBookingSuccess(dynamic baseResponse) async {
    try {
      Map<String, dynamic> responseData;
      if (baseResponse != null && baseResponse.data != null) {
        responseData = baseResponse.data is Map<String, dynamic>
            ? baseResponse.data
            : baseResponse.data as Map<String, dynamic>;
      } else if (baseResponse is Map<String, dynamic>) {
        responseData = baseResponse;
      } else {
        throw Exception('Invalid response format');
      }

      bool success = responseData['success'] ?? false;
      String message =
          responseData['message'] ?? 'Booking created successfully';

      if (success == true) {
        final rawSummaryArgs = Get.arguments;
        final summaryArgs = rawSummaryArgs is Map
            ? Map<String, dynamic>.from(rawSummaryArgs)
            : null;
        final category = AnalyticsService.resolvePageCategory(
          summaryArgs?['category']?.toString(),
          itemBrand: summaryArgs?['item_brand']?.toString(),
          itemVariant: summaryArgs?['item_variant']?.toString(),
        );
        final itemVariant = summaryArgs?['item_variant']?.toString() ?? '';
        final itemBrand = summaryArgs?['item_brand']?.toString() ?? '';
        final successBookingId =
            responseData['data']?['booking_id']?.toString() ??
                responseData['data']?['_id']?.toString() ??
                bookingId.value;

        Get.offAll(
          () => PaymentSuccessScreen(),
          binding: PaymentSuccessBinding(),
          arguments: {
            'professional_id': professionalId.value,
            'service_name': serviceName.value,
            'price': price.value,
            'booking_id': successBookingId.isNotEmpty
                ? successBookingId
                : DateTime.now().millisecondsSinceEpoch.toString(),
            'category': category,
            'consultation_type': serviceName.value,
            'item_variant': itemVariant,
            'item_brand': itemBrand,
          },
        );
      } else {
        showResponseDialog(
          message: message,
          title: 'Error',
          isError: true,
          showButton: true,
          onOkPressed: () {},
        );
      }
    } catch (e) {
      showResponseDialog(
        message: "Error processing response: $e",
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    }
  }

  void _handleCreateBookingError(dynamic e) {
    if (e is BaseException) {
      showResponseDialog(
        message: e.message,
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    }
  }

  @override
  void onClose() {
    // Cancel timer when leaving the screen
    _cancelTimer();
    super.onClose();
  }
}
