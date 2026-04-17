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
import 'package:verithrive_dev/services/analytics_service.dart';

class BookingsController extends BaseController {
  final ProjectRepository _repository = Get.find(tag: (ProjectRepository).toString());
  
  // Observable list of bookings
  var myBookings = <Booking>[].obs;
  var pastBookings = <Booking>[].obs;
  var showCancellationSuccess = false.obs;
  var isLoading = false.obs;
  var targetBookingId = ''.obs;
  var highlightedBookingId = ''.obs;
  final ScrollController scrollController = ScrollController();
  final Map<String, GlobalKey> bookingKeys = {};

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  GlobalKey getOrCreateKey(String bookingId) {
    if (!bookingKeys.containsKey(bookingId)) {
      bookingKeys[bookingId] = GlobalKey();
    }
    return bookingKeys[bookingId]!;
  }

  void scrollToBooking(String bookingId) {
    targetBookingId.value = bookingId;
    if (bookingId.isNotEmpty) {
      // Wait for UI to settle after navigation/refresh
      Future.delayed(const Duration(milliseconds: 500), () {
        _performScroll();
      });
    }
  }

  void _performScroll() {
    if (targetBookingId.value.isEmpty) return;

    final bookingId = targetBookingId.value;
    final key = bookingKeys[bookingId];

    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        alignment: 0.1, // Scroll to near the top
      );

      // Start highlight
      highlightedBookingId.value = bookingId;
      targetBookingId.value = ''; // Done with this target

      // Remove highlight after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (highlightedBookingId.value == bookingId) {
          highlightedBookingId.value = '';
        }
      });
    } else {
      // If data is still loading or view not ready, retry in a bit
      if (!isLoading.value) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (targetBookingId.value == bookingId) {
            _performScroll();
          }
        });
      }
    }
  }

  @override
  void fetchData() async {
    print("API Called: Bookings Loaded");
    loadBookings();
  }

  // Refresh data method called by MainScreen
  void refreshData() {
    _checkAuthAndLoadBookings();
  }

  // Refresh data method called by MainScreen
  void loadBookings() {
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
      return <String, dynamic>{};
    }
    
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

      if (success == true && responseData['data'] != null) {
        Map<String, dynamic> dataMap = responseData['data'] as Map<String, dynamic>;

        // Parse my_bookings
        List<dynamic>? myBookingsList = dataMap['my_bookings'] as List<dynamic>?;
        if (myBookingsList != null) {
          myBookings.value = myBookingsList.map((json) => _parseBooking(json, false)).toList();
        }
        
        // Parse past_bookings
        List<dynamic>? pastBookingsList = dataMap['past_bookings'] as List<dynamic>?;
        if (pastBookingsList != null) {
          pastBookings.value = pastBookingsList.map((json) => _parseBooking(json, true)).toList();
        }

        // Trigger scroll if we have a target
        if (targetBookingId.value.isNotEmpty) {
          scrollToBooking(targetBookingId.value);
        }
      }
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
    }
  }

  void _handleBookingsListError(Exception exception) {
    isLoading.value = false;
  }

  Booking _parseBooking(Map<String, dynamic> json, bool isPast) {
    DateTime? bookingDateTime;
    try {
      String? timeRange = json['booking_time_range']?.toString();
      if (timeRange != null && timeRange.isNotEmpty) {
        List<String> parts = timeRange.split(' ');
        if (parts.length >= 3) {
          String dateStr = parts[0];
          String timeStr = parts[1] + ' ' + parts[2];
          List<String> dateParts = dateStr.split('/');
          if (dateParts.length == 3) {
            int day = int.parse(dateParts[0]);
            int month = int.parse(dateParts[1]);
            int year = int.parse(dateParts[2]);
            List<String> timeParts = timeStr.split(':');
            if (timeParts.length == 2) {
              int hour = int.parse(timeParts[0]);
              String minuteAndPeriod = timeParts[1];
              int minute = int.parse(minuteAndPeriod.split(' ')[0]);
              String period = minuteAndPeriod.split(' ')[1].toUpperCase();
              if (period == 'PM' && hour != 12) hour += 12;
              else if (period == 'AM' && hour == 12) hour = 0;
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

    // Parse price_breakdown
    PriceBreakdown? priceBreakdown;
    if (json['price_breakdown'] != null) {
      Map<String, dynamic> pb = json['price_breakdown'] as Map<String, dynamic>;
      priceBreakdown = PriceBreakdown(
        serviceAmount: (pb['service_amount'] as num?)?.toDouble() ?? 0.0,
        platformFee: (pb['platform_fee'] as num?)?.toDouble() ?? 0.0,
        bookingFixDepositAmount: (pb['booking_fix_deposit_amount'] as num?)?.toDouble() ?? 0.0,
        refundAmount: (pb['refund_amount'] as num?)?.toDouble() ?? 0.0,
      );
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
      professionalServiceFormatId: json['professional_service_format_id']?.toString(),
      bookingStatus: json['status']?.toString(),
      paymentStatus: json['payment_status']?.toString(),
      priceBreakdown: priceBreakdown,
      uniqueBookingId: json['unique_booking_id']?.toString(),
      uniqueTransactionId: json['unique_transaction_id']?.toString(),
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
        // Analytics: Log booking cancellation
        

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
