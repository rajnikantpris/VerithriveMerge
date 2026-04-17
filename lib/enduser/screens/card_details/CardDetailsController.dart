import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/core/values/app_text.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../core/base/base_controller.dart';
import '../../data/repository/project_repository.dart';
import '../../network/exceptions/base_exception.dart';
import '../../utils/api_services.dart';
import '../../utils/common_dialog.dart';
import 'package:verithrive_dev/services/analytics_service.dart';
import 'CardModel.dart';
import 'CardNumberFormatter.dart';
import 'ExpiryDateFormatter.dart';

class CardDetailsController extends BaseController {
  final ProjectRepository _repository = Get.find(tag: (ProjectRepository).toString());
  
  var cards = <CardModel>[].obs;
  var selectedCardIndex = 0.obs;
  final isLoading = false.obs;

  // Form controllers
  final nameController = TextEditingController();
  final cardNumberController = TextEditingController();
  final expiryDateController = TextEditingController();
  final cvvController = TextEditingController();
  final isDefaultCard = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadCards();
  }

  void loadCards() {
    fetchCardsFromAPI();
  }

  void fetchCardsFromAPI() {
    isLoading.value = true;
    var service = _repository.sendGetApiNoParamRequest(get_card_details);
    
    callDataService(
      service,
      onSuccess: _handleGetCardsSuccess,
      onError: _handleGetCardsError,
      isShowLoading: false, // We're using isLoading observable
    );
  }

  Future<void> _handleGetCardsSuccess(dynamic baseResponse) async {
    isLoading.value = false;
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
        // Analytics: Log cards loaded
        

        List<dynamic> cardsData = responseData['data'] as List<dynamic>;
        cards.value = cardsData.map((json) => CardModel.fromJson(json as Map<String, dynamic>)).toList();
        
        // Set default card index
        for (int i = 0; i < cards.length; i++) {
          if (cards[i].isDefault == true) {
            selectedCardIndex.value = i;
            break;
          }
        }
      } else {
        cards.value = [];
      }
    } catch (e) {
      cards.value = [];
      showResponseDialog(
        message: "Error loading cards: $e",
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    }
  }

  void _handleGetCardsError(dynamic e) {
    isLoading.value = false;
    cards.value = [];
    
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

  void selectCard(int index) {
    selectedCardIndex.value = index;
  }

  void showAddCardDialogOld(BuildContext context) {
    _resetForm();
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main content container
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Debit/Credit card',
                        style: AppTextStyles.popinMediumTextStyle(
                          fontSize: 16,
                          color: AppColors.greyText,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.grey),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Name on card',
                      hintStyle: AppTextStyles.popinRegularTextStyle(
                        fontSize: 14,
                        color: AppColors.color919191
                      ),
                      filled: true,
                      fillColor: AppColors.lightGreyF5F7F8,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: cardNumberController,
                    decoration: InputDecoration(
                      hintText: 'Card number',
                      hintStyle: AppTextStyles.popinRegularTextStyle(
                          fontSize: 14,
                          color: AppColors.color919191
                      ),
                      filled: true,
                      fillColor: AppColors.lightGreyF5F7F8,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: expiryDateController,
                          decoration: InputDecoration(
                            hintText: 'Expiry date',
                            hintStyle: AppTextStyles.popinRegularTextStyle(
                                fontSize: 14,
                                color: AppColors.color919191
                            ),
                            filled: true,
                            fillColor: AppColors.lightGreyF5F7F8,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(left: 10,right: 5),
                                child: SvgPicture.asset(AppAssets.expire_calendar,height: 20,width: 20,)),
                            prefixIconConstraints: BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: cvvController,
                          decoration: InputDecoration(
                            hintText: 'CVV',
                            hintStyle: AppTextStyles.popinRegularTextStyle(
                                fontSize: 14,
                                color: AppColors.color919191
                            ),
                            filled: true,
                            fillColor: AppColors.lightGreyF5F7F8,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          keyboardType: TextInputType.number,
                          obscureText: true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Obx(() => Row(
                    children: [
                      GestureDetector(
                        onTap: () => isDefaultCard.value = !isDefaultCard.value,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDefaultCard.value ? AppColors.primaryColor : AppColors.grey,
                              width: 2,
                            ),
                            color: isDefaultCard.value ? AppColors.primaryColor : Colors.transparent,
                          ),
                          child: isDefaultCard.value
                              ? Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Use this as a default payment method.',
                        style: AppTextStyles.regularTextStyle(
                          fontSize: 12,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  )),
                ],
              ),
            ),
            // Submit Button - Attached at bottom
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _saveCard(),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      'Save card',
                      style: AppTextStyles.mediumTextStyle(
                        fontSize: 16,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showEditCardDialogOld(BuildContext context, CardModel card, int index) {
    nameController.text = card.nameOnCard;
    // Show masked card number (read-only, cannot be edited)
    cardNumberController.text = card.maskedNumber;
    expiryDateController.text = card.expiryDate;
    // Don't populate CVV as API doesn't return it
    cvvController.clear();
    isDefaultCard.value = card.isDefault;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main content container
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Debit/Credit card',
                        style: AppTextStyles.popinMediumTextStyle(
                          fontSize: 16,
                          color: AppColors.greyText,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.grey),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Name on card',
                      hintStyle: AppTextStyles.popinRegularTextStyle(
                        fontSize: 14,
                        color: AppColors.color919191
                      ),
                      filled: true,
                      fillColor: AppColors.lightGreyF5F7F8,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: cardNumberController,
                    decoration: InputDecoration(
                      hintText: 'Card number (cannot be changed)',
                      hintStyle: AppTextStyles.popinRegularTextStyle(
                          fontSize: 14,
                          color: AppColors.color919191
                      ),
                      filled: true,
                      fillColor: AppColors.lightGreyF5F7F8,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: false, // Disable card number editing
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: expiryDateController,
                          decoration: InputDecoration(
                            hintText: 'Expiry date',
                            hintStyle: AppTextStyles.popinRegularTextStyle(
                                fontSize: 14,
                                color: AppColors.color919191
                            ),
                            filled: true,
                            fillColor: AppColors.lightGreyF5F7F8,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(left: 10,right: 5),
                                child: SvgPicture.asset(AppAssets.expire_calendar,height: 20,width: 20,)),
                            prefixIconConstraints: BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: cvvController,
                          decoration: InputDecoration(
                            hintText: 'CVV',
                            hintStyle: AppTextStyles.popinRegularTextStyle(
                                fontSize: 14,
                                color: AppColors.color919191
                            ),
                            filled: true,
                            fillColor: AppColors.lightGreyF5F7F8,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          keyboardType: TextInputType.number,
                          obscureText: true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Obx(() => Row(
                    children: [
                      GestureDetector(
                        onTap: () => isDefaultCard.value = !isDefaultCard.value,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDefaultCard.value ? AppColors.primaryColor : AppColors.grey,
                              width: 2,
                            ),
                            color: isDefaultCard.value ? AppColors.primaryColor : Colors.transparent,
                          ),
                          child: isDefaultCard.value
                              ? Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Use this as a default payment method.',
                        style: AppTextStyles.regularTextStyle(
                          fontSize: 12,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  )),
                ],
              ),
            ),
            // Submit Button - Attached at bottom
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _updateCard(index),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      'Save card',
                      style: AppTextStyles.mediumTextStyle(
                        fontSize: 16,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showAddCardDialog(BuildContext context) {
    _resetForm();
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main content container
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Debit/Credit card',
                        style: AppTextStyles.popinMediumTextStyle(
                          fontSize: 16,
                          color: AppColors.greyText,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.grey),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Name on card',
                      hintStyle: AppTextStyles.popinRegularTextStyle(
                          fontSize: 14,
                          color: AppColors.color919191
                      ),
                      filled: true,
                      fillColor: AppColors.lightGreyF5F7F8,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: cardNumberController,
                    decoration: InputDecoration(
                      hintText: 'Card number',
                      hintStyle: AppTextStyles.popinRegularTextStyle(
                          fontSize: 14,
                          color: AppColors.color919191
                      ),
                      filled: true,
                      fillColor: AppColors.lightGreyF5F7F8,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CardNumberFormatter(),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: expiryDateController,
                          decoration: InputDecoration(
                            hintText: 'MM/YY',
                            hintStyle: AppTextStyles.popinRegularTextStyle(
                                fontSize: 14,
                                color: AppColors.color919191
                            ),
                            filled: true,
                            fillColor: AppColors.lightGreyF5F7F8,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Padding(
                                padding: EdgeInsets.only(left: 10,right: 5),
                                child: SvgPicture.asset(AppAssets.expire_calendar,height: 20,width: 20,)),
                            prefixIconConstraints: BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            ExpiryDateFormatter(),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: cvvController,
                          decoration: InputDecoration(
                            hintText: 'CVV',
                            hintStyle: AppTextStyles.popinRegularTextStyle(
                                fontSize: 14,
                                color: AppColors.color919191
                            ),
                            filled: true,
                            fillColor: AppColors.lightGreyF5F7F8,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Obx(() => Row(
                    children: [
                      GestureDetector(
                        onTap: () => isDefaultCard.value = !isDefaultCard.value,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDefaultCard.value ? AppColors.primaryColor : AppColors.grey,
                              width: 2,
                            ),
                            color: isDefaultCard.value ? AppColors.primaryColor : Colors.transparent,
                          ),
                          child: isDefaultCard.value
                              ? Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Use this as a default payment method.',
                        style: AppTextStyles.regularTextStyle(
                          fontSize: 12,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  )),
                ],
              ),
            ),
            // Submit Button - Attached at bottom
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _saveCard(),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      'Save card',
                      style: AppTextStyles.mediumTextStyle(
                        fontSize: 16,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showEditCardDialog(BuildContext context, CardModel card, int index) {
    nameController.text = card.nameOnCard;
    cardNumberController.text = card.maskedNumber;
    expiryDateController.text = card.expiryDate;
    cvvController.clear();
    isDefaultCard.value = card.isDefault;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main content container
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Debit/Credit card',
                        style: AppTextStyles.popinMediumTextStyle(
                          fontSize: 16,
                          color: AppColors.greyText,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.grey),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Name on card',
                      hintStyle: AppTextStyles.popinRegularTextStyle(
                          fontSize: 14,
                          color: AppColors.color919191
                      ),
                      filled: true,
                      fillColor: AppColors.lightGreyF5F7F8,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: cardNumberController,
                    decoration: InputDecoration(
                      hintText: 'Card number (cannot be changed)',
                      hintStyle: AppTextStyles.popinRegularTextStyle(
                          fontSize: 14,
                          color: AppColors.color919191
                      ),
                      filled: true,
                      fillColor: AppColors.lightGreyF5F7F8,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: false,
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: expiryDateController,
                          decoration: InputDecoration(
                            hintText: 'MM/YY',
                            hintStyle: AppTextStyles.popinRegularTextStyle(
                                fontSize: 14,
                                color: AppColors.color919191
                            ),
                            filled: true,
                            fillColor: AppColors.lightGreyF5F7F8,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Padding(
                                padding: EdgeInsets.only(left: 10,right: 5),
                                child: SvgPicture.asset(AppAssets.expire_calendar,height: 20,width: 20,)),
                            prefixIconConstraints: BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            ExpiryDateFormatter(),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: cvvController,
                          decoration: InputDecoration(
                            hintText: 'CVV',
                            hintStyle: AppTextStyles.popinRegularTextStyle(
                                fontSize: 14,
                                color: AppColors.color919191
                            ),
                            filled: true,
                            fillColor: AppColors.lightGreyF5F7F8,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Obx(() => Row(
                    children: [
                      GestureDetector(
                        onTap: () => isDefaultCard.value = !isDefaultCard.value,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDefaultCard.value ? AppColors.primaryColor : AppColors.grey,
                              width: 2,
                            ),
                            color: isDefaultCard.value ? AppColors.primaryColor : Colors.transparent,
                          ),
                          child: isDefaultCard.value
                              ? Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Use this as a default payment method.',
                        style: AppTextStyles.regularTextStyle(
                          fontSize: 12,
                          color: AppColors.black,
                        ),
                      ),
                    ],
                  )),
                ],
              ),
            ),
            // Submit Button - Attached at bottom
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _updateCard(index),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      'Save card',
                      style: AppTextStyles.mediumTextStyle(
                        fontSize: 16,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showRemoveCardDialog(BuildContext context, int index) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Remove card',
                style: AppTextStyles.mediumTextStyle(
                  fontSize: 24,
                  color: AppColors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'This card will no longer be saved for future bookings.',
                style: AppTextStyles.regularTextStyle(
                  fontSize: 16,
                  color: AppColors.color919191,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
                  SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back();
                    _removeCard(index);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.redDark,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Yes remove',
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
                  'No, keep it',
                  style: AppTextStyles.mediumTextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? validateCardHolderName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Card holder name is required';
    }
    if (value.length < 2) {
      return 'Card holder name must be at least 2 characters';
    }
    return null;
  }

  String? validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Card number is required';
    }
    // Remove spaces and check if it's numeric
    String cleaned = value.replaceAll(' ', '');
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'Card number must contain only digits';
    }
    return null;
  }

  String? validateExpiryDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Expiry date is required';
    }
    // Check format MM/YY or MM/YYYY
    if (!RegExp(r'^\d{2}/\d{2,4}$').hasMatch(value)) {
      return 'Please enter date in MM/YY or MM/YYYY format';
    }
    return null;
  }

  void _saveCard() {
    // Validate fields
    String? nameError = validateCardHolderName(nameController.text);
    String? cardNumberError = validateCardNumber(cardNumberController.text);
//   String? expiryError = validateExpiryDate(expiryDateController.text);

    if (nameError != null) {
      showResponseDialog(
        message: nameError,
        title: 'Validation Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
      return;
    }

    if (cardNumberError != null) {
      showResponseDialog(
        message: cardNumberError,
        title: 'Validation Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
      return;
    }

 /*   if (expiryError != null) {
      showResponseDialog(
        message: expiryError,
        title: 'Validation Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
      return;
    }*/

    // Parse expiry date
    List<String> expiryParts = expiryDateController.text.split('/');
    int expiryMonth = int.tryParse(expiryParts[0]) ?? 0;
    int expiryYear = expiryParts[1].length == 2 
        ? 2000 + (int.tryParse(expiryParts[1]) ?? 0)
        : int.tryParse(expiryParts[1]) ?? 0;

    if (expiryMonth < 1 || expiryMonth > 12) {
      showResponseDialog(
        message: 'Invalid expiry month. Please enter a valid month (01-12)',
        title: 'Validation Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
      return;
    }

    // Call add card API
    callAddCardAPI(
      nameController.text.trim(),
      cardNumberController.text.replaceAll(' ', ''),
      expiryMonth,
      expiryYear,
      isDefaultCard.value,
    );
  }

  void callAddCardAPI(String cardHolderName, String cardNumber, int expiryMonth, int expiryYear, bool isDefault) {
    Map<String, dynamic> toJson() {
      final Map<String, dynamic> data = <String, dynamic>{};
      data['card_holder_name'] = cardHolderName;
      data['card_number'] = cardNumber;
      data['expiry_month'] = expiryMonth;
      data['expiry_year'] = expiryYear;
      data['is_default'] = isDefault;
      return data;
    }
    
    var service = _repository.sendPostApiRequest(
      toJson,
      add_card,
      true, // isToken = true (requires authentication)
    );

    callDataService(
      service,
      onSuccess: _handleAddCardSuccess,
      onError: _handleAddCardError,
      isShowLoading: true,
    );
  }

  Future<void> _handleAddCardSuccess(dynamic baseResponse) async {
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
      String message = responseData['message'] ?? 'Card added successfully';

      if (success == true && responseData['data'] != null) {
        // Analytics: Log card added
        

        // Add the new card to the list
        Map<String, dynamic> cardData = responseData['data'] as Map<String, dynamic>;
        CardModel newCard = CardModel.fromJson(cardData);
        cards.add(newCard);
        
        // Set as default if needed
        if (isDefaultCard.value) {
          selectedCardIndex.value = cards.length - 1;
        }

        Get.back();
        _resetForm();
        
        // Show success message
        showResponseDialog(
          message: message,
          title: 'Success',
          isError: false,
          showButton: true,
          onOkPressed: () {},
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

  void _handleAddCardError(dynamic e) {
    if (e is BaseException) {
      showResponseDialog(
        message: e.message,
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    } else {
      showResponseDialog(
        message: "An error occurred while adding the card",
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    }
  }

  void _updateCard(int index) {
    // Validate fields
    String? nameError = validateCardHolderName(nameController.text);
    String? expiryError = validateExpiryDate(expiryDateController.text);

    if (nameError != null) {
      showResponseDialog(
        message: nameError,
        title: 'Validation Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
      return;
    }

    if (expiryError != null) {
      showResponseDialog(
        message: expiryError,
        title: 'Validation Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
      return;
    }

    // Parse expiry date
    List<String> expiryParts = expiryDateController.text.split('/');
    int expiryMonth = int.tryParse(expiryParts[0]) ?? 0;
    int expiryYear = expiryParts[1].length == 2 
        ? 2000 + (int.tryParse(expiryParts[1]) ?? 0)
        : int.tryParse(expiryParts[1]) ?? 0;

    if (expiryMonth < 1 || expiryMonth > 12) {
      showResponseDialog(
        message: 'Invalid expiry month. Please enter a valid month (01-12)',
        title: 'Validation Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
      return;
    }

    // Call edit card API
    callEditCardAPI(
      cards[index].id,
      nameController.text.trim(),
      expiryMonth,
      expiryYear,
      isDefaultCard.value,
    );
  }

  void callEditCardAPI(String cardId, String cardHolderName, int expiryMonth, int expiryYear, bool isDefault) {
    Map<String, dynamic> toJson() {
      final Map<String, dynamic> data = <String, dynamic>{};
      data['card_holder_name'] = cardHolderName;
      data['expiry_month'] = expiryMonth;
      data['expiry_year'] = expiryYear;
      data['is_default'] = isDefault;
      return data;
    }
    
    // Construct API endpoint with card ID
    String apiEndpoint = '$edit_card/$cardId';
    
    var service = _repository.sendPutApiRequest(
      toJson,
      apiEndpoint,
      true, // isToken = true (requires authentication)
    );

    callDataService(
      service,
      onSuccess: (response) => _handleEditCardSuccess(response, cardId),
      onError: _handleEditCardError,
      isShowLoading: true,
    );
  }

  Future<void> _handleEditCardSuccess(dynamic baseResponse, String cardId) async {
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
      String message = responseData['message'] ?? 'Card updated successfully';

      if (success == true) {
        // Analytics: Log card updated
        

        // Refresh cards list
        fetchCardsFromAPI();
        
        Get.back();
        _resetForm();
        
        // Show success message
        showResponseDialog(
          message: message,
          title: 'Success',
          isError: false,
          showButton: true,
          onOkPressed: () {},
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

  void _handleEditCardError(dynamic e) {
    if (e is BaseException) {
      showResponseDialog(
        message: e.message,
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    } else {
      showResponseDialog(
        message: "An error occurred while updating the card",
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    }
  }

  void _removeCard(int index) {
    if (index < 0 || index >= cards.length) return;
    
    String cardId = cards[index].id;
    callDeleteCardAPI(cardId, index);
  }

  void callDeleteCardAPI(String cardId, int index) {
    // Construct API endpoint with card ID
    String apiEndpoint = '$delete_card/$cardId';
    
    var service = _repository.sendDeleteApiRequest(
      apiEndpoint,
      true, // isToken = true (requires authentication)
    );

    callDataService(
      service,
      onSuccess: (response) => _handleDeleteCardSuccess(response, index),
      onError: _handleDeleteCardError,
      isShowLoading: true,
    );
  }

  Future<void> _handleDeleteCardSuccess(dynamic baseResponse, int index) async {
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
      String message = responseData['message'] ?? 'Card deleted successfully';

      if (success == true) {
        // Analytics: Log card deleted
        

        // Remove card from list
        cards.removeAt(index);
        if (selectedCardIndex.value >= cards.length) {
          selectedCardIndex.value = cards.length > 0 ? 0 : -1;
        }
        
        // Show success message
        showResponseDialog(
          message: message,
          title: 'Success',
          isError: false,
          showButton: true,
          onOkPressed: () {},
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

  void _handleDeleteCardError(dynamic e) {
    if (e is BaseException) {
      showResponseDialog(
        message: e.message,
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    } else {
      showResponseDialog(
        message: "An error occurred while deleting the card",
        title: 'Error',
        isError: true,
        showButton: true,
        onOkPressed: () {},
      );
    }
  }

  void _resetForm() {
    nameController.clear();
    cardNumberController.clear();
    expiryDateController.clear();
    cvvController.clear();
    isDefaultCard.value = false;
  }

  @override
  void onClose() {
    nameController.dispose();
    cardNumberController.dispose();
    expiryDateController.dispose();
    cvvController.dispose();
    super.onClose();
  }
}

