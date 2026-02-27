import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:verithrive_dev/enduser/network/exceptions/not_found_exception.dart';
import 'package:verithrive_dev/enduser/routes/app_routes.dart';
import 'package:verithrive_dev/enduser/screens/payment/PaymentMethodBinding.dart';
import 'package:verithrive_dev/enduser/screens/payment/PaymentMethodScreen.dart';
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
  final ProjectRepository _repository = Get.find<ProjectRepository>(tag: (ProjectRepository).toString());
  
  // Booking details from cart
  var selectedDate = DateTime.now().obs;
  var fromTime = Rxn<TimeOfDay>();
  var untilTime = Rxn<TimeOfDay>();
  var serviceName = 'Consultation - in person'.obs;
  var price = 30.0.obs;
  var location = 'Lorem Ipsum,*******'.obs;
  var professionalId = ''.obs;
  var professionalServiceFormatId = ''.obs;
  var serviceFormatId = ''.obs; // service_format_id for API call
  var bookingId = ''.obs; // booking_id for update-booking API in edit mode
  var isEditMode = false.obs; // Flag to indicate edit mode
  
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
    expiryTime.value = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
        price.value = (arguments['price'] as num).toDouble();
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
        professionalServiceFormatId.value = arguments['professional_service_format_id'] as String;
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
  
  // Call validate booking window API
  void callValidateBookingWindowAPI() {
    Map<String, dynamic> toJson() {
      final Map<String, dynamic> data = <String, dynamic>{};
      
      // Format date as DD/MM/YYYY
      String formattedDate = DateFormat('dd/MM/yyyy').format(selectedDate.value);
      
      // Format to_time as HH:mm
      String formattedToTime = '';
      if (untilTime.value != null) {
        final time = untilTime.value!;
        formattedToTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      }
      
      data['professional_id'] = professionalId.value;
      data['service_format_id'] = serviceFormatId.value.isNotEmpty ? serviceFormatId.value : "";
      data['date'] = formattedDate;
      data['to_time'] = formattedToTime;
      
      print('========================================');
      print('Validate Booking Window API Request:');
      print(data);
      print('========================================');
      
      return data;
    }
    
    var service = _repository.sendPostApiRequest(toJson, validate_booking_window, true);
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
      String message = responseData['message'] ?? 'Booking validated successfully';
      
      if (success == true) {
        // Navigate to payment screen with all booking data
        Get.to(
          () => PaymentMethodScreen(),
          binding: PaymentMethodBinding(),
          arguments: {
            'selected_date': selectedDate.value,
            'from_time': fromTime.value,
            'until_time': untilTime.value,
            'service_name': serviceName.value,
            'price': price.value,
            'location': location.value,
            'professional_id': professionalId.value,
            'service_format_id': serviceFormatId.value,
            'professional_service_format_id': professionalServiceFormatId.value,
            'booking_id': bookingId.value,
            'is_edit_mode': isEditMode.value,
          },
        );
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
    if(e is BaseException) {


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
  
  @override
  void onClose() {
    // Cancel timer when leaving the screen
    _cancelTimer();
    super.onClose();
  }
}
