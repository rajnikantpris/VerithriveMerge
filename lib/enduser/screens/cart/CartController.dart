import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:verithrive_dev/enduser/screens/payment/PaymentMethodBinding.dart';
import 'package:verithrive_dev/enduser/screens/payment/PaymentMethodScreen.dart';
import 'package:verithrive_dev/enduser/screens/summary/SummaryBinding.dart';
import 'package:verithrive_dev/enduser/screens/summary/SummaryScreen.dart';
import 'package:verithrive_dev/utils/timezone_helper.dart';
import '../../core/base/base_controller.dart';
import '../../data/repository/project_repository.dart';
import '../../utils/api_services.dart';
import '../../utils/common_dialog.dart';
import '../../utils/app_colors.dart';
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
  
  // Available time slots from consultation booking (only AVAILABLE slots)
  var availableTimeSlots = <TimeOfDay>[].obs;
  
  // Slot duration in minutes
  var slotDurationMinutes = 15.obs;
  
  // Get slot duration in minutes (calculated from original times or from argument)
  int get slotDuration {
    // If slot duration was provided, use it
    if (slotDurationMinutes.value != 15 || (originalFromTime.value != null && originalUntilTime.value != null)) {
      // Calculate from original times if not provided
      if (originalFromTime.value != null && originalUntilTime.value != null) {
        int fromMinutes = originalFromTime.value!.hour * 60 + originalFromTime.value!.minute;
        int untilMinutes = originalUntilTime.value!.hour * 60 + originalUntilTime.value!.minute;
        int duration = untilMinutes - fromMinutes;
        if (duration > 0) {
          return duration;
        }
      }
    }
    return slotDurationMinutes.value;
  }
  
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
  var category = ''.obs;
  var itemVariant = ''.obs;
  var itemBrand = ''.obs;

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
      if (arguments['category'] != null) {
        category.value = arguments['category'] as String;
      }
      if (arguments['item_variant'] != null) {
        itemVariant.value = arguments['item_variant'].toString();
      }
      if (arguments['item_brand'] != null) {
        itemBrand.value = arguments['item_brand'].toString();
      }
      if (arguments['available_time_slots'] != null) {
        try {
          List<dynamic> slots = arguments['available_time_slots'] as List<dynamic>;
          availableTimeSlots.value = slots
              .where((slot) => slot is TimeOfDay)
              .cast<TimeOfDay>()
              .toList();
        } catch (e) {
          print('Error parsing available_time_slots: $e');
          availableTimeSlots.value = [];
        }
      }
      if (arguments['slot_duration_minutes'] != null) {
        try {
          if (arguments['slot_duration_minutes'] is int) {
            slotDurationMinutes.value = arguments['slot_duration_minutes'] as int;
          } else if (arguments['slot_duration_minutes'] is num) {
            slotDurationMinutes.value = (arguments['slot_duration_minutes'] as num).toInt();
          }
        } catch (e) {
          print('Error parsing slot_duration_minutes: $e');
        }
      }
    }
  }
  
  // Helper method to get current timezone
  Future<String> _getCurrentTimezone() async {
    try {
      // TimezoneInfo timezone = await FlutterTimezone.getLocalTimezone();
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
    
    // Check if selected date is today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(selectedDate.value.year, selectedDate.value.month, selectedDate.value.day);
    final bool isToday = selectedDay.isAtSameMomentAs(today);
    
    // Get available time slots - if available, use them; otherwise fallback to default picker
    if (availableTimeSlots.isNotEmpty) {
      // Show custom time picker with only available slots
      final TimeOfDay? picked = await _showAvailableTimePicker(
        context: context,
        availableTimes: availableTimeSlots,
        initialTime: fromTime.value ?? availableTimeSlots.first,
      );
      
      if (picked != null) {
        // Slot duration is calculated from original times - automatically calculate until time
        TimeOfDay calculatedUntilTime = _addMinutes(picked, slotDuration);
        
        // Set from time and automatically calculate until time
        fromTime.value = picked;
        untilTime.value = calculatedUntilTime;
      }
      return;
    }
    
    // Fallback: Use default Flutter time picker if no available slots provided
    TimeOfDay? minTime;
    if (isToday) {
      final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);
      int currentMinutes = currentTime.hour * 60 + currentTime.minute;
      int originalMinutes = originalFromTime.value!.hour * 60 + originalFromTime.value!.minute;
      minTime = currentMinutes > originalMinutes ? currentTime : originalFromTime.value;
    } else {
      minTime = originalFromTime.value;
    }
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: fromTime.value ?? minTime!,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      // Get slot duration
      int slotDurationValue = slotDuration;
      
      // Validate: picked time must be within valid range
      int pickedMinutes = picked.hour * 60 + picked.minute;
      int maxMinutes = originalUntilTime.value!.hour * 60 + originalUntilTime.value!.minute;
      
      // Calculate the end time if this time is selected
      int calculatedEndMinutes = pickedMinutes + slotDurationValue;
      
      // Validate: calculated end time (picked + duration) must not exceed originalUntilTime
      if (calculatedEndMinutes > maxMinutes) {
        TimeOfDay maxAllowedStart = _subtractMinutes(originalUntilTime.value!, slotDurationValue);
        showResponseDialog(
          message: 'Selected time would exceed available time range. Please select a time before ${formatTime(maxAllowedStart)}.',
          title: 'Invalid Time Selection',
          isError: true,
          showButton: true,
          onOkPressed: () {},
        );
        return;
      }
      
      // Slot duration is calculated from original times - automatically calculate until time
      TimeOfDay calculatedUntilTime = _addMinutes(picked, slotDurationValue);
      
      // Set from time and automatically calculate until time
      fromTime.value = picked;
      untilTime.value = calculatedUntilTime;
    }
  }
  
  // Helper method to add minutes to TimeOfDay
  TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
    int totalMinutes = time.hour * 60 + time.minute + minutes;
    int newHour = (totalMinutes ~/ 60) % 24;
    int newMinute = totalMinutes % 60;
    return TimeOfDay(hour: newHour, minute: newMinute);
  }
  
  // Helper method to subtract minutes from TimeOfDay
  TimeOfDay _subtractMinutes(TimeOfDay time, int minutes) {
    int totalMinutes = time.hour * 60 + time.minute - minutes;
    if (totalMinutes < 0) {
      totalMinutes += 24 * 60; // Handle negative by adding 24 hours
    }
    int newHour = (totalMinutes ~/ 60) % 24;
    int newMinute = totalMinutes % 60;
    return TimeOfDay(hour: newHour, minute: newMinute);
  }
  
  // Show custom time picker with only available time slots
  Future<TimeOfDay?> _showAvailableTimePicker({
    required BuildContext context,
    required List<TimeOfDay> availableTimes,
    required TimeOfDay initialTime,
  }) async {
    TimeOfDay? selectedTime = initialTime;
    
    // Find closest available time to initial time
    if (!availableTimes.any((t) => t.hour == initialTime.hour && t.minute == initialTime.minute)) {
      int initialMinutes = initialTime.hour * 60 + initialTime.minute;
      int minDiff = 9999;
      for (var time in availableTimes) {
        int diff = (time.hour * 60 + time.minute - initialMinutes).abs();
        if (diff < minDiff) {
          minDiff = diff;
          selectedTime = time;
        }
      }
    }
    
    return showDialog<TimeOfDay>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            constraints: BoxConstraints(maxHeight: 400, maxWidth: 300),
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  'Select Time',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                SizedBox(height: 16),
                
                // Time Selection List
                Flexible(
                  child: _AvailableTimePickerList(
                    availableTimes: availableTimes,
                    initialTime: selectedTime!,
                    onTimeSelected: (time) {
                      selectedTime = time;
                    },
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.greyText,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(selectedTime),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Select Until Time - Disabled (until time is automatically calculated)
  Future<void> selectUntilTime(BuildContext context) async {
    // Until time is automatically calculated based on from time (15 minutes later)
    // This method is kept for compatibility but does nothing
    return;
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
    Get.to(
      () => PaymentMethodScreen(),
      binding: PaymentMethodBinding(),
    );
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
      Get.to(
        () => SummaryScreen(),
        binding: SummaryBinding(),
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
          'category': category.value,
          'item_variant': itemVariant.value,
          'item_brand': itemBrand.value,
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
        // Navigate back to bookings screen (CartScreen -> ConsultationBookingScreen -> BookingsScreen)
        Get.back(); // Close CartScreen
        Get.back(); // Close ConsultationBookingScreen
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

// Widget for available time picker list
class _AvailableTimePickerList extends StatefulWidget {
  final List<TimeOfDay> availableTimes;
  final TimeOfDay initialTime;
  final Function(TimeOfDay) onTimeSelected;

  const _AvailableTimePickerList({
    required this.availableTimes,
    required this.initialTime,
    required this.onTimeSelected,
  });

  @override
  State<_AvailableTimePickerList> createState() => _AvailableTimePickerListState();
}

class _AvailableTimePickerListState extends State<_AvailableTimePickerList> {
  late TimeOfDay selectedTime;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    selectedTime = widget.initialTime;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedTime();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedTime() {
    final index = widget.availableTimes.indexWhere(
      (time) => time.hour == selectedTime.hour && time.minute == selectedTime.minute,
    );
    if (index != -1 && _scrollController.hasClients) {
      final scrollPosition = index * 60.0;
      final viewportHeight = _scrollController.position.viewportDimension;
      final targetPosition = scrollPosition - (viewportHeight / 2) + 30;
      
      _scrollController.animateTo(
        targetPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.availableTimes.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text(
            'No available times',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.greyText,
            ),
          ),
        ),
      );
    }

    // Find initial selected index
    int initialIndex = widget.availableTimes.indexWhere(
      (time) => time.hour == selectedTime.hour && time.minute == selectedTime.minute,
    );
    if (initialIndex == -1 && widget.availableTimes.isNotEmpty) {
      initialIndex = 0;
      selectedTime = widget.availableTimes[0];
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.availableTimes.length,
      itemBuilder: (context, index) {
        final time = widget.availableTimes[index];
        final isSelected = time.hour == selectedTime.hour && time.minute == selectedTime.minute;
        
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedTime = time;
                });
                widget.onTimeSelected(time);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected 
                        ? AppColors.primaryColor 
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatTime(time),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected 
                            ? AppColors.primaryColor 
                            : AppColors.black,
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: AppColors.primaryColor,
                        size: 18,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
