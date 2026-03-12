import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import '../../utils/AppText.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../core/widget/animated_loader.dart';
import 'PaymentMethodController.dart';
import 'PaymentMethodType.dart';

class PaymentMethodScreen extends StatelessWidget {
  final controller = Get.put(PaymentMethodController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.white,
        elevation: 4, // 🔴 Add shadow depth (try 2-8)
        shadowColor: Colors.black.withOpacity(
          0.1,
        ), // Optional: customize shadow color
        scrolledUnderElevation: 4,
        leading: IconButton(
          icon: SvgPicture.asset(AppAssets.back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          AppText.paymentMethod,
          style: AppTextStyles.mediumTextStyle(fontSize: 20,color: AppColors.black),
        ),
        centerTitle: true,
      ),
      body: Obx(() => controller.isLoading.value
          ? _buildLoadingScreen()
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Credit/Debit Card
                        _buildPaymentOption(
                          type: PaymentMethodType.creditCard,
                          imagePath: AppAssets.credit_card,
                          iconColor: Colors.red,
                          title: AppText.creditDebitCard,
                        ),

                        SizedBox(height: 16),

                        // Google Pay
                        _buildPaymentOption(
                          type: PaymentMethodType.googlePay,
                          imagePath: 'google',
                          iconColor: Colors.blue,
                          title: AppText.googlePay,
                        ),

                        SizedBox(height: 16),

                        // Apple Pay
                        _buildPaymentOption(
                          type: PaymentMethodType.applePay,
                          imagePath: 'apple',
                          iconColor: AppColors.black,
                          title: AppText.applePay,
                        ),

                   /*     SizedBox(height: 16),

                        // PayPal
                        _buildPaymentOption(
                          type: PaymentMethodType.paypal,
                          imagePath: AppAssets.paypal,
                          iconColor: Colors.blue.shade700,
                          title: AppText.paypal,
                        ),*/
                      ],
                    ),
                  ),
                ),

              ],
            )),
      bottomNavigationBar: Obx(() => controller.isLoading.value
          ? SizedBox.shrink()
          : _buildBottomButton()),
    );
  }
  
  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Custom Circular Loader (matching your teal color)
          AnimatedLoader(
            assetPath: AppAssets.loader,
            width: 80,
            height: 80,
            duration: const Duration(seconds: 2),
          ),
          SizedBox(height: 32),
          Text(
            AppText.pleaseWait,
            style: AppTextStyles.popinSemiboldTextStyle(
              fontSize: 18,
              color: AppColors.primaryColor,
            ),
          ),
          SizedBox(height: 12),
          Text(
            AppText.almostThere,
            style: AppTextStyles.popinMediumTextStyle(
              fontSize: 14,
              color: AppColors.blueColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required PaymentMethodType type,
    required String imagePath,
    required Color iconColor,
    required String title,
  }) {
    return Obx(() {
      bool isSelected = controller.selectedPaymentMethod.value == type;
      bool isCreditCard = type == PaymentMethodType.creditCard;

      return Column(
        children: [
          GestureDetector(
            onTap: () => controller.selectPaymentMethod(type),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.grey,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                 (imagePath == "google") ? Image.asset(AppAssets.google_pay) : (imagePath == "apple") ? Image.asset(AppAssets.apple_pay) : SvgPicture.asset(imagePath),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.mediumTextStyle(
                        fontSize: 16,
                        color: AppColors.color2D3648,
                      ),
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.black
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.black,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),

          // Card Details Form (only for Credit Card)
          if (isCreditCard && isSelected) ...[
            SizedBox(height: 16),
            _buildCardDetailsForm(),
          ],
        ],
      );
    });
  }

  Widget _buildCardDetailsForm() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Number
          Text(
            AppText.cardNumber,
            style: AppTextStyles.mediumTextStyle(
              fontSize: 13,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: controller.cardNumberController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
              _CardNumberInputFormatter(),
            ],
            decoration: InputDecoration(
              hintText: AppText.cardNumberHint,
              hintStyle: AppTextStyles.regularTextStyle(
                fontSize: 14,
                color: AppColors.greyText,
              ),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryColor),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: AppTextStyles.regularTextStyle(
              fontSize: 14,
              color: AppColors.black,
            ),
          ),

          SizedBox(height: 16),

          // Expiry Date and CVV
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppText.expiryDate,
                      style: AppTextStyles.mediumTextStyle(
                        fontSize: 13,
                        color: AppColors.black,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: controller.expiryDateController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        _ExpiryDateInputFormatter(),
                      ],
                      decoration: InputDecoration(
                        hintText: AppText.expiryDateHint,
                        hintStyle: AppTextStyles.regularTextStyle(
                          fontSize: 14,
                          color: AppColors.greyText,
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primaryColor),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      style: AppTextStyles.regularTextStyle(
                        fontSize: 14,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppText.cvv,
                      style: AppTextStyles.mediumTextStyle(
                        fontSize: 13,
                        color: AppColors.black,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: controller.cvvController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      decoration: InputDecoration(
                        hintText: AppText.cvvHint,
                        hintStyle: AppTextStyles.regularTextStyle(
                          fontSize: 14,
                          color: AppColors.greyText,
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primaryColor),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      style: AppTextStyles.regularTextStyle(
                        fontSize: 14,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Name on Card
          Text(
            AppText.nameOnCard,
            style: AppTextStyles.mediumTextStyle(
              fontSize: 13,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: controller.cardHolderNameController,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: AppText.enterCardholderName,
              hintStyle: AppTextStyles.regularTextStyle(
                fontSize: 14,
                color: AppColors.greyText,
              ),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryColor),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: AppTextStyles.regularTextStyle(
              fontSize: 14,
              color: AppColors.black,
            ),
          ),

          SizedBox(height: 16),

          // Save Card Details Checkbox
          Obx(() => Row(
                children: [
                  GestureDetector(
                    onTap: () => controller.toggleSaveCard(!controller.saveCardDetails.value),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: controller.saveCardDetails.value
                              ? AppColors.primaryColor
                              : Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                      child: controller.saveCardDetails.value
                          ? Center(
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => controller.toggleSaveCard(!controller.saveCardDetails.value),
                    child: Text(
                      AppText.saveCardDetails,
                      style: AppTextStyles.regularTextStyle(
                        fontSize: 13,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        onPressed: controller.continuePayment,
        style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            padding: EdgeInsets.symmetric(vertical: 15)
        ),
        child: Text(
          AppText.continueText,
          style: AppTextStyles.mediumTextStyle(
            fontSize: 16,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}

// Card Number Input Formatter
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

// Expiry Date Input Formatter
class _ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 2 == 0 && nonZeroIndex != text.length) {
        buffer.write('/');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }


}