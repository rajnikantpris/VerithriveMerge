import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:intl/intl.dart';
import 'package:verithrive_dev/enduser/screens/payment/payment_end_webview_screen.dart';
import 'package:verithrive_dev/enduser/screens/payment_success/PaymentSuccessBinding.dart';
import 'package:verithrive_dev/enduser/screens/payment_success/PaymentSuccessScreen.dart';
import '../../../services/analytics_service.dart';
import '../../core/base/base_controller.dart';
import '../../data/repository/project_repository.dart';
import '../../network/exceptions/base_exception.dart';
import '../../utils/api_services.dart';
import '../../utils/common_dialog.dart';
import '../../routes/app_routes.dart';
import 'PaymentMethodType.dart';

class PaymentMethodController extends BaseController {
  final ProjectRepository _repository = Get.find(tag: (ProjectRepository).toString());
  
  // Observable variables
  var selectedPaymentMethod = Rxn<PaymentMethodType>();
  var cardNumber = ''.obs;
  var expiryDate = ''.obs;
  var cvv = ''.obs;
  var cardHolderName = ''.obs;
  var saveCardDetails = false.obs;
  var isLoading = false.obs;
  
  // Booking details from summary
  var selectedDate = DateTime.now().obs;
  var fromTime = Rxn<TimeOfDay>();
  var untilTime = Rxn<TimeOfDay>();
  var serviceName = 'Consultation - in person'.obs;
  var price = 30.0.obs;
  var location = 'Lorem Ipsum,*******'.obs;
  var professionalId = ''.obs;
  var serviceFormatId = ''.obs; // service_format_id (for reference, not used in API)
  var professionalServiceFormatId = ''.obs; // _id (used in create-booking API)
  var bookingId = ''.obs; // booking_id for update-booking API in edit mode
  var isEditMode = false.obs; // Flag to indicate edit mode

  // Text editing controllers
  final cardNumberController = TextEditingController();
  final expiryDateController = TextEditingController();
  final cvvController = TextEditingController();
  final cardHolderNameController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _receiveArguments();

    // Add listeners to update observables when text changes to trigger reactivity in Obx
    cardNumberController.addListener(() {
      cardNumber.value = cardNumberController.text;
    });
    expiryDateController.addListener(() {
      expiryDate.value = expiryDateController.text;
    });
    cvvController.addListener(() {
      cvv.value = cvvController.text;
    });
    cardHolderNameController.addListener(() {
      cardHolderName.value = cardHolderNameController.text;
    });
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
        // Store service_format_id for reference (not used in API)
        serviceFormatId.value = arguments['service_format_id'] as String;
      }
      if (arguments['professional_service_format_id'] != null) {
        // Handle both object and string cases - extract _id for create-booking API
        dynamic serviceFormatData = arguments['professional_service_format_id'];
        if (serviceFormatData is Map<String, dynamic>) {
          // If it's an object, extract _id
          professionalServiceFormatId.value = serviceFormatData['_id']?.toString() ?? 
                                             serviceFormatData['id']?.toString() ?? '';
        } else if (serviceFormatData is String) {
          // If it's already a string (the _id), use it directly
          professionalServiceFormatId.value = serviceFormatData;
        }
      }
      if (arguments['booking_id'] != null) {
        // Store booking_id for update-booking API in edit mode
        bookingId.value = arguments['booking_id'] as String;
      }
      if (arguments['is_edit_mode'] != null) {
        // Store edit mode flag
        isEditMode.value = arguments['is_edit_mode'] as bool;
      }
    }
  }

  @override
  void onClose() {
    cardNumberController.dispose();
    expiryDateController.dispose();
    cvvController.dispose();
    cardHolderNameController.dispose();
    super.onClose();
  }

  // Select payment method
  void selectPaymentMethod(PaymentMethodType method) {
    selectedPaymentMethod.value = method;
    // Clear card details when switching methods
    if (method != PaymentMethodType.creditCard) {
      clearCardDetails();
    }
  }

  // Clear card details
  void clearCardDetails() {
    cardNumberController.clear();
    expiryDateController.clear();
    cvvController.clear();
    cardHolderNameController.clear();
    saveCardDetails.value = false;
    
    // Also clear the observables
    cardNumber.value = '';
    expiryDate.value = '';
    cvv.value = '';
    cardHolderName.value = '';
  }

  // Toggle save card details
  void toggleSaveCard(bool? value) {
    saveCardDetails.value = value ?? false;
  }

  // Check if continue button should be enabled
  bool get isContinueEnabled {
    return selectedPaymentMethod.value != null;
  }

  // Format card number with spaces
  String formatCardNumber(String value) {
    value = value.replaceAll(' ', '');
    String formatted = '';
    for (int i = 0; i < value.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += value[i];
    }
    return formatted;
  }

  // Format expiry date
  String formatExpiryDate(String value) {
    value = value.replaceAll('/', '');
    if (value.length >= 2) {
      return value.substring(0, 2) + '/' + value.substring(2);
    }
    return value;
  }

  // Continue with payment
  void continuePayment() {
    if (!isContinueEnabled) {
      Get.snackbar(
        'Incomplete Information',
        'Please fill in all required fields',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Analytics: Log continue button tap event
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = Get.arguments as Map<String, dynamic>?;
      final category = args?['category'] as String? ?? 'wellness';
      
      final item = {
        'item_id': professionalId.value,
        'item_name': serviceName.value,
        'item_category': category,
        'item_variant': serviceName.value,
        'item_brand': professionalId.value,
        'price': price.value.toString(),
        'quantity': 1,
        'currency': 'GBP',
      };
      
      AnalyticsService.instance.logEvent(
        name: 'begin_checkout',
        parameters: {
          'screen_name': 'PaymentMethodScreen',
          'screen_class': 'PaymentMethodScreen',
          'page_category': category,
          'items': [item],
        },
      );
    });

    // Call create-booking API (edit mode is handled in SummaryController)
    callCreateBookingAPI();
  }
  
  // Call create booking API
  void callCreateBookingAPI() {
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
      // Format date as DD/MM/YYYY
      String formattedDate = DateFormat('dd/MM/yyyy').format(selectedDate.value);
      
      // Format time as HH:mm (24-hour format)
      String formatTime24Hour(TimeOfDay time) {
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      }
      
      final Map<String, dynamic> data = <String, dynamic>{};
      data['professional_id'] = professionalId.value;
      // professional_service_format_id should be the _id from service format object
      data['professional_service_format_id'] = professionalServiceFormatId.value;
      data['date'] = formattedDate;
      data['from_time'] = formatTime24Hour(fromTime.value!);
      data['to_time'] = formatTime24Hour(untilTime.value!);
      
      print('========================================');
      print('Create Booking API Request:');
      print('professional_service_format_id (_id): ${professionalServiceFormatId.value}');
      print(data);
      print('========================================');
      
      return data;
    }
    
    // Set loading state
    isLoading.value = true;
    
    var service = _repository.sendPostApiRequest(toJson, create_booking, true);
    callDataService(
      service,
      onSuccess: _handleCreateBookingSuccess,
      onError: _handleCreateBookingError,
      isShowLoading: true, // We'll show custom loading UI
    );
  }
  
  Future<void> _handleCreateBookingSuccess(dynamic baseResponse) async {
    try {
      // Stop loading
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
      String message = responseData['message'] ?? 'Booking created successfully';
      
      if (success == true) {
        String? checkoutUrl;
        if (responseData['data'] != null && 
            responseData['data']['payment_link'] != null) {
          checkoutUrl = responseData['data']['payment_link']['checkout_url'];
        }

        if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
          // Navigate to WebView
          final result = await Get.to(() => PaymentEndWebViewScreen(url: checkoutUrl!));
          
          if (result == 'success') {
            Get.offAll(
              () => PaymentSuccessScreen(),
              binding: PaymentSuccessBinding(),
            );
          } else if (result == 'failed') {
            showResponseDialog(
              message: 'Payment failed or was cancelled.',
              title: 'Payment Error',
              isError: true,
              showButton: true,
              onOkPressed: () {},
            );
          }
        }
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
  
  void _handleCreateBookingErrorOld(dynamic e) {
    // Stop loading
    isLoading.value = false;
    
    String errorMessage = 'An error occurred while creating booking. Please try again.';
    
    if (e != null && e.toString().isNotEmpty) {
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

  void _handleCreateBookingError(dynamic e) {
    isLoading.value = false;

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
  
}
