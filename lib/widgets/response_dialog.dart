import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/colors.dart';
import '../theme/font_sizes.dart';
import '../theme/fonts.dart';
import '../theme/hight_width_sizes.dart';

/// Shows a response dialog with message and OK button
/// Can be used for both success and error messages
void showResponseDialog({
  required String message,
  String? title,
  bool isError = false,
  VoidCallback? onOkPressed,
  bool showButton = true,
}) {
  showDialog(
    context: Get.context!,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext context) {
      // Auto-dismiss after 2 seconds if showButton is false
      if (!showButton) {
        Timer(const Duration(seconds: 2), () {
          Navigator.of(context).pop();
          // Wait 2 seconds after dismiss, then call onOkPressed
          // Timer(const Duration(seconds: 2), () {
          onOkPressed?.call();
          // });
        });
      }

      return PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: HightWidthSizes.setValue_16,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(HightWidthSizes.setValue_10),
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: HightWidthSizes.setValue_10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: EdgeInsets.all(HightWidthSizes.setValue_24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon (optional - can show success or error icon)
                if (isError)
                  Container(
                    width: HightWidthSizes.setValue_60,
                    height: HightWidthSizes.setValue_60,
                    decoration: BoxDecoration(
                      color: AppColor.color_B53232.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      color: AppColor.color_B53232,
                      size: HightWidthSizes.setValue_30,
                    ),
                  )
                else
                  Container(
                    width: HightWidthSizes.setValue_60,
                    height: HightWidthSizes.setValue_60,
                    decoration: BoxDecoration(
                      color: AppColor.color_2FC4B2.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      color: AppColor.color_2FC4B2,
                      size: HightWidthSizes.setValue_30,
                    ),
                  ),
                SizedBox(height: HightWidthSizes.setValue_20),

                // Title (optional)
                if (title != null && title.isNotEmpty) ...[
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.rubikMedium,
                      fontWeight: FontWeight.w500,
                      fontSize: FontSizes.setFontValue_20,
                      color: isError
                          ? AppColor.color_B53232
                          : AppColor.color_2FC4B2,
                    ),
                  ),
                  SizedBox(height: HightWidthSizes.setValue_12),
                ],

                // Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.rubikRegular,
                    fontWeight: FontWeight.w400,
                    fontSize: FontSizes.setFontValue_14,
                    color: AppColor.color_2D2D2D,
                    height: 1.5,
                  ),
                ),
                if (showButton) ...[
                  SizedBox(height: HightWidthSizes.setValue_24),

                  // OK button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onOkPressed?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isError
                            ? AppColor.color_B53232
                            : AppColor.color_2FC4B2,
                        foregroundColor: AppColor.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          vertical: HightWidthSizes.setValue_14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            HightWidthSizes.setValue_10,
                          ),
                        ),
                      ),
                      child: Text(
                        'OK',
                        style: TextStyle(
                          fontFamily: AppFonts.rubikMedium,
                          fontWeight: FontWeight.w500,
                          fontSize: FontSizes.setFontValue_16,
                          color: AppColor.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Shows a confirmation dialog with Yes/No buttons
/// Used for confirming actions like deleting existing records
void showConfirmationDialog({
  required String message,
  String? title,
  required VoidCallback onYesPressed,
  VoidCallback? onNoPressed,
  String yesText = 'Yes',
  String noText = 'No',
}) {
  showDialog(
    context: Get.context!,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext context) {
      return PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: HightWidthSizes.setValue_16,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(HightWidthSizes.setValue_10),
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: HightWidthSizes.setValue_10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: EdgeInsets.all(HightWidthSizes.setValue_24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Error icon
                Container(
                  width: HightWidthSizes.setValue_60,
                  height: HightWidthSizes.setValue_60,
                  decoration: BoxDecoration(
                    color: AppColor.color_B53232.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    color: AppColor.color_B53232,
                    size: HightWidthSizes.setValue_30,
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_20),

                // Title (optional)
                if (title != null && title.isNotEmpty) ...[
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.rubikMedium,
                      fontWeight: FontWeight.w500,
                      fontSize: FontSizes.setFontValue_20,
                      color: AppColor.color_B53232,
                    ),
                  ),
                  SizedBox(height: HightWidthSizes.setValue_12),
                ],

                // Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.rubikRegular,
                    fontWeight: FontWeight.w400,
                    fontSize: FontSizes.setFontValue_14,
                    color: AppColor.color_2D2D2D,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_24),

                // Yes button (Primary)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onYesPressed();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.color_2FC4B2,
                      foregroundColor: AppColor.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        vertical: HightWidthSizes.setValue_14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          HightWidthSizes.setValue_10,
                        ),
                      ),
                    ),
                    child: Text(
                      yesText,
                      style: TextStyle(
                        fontFamily: AppFonts.rubikMedium,
                        fontWeight: FontWeight.w500,
                        fontSize: FontSizes.setFontValue_16,
                        color: AppColor.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_12),

                // No button (Secondary - text link)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onNoPressed?.call();
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: HightWidthSizes.setValue_14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          HightWidthSizes.setValue_10,
                        ),
                      ),
                    ),
                    child: Text(
                      noText,
                      style: TextStyle(
                        fontFamily: AppFonts.rubikRegular,
                        fontWeight: FontWeight.w400,
                        fontSize: FontSizes.setFontValue_16,
                        color: AppColor.color_32435F,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
