import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

import '../../../../common/base_view.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/fonts.dart';
import '../../../../theme/font_sizes.dart';
import '../../../../theme/hight_width_sizes.dart';
import '../../../../widgets/custom_text_field.dart';
import 'bank_account_controller.dart';

class BankAccountView extends BaseView<BankAccountController> {
  const BankAccountView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 1),
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000), // #0000001A
              blurRadius: HightWidthSizes.setValue_10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: AppBar(
          backgroundColor: AppColor.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: AppColor.color_2D3648,
            ),
            onPressed: () => Get.back(),
          ),
          centerTitle: true,
          title: Text(
            'Bank account',
            style: TextStyle(
              fontFamily: AppFonts.rubikMedium,
              fontWeight: FontWeight.w500,
              fontSize: FontSizes.setFontValue_18,
              color: AppColor.color_2D3648,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildView(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: Container(
        color: AppColor.white,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: HightWidthSizes.setValue_16,
            vertical: HightWidthSizes.setValue_20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account holder name field
              CustomTextField(
                label: 'Account holder name',
                hintText: 'Enter name',
                controller: controller.accountHolderNameController,
                validator: (value) =>
                    controller.validateNotEmpty(value, 'account holder name'),
                onChanged: (_) => controller.onFieldChanged(),
              ),
              SizedBox(height: HightWidthSizes.setValue_16),

              // Account number field
              CustomTextField(
                label: 'Account number',
                hintText: 'Enter account number',
                controller: controller.accountNumberController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) =>
                    controller.validateNotEmpty(value, 'account number'),
                onChanged: (_) => controller.onFieldChanged(),
              ),
              SizedBox(height: HightWidthSizes.setValue_16),

              // Sort code field
              CustomTextField(
                label: 'Sort code',
                hintText: '00-00-00',
                controller: controller.sortCodeController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                  _SortCodeInputFormatter(),
                ],
                validator: controller.validateSortCode,
                onChanged: (_) => controller.onFieldChanged(),
              ),
              SizedBox(height: HightWidthSizes.setValue_20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget? bottomNavigationBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: HightWidthSizes.setValue_16,
        vertical: HightWidthSizes.setValue_16,
      ),
      decoration: BoxDecoration(
        color: AppColor.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: HightWidthSizes.setValue_10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.color_2FC4B2,
              foregroundColor: AppColor.white,
              elevation: 0,
              minimumSize: Size(double.infinity, HightWidthSizes.setValue_45),
              padding: EdgeInsets.symmetric(
                  vertical: HightWidthSizes.setValue_12,
                  horizontal: HightWidthSizes.setValue_16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  HightWidthSizes.setValue_10,
                ),
              ),
            ),
            onPressed: controller.onAddAccount,
            child: Obx(
              () => Text(
                controller.hasBankDetails.value
                    ? 'Update account'
                    : 'Add account',
                style: TextStyle(
                  fontFamily: AppFonts.rubikMedium,
                  fontWeight: FontWeight.w500,
                  color: AppColor.white,
                  fontSize: FontSizes.setFontValue_16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom formatter for sort code (00-00-00 format)
class _SortCodeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('-', '');

    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 2 == 0 && i < 6) {
        buffer.write('-');
      }
      buffer.write(text[i]);
    }

    return newValue.copyWith(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
