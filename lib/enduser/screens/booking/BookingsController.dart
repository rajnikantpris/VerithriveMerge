import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/screens/consultation/ConsultationBinding.dart';
import 'package:verithrive_dev/enduser/screens/consultation/ConsultationBookingScreen.dart';
import 'package:verithrive_dev/enduser/screens/message/ChatDetailBinding.dart';
import 'package:verithrive_dev/enduser/screens/message/ChatDetailScreen.dart';
import '../../core/base/base_controller.dart';
import '../../data/repository/project_repository.dart';
import '../../models/Booking.dart';
import '../../models/Conversation.dart';
import '../../routes/app_routes.dart';
import '../../utils/api_services.dart';
import '../../utils/app_colors.dart';
import '../../utils/auth_service.dart';

class BookingsController extends BaseController {
  final ProjectRepository _repository = Get.find(tag: (ProjectRepository).toString());
  
  // Observable list of bookings
  var myBookings = <Booking>[].obs;
  var pastBookings = <Booking>[].obs;
  var showCancellationSuccess = false.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Don't check authentication on init - let user navigate first
    // Authentication will be checked when data is actually loaded
  }

  @override
  void fetchData() async {
    print("API Called: Bookings Loaded");
    loadBookings();
  }

  // Refresh data method called by MainScreen
  void refreshData() {
    // Check authentication before loading bookings
    _checkAuthAndLoadBookings();
  }

  // Refresh data method called by MainScreen
  void loadBookings() {
    // Check authentication before loading bookings
    _checkAuthAndLoadBookings();
  }

  // Check authentication and load bookings
  Future<void> _checkAuthAndLoadBookings() async {
    bool canAccess = await AuthService.requireAuth();
    if (canAccess) {
      callBookingsListAPI();
    }
  }

  void callBookingsListAPI() {
    isLoading.value = true;
    
    Map<String, dynamic> toJson() {
      final Map<String, dynamic> data = <String, dynamic>{};
      
      print('========================================');
      print('Bookings List API Request (POST):');
      print(data);
      print('========================================');
      
      return data;
    }
    
    // Using POST request
    var service = _repository.sendPostApiRequest(toJson, bookings_list, true);
    callDataService(
      service,
      onSuccess: _handleBookingsListSuccess,
      onError: _handleBookingsListError,
      isShowLoading: true,
    );
  }

  Future<void> _handleBookingsListSuccess(dynamic baseResponse) async {
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
      String message = responseData['message'] ?? '';
      
      if (success == true && responseData['data'] != null) {
        Map<String, dynamic> dataMap = responseData['data'] as Map<String, dynamic>;
        
        // Parse my_bookings
        List<dynamic>? myBookingsList = dataMap['my_bookings'] as List<dynamic>?;
        if (myBookingsList != null && myBookingsList.isNotEmpty) {
          myBookings.value = myBookingsList.map((json) => _parseBooking(json, false)).toList();
        } else {
          myBookings.value = [];
        }
        
        // Parse past_bookings
        List<dynamic>? pastBookingsList = dataMap['past_bookings'] as List<dynamic>?;
        if (pastBookingsList != null && pastBookingsList.isNotEmpty) {
          pastBookings.value = pastBookingsList.map((json) => _parseBooking(json, true)).toList();
        } else {
          pastBookings.value = [];
        }
        
        print('========================================');
        print('Bookings List API Success:');
        print('My Bookings: ${myBookings.length}');
        print('Past Bookings: ${pastBookings.length}');
        print('========================================');
      } else {
        print('Bookings List API Error: $message');
        myBookings.value = [];
        pastBookings.value = [];
      }
      isLoading.value = false;
    } catch (e) {
      print('Error parsing bookings list response: $e');
      myBookings.value = [];
      pastBookings.value = [];
      isLoading.value = false;
    }
  }

  void _handleBookingsListError(Exception exception) {
    print('Bookings List API Error: $exception');
    myBookings.value = [];
    pastBookings.value = [];
    isLoading.value = false;
  }

  Booking _parseBooking(Map<String, dynamic> json, bool isPast) {
    // Parse booking_time_range (format: "06/01/2026 05:00 PM - 06:00 PM")
    DateTime? bookingDateTime;
    try {
      String? timeRange = json['booking_time_range']?.toString();
      if (timeRange != null && timeRange.isNotEmpty) {
        // Extract date and time from "06/01/2026 05:00 PM - 06:00 PM"
        List<String> parts = timeRange.split(' ');
        if (parts.length >= 3) {
          String dateStr = parts[0]; // "06/01/2026"
          String timeStr = parts[1] + ' ' + parts[2]; // "05:00 PM"
          
          // Parse date (DD/MM/YYYY)
          List<String> dateParts = dateStr.split('/');
          if (dateParts.length == 3) {
            int day = int.parse(dateParts[0]);
            int month = int.parse(dateParts[1]);
            int year = int.parse(dateParts[2]);
            
            // Parse time (HH:mm AM/PM)
            List<String> timeParts = timeStr.split(':');
            if (timeParts.length == 2) {
              int hour = int.parse(timeParts[0]);
              String minuteAndPeriod = timeParts[1];
              int minute = int.parse(minuteAndPeriod.split(' ')[0]);
              String period = minuteAndPeriod.split(' ')[1].toUpperCase();
              
              // Convert to 24-hour format
              if (period == 'PM' && hour != 12) {
                hour += 12;
              } else if (period == 'AM' && hour == 12) {
                hour = 0;
              }
              
              bookingDateTime = DateTime(year, month, day, hour, minute);
            }
          }
        }
      }
    } catch (e) {
      print('Error parsing booking date/time: $e');
      bookingDateTime = DateTime.now(); // Fallback to current date/time
    }

    String? bookingDateTimeRange = json['booking_time_range']?.toString();
    
    // Parse professional data
    Map<String, dynamic>? professional = json['professional'] as Map<String, dynamic>?;
    String therapistName = professional?['full_name']?.toString() ?? 'Unknown';
    String therapistTitle = professional?['profession_sub_type']?.toString() ?? '';
    String? therapistImageUrl = professional?['profile_picture']?.toString();
    String? professionalId = professional?['_id']?.toString();
    
    // Parse price
    double price = 0.0;
    if (json['price'] != null) {
      if (json['price'] is num) {
        price = (json['price'] as num).toDouble();
      } else if (json['price'] is String) {
        price = double.tryParse(json['price']) ?? 0.0;
      }
    }
    
    // Parse duration_minutes
    int? durationMinutes;
    if (json['duration_minutes'] != null) {
      if (json['duration_minutes'] is num) {
        durationMinutes = (json['duration_minutes'] as num).toInt();
      } else if (json['duration_minutes'] is String) {
        durationMinutes = int.tryParse(json['duration_minutes']);
      }
    }
    
    // Note: professional_service_format_id and service_format_id are not in booking list response
    // They will need to be retrieved from booking details API or stored when booking is created
    // For now, we'll extract what we can from the response
    
    return Booking(
      id: json['_id']?.toString() ?? '',
      consultationType: json['service_format_name']?.toString() ?? 'Consultation - in person',
      price: price,
      dateTime: bookingDateTime ?? DateTime.now(),
      address: json['full_address']?.toString() ?? json['work_address']?.toString() ?? '',
      therapistName: therapistName,
      therapistTitle: therapistTitle,
      therapistImageUrl: therapistImageUrl?.isNotEmpty == true ? therapistImageUrl : null,
      isPast: isPast,
      professionalId: professionalId,
      durationMinutes: durationMinutes,
      dateTimeRange: bookingDateTimeRange,
      serviceFormatId: json['service_format_id']?.toString(),
      professionalServiceFormatId: json['professional_service_format_id']?.toString()
      // professional_service_format_id and service_format_id will be set when navigating to edit
    );
  }

  void showCancelBookingDialog(String bookingId) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cancel this booking!',
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Life happens. Are you sure you want to cancel?',
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.color2D2D2D,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    cancelBooking(bookingId);
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.redDark,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Yes, cancel booking',
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12),
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'No, go back',
                  style: TextStyle(
                    fontFamily: 'Rubik',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void cancelBooking(String bookingId) {
    // Call cancel booking API
    callCancelBookingAPI(bookingId);
  }

  void callCancelBookingAPI(String bookingId) {
    // Construct API endpoint with booking ID
    String apiEndpoint = 'bookings/$bookingId';
    
    print('========================================');
    print('Cancel Booking API Request (DELETE):');
    print('Endpoint: $apiEndpoint');
    print('Booking ID: $bookingId');
    print('========================================');
    
    var service = _repository.sendDeleteApiRequest(
      apiEndpoint,
      true, // isToken = true (requires authentication)
    );

    callDataService(
      service,
      onSuccess: (response) => _handleCancelBookingSuccess(response, bookingId),
      onError: _handleCancelBookingError,
      isShowLoading: true,
    );
  }

  Future<void> _handleCancelBookingSuccess(dynamic baseResponse, String bookingId) async {
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
      String message = responseData['message'] ?? 'Booking cancelled successfully';
      
      if (success == true) {
        // Remove booking from myBookings
        myBookings.removeWhere((booking) => booking.id == bookingId);
        
        print('Booking $bookingId cancelled successfully');
        
        // Show success screen
        showCancellationSuccess.value = true;
        
        // Hide success screen after 2 seconds
        Future.delayed(Duration(seconds: 2), () {
          showCancellationSuccess.value = false;
        });
        
        // Optionally reload bookings list to ensure consistency
        // loadBookings();
      } else {
        print('Cancel Booking API Error: $message');
        // Show error dialog
        Get.snackbar(
          'Error',
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red,
        );
      }
    } catch (e) {
      print('Error parsing cancel booking response: $e');
      Get.snackbar(
        'Error',
        'Failed to cancel booking. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red,
      );
    }
  }

  void _handleCancelBookingError(Exception exception) {
    print('Cancel Booking API Error: $exception');
    Get.snackbar(
      'Error',
      'Failed to cancel booking. Please try again.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red,
    );
  }

  void editBooking(String bookingId) {
    // Find the booking
    Booking? booking = myBookings.firstWhereOrNull((b) => b.id == bookingId);
    if (booking == null) {
      booking = pastBookings.firstWhereOrNull((b) => b.id == bookingId);
    }
    
    if (booking == null) {
      print('Booking not found: $bookingId');
      Get.snackbar(
        'Error',
        'Booking not found',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    // Calculate duration from booking time range
    // Parse booking_time_range to get duration
    int durationMinutes = booking.durationMinutes ?? 30; // Default to 30 if not available
    
    // Navigate to consultation booking screen with booking data
    Get.to(
      () => ConsultationBookingScreen(),
      binding: ConsultationBinding(),
      arguments: {
        'professional_id': booking.professionalId ?? '',
        'duration_minutes': durationMinutes,
        'service_name': booking.consultationType,
        'price': booking.price,
        'location': booking.address,
        'service_format_id': booking.professionalServiceFormatId ?? '',
        'professional_service_format_id': booking.professionalServiceFormatId ?? '',
        'booking_id': bookingId,
        'is_edit_mode': true,
        'selected_date': booking.dateTime,
      },
    );
  }

  void messageTherapist(String therapistName, String? professionalId) {
    messageTherapistWithProfile(
      therapistName,
      professionalId,
      profileImageUrl: null,
    );
  }

  Future<void> messageTherapistWithProfile(
    String therapistName,
    String? professionalId, {
    String? profileImageUrl,
  }) async {
    final canAccess = await AuthService.requireAuth();
    if (!canAccess) return;

    if (professionalId == null || professionalId.isEmpty) {
      Get.snackbar(
        'Error',
        'Unable to start chat. Therapist id not found.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final conversation = Conversation(
      id: '', // Empty ID to let chat system create room
      name: therapistName,
      profileImageUrl: (profileImageUrl != null && profileImageUrl.isNotEmpty)
          ? profileImageUrl
          : null,
      lastMessage: '',
      lastMessageTime: DateTime.now(),
      userId: professionalId,
      isOnline: false,
      isHighlighted: false,
      unreadCount: 0,
    );

    Get.to(
      () => ChatDetailScreen(),
      binding: ChatDetailBinding(),
      arguments: conversation,
    );
  }
}
