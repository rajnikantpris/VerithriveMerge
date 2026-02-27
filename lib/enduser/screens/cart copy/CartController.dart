import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:verithrive_dev/enduser/routes/app_routes.dart';
import 'package:verithrive_dev/utils/timezone_helper.dart';
import '../../core/base/base_controller.dart';
import '../../data/repository/project_repository.dart';
import '../../utils/api_services.dart';
import '../../utils/common_dialog.dart';
import '../../widgets/restricted_time_picker.dart';
import '../booking/BookingsController.dart';

class CartController extends BaseController {
  final ProjectRepository _repository = Get.find(tag: (ProjectRepository).toString());
  // Observable variables
  var fromTime = Rxn<TimeOfDay>();
  var untilTime = Rxn<TimeOfDay>();
  var expiryTime = '15:00'.obs;
  var selectedDate = DateTime.now().obs;
  
  // Original time range from consultation booking (used for time picker limits)
  var originalFromTime = Rxn<TimeOfDay>();
  var originalUntilTime = Rxn<TimeOfDay>();
  
  // Booking details
  var consultationType = 'Consultation - in person'.obs;
  var price = 30.0.obs;
  var location = 'Lorem Ipsum,*******'.obs;
  var serviceName = 'Consultation - in person'.obs;
  var professionalId = ''.obs;
  var serviceFormatId = ''.obs; // service_format_id for summary screen
  var professionalServiceFormatId = ''.obs; // _id for create-booking API
  var bookingId = ''.obs; // booking_id for edit mode
  var isEditMode = false.obs; // Flag to indicate edit mode
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _receiveArguments();
    // Initialize with default times if not set
    if (fromTime.value == null) {
      fromTime.value = TimeOfDay(hour: 14, minute: 0); // Default 2:00 PM
    }
    if (untilTime.value == null) {
      untilTime.value = TimeOfDay(hour: 15, minute: 0); // Default 3:00 PM
    }
  }

  void _receiveArguments() {
    final arguments = Get.arguments;
    if (arguments != null && arguments is Map<String, dynamic>) {
      // Set selected date
      if (arguments['selected_date'] != null) {
        selectedDate.value = arguments['selected_date'] as DateTime;
      }
      
      // Set from and until time from consultation booking
      if (arguments['from_time'] != null) {
        fromTime.value = arguments['from_time'] as TimeOfDay;
        originalFromTime.value = arguments['from_time'] as TimeOfDay; // Store original
      }
      if (arguments['until_time'] != null) {
        untilTime.value = arguments['until_time'] as TimeOfDay;
        originalUntilTime.value = arguments['until_time'] as TimeOfDay; // Store original
      }
      
      // Set service details
      if (arguments['service_name'] != null) {
        serviceName.value = arguments['service_name'] as String;
        consultationType.value = serviceName.value;
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
        serviceFormatId.value = arguments['service_format_id'] as String;
      }
      if (arguments['professional_service_format_id'] != null) {
        professionalServiceFormatId.value = arguments['professional_service_format_id'] as String;
      }
      if (arguments['booking_id'] != null) {
        bookingId.value = arguments['booking_id'] as String;
      }
      if (arguments['is_edit_mode'] != null) {
        isEditMode.value = arguments['is_edit_mode'] as bool;
      }
    }
  }
  
  // Helper method to get current timezone
  Future<String> _getCurrentTimezone() async {
    try {
      final selectedTimezone = TimezoneHelper.getCurrentTimezone();
      return selectedTimezone;
    } catch (e) {
      print('Error getting timezone: $e');
      return 'Asia/Kolkata'; // Default fallback
    }
  }

  // Select From Time
  Future<void> selectFromTime(BuildContext context) async {
    // Use restricted time picker that only shows valid times
    // Use original range to always show all available times
    if (originalFromTime.value == null || originalUntilTime.value == null) {
      showResponseDialog(
        message: 'Please set both from and until times first',
        title: 'Invalid Selection',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
      return;
    }
    
    final TimeOfDay? picked = await RestrictedTimePicker.showRestrictedTimePicker(
      context: context,
      initialTime: fromTime.value ?? originalFromTime.value!,
      minTime: originalFromTime.value, // Use original from time as minimum
      maxTime: originalUntilTime.value, // Use original until time as maximum
    );
    
    if (picked != null) {
      // Validate: picked time must be before until time
      int pickedMinutes = picked.hour * 60 + picked.minute;
      int untilMinutes = untilTime.value!.hour * 60 + untilTime.value!.minute;
      
      if (pickedMinutes >= untilMinutes) {
        showResponseDialog(
          message: 'From time must be before until time (${formatTime(untilTime.value)})',
          title: 'Invalid Time Selection',
          isError: true,
          showButton: true,
          onOkPressed: () {},
        );
        return;
      }
      
      fromTime.value = picked;
    }
  }

  // Select Until Time
  Future<void> selectUntilTime(BuildContext context) async {
    // Use restricted time picker that only shows valid times
    // Use original range to always show all available times
    if (originalFromTime.value == null || originalUntilTime.value == null) {
      showResponseDialog(
        message: 'Please set both from and until times first',
        title: 'Invalid Selection',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
      return;
    }
    
    final TimeOfDay? picked = await RestrictedTimePicker.showRestrictedTimePicker(
      context: context,
      initialTime: untilTime.value ?? originalUntilTime.value!,
      minTime: originalFromTime.value, // Use original from time as minimum
      maxTime: originalUntilTime.value, // Use original until time as maximum
    );
    
    if (picked != null) {
      // Validate: picked time must be after from time
      int pickedMinutes = picked.hour * 60 + picked.minute;
      int fromMinutes = fromTime.value!.hour * 60 + fromTime.value!.minute;
      
      if (pickedMinutes <= fromMinutes) {
        showResponseDialog(
          message: 'Until time must be after from time (${formatTime(fromTime.value)})',
          title: 'Invalid Time Selection',
          isError: true,
          showButton: true,
          onOkPressed: () {},
        );
        return;
      }
      
      untilTime.value = picked;
    }
  }

  // Check if times are selected
  bool get isTimesSelected => fromTime.value != null && untilTime.value != null;

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
    // Use default times if not set
    final from = fromTime.value ?? TimeOfDay(hour: 14, minute: 0);
    final until = untilTime.value ?? TimeOfDay(hour: 15, minute: 0);
    final date = '${selectedDate.value.day.toString().padLeft(2, '0')}/${selectedDate.value.month.toString().padLeft(2, '0')}/${selectedDate.value.year}';
    return '$date  ${formatTime(from)}-${formatTime(until)}';
  }

  // Edit booking
  void editBooking() {
    Get.back();
  }

  // Remove booking
  void removeBooking() {
/*    Get.defaultDialog(
      title: 'Remove Booking',
      middleText: 'Are you sure you want to remove this booking?',
      textConfirm: 'Yes',
      textCancel: 'No',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        Get.back();
        Get.snackbar(
          'Booking Removed',
          'Your booking has been removed',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );*/
  }

  // Proceed to payment
  void proceedToPayment() {
    Get.toNamed(AppRoutes.payment);
  }

  // Continue (from first screen) - navigate to summary screen
  // In edit mode, directly call update booking API instead of going to summary screen
  void continueBooking() {
    // Set default times if not selected
    if (fromTime.value == null) {
      fromTime.value = TimeOfDay(hour: 14, minute: 0); // Default 2:00 PM
    }
    if (untilTime.value == null) {
      untilTime.value = TimeOfDay(hour: 15, minute: 0); // Default 3:00 PM
    }
    
    // Check if in edit mode - if so, call update booking API directly
    if (isEditMode.value && bookingId.value.isNotEmpty) {
      callUpdateBookingAPI();
    } else {
      // Normal flow: navigate to summary screen with all booking data
      Get.toNamed(
        AppRoutes.summary,
        arguments: {
          'selected_date': selectedDate.value,
          'from_time': fromTime.value,
          'until_time': untilTime.value,
          'service_name': serviceName.value,
          'price': price.value,
          'location': location.value,
          'professional_id': professionalId.value,
          'service_format_id': serviceFormatId.value, // service_format_id for summary
          'professional_service_format_id': professionalServiceFormatId.value, // _id for create-booking API
          'booking_id': bookingId.value, // Pass booking_id for edit mode
          'is_edit_mode': isEditMode.value, // Pass edit mode flag
        },
      );
    }
  }
  
  void callUpdateBookingAPI() async {
    // Validate required fields
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
        message: 'Professional service format ID is missing',
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
      return;
    }
    
    if (bookingId.value.isEmpty) {
      showResponseDialog(
        message: 'Booking ID is missing',
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
    
    isLoading.value = true;
    
    // Get timezone
    String timezone = await _getCurrentTimezone();
    
    Map<String, dynamic> toJson() {
      // Format date as DD/MM/YYYY
      String formattedDate = DateFormat('dd/MM/yyyy').format(selectedDate.value);
      
      // Format time as HH:mm (24-hour format)
      String formatTime24Hour(TimeOfDay time) {
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      }
      
      final Map<String, dynamic> data = <String, dynamic>{};
      data['booking_id'] = bookingId.value;
      data['professional_id'] = professionalId.value;
      data['professional_service_format_id'] = professionalServiceFormatId.value; // _id
      data['date'] = formattedDate;
      data['from_time'] = formatTime24Hour(fromTime.value!);
      data['to_time'] = formatTime24Hour(untilTime.value!);
      data['timezone'] = timezone;
      
      print('========================================');
      print('Update Booking API Request:');
      print(data);
      print('========================================');
      
      return data;
    }
    
    // Use PUT method for update-booking API
    var service = _repository.sendPutApiRequest(toJson, update_booking, true);
    callDataService(
      service,
      onSuccess: _handleUpdateBookingSuccess,
      onError: _handleUpdateBookingError,
      isShowLoading: true,
    );
  }
  
  Future<void> _handleUpdateBookingSuccess(dynamic baseResponse) async {
    try {
      isLoading.value = false;
      
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
      String message = responseData['message'] ?? 'Booking updated successfully';
      
      if (success == true) {
        // Show success message and navigate back to bookings
        showResponseDialog(
          message: message,
          title: 'Success',
          isError: false,
          showButton: true,
          onOkPressed: () {
        // Navigate back to main screen (bookings tab)
        Get.until((route) => route.settings.name == AppRoutes.main);
        // Refresh bookings list
        if (Get.isRegistered<BookingsController>(tag: 'bookings')) {
          Get.find<BookingsController>(tag: 'bookings').loadBookings();
        }
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
      isLoading.value = false;
      showResponseDialog(
        message: "Error processing response: $e",
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    }
  }
  
  void _handleUpdateBookingError(Exception exception) {
    isLoading.value = false;
    String errorMessage = 'An error occurred while updating booking. Please try again.';
    
    if (exception != null && exception.toString().isNotEmpty) {
      errorMessage = exception.toString();
    }
    
    showResponseDialog(
      message: errorMessage,
      title: 'Error',
      isError: true,
      showButton: true,
      onOkPressed: () {},
    );
  }
}
